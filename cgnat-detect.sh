#!/usr/bin/env bash
# CGNAT detector: see README.md for the method.
# Reports: CGNAT or not, Docker or not, ChromeOS (Crostini) or not,
# and whether we sit on an RFC1918 LAN behind the NAT of a router.
#
# Needs: curl, mtr, iproute2   (sudo apt install -y iproute2 mtr curl)
# Usage: ./cgnat-detect.sh [-v]   (-v also prints the mtr output)

set -u

VERBOSE=0
[ "${1:-}" = "-v" ] && VERBOSE=1

for tool in curl mtr ip; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Missing tool: $tool  (sudo apt install -y iproute2 mtr curl)" >&2
        exit 2
    fi
done

ip2int() {
    local IFS=.
    # shellcheck disable=SC2086
    set -- $1
    echo $(( ($1 << 24) + ($2 << 16) + ($3 << 8) + $4 ))
}

# in_cidr 10.1.2.3 10.0.0.0/8
in_cidr() {
    local ip=$1 net=${2%/*} bits=${2#*/}
    [[ $ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || return 1
    local mask=$(( (0xFFFFFFFF << (32 - bits)) & 0xFFFFFFFF ))
    (( ($(ip2int "$ip") & mask) == ($(ip2int "$net") & mask) ))
}

is_rfc1918() {
    in_cidr "$1" 10.0.0.0/8 || in_cidr "$1" 172.16.0.0/12 || in_cidr "$1" 192.168.0.0/16
}

is_chromeos_net() {
    in_cidr "$1" 100.115.92.0/23
}

is_cgnat_range() {
    in_cidr "$1" 100.64.0.0/10 && ! is_chromeos_net "$1"
}

# 1. public IPv4 as seen from the Internet
PUBLIC_IP=""
for url in https://ifconfig.me https://api.ipify.org https://ipv4.icanhazip.com; do
    PUBLIC_IP=$(curl -s -4 --max-time 5 "$url" | tr -d '[:space:]')
    [[ $PUBLIC_IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] && break
    PUBLIC_IP=""
done
if [ -z "$PUBLIC_IP" ]; then
    echo "Could not determine public IPv4 address (no IPv4 Internet access?)" >&2
    exit 2
fi

# local source address used for the route towards the Internet
LOCAL_IP=$(ip -4 route get "$PUBLIC_IP" 2>/dev/null | awk '{for (i=1;i<NF;i++) if ($i=="src") {print $(i+1); exit}}')
GATEWAY=$(ip -4 route show default 2>/dev/null | awk '{print $3; exit}')

# 2. traceroute to our own public IPv4
MTR_OUT=$(mtr -nrc2 "$PUBLIC_IP" 2>&1)
mapfile -t HOPS < <(awk '/^ *[0-9]+\.\|--/ {print $2}' <<<"$MTR_OUT")
[ "$VERBOSE" = 1 ] && echo "$MTR_OUT" && echo

# Docker?
IN_DOCKER=no
if [ -f /.dockerenv ] || grep -qa docker /proc/1/cgroup 2>/dev/null; then
    IN_DOCKER=yes
fi

# ChromeOS (Crostini)? Filesystem markers only exist in the penguin container itself,
# so also look for the ChromeOS-internal 100.115.92.0/23 network (e.g. Docker inside Crostini).
ON_CHROMEOS=no
if [ -d /opt/google/cros-containers ] || [ -e /dev/.cros_milestone ]; then
    ON_CHROMEOS=yes
fi
{ [ -n "$LOCAL_IP" ] && is_chromeos_net "$LOCAL_IP"; } && ON_CHROMEOS=yes
for h in "${HOPS[@]}"; do
    is_chromeos_net "$h" && ON_CHROMEOS=yes
done

# Strip the virtual hops (Docker bridge, ChromeOS VM/container) to get the real path
REAL_HOPS=()
for i in "${!HOPS[@]}"; do
    h=${HOPS[$i]}
    [ "$IN_DOCKER" = yes ] && [ "$i" = 0 ] && [ "$h" = "$GATEWAY" ] && continue
    is_chromeos_net "$h" && continue
    REAL_HOPS+=("$h")
done

# 3. does our own router answer for the public IPv4?
PUBLIC_POS=-1
for i in "${!REAL_HOPS[@]}"; do
    [ "${REAL_HOPS[$i]}" = "$PUBLIC_IP" ] && PUBLIC_POS=$i && break
done
CGNAT_HOP=""
for h in "${REAL_HOPS[@]}"; do
    is_cgnat_range "$h" && CGNAT_HOP=$h && break
done

if [ "$LOCAL_IP" = "$PUBLIC_IP" ]; then
    CGNAT="no (public IPv4 is on this machine)"
elif [ "$PUBLIC_POS" = 0 ]; then
    CGNAT="no (your router answers on the public IPv4)"
elif [ "$PUBLIC_POS" -gt 0 ]; then
    CGNAT="no, but public IPv4 is $((PUBLIC_POS + 1)) hops away (double NAT?)"
elif [ -n "$CGNAT_HOP" ]; then
    CGNAT="YES (public IPv4 not reachable in traceroute, CGNAT hop $CGNAT_HOP)"
else
    CGNAT="YES, probably (public IPv4 not reachable in traceroute)"
fi

# 4. RFC1918 LAN behind a router's NAT?
LAN="unknown"
LAN_IP=""
if [ "$LOCAL_IP" = "$PUBLIC_IP" ]; then
    LAN="no"
elif [ "$IN_DOCKER" = no ] && [ "$ON_CHROMEOS" = no ] && [ -n "$LOCAL_IP" ]; then
    is_rfc1918 "$LOCAL_IP" && LAN_IP=$LOCAL_IP
fi
# inside Docker / ChromeOS the LAN shows up as the first real hop (e.g. 192.168.1.254)
if [ -z "$LAN_IP" ] && [ "${#REAL_HOPS[@]}" -gt 0 ] && is_rfc1918 "${REAL_HOPS[0]}"; then
    LAN_IP=${REAL_HOPS[0]}
fi
if [ -n "$LAN_IP" ]; then
    LAN="yes ($LAN_IP)"
elif [ "$LAN" = unknown ] && [ "$PUBLIC_POS" = 0 ] && [ "$ON_CHROMEOS" = yes ]; then
    LAN="unknown (hidden behind ChromeOS NAT)"
fi

echo "Public IPv4 : $PUBLIC_IP"
echo "Local IPv4  : ${LOCAL_IP:-?}   gateway: ${GATEWAY:-?}"
echo "Real hops   : ${REAL_HOPS[*]:-none}"
echo
echo "CGNAT       : $CGNAT"
echo "Docker      : $IN_DOCKER"
echo "ChromeOS    : $ON_CHROMEOS"
echo "RFC1918 LAN : $LAN"
