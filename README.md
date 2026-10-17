# CGNAT-detector
CGNAT detector

With CGNAT, your CPE (router) has no public IPv4 address on its WAN interface. So how can we find that (without UPnP or access to the CPE)?

Method: 
1. find the real public ipv4 with which you are seen on Internet.
2. find the traceroute to that ipv4
3. in the traceroute, check if your local router responds to that public ipv4. If not: CGNAT

# non-CGAT, typical LAN (with RFC1918)
```

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

# VPS, public IPv4 on the machine itself

```
$ mtr -nrc2 $(curl -s -4 ifconfig.me)
Start: 2026-10-17T14:55:56+0200
HOST: haring1                     Loss%   Snt   Last   Avg  Best  Wrst StDev
  1.|-- 66.45.54.18                0.0%     2    0.1   0.1   0.1   0.1   0.0

```
