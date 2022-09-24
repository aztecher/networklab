# Simple FRR + BGP Labo

```
   [FRR1(10.0.1.2)]-------------------------[FRR2(10.0.1.3)]
        |                                        |
        |                                        |
  [Alpine1(10.0.0.2)]                      [Alpine2(10.0.2.2)]
```

## Requirement

- docker
- jq

This script has been tested on Ubuntu 20.04, but it is based on container, so it should work on other environments as well.

## Getting Started

Plrease confirm to install the requirements and execute the `setup.sh` command.

```
$ chmod +x setup.sh
$ ./setup.sh
```

This command will create 3 netns(net1, net2, net3) and 4 containers(2 frr and 2 alpine) s.t.

```bash
$ docker network ls | grep net
1bd68254a40a   net1      bridge    local
f2ffdecf5641   net2      bridge    local
9c6d557c46fe   net3      bridge    local

$ docker container ls
CONTAINER ID   IMAGE                  COMMAND                  CREATED          STATUS          PORTS     NAMES
785e55a7d89c   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   13 minutes ago   Up 13 minutes             frr2
d1b6b42480f0   frrouting/frr:v7.5.0   "/sbin/tini -- /usr/…"   13 minutes ago   Up 13 minutes             frr1
6b3710806008   alpine                 "/bin/sh"                13 minutes ago   Up 13 minutes             alpine2
5ba9f30af4b9   alpine                 "/bin/sh"                13 minutes ago   Up 13 minutes             alpine1
```

Then, the alpine1 and alpine2 have the different range of ip address.

```bash
# alpine1 has address '10.0.0.2' that is the range of 'net1'
$ docker inspect alpine1 | jq .[0].NetworkSettings.Networks.net1.IPAddress
"10.0.0.2"

# alpine2 has address '10.0.2.2' that is the range of 'net3'
$ docker inspect alpine2 | jq .[0].NetworkSettings.Networks.net3.IPAddress
"10.0.2.2"
```

And the frr1 and frr2 (running as bgpd) are routing these packet.
So, these containers are reachable.

```bash
# ping from alpine1(10.0.0.2) to alpine2(10.0.2.2) is success
$ docker exec -it alpine1 ping -c 3 10.0.2.2                                              
PING 10.0.2.2 (10.0.2.2): 56 data bytes
64 bytes from 10.0.2.2: seq=0 ttl=62 time=0.322 ms
64 bytes from 10.0.2.2: seq=1 ttl=62 time=0.164 ms
64 bytes from 10.0.2.2: seq=2 ttl=62 time=0.145 ms

--- 10.0.2.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.145/0.210/0.322 ms

# ping from alpine2(10.0.2.2) to alpine1(10.0.0.2) is success
$ docker exec -it alpine2 ping -c 3 10.0.0.2                                              
PING 10.0.0.2 (10.0.0.2): 56 data bytes
64 bytes from 10.0.0.2: seq=0 ttl=62 time=0.231 ms
64 bytes from 10.0.0.2: seq=1 ttl=62 time=0.171 ms
64 bytes from 10.0.0.2: seq=2 ttl=62 time=0.181 ms

--- 10.0.0.2 ping statistics ---
3 packets transmitted, 3 packets received, 0% packet loss
round-trip min/avg/max = 0.171/0.194/0.231 ms1
```

If you want to cleanup, then you can use 'clean.sh' script that remove the docker resources created above.

```bash
$ chmod +x clean.sh
$ ./clean.sh
```
