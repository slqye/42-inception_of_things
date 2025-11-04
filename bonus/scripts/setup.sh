#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
export MY_USERNAME=iot

./scripts/vm.sh $1
./scripts/cluster.sh $1
