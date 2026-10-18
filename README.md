# CGNAT-detector


With CGNAT, your CPE (router) has no public IPv4 address on its WAN interface. A typical CGNAT WAN IP address is 100.64.193.104, but it might be another address


So how can we find that (without UPnP or access to the router/CPE)?

Method: 
1. find the real public ipv4 with which you are seen on Internet.
2. find the traceroute to that ipv4
3. in the traceroute, check if your local router responds to that public ipv4. If not: CGNAT
4. based on the intermediate IP addresses, determine the type of connection and/or NAT types

# non-CGAT, typical LAN (with RFC1918 = local NAT)
```
$ mtr -nrc2 $(curl -s -4 ifconfig.me)
Start: 2026-10-18T08:33:45+0200
HOST: xubuntu                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 88.75.45.236               0.0%     2   61.5  54.1  46.6  61.5  10.5

$ ip a show | grep 192
    inet 192.168.178.31/24 brd 192.168.178.255 scope global dynamic noprefixroute wlp2s0

```

# CGNAT

```
$ mtr -nrc2 $(curl -s -4 ifconfig.me)
Start: 2026-10-17T14:49:54+0200
HOST: x360                        Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 192.168.1.254              0.0%     2    8.4   8.3   8.1   8.4   0.2
  2.|-- ???                       100.0     2    0.0   0.0   0.0   0.0   0.0
  3.|-- 100.64.0.1                 0.0%     2   12.7  12.8  12.7  12.8   0.1
  4.|-- ???                       100.0     2    0.0   0.0   0.0   0.0   0.0
```

# CGNAT, from within docker

```
root@9952b12eed9a:/# mtr -nrc2 $(curl -s -4 ifconfig.me)
Start: 2026-10-18T22:29:44+0200
HOST: 9952b12eed9a                Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 172.17.0.1                 0.0%     2    0.2   0.2   0.2   0.2   0.0
  2.|-- 192.168.1.254              0.0%     2   10.9  10.2   9.4  10.9   1.1
  3.|-- ???                       100.0     2    0.0   0.0   0.0   0.0   0.0
  4.|-- 100.64.0.1                 0.0%     2   15.1  14.0  12.8  15.1   1.6
  5.|-- ???                       100.0     2    0.0   0.0   0.0   0.0   0.0
root@9952b12eed9a:/#

root@9952b12eed9a:/# ip route show | grep default
default via 172.17.0.1 dev eth0 
```

# via mobile hotspot to 4G/5G, probably some kind of CGNAT

```
$ mtr -nrc2 $(curl -s -4 ifconfig.me)
Start: 2026-10-18T22:33:45+0200
HOST: x360                        Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 10.240.252.82              0.0%     2    6.1   4.8   3.5   6.1   1.8
  2.|-- ???                       100.0     2    0.0   0.0   0.0   0.0   0.0
  3.|-- 10.121.132.177             0.0%     2   33.9  27.0  20.1  33.9   9.7
  4.|-- 10.226.4.135               0.0%     2   25.5  29.0  25.5  32.5   5.0
  5.|-- 10.226.4.6                 0.0%     2   28.1 137.2  28.1 246.4 154.4
  6.|-- 10.121.183.1               0.0%     2   24.6  85.4  24.6 146.2  86.0
  7.|-- 10.121.183.0               0.0%     2   24.7  35.1  24.7  45.5  14.6
  8.|-- ???                       100.0     2    0.0   0.0   0.0   0.0   0.0


$ ip route show | grep default
default via 10.240.252.82 dev wlo1 proto dhcp src 10.240.252.223 metric 600
```


# non-CGNAT, but inside ChromeOS' Linux

A "100." address is not proof of CGNAT. It seems 100.115.92.0/23 is used by ChromeOS (although it's from the CGNAT pool)

```
$ mtr -nrc2 $(curl -s -4 ifconfig.me)
Start: 2026-10-17T14:51:52+0200
HOST: penguin                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 100.115.92.193             0.0%     2    0.1   0.1   0.1   0.2   0.1
  2.|-- 100.115.92.25              0.0%     2    0.4   0.3   0.2   0.4   0.1
  3.|-- 88.75.45.236               0.0%     2    4.5  13.5   4.5  22.4  12.7
```

# non-CGNAT, but docker on chromeOS' linux

```
root@ddaceec7cbd2:/# mtr -nrc2 $(curl -s -4 ifconfig.me)
Start: 2026-10-18T17:33:48+0200
HOST: ddaceec7cbd2                Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 172.17.0.1                 0.0%     2    0.1   0.1   0.1   0.1   0.0
  2.|-- 100.115.92.193             0.0%     2    0.1   0.2   0.1   0.3   0.1
  3.|-- 100.115.92.25              0.0%     2    0.7   0.6   0.5   0.7   0.1
  4.|-- 82.75.45.236               0.0%     2    8.4   8.6   8.4   8.8   0.3
root@ddaceec7cbd2:/#
```

# non-CGNAT, VPS, public IPv4 on the machine itself

```
$ mtr -nrc2 $(curl -s -4 ifconfig.me)
Start: 2026-10-17T14:55:56+0200
HOST: haring1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 66.45.54.18                0.0%     2    0.1   0.1   0.1   0.1   0.0

```
