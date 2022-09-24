# 3-Layer FRR + BGP + ECMP Labo

```
                    +---------------[Spine(10.0.0.2)]---------------+
                    |                                               |
        +-----------+-------------+                                 |
        |                         |                                 |
  [Leaf1(10.0.1.2)]     [Leaf1-Ext(10.0.5.2)]                 [Leaf2(10.0.2.2)]
        |                         |                                 |
        +-----------+-------------+                                 |
                    |                                               |
            [Server1(10.0.3.2)]                             [Server2(10.0.4.2)]
                    |                                               |
                    |                                               |
            [Alpine1(10.0.10.2)]                            [Alpine2(10.0.11.2)]
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

This command will create 8 netns and 8 containers(6 frr and 2 alpine) s.t.

```bash
$ docker network ls |grep -e spine -e leaf -e server -e container
aeb4208ea74a   container1   bridge    local
03f3ab4e4567   container2   bridge    local
b66a29847385   leaf1        bridge    local
4e697e1df3b8   leaf1-ext    bridge    local
55f2eb7d6e30   leaf2        bridge    local
192109ebe574   server1      bridge    local
fb14c8bb0e04   server2      bridge    local
9e9db0e0f27b   spine        bridge    local

$ docker container ls
$ docker container ls
CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS          PORTS     NAMES
d3c610843dbc   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   53 seconds ago   Up 52 seconds             server2
2d82e2d772c0   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   54 seconds ago   Up 53 seconds             server1
7819ed8c6212   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   55 seconds ago   Up 54 seconds             leaf1-ext
87fdb9ffcb74   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   55 seconds ago   Up 55 seconds             leaf2
ab9988218f9f   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   56 seconds ago   Up 55 seconds             leaf1
0e842b9d58a5   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   57 seconds ago   Up 56 seconds             spine
4784d4bf4c87   alpine                 "/bin/sh"                57 seconds ago   Up 56 seconds             alpine2
03dafb6e40de   alpine                 "/bin/sh"                58 seconds ago   Up 57 seconds             alpine1
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

`leaf1-ext` is created due to check and validate the ECMP behavior.
As the topology shown above, server1 and spine have multi-path to leaf1 and leaf1-ext.
In this labo, frr.conf of those are configured to use multi-path, so multi routes are injected with equal weight.

```bash
# Existing multi-path route to 10.0.11.0/24 in RIB table.
$ docker exec -it server1 vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.0.10.1, eth3, 00:00:20
C>* 10.0.1.0/24 is directly connected, eth1, 00:00:20
C>* 10.0.3.0/24 is directly connected, eth0, 00:00:20
C>* 10.0.5.0/24 is directly connected, eth2, 00:00:20
C>* 10.0.10.0/24 is directly connected, eth3, 00:00:20
B>* 10.0.11.0/24 [20/0] via 10.0.1.2, eth1, weight 1, 00:00:16
  *                     via 10.0.5.2, eth2, weight 1, 00:00:16

# And also exist in Kernel routing table.
$ docker exec -it server1 ip route
default via 10.0.10.1 dev eth3
10.0.1.0/24 dev eth1 proto kernel scope link src 10.0.1.3
10.0.3.0/24 dev eth0 proto kernel scope link src 10.0.3.2
10.0.5.0/24 dev eth2 proto kernel scope link src 10.0.5.3
10.0.10.0/24 dev eth3 proto kernel scope link src 10.0.10.3
10.0.11.0/24 nhid 17 proto bgp metric 20
        nexthop via 10.0.1.2 dev eth1 weight 1
        nexthop via 10.0.5.2 dev eth2 weight 1

# spine is the same as above.
```

To check the robustness of multi-path by ECMP, we test the reachability from alpine1 to alpine2 under the switch crashing.
First, setup two terminal and execute ping from alpine1 to alpine2 in the one.

```bash
$ docker exec -it alpine1 ping 10.0.11.2
```

On the other hand, execute `docker stop [leaf1/leaf1-ext]` and check the reachability and routing table changes.

