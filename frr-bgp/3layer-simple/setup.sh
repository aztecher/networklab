#!/bin/bash

# Requirement
# - docker
# - jq

DOCKER_NETWORK_NAME_SPINE="spine"
DOCKER_NETWORK_NAME_LEAF_1="leaf1"
DOCKER_NETWORK_NAME_LEAF_2="leaf2"
DOCKER_NETWORK_NAME_SERVERSIDE_1="server1"
DOCKER_NETWORK_NAME_SERVERSIDE_2="server2"
DOCKER_NETWORK_NAME_CONTAINER_1="container1"
DOCKER_NETWORK_NAME_CONTAINER_2="container2"

DOCKER_NETWORK_SUBNET_SPINE=10.0.0.0/24
DOCKER_NETWORK_SUBNET_SPINE_DEFAULT_GW=10.0.0.1
DOCKER_NETWORK_SUBNET_LEAF_1=10.0.1.0/24
DOCKER_NETWORK_SUBNET_LEAF_1_DEFAULT_GW=10.0.1.1
DOCKER_NETWORK_SUBNET_LEAF_2=10.0.2.0/24
DOCKER_NETWORK_SUBNET_LEAF_2_DEFAULT_GW=10.0.2.1
DOCKER_NETWORK_SUBNET_SERVERSIDE_1=10.0.3.0/24
DOCKER_NETWORK_SUBNET_SERVERSIDE_1_DEFAULT_GW=10.0.3.1
DOCKER_NETWORK_SUBNET_SERVERSIDE_2=10.0.4.0/24
DOCKER_NETWORK_SUBNET_SERVERSIDE_2_DEFAULT_GW=10.0.4.1
DOCKER_NETWORK_SUBNET_CONTAINER_1=10.0.10.0/24
DOCKER_NETWORK_SUBNET_CONTAINER_1_DEFAULT_GW=10.0.10.1
DOCKER_NETWORK_SUBNET_CONTAINER_2=10.0.11.0/24
DOCKER_NETWORK_SUBNET_CONTAINER_2_DEFAULT_GW=10.0.11.1

echo "Creating 3-Layer FRR + BGP Labo"

echo "Creating networks (netns) ..."
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE} --subnet=${DOCKER_NETWORK_SUBNET_SPINE}
sudo docker network create ${DOCKER_NETWORK_NAME_LEAF_1} --subnet=${DOCKER_NETWORK_SUBNET_LEAF_1}
sudo docker network create ${DOCKER_NETWORK_NAME_LEAF_2} --subnet=${DOCKER_NETWORK_SUBNET_LEAF_2}
sudo docker network create ${DOCKER_NETWORK_NAME_SERVERSIDE_1} --subnet=${DOCKER_NETWORK_SUBNET_SERVERSIDE_1}
sudo docker network create ${DOCKER_NETWORK_NAME_SERVERSIDE_2} --subnet=${DOCKER_NETWORK_SUBNET_SERVERSIDE_2}
sudo docker network create ${DOCKER_NETWORK_NAME_CONTAINER_1} --subnet=${DOCKER_NETWORK_SUBNET_CONTAINER_1}
sudo docker network create ${DOCKER_NETWORK_NAME_CONTAINER_2} --subnet=${DOCKER_NETWORK_SUBNET_CONTAINER_2}

echo "Creating alpine containers ..."
# create container
sudo docker run -dit --name alpine1 --hostname alpine1 --privileged --net ${DOCKER_NETWORK_NAME_CONTAINER_1} alpine
sudo docker run -dit --name alpine2 --hostname alpine2 --privileged --net ${DOCKER_NETWORK_NAME_CONTAINER_2} alpine

echo "Creating frr containers ..."
# Spine SW
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/spine/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/spine/vtysh.conf:/etc/frr/vtysh.conf \
    --name spine --hostname spine --privileged --net ${DOCKER_NETWORK_NAME_SPINE} frrouting/frr:v7.5.0

# Leaf SW1
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/leaf1/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/leaf1/vtysh.conf:/etc/frr/vtysh.conf \
    --name leaf1 --hostname leaf1 --privileged --net ${DOCKER_NETWORK_NAME_LEAF_1} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE} leaf1

# Leaf SW2
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/leaf2/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/leaf2/vtysh.conf:/etc/frr/vtysh.conf \
    --name leaf2 --hostname leaf2 --privileged --net ${DOCKER_NETWORK_NAME_LEAF_2} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE} leaf2

# Leaf Server1
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/server1/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/server1/vtysh.conf:/etc/frr/vtysh.conf \
    --name server1 --hostname server1 --privileged --net ${DOCKER_NETWORK_NAME_SERVERSIDE_1} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_LEAF_1} server1
sudo docker network connect ${DOCKER_NETWORK_NAME_CONTAINER_1} server1

# Leaf Server2
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/server2/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/server2/vtysh.conf:/etc/frr/vtysh.conf \
    --name server2 --hostname server2 --privileged --net ${DOCKER_NETWORK_NAME_SERVERSIDE_2} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_LEAF_2} server2
sudo docker network connect ${DOCKER_NETWORK_NAME_CONTAINER_2} server2

# overwrite netns gateway of each netns
alpine1_gw_address=$(sudo docker inspect server1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_CONTAINER_1}.IPAddress | tr -d '"')
alpine2_gw_address=$(sudo docker inspect server2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_CONTAINER_2}.IPAddress | tr -d '"')

echo "Setting routing tables of alpine containers ..."
sudo docker exec -it alpine1 route add default gw ${alpine1_gw_address}
sudo docker exec -it alpine1 route del default gw ${DOCKER_NETWORK_SUBNET_CONTAINER_1_DEFAULT_GW}
sudo docker exec -it alpine2 route add default gw ${alpine2_gw_address}
sudo docker exec -it alpine2 route del default gw ${DOCKER_NETWORK_SUBNET_CONTAINER_2_DEFAULT_GW}

spine_address=$(sudo docker inspect spine | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_SPINE}.IPAddress | tr -d '"')
leaf1_address=$(sudo docker inspect leaf1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_LEAF_1}.IPAddress | tr -d '"')
leaf2_address=$(sudo docker inspect leaf2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_LEAF_2}.IPAddress | tr -d '"')
server1_address=$(sudo docker inspect server1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_SERVERSIDE_1}.IPAddress | tr -d '"')
server2_address=$(sudo docker inspect server2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_SERVERSIDE_2}.IPAddress | tr -d '"')
alpine1_address=$(sudo docker inspect alpine1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_CONTAINER_1}.IPAddress | tr -d '"')
alpine2_address=$(sudo docker inspect alpine2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_CONTAINER_2}.IPAddress | tr -d '"')

echo ""
echo "Sucessfully creating L3-Layer CLOS FRR + BGP Labo"
echo ""
echo "        +-------------[Spine(${spine_address})]-------------+"
echo "        |                                           |"
echo "  [Leaf1(${leaf1_address})]                           [Leaf2(${leaf2_address})]"
echo "        |                                           |"
echo "        |                                           |"
echo "[Server1(${server1_address})]                         [Server2(${server2_address})]"
echo "        |                                           |"
echo "        |                                           |"
echo "[Alpine1(${alpine1_address})]                        [Alpine2(${alpine2_address})]"
echo ""
