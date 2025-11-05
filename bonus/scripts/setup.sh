#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

# Colors
DEBUG=$'\e[0;34m'
SUCCESS=$'\e[0;32m'
WARNING=$'\e[0;33m'
ERROR=$'\e[0;31m'
VM_COLOR=$'\e[1;35m'
CLUSTER_COLOR=$'\e[1;36m'
ARGOCD_COLOR=$'\e[38;5;208m'
GITLAB_COLOR=$'\e[38;5;202m'
RESET=$'\e[0m'

# Main
if [ "$1" = "--only-vm" ]; then
	./scripts/vm.sh 2>&1 | sed "s/^/${VM_COLOR}vm${RESET}: /"
	exit
fi
./scripts/cluster.sh 2>&1 | sed "s/^/${CLUSTER_COLOR}cluster${RESET}: /"
./scripts/gitlab.sh 2>&1 | sed "s/^/${GITLAB_COLOR}gitlab${RESET}: /"
./scripts/argocd.sh 2>&1 | sed "s/^/${ARGOCD_COLOR}argocd${RESET}: /"
