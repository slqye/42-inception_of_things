#!/bin/bash
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server --node-ip=192.168.56.110" K3S_KUBECONFIG_MODE="644" sh -

while ! kubectl get nodes --no-headers | grep -q "Ready"; do
    echo "Waiting for node to be ready..."
    sleep 5
done

sudo cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token
sudo chown vagrant:vagrant /vagrant/node-token

echo "k3s server installed and token copied to /vagrant/node-token"