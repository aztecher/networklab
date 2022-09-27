#!/bin/bash

# Requirement
# - docker
# - jq

DOCKER_NETWORK_NAME_SPINE_1="spine1"
DOCKER_NETWORK_NAME_SPINE_1_ETH_1="spine1eth1"
DOCKER_NETWORK_NAME_SPINE_1_ETH_2="spine1eth2"
DOCKER_NETWORK_NAME_SPINE_1_ETH_3="spine1eth3"
DOCKER_NETWORK_NAME_SPINE_1_ETH_4="spine1eth4"
DOCKER_NETWORK_NAME_SPINE_2="spine2"
DOCKER_NETWORK_NAME_SPINE_2_ETH_1="spine2eth1"
DOCKER_NETWORK_NAME_SPINE_2_ETH_2="spine2eth2"
DOCKER_NETWORK_NAME_SPINE_2_ETH_3="spine2eth3"
DOCKER_NETWORK_NAME_SPINE_2_ETH_4="spine2eth4"
DOCKER_NETWORK_NAME_LEAF_1="leaf1"
DOCKER_NETWORK_NAME_LEAF_2="leaf2"
DOCKER_NETWORK_NAME_LEAF_3="leaf3"
DOCKER_NETWORK_NAME_LEAF_4="leaf4"
DOCKER_NETWORK_NAME_SERVERSIDE_1="server1"
DOCKER_NETWORK_NAME_SERVERSIDE_2="server2"
DOCKER_NETWORK_NAME_CONTAINER_1="container1"
DOCKER_NETWORK_NAME_CONTAINER_2="container2"

DOCKER_NETWORK_SUBNET_SPINE_1=10.1.0.0/24
DOCKER_NETWORK_SUBNET_SPINE_1_DEFAULT_GW=10.1.0.1
DOCKER_NETWORK_SUBNET_SPINE_1_ETH_1=10.1.1.0/24
DOCKER_NETWORK_SUBNET_SPINE_1_ETH_2=10.1.2.0/24
DOCKER_NETWORK_SUBNET_SPINE_1_ETH_3=10.1.3.0/24
DOCKER_NETWORK_SUBNET_SPINE_1_ETH_4=10.1.4.0/24
DOCKER_NETWORK_SUBNET_SPINE_2=10.2.0.0/24
DOCKER_NETWORK_SUBNET_SPINE_2_DEFAULT_GW=10.2.0.1
DOCKER_NETWORK_SUBNET_SPINE_2_ETH_1=10.2.1.0/24
DOCKER_NETWORK_SUBNET_SPINE_2_ETH_2=10.2.2.0/24
DOCKER_NETWORK_SUBNET_SPINE_2_ETH_3=10.2.3.0/24
DOCKER_NETWORK_SUBNET_SPINE_2_ETH_4=10.2.4.0/24
DOCKER_NETWORK_SUBNET_LEAF_1=10.0.2.0/24
DOCKER_NETWORK_SUBNET_LEAF_1_DEFAULT_GW=10.0.2.1
DOCKER_NETWORK_SUBNET_LEAF_2=10.0.3.0/24
DOCKER_NETWORK_SUBNET_LEAF_2_DEFAULT_GW=10.0.3.1
DOCKER_NETWORK_SUBNET_LEAF_3=10.0.4.0/24
DOCKER_NETWORK_SUBNET_LEAF_3_DEFAULT_GW=10.0.4.1
DOCKER_NETWORK_SUBNET_LEAF_4=10.0.5.0/24
DOCKER_NETWORK_SUBNET_LEAF_4_DEFAULT_GW=10.0.5.1
DOCKER_NETWORK_SUBNET_SERVERSIDE_1=10.0.6.0/24
DOCKER_NETWORK_SUBNET_SERVERSIDE_1_DEFAULT_GW=10.0.6.1
DOCKER_NETWORK_SUBNET_SERVERSIDE_2=10.0.7.0/24
DOCKER_NETWORK_SUBNET_SERVERSIDE_2_DEFAULT_GW=10.0.7.1
DOCKER_NETWORK_SUBNET_CONTAINER_1=10.0.10.0/24
DOCKER_NETWORK_SUBNET_CONTAINER_1_DEFAULT_GW=10.0.10.1
DOCKER_NETWORK_SUBNET_CONTAINER_2=10.0.11.0/24
DOCKER_NETWORK_SUBNET_CONTAINER_2_DEFAULT_GW=10.0.11.1

echo "Creating 3-Layer FRR + ECMP + BGP + Unnumbered Labo"

echo "Creating networks (netns) ..."
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_1} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_1}
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_1_ETH_1} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_1_ETH_1}
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_1_ETH_2} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_1_ETH_2}
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_1_ETH_3} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_1_ETH_3}
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_1_ETH_4} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_1_ETH_4}
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_2} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_2}
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_2_ETH_1} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_2_ETH_1}
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_2_ETH_2} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_2_ETH_2}
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_2_ETH_3} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_2_ETH_3}
sudo docker network create ${DOCKER_NETWORK_NAME_SPINE_2_ETH_4} --subnet=${DOCKER_NETWORK_SUBNET_SPINE_2_ETH_4}
sudo docker network create ${DOCKER_NETWORK_NAME_LEAF_1} --subnet=${DOCKER_NETWORK_SUBNET_LEAF_1}
sudo docker network create ${DOCKER_NETWORK_NAME_LEAF_2} --subnet=${DOCKER_NETWORK_SUBNET_LEAF_2}
sudo docker network create ${DOCKER_NETWORK_NAME_LEAF_3} --subnet=${DOCKER_NETWORK_SUBNET_LEAF_3}
sudo docker network create ${DOCKER_NETWORK_NAME_LEAF_4} --subnet=${DOCKER_NETWORK_SUBNET_LEAF_4}
sudo docker network create ${DOCKER_NETWORK_NAME_SERVERSIDE_1} --subnet=${DOCKER_NETWORK_SUBNET_SERVERSIDE_1}
sudo docker network create ${DOCKER_NETWORK_NAME_SERVERSIDE_2} --subnet=${DOCKER_NETWORK_SUBNET_SERVERSIDE_2}
sudo docker network create ${DOCKER_NETWORK_NAME_CONTAINER_1} --subnet=${DOCKER_NETWORK_SUBNET_CONTAINER_1}
sudo docker network create ${DOCKER_NETWORK_NAME_CONTAINER_2} --subnet=${DOCKER_NETWORK_SUBNET_CONTAINER_2}

echo "Creating alpine containers ..."
# create container
sudo docker run -dit --name alpine1 --hostname alpine1 --privileged --net ${DOCKER_NETWORK_NAME_CONTAINER_1} alpine
sudo docker run -dit --name alpine2 --hostname alpine2 --privileged --net ${DOCKER_NETWORK_NAME_CONTAINER_2} alpine

echo "Creating frr containers ..."
# Spine SW1
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/spine1/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/spine1/vtysh.conf:/etc/frr/vtysh.conf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --name spine1 --hostname spine1 --privileged --net ${DOCKER_NETWORK_NAME_SPINE_1} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_1_ETH_1} spine1
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_1_ETH_2} spine1
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_1_ETH_3} spine1
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_1_ETH_4} spine1

# Spine SW2
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/spine2/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/spine2/vtysh.conf:/etc/frr/vtysh.conf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --name spine2 --hostname spine2 --privileged --net ${DOCKER_NETWORK_NAME_SPINE_2} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_2_ETH_1} spine2
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_2_ETH_2} spine2
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_2_ETH_3} spine2
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_2_ETH_4} spine2

# Leaf SW1
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/leaf1/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/leaf1/vtysh.conf:/etc/frr/vtysh.conf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --name leaf1 --hostname leaf1 --privileged --net ${DOCKER_NETWORK_NAME_LEAF_1} frrouting/frr:v7.5.0

# Leaf SW2
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/leaf2/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/leaf2/vtysh.conf:/etc/frr/vtysh.conf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --name leaf2 --hostname leaf2 --privileged --net ${DOCKER_NETWORK_NAME_LEAF_2} frrouting/frr:v7.5.0

# Leaf SW3
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/leaf3/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/leaf3/vtysh.conf:/etc/frr/vtysh.conf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --name leaf3 --hostname leaf3 --privileged --net ${DOCKER_NETWORK_NAME_LEAF_3} frrouting/frr:v7.5.0

# Leaf SW4
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/leaf4/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/leaf4/vtysh.conf:/etc/frr/vtysh.conf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --name leaf4 --hostname leaf4 --privileged --net ${DOCKER_NETWORK_NAME_LEAF_4} frrouting/frr:v7.5.0

# Connect (full mesh) leaf - spine
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_1_ETH_1} leaf1
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_2_ETH_1} leaf1
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_1_ETH_2} leaf2
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_2_ETH_2} leaf2
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_1_ETH_3} leaf3
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_2_ETH_3} leaf3
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_1_ETH_4} leaf4
sudo docker network connect ${DOCKER_NETWORK_NAME_SPINE_2_ETH_4} leaf4

# Leaf Server1
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/server1/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/server1/vtysh.conf:/etc/frr/vtysh.conf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --name server1 --hostname server1 --privileged --net ${DOCKER_NETWORK_NAME_SERVERSIDE_1} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_LEAF_1} server1
sudo docker network connect ${DOCKER_NETWORK_NAME_LEAF_2} server1
sudo docker network connect ${DOCKER_NETWORK_NAME_CONTAINER_1} server1

# Leaf Server2
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/server2/frr.conf:/etc/frr/frr.conf \
    -v=`pwd`/config/server2/vtysh.conf:/etc/frr/vtysh.conf \
    --sysctl net.ipv6.conf.all.disable_ipv6=0 \
    --name server2 --hostname server2 --privileged --net ${DOCKER_NETWORK_NAME_SERVERSIDE_2} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_LEAF_3} server2
sudo docker network connect ${DOCKER_NETWORK_NAME_LEAF_4} server2
sudo docker network connect ${DOCKER_NETWORK_NAME_CONTAINER_2} server2

# overwrite netns gateway of each netns
alpine1_gw_address=$(sudo docker inspect server1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_CONTAINER_1}.IPAddress | tr -d '"')
alpine2_gw_address=$(sudo docker inspect server2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_CONTAINER_2}.IPAddress | tr -d '"')

echo "Setting routing tables of alpine containers ..."
sudo docker exec -it alpine1 route add default gw ${alpine1_gw_address}
sudo docker exec -it alpine1 route del default gw ${DOCKER_NETWORK_SUBNET_CONTAINER_1_DEFAULT_GW}
sudo docker exec -it alpine2 route add default gw ${alpine2_gw_address}
sudo docker exec -it alpine2 route del default gw ${DOCKER_NETWORK_SUBNET_CONTAINER_2_DEFAULT_GW}


spine1_address=$(sudo docker inspect spine1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_SPINE_1}.IPAddress | tr -d '"')
spine2_address=$(sudo docker inspect spine2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_SPINE_2}.IPAddress | tr -d '"')
leaf1_address=$(sudo docker inspect leaf1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_LEAF_1}.IPAddress | tr -d '"')
leaf2_address=$(sudo docker inspect leaf2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_LEAF_2}.IPAddress | tr -d '"')
leaf3_address=$(sudo docker inspect leaf3 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_LEAF_3}.IPAddress | tr -d '"')
leaf4_address=$(sudo docker inspect leaf4 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_LEAF_4}.IPAddress | tr -d '"')
server1_address=$(sudo docker inspect server1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_SERVERSIDE_1}.IPAddress | tr -d '"')
server2_address=$(sudo docker inspect server2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_SERVERSIDE_2}.IPAddress | tr -d '"')
alpine1_address=$(sudo docker inspect alpine1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_CONTAINER_1}.IPAddress | tr -d '"')
alpine2_address=$(sudo docker inspect alpine2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_CONTAINER_2}.IPAddress | tr -d '"')

echo ""
echo "Sucessfully creating L3-Layer FRR + BGP + Unnumbered Labo"
echo ""
echo "         [Spine1(${spine1_address})]                        [Spine2(${spine2_address})]"
echo "          | |        | |                             | |       | |    "
echo "          | |        | +---------------------------------------------+"
echo "          | |        +---------------------------+   | |       | |   |"
echo "          | |                                    |   | |       | |   |"
echo "      +----------------------------------------------+ |       | |   |"
echo "      |   | |            +-----------------------------+       | |   |"
echo "    +-----+ +----------+ |                       | +-----------+ +-----+"
echo "    | |                | |                       | |                 | |"
echo "[Leaf1(${leaf1_address})]  [Leaf2(${leaf2_address})]        [Leaf3(${leaf3_address})]  [Leaf4(${leaf4_address})]"
echo "     |                  |                         |                   |"
echo "     +----------+-------+                         +---------+---------+"
echo "                |                                           |               [BGP Unnumbered]"
echo "----------------|-------------------------------------------|--------------------------------"
echo "        [Server1(${server1_address})]                         [Server2(${server2_address})]"
echo "                |                                           |"
echo "        [Alpine1(${alpine1_address})]                        [Alpine2(${alpine2_address})]"
echo ""