```bash
# First, check the `server1` and `spine` RIB table. They have multi-path route.
$ docker exec -it server1 vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.0.10.1, eth3, 00:08:34
C>* 10.0.1.0/24 is directly connected, eth1, 00:08:34
C>* 10.0.3.0/24 is directly connected, eth0, 00:08:34
C>* 10.0.5.0/24 is directly connected, eth2, 00:08:34
C>* 10.0.10.0/24 is directly connected, eth3, 00:08:34
B>* 10.0.11.0/24 [20/0] via 10.0.1.2, eth1, weight 1, 00:08:30
  *                     via 10.0.5.2, eth2, weight 1, 00:08:30

$ docker exec -it spine vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.0.0.1, eth0, 00:09:00
C>* 10.0.0.0/24 is directly connected, eth0, 00:09:00
B>* 10.0.10.0/24 [20/0] via 10.0.0.3, eth0, weight 1, 00:08:55
  *                     via 10.0.0.5, eth0, weight 1, 00:08:55
B>* 10.0.11.0/24 [20/0] via 10.0.0.4, eth0, weight 1, 00:08:53

# Execute 'docker stop leaf1' and down the path to leaf1.
# And then, ping will continue to reach since the leaf1-ext path is still exist.
$ sudo docker stop leaf1
leaf1

# In this time, `server1` and `spine` have single path to `leaf1-ext`
$ docker exec -it server1 vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.0.10.1, eth3, 00:13:41
C>* 10.0.1.0/24 is directly connected, eth1, 00:13:41
C>* 10.0.3.0/24 is directly connected, eth0, 00:13:41
C>* 10.0.5.0/24 is directly connected, eth2, 00:13:41
C>* 10.0.10.0/24 is directly connected, eth3, 00:13:41
B>* 10.0.11.0/24 [20/0] via 10.0.5.2, eth2, weight 1, 00:00:47

$ docker exec -it spine vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.0.0.1, eth0, 00:13:48
C>* 10.0.0.0/24 is directly connected, eth0, 00:13:48
B>* 10.0.10.0/24 [20/0] via 10.0.0.5, eth0, weight 1, 00:00:51
B>* 10.0.11.0/24 [20/0] via 10.0.0.4, eth0, weight 1, 00:13:41

# Restore the `leaf1` container and shutdown the `leaf1-ext`.
# Of cause, ping will continue to reach since the leaf1 path is exist.
$ docker start leaf1
leaf1
$ docker stop leaf1-ext
leaf1-ext

# check the RIB of `server1` and `spine`
$ docker exec -it server1 vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.0.10.1, eth3, 00:17:15
C>* 10.0.1.0/24 is directly connected, eth1, 00:17:15
C>* 10.0.3.0/24 is directly connected, eth0, 00:17:15
C>* 10.0.5.0/24 is directly connected, eth2, 00:17:15
C>* 10.0.10.0/24 is directly connected, eth3, 00:17:15
B>* 10.0.11.0/24 [20/0] via 10.0.1.2, eth1, weight 1, 00:00:34

$ docker exec -it spine vtysh -c 'show ip route'
Codes: K - kernel route, C - connected, S - static, R - RIP,
       O - OSPF, I - IS-IS, B - BGP, E - EIGRP, N - NHRP,
       T - Table, v - VNC, V - VNC-Direct, A - Babel, D - SHARP,
       F - PBR, f - OpenFabric,
       > - selected route, * - FIB route, q - queued, r - rejected, b - backup

K>* 0.0.0.0/0 [0/0] via 10.0.0.1, eth0, 00:17:22
C>* 10.0.0.0/24 is directly connected, eth0, 00:17:22
B>* 10.0.10.0/24 [20/0] via 10.0.0.3, eth0, weight 1, 00:00:38
B>* 10.0.11.0/24 [20/0] via 10.0.0.4, eth0, weight 1, 00:17:15
```

As shown above, the robustness of multi-path against switch failure was confirmed!

If you want to cleanup, then you can use `clean.sh` script that remove the docker resources created above.

```
$ chmod +x clean.sh
$ ./clean.sh
```
