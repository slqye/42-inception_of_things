#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
export MY_USERNAME=iot
set -e

apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget git vim ca-certificates gnupg lsb-release sudo

echo "=== Adding $MY_USERNAME to sudoers ==="
echo "$MY_USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo "=== Installing Docker ==="
echo "  Adding Docker's official GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "  = Adding the docker repository to Apt sources ="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y

echo "  = Installing Docker packages ="
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "  = Adding $MY_USERNAME to the docker group ="
usermod -aG docker $MY_USERNAME

echo "  = Enabling and starting Docker ="
systemctl enable docker
systemctl start docker
docker --version

echo "=== Installing k3d ==="
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d version

echo "=== Installing kubectl ==="
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

