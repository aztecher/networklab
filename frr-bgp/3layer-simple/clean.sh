#!/bin/bash

echo "Removing 3-Layer FRR + BGP Labo"
# remove container
sudo docker stop alpine2
sudo docker stop alpine1
sudo docker stop leaf2
sudo docker stop leaf1
sudo docker stop server1
sudo docker stop server2
sudo docker stop spine
sudo docker rm alpine2
sudo docker rm alpine1
sudo docker rm leaf2
sudo docker rm leaf1
sudo docker rm server1
sudo docker rm server2
sudo docker rm spine

# remove network
sudo docker network rm spine
sudo docker network rm leaf1
sudo docker network rm leaf2
sudo docker network rm server1
sudo docker network rm server2
sudo docker network rm container1
sudo docker network rm container2
