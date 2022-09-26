# Simple FRR + BGP + Unnumbered Labo

```
  [Leaf1(10.0.1.2)]------[BGP Unnumbered]-----[Leaf2(10.0.2.2)]
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

This command will create 7 netns and 6 containers(4 frr and 2 alpine) s.t.

```bash
$ docker network ls |grep -e shared -e leaf -e server -e container
277e671b0e4b   container1   bridge    local
3945a2f82d62   container2   bridge    local
9e3474209387   leaf1        bridge    local
ccaa1adf2671   leaf2        bridge    local
84a101ce5bbb   server1      bridge    local
b547574d5e3f   server2      bridge    local
2de82339ede9   shared       bridge    local

$ docker container ls
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS     NAMES
6c4b6100517e   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   5 minutes ago   Up 5 minutes             server2
50b5140df098   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   5 minutes ago   Up 5 minutes             server1
8399bc5b655f   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   5 minutes ago   Up 5 minutes             leaf2
273f94ad8b95   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   5 minutes ago   Up 5 minutes             leaf1
a8085a69aff9   alpine                 "/bin/sh"                5 minutes ago   Up 5 minutes             alpine2
3614941f18a3   alpine                 "/bin/sh"                5 minutes ago   Up 5 minutes             alpine1
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

Each container located on different netns, and leaf1 and leaf2 is connected to the netns name `shared`.
And all frr container(`leaf1`, `leaf2`, `server1`, `server2`) has ipv6 address since we use IPv6 Link Local Address in BGP unnumbered.
Each frr container advertise it's route by BGP unnumbered and alpine1, 2 are reachable.

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
