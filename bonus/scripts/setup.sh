#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive
export MY_USERNAME=iot

./vm.sh $1
./cluster.sh $1
