#!/bin/bash
set -e
MY_USERNAME=iot
NAME=$(basename $0)

# Main
echo "Updating system"
apt-get update -y
apt-get upgrade -y
apt-get install -y curl wget git vim ca-certificates gnupg lsb-release sudo

echo "Adding $MY_USERNAME to sudoers"
echo "$MY_USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo "Installing Docker"
echo "Adding Docker's official GPG key"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo "Adding the docker repository to Apt sources"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y

echo "Installing Docker packages"
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Adding $MY_USERNAME to the docker group"
usermod -aG docker $MY_USERNAME

echo "Enabling and starting Docker"
systemctl enable docker
systemctl start docker
docker --version

echo "Installing k3d"
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
k3d version

echo "Installing kubectl"
curl -o /tmp/kubectl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -o /tmp/kubectl.sha256 -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
sh -c 'echo "$(cat /tmp/kubectl.sha256)  /tmp/kubectl" | sha256sum --check'
install -o root -g root -m 0755 /tmp/kubectl /usr/local/bin/kubectl
kubectl version --client
rm /tmp/kubectl
rm /tmp/kubectl.sha256

echo "Installing helm"
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version

echo "Installing argocd-cli"
curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
rm /tmp/argocd-linux-amd64

echo "Installing glab cli"
wget -O /tmp/glab_1.76.2_linux_amd64.deb https://gitlab.com/gitlab-org/cli/-/releases/v1.76.2/downloads/glab_1.76.2_linux_amd64.deb
apt-get install -y /tmp/glab_1.76.2_linux_amd64.deb
rm /tmp/glab_1.76.2_linux_amd64.deb
glab version

echo "Updating /etc/hosts"
echo "127.0.0.1 argocd.sh" >> /etc/hosts
echo "127.0.0.1 playground.sh" >> /etc/hosts
echo "127.0.0.1 gitlab.sh" >> /etc/hosts

echo "Done"
