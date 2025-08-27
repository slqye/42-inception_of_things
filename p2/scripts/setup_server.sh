#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install curl -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --write-kubeconfig-mode 644 --node-ip 192.168.56.110

echo "=== K3s Server installed successfully ==="