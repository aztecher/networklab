# 3-Layer FRR + ECMP + BGP + Unnumbered Labo

```
         [Spine1(10.1.0.2)]                        [Spine2(10.2.0.2)]
          | |        | |                             | |       | |
          | |        | +---------------------------------------------+
          | |        +---------------------------+   | |       | |   |
          | |                                    |   | |       | |   |
      +----------------------------------------------+ |       | |   |
      |   | |            +-----------------------------+       | |   |
    +-----+ +----------+ |                       | +-----------+ +-----+
    | |                | |                       | |                 | |
[Leaf1(10.0.2.2)]  [Leaf2(10.0.3.2)]        [Leaf3(10.0.4.2)]  [Leaf4(10.0.5.2)]
     |                  |                         |                   |
     +----------+-------+                         +---------+---------+
                |                                           |                   [BGP Unnumbered]
----------------|-------------------------------------------|------------------------------------
        [Server1(10.0.6.2)]                         [Server2(10.0.7.2)]
                |                                           |
        [Alpine1(10.0.10.2)]                        [Alpine2(10.0.11.2)]
```

## Requirement

- docker
- jq

## Getting Started

Plrease confirm to install the requirements and execute the `setup.sh` command.

```
$ chmod +x setup.sh
$ ./setup.sh
```

This command will create 18 netns and 10 containers(8 frr and 2 alpine) as bellow.

```bash
$ docker network ls | grep -e spine -e leaf -e server -e container
88aaeb381d6a   container1   bridge    local
0173b087ab6c   container2   bridge    local
0ca47dda8da3   leaf1        bridge    local
4bf77c6954be   leaf2        bridge    local
a58bde381c9d   leaf3        bridge    local
9f6cbf9704e8   leaf4        bridge    local
c74e1026420a   server1      bridge    local
7ee8d2663b88   server2      bridge    local
8044367668cb   spine1       bridge    local
06d38dd90340   spine1eth1   bridge    local
5a29e05e0dbf   spine1eth2   bridge    local
9f8a48a06a87   spine1eth3   bridge    local
c72516e54c09   spine1eth4   bridge    local
5f6b7b7e14d6   spine2       bridge    local
dcbd7e771b34   spine2eth1   bridge    local
0a520dc5b2d0   spine2eth2   bridge    local
f76008b92e9d   spine2eth3   bridge    local
63f97214ab7a   spine2eth4   bridge    local

$ docker container ls
CONTAINER ID   IMAGE                  COMMAND                  CREATED        STATUS         PORTS     NAMES
6ddfdbe4af39   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   10 hours ago   Up 10 hours              server2
f8375e47e0bd   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   10 hours ago   Up 10 hours              server1
71f7aa10c796   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   10 hours ago   Up 6 minutes             leaf4
667303c713e5   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   10 hours ago   Up 6 minutes             leaf3
c6c9d0eb137b   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   10 hours ago   Up 6 minutes             leaf2
77ac3726fa72   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   10 hours ago   Up 6 minutes             leaf1
96f236730b8d   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   10 hours ago   Up 5 minutes             spine2
ca5dc92c2a3f   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   10 hours ago   Up 5 minutes             spine1
5546d3ce0103   alpine                 "/bin/sh"                10 hours ago   Up 10 hours              alpine2
975a3ac4fbae   alpine                 "/bin/sh"                10 hours ago   Up 10 hours              alpine1
```

Then, the alpine1 and alpine2 have the different range of ip address.

```bash
# alpine1 has address '10.0.10.2' that is the range of 'container1'
$ docker inspect alpine1 | jq .[0].NetworkSettings.Networks.container1.IPAddress
"10.0.10.2"

# alpine2 has address '10.0.11.2' that is the range of 'container2'
$ docker inspect alpine2 | jq .[0].NetworkSettings.Networks.container2.IPAddress
"10.0.11.2"
```

Thanks for the frr, alpine1 and alpine 2 is reachable.

```bash
# ping from alpine1(10.0.10.2) to alpine2(10.0.11.2) -> success
$ docker exec -it alpine1 ping -c 3 10.0.11.2
PING 10.0.11.2 (10.0.11.2): 56 data bytes
64 bytes from 10.0.11.2: seq=0 ttl=60 time=0.305 ms
64 bytes from 10.0.11.2: seq=1 ttl=60 time=0.253 ms
64 bytes from 10.0.11.2: seq=2 ttl=60 time=0.240 ms

--- 10.0.11.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.240/0.266/0.305 ms

# ping from alpine2(10.0.11.2) to alpine1(10.0.10.2) -> success
$ docker exec -it alpine2 ping -c 3 10.0.10.2
PING 10.0.10.2 (10.0.10.2): 56 data bytes
64 bytes from 10.0.10.2: seq=0 ttl=60 time=0.243 ms
64 bytes from 10.0.10.2: seq=1 ttl=60 time=0.217 ms
64 bytes from 10.0.10.2: seq=2 ttl=60 time=0.211 ms

--- 10.0.10.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.211/0.223/0.243 ms
```

If you want to cleanup, then you can use `clean.sh` script that remove the docker resources created above.

```
$ chmod +x clean.sh
$ ./clean.sh
```

## Deep Dive into this Labo

### Topology

The netns named `spine1eth[1-4]` and `spine2eth[1-4]` means that each range of ip address is unique for spine's ethX interface.
Quicklly understanding, you can checkout the ip addresses of spine[1-2].

