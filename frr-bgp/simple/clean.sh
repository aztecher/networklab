#!/bin/bash

echo "Removing creating simpleFRR + BGP Labo"
# remove container
sudo docker stop frr1
sudo docker stop frr2
sudo docker stop alpine1
sudo docker stop alpine2
sudo docker rm frr1
sudo docker rm frr2
sudo docker rm alpine1
sudo docker rm alpine2

# remove network
sudo docker network rm net1
sudo docker network rm net2
sudo docker network rm net3
