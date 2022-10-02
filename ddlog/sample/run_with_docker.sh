#!/bin/bash

CONT=$1

if [ -z "$CONT" ]; then
  echo "Please specify the container name for first arguments"
  echo "./run_with_docker <CONNTAINER_NAME>"
  echo ""
  echo "If you want to set memory hard-limit and available cpus, then please set bellow environmental variables"
  echo "export CONTAINER_MEM=8g # set the memory hard-limit to 8G"
  echo "export CONTAINER_CPUS=8 # set the available amount of CPUs is 8(core)"
  exit 1
fi

CPU=${CONTAINER_CPUS:-}
MEMORY=${CONTAINER_MEM:-}

docker run --rm -v `pwd`:/workspace -m ${MEMORY} --cpus ${CPU} -it ${CONT} ./run.sh
