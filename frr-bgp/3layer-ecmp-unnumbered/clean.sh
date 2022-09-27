#!/bin/bash

echo "Removing 3-Layer FRR + ECMP + BGP + Unnumbered Labo"
# remove container
sudo docker stop alpine2
sudo docker stop alpine1
sudo docker stop server2
sudo docker stop server1
sudo docker stop leaf4
sudo docker stop leaf3
sudo docker stop leaf2
sudo docker stop leaf1
sudo docker stop spine2
sudo docker stop spine1
sudo docker rm alpine2
sudo docker rm alpine1
sudo docker rm server2
sudo docker rm server1
sudo docker rm leaf4
sudo docker rm leaf3
sudo docker rm leaf2
sudo docker rm leaf1
sudo docker rm spine2
sudo docker rm spine1

# remove network
sudo docker network rm spine1
sudo docker network rm spine1eth1
sudo docker network rm spine1eth2
sudo docker network rm spine1eth3
sudo docker network rm spine1eth4
sudo docker network rm spine2
sudo docker network rm spine2eth1
sudo docker network rm spine2eth2
sudo docker network rm spine2eth3
sudo docker network rm spine2eth4
sudo docker network rm leaf1
sudo docker network rm leaf2
sudo docker network rm leaf3
sudo docker network rm leaf4
sudo docker network rm server1
sudo docker network rm server2
sudo docker network rm container1
sudo docker network rm container2
