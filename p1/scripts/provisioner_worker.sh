#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget

while [ ! -f /vagrant/node-token ]; do
    echo "Waiting for server token..."
    sleep 5
done

TOKEN=$(cat /vagrant/node-token)
SERVER_IP="192.168.56.110"

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="agent --node-ip=192.168.56.111" K3S_URL="https://${SERVER_IP}:6443" K3S_TOKEN="${TOKEN}" sh -

echo "k3s agent installed and joined the cluster"