#!/bin/bash

# Requirement
# - docker
# - jq

DOCKER_NETWORK_NAME_1="net1"
DOCKER_NETWORK_NAME_2="net2"
DOCKER_NETWORK_NAME_3="net3"

DOCKER_NETWORK_SUBNET_1=10.0.0.0/24
DOCKER_NETWORK_SUBNET_1_DEFAULT_GW=10.0.0.1
DOCKER_NETWORK_SUBNET_2=10.0.1.0/24
DOCKER_NETWORK_SUBNET_2_DEFAULT_GW=10.0.1.1
DOCKER_NETWORK_SUBNET_3=10.0.2.0/24
DOCKER_NETWORK_SUBNET_3_DEFAULT_GW=10.0.2.1

echo "Creating simple FRR + BGP Labo"
echo "Creating networks (netns) ..."
sudo docker network create ${DOCKER_NETWORK_NAME_1} --subnet=${DOCKER_NETWORK_SUBNET_1}
sudo docker network create ${DOCKER_NETWORK_NAME_2} --subnet=${DOCKER_NETWORK_SUBNET_2}
sudo docker network create ${DOCKER_NETWORK_NAME_3} --subnet=${DOCKER_NETWORK_SUBNET_3}

echo "Creating alpine containers ..."
sudo docker run -dit --name alpine1 --hostname alpine1 --privileged --net ${DOCKER_NETWORK_NAME_1} alpine
sudo docker run -dit --name alpine2 --hostname alpine2 --privileged --net ${DOCKER_NETWORK_NAME_3} alpine

echo "Creating frr containers ..."
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/frr1/frr.conf:/etc/frr/frr.conf \
    --name frr1 --hostname frr1 --privileged --net ${DOCKER_NETWORK_NAME_1} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_2} frr1
sudo docker run -dit \
    -v=`pwd`/config/daemons:/etc/frr/daemons \
    -v=`pwd`/config/frr2/frr.conf:/etc/frr/frr.conf \
    --name frr2 --hostname frr2 --privileged --net ${DOCKER_NETWORK_NAME_2} frrouting/frr:v7.5.0
sudo docker network connect ${DOCKER_NETWORK_NAME_3} frr2

frr1_gw_address_net1=$(sudo docker inspect frr1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_1}.IPAddress | tr -d '"')
frr2_gw_address_net3=$(sudo docker inspect frr2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_3}.IPAddress | tr -d '"')

# set the default route of alpine from bridge to frr
echo "Setting routing table of frr containers ..."
sudo docker exec -it alpine1 route add default gw ${frr1_gw_address_net1}
sudo docker exec -it alpine1 route del default gw ${DOCKER_NETWORK_SUBNET_1_DEFAULT_GW}
sudo docker exec -it alpine2 route add default gw ${frr2_gw_address_net3}
sudo docker exec -it alpine2 route del default gw ${DOCKER_NETWORK_SUBNET_3_DEFAULT_GW}


# finalize, report ip address of alpine container
frr1_address=$(sudo docker inspect frr1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_2}.IPAddress | tr -d '"')
frr2_address=$(sudo docker inspect frr2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_2}.IPAddress | tr -d '"')
alpine1_address=$(sudo docker inspect alpine1 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_1}.IPAddress | tr -d '"')
alpine2_address=$(sudo docker inspect alpine2 | jq .[0].NetworkSettings.Networks.${DOCKER_NETWORK_NAME_3}.IPAddress | tr -d '"')

echo ""
echo "Sucessfully creating simpleFRR + BGP Labo"
echo ""
echo "   [FRR1(${frr1_address})]-------------------------[FRR2(${frr2_address})]"
echo "        |                                        |"
echo "        |                                        |"
echo "  [Alpine1(${alpine1_address})]                      [Alpine2(${alpine2_address})]"
echo ""
