# CGNAT-detector


With CGNAT, your CPE (router) has no public IPv4 address on its WAN interface. A typical CGNAT WAN IP address is 100.64.193.104, but it might be another address


So how can we find that (without UPnP or access to the router/CPE)?

Method: 
1. find the real public ipv4 with which you are seen on Internet.
2. find the traceroute to that ipv4
3. in the traceroute, check if your local router responds to that public ipv4. If not: CGNAT

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


# non-CGNAT, but inside ChromeOS' Linux

A "100." address is not proof of CGNAT:

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

# VPS, public IPv4 on the machine itself

```
$ mtr -nrc2 $(curl -s -4 ifconfig.me)
Start: 2026-10-17T14:55:56+0200
HOST: haring1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 66.45.54.18                0.0%     2    0.1   0.1   0.1   0.1   0.0

```
