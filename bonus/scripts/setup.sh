#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
export MY_USERNAME=iot

# Colors
DEBUG=$'\e[0;34m'
SUCCESS=$'\e[0;32m'
WARNING=$'\e[0;33m'
ERROR=$'\e[0;31m'
VM_COLOR=$'\e[1;35m'
CLUSTER_COLOR=$'\e[1;36m'
RESET=$'\e[0m'

# Main
./scripts/vm.sh $1 2>&1 | sed "s/^/${VM_COLOR}vm${RESET}: /"
./scripts/cluster.sh $1 2>&1 | sed "s/^/${CLUSTER_COLOR}cluster${RESET}: /"