```bash
$ docker exec -it spine1 ip -o a |grep -v inet6
1: lo    inet 127.0.0.1/8 scope host lo\       valid_lft forever preferred_lft forever
3053: eth2    inet 10.1.2.2/24 brd 10.1.2.255 scope global eth2\       valid_lft forever preferred_lft forever
3055: eth3    inet 10.1.3.2/24 brd 10.1.3.255 scope global eth3\       valid_lft forever preferred_lft forever
3057: eth4    inet 10.1.4.2/24 brd 10.1.4.255 scope global eth4\       valid_lft forever preferred_lft forever
3059: eth0    inet 10.1.0.2/24 brd 10.1.0.255 scope global eth0\       valid_lft forever preferred_lft forever
3061: eth1    inet 10.1.1.2/24 brd 10.1.1.255 scope global eth1\       valid_lft forever preferred_lft forever
```

This shows that `spine1` has 5 interfaces (eth0-4) except for loopback (lo) and each of these has the ip address that come from different range.
And the routing of these range extreamly depends on the configuration of frr.

The connection of Spine-Leaf layer is full-mesh and it means that each leaf has the connection to all spines.
In this way, from the spine point of view, the routing from alpine1 to alpine2 is the two direction (leaf3, leaf4) and the opoosite side is also two direction (leaf1, leaf2).
And the packet from/to alpine1/alpine2 must pass through spine1 or spine2.

The redundancy is provided in spine layer (by spine1-spine2) and leaf layer(by leaf1-leaf2 and leaf3-leaf4), so the reachability between alpine1 and alpine2 will continue even if one side of redundant switch is dropped.

All frr container has ipv6 address since we use IPv6 Link Local Address in BGP unnumbered.
Each frr container advertise it's route by BGP unnumbered and alpine1, 2 are reachable.

### Test the reachability

In this testbed, we expect the reachability between alpine1 and alpine2 wll be retained even if the `spine2` `leaf2` `leaf4` are stopped.  
To check this property, open two terminal and execute ping from alpine1 to alpine2 in one side.

```bash
$ docker exec -it alpine1 ping 10.0.11.2
```

and stop these switches in other terminal.

```bash
$ docker stop spine2
$ docker stop leaf2
$ docker stop leaf4
```

then you can see that the ping has been continued!
Now let's check the RIB table on `spine1`, `leaf1` and `leaf2`

```bash
# The RIB of spine1
$ docker exec -it spine1 vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.1.0.1, eth0, 00:32:40
B>* 10.0.10.0/24 [20/0] via fe80::42:aff:fe01:103, eth1, weight 1, 00:01:25
B>* 10.0.11.0/24 [20/0] via fe80::42:aff:fe01:303, eth3, weight 1, 00:01:22
C>* 10.1.0.0/24 is directly connected, eth0, 00:32:40
C>* 10.1.1.0/24 is directly connected, eth1, 00:32:40
C>* 10.1.2.0/24 is directly connected, eth2, 00:32:40
C>* 10.1.3.0/24 is directly connected, eth3, 00:32:40
C>* 10.1.4.0/24 is directly connected, eth4, 00:32:40

# The RIB of leaf1
$ docker exec -it leaf1 vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.0.2.1, eth0, 00:33:30
C>* 10.0.2.0/24 is directly connected, eth0, 00:33:30
B>* 10.0.10.0/24 [20/0] via fe80::42:aff:fe00:203, eth0, weight 1, 00:33:28
B>* 10.0.11.0/24 [20/0] via fe80::42:aff:fe01:102, eth1, weight 1, 00:01:27
C>* 10.1.1.0/24 is directly connected, eth1, 00:33:30
C>* 10.2.1.0/24 is directly connected, eth2, 00:33:30

# The RIB of leaf3
$ docker exec -it leaf3 vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.0.4.1, eth0, 00:33:28
C>* 10.0.4.0/24 is directly connected, eth0, 00:33:28
B>* 10.0.10.0/24 [20/0] via fe80::42:aff:fe01:302, eth1, weight 1, 00:01:42
B>* 10.0.11.0/24 [20/0] via fe80::42:aff:fe00:403, eth0, weight 1, 00:33:26
C>* 10.1.3.0/24 is directly connected, eth1, 00:33:28
C>* 10.2.3.0/24 is directly connected, eth2, 00:33:28
```

ok. restore the switch `spine2`, `leaf2` and `leaf4` then the RIB table also be restored and you can find the multi-path in spine's table.

```bash
$ docker start spine2
$ docker start leaf2
$ docker start leaf4

# Check the RIB table of spine1
$ docker exec -it spine1 vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.1.0.1, eth0, 00:36:50
B>* 10.0.10.0/24 [20/0] via fe80::42:aff:fe01:103, eth1, weight 1, 00:00:52
  *                     via fe80::42:aff:fe01:203, eth2, weight 1, 00:00:52
B>* 10.0.11.0/24 [20/0] via fe80::42:aff:fe01:303, eth3, weight 1, 00:00:50
  *                     via fe80::42:aff:fe01:403, eth4, weight 1, 00:00:50
C>* 10.1.0.0/24 is directly connected, eth0, 00:36:50
C>* 10.1.1.0/24 is directly connected, eth1, 00:36:50
C>* 10.1.2.0/24 is directly connected, eth2, 00:36:50
C>* 10.1.3.0/24 is directly connected, eth3, 00:36:50
C>* 10.1.4.0/24 is directly connected, eth4, 00:36:50
```

Excellent! This lab confirmed the basis of the reliable CLOS topologies used in recent data center.
