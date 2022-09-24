# Simple 3-Layer FRR + BGP Labo

```
        +-------------[Spine(10.0.0.2)]-------------+
        |                                           |
  [Leaf1(10.0.1.2)]                           [Leaf2(10.0.2.2)]
        |                                           |
        |                                           |
[Server1(10.0.3.2)]                         [Server2(10.0.4.2)]
        |                                           |
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

This command will create 7 netns and 7 containers(5 frr and 2 alpine) s.t.

```bash
$ docker network ls | grep -e spine -e leaf -e server -e container
26982ad0a0cd   container1   bridge    local
0680dcd07713   container2   bridge    local
4810e4171841   leaf1        bridge    local
a5ee3480bf6d   leaf2        bridge    local
d18441ada024   server1      bridge    local
30387a9944eb   server2      bridge    local
fdf6c3aa6b3b   spine        bridge    local

$ docker container ls
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS     NAMES
40a7971b83fd   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   8 minutes ago   Up 8 minutes             server2
023af0520db6   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   8 minutes ago   Up 8 minutes             server1
c2fa2021b902   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   8 minutes ago   Up 8 minutes             leaf2
fd7cfa116bf7   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   8 minutes ago   Up 8 minutes             leaf1
73b4678367eb   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   8 minutes ago   Up 8 minutes             spine
e7368d443246   alpine                 "/bin/sh"                8 minutes ago   Up 8 minutes             alpine2
8b1225a01292   alpine                 "/bin/sh"                8 minutes ago   Up 8 minutes             alpine1
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

server1 and server2 (that are frr container and bgpd is running as its process) are the GW of these containers.
And also leaf1 (frr) and leaf2 (frr) are the GW of server1 and server2.
they are aggregated by spine (frr).
This design was created with a 3-layer CLOS topology in mind.

All frr containers (server1, server2, leaf1, leaf2, spine) are routing the packet from one alpine container to the other one.
So, these containers are reachable.

```bash
# ping from alpine1(10.0.10.2) to alpine2(10.0.11.2) -> success
$ docker exec -it alpine1 ping -c 3 10.0.11.2
PING 10.0.11.2 (10.0.11.2): 56 data bytes
64 bytes from 10.0.11.2: seq=0 ttl=60 time=0.311 ms
64 bytes from 10.0.11.2: seq=1 ttl=60 time=0.218 ms
64 bytes from 10.0.11.2: seq=2 ttl=60 time=0.163 ms

--- 10.0.11.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.163/0.230/0.311 ms

# ping from alpine2(10.0.11.2) to alpine1(10.0.10.2) -> success
$ docker exec -it alpine2 ping -c 3 10.0.10.2
PING 10.0.10.2 (10.0.10.2): 56 data bytes
64 bytes from 10.0.10.2: seq=0 ttl=60 time=0.239 ms
64 bytes from 10.0.10.2: seq=1 ttl=60 time=0.251 ms
64 bytes from 10.0.10.2: seq=2 ttl=60 time=0.219 ms

--- 10.0.10.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.219/0.236/0.251 ms
```

If you want to cleanup, then you can use `clean.sh` script that remove the docker resources created above.

```
$ chmod +x clean.sh
$ ./clean.sh
```
