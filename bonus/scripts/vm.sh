#!/bin/bash
MY_USERNAME=iot
NAME=$(basename $0)
VERBOSE=${VERBOSE:-0}

# Functions
run() {
    if [ "$VERBOSE" -eq 1 ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

# Main
echo "Updating system"
run apt-get update -y
run apt-get upgrade -y
run apt-get install -y curl wget git vim ca-certificates gnupg lsb-release sudo

echo "Adding $MY_USERNAME to sudoers"
echo "$MY_USERNAME ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

echo "Installing Docker"
echo "Adding Docker's official GPG key"
run install -m 0755 -d /etc/apt/keyrings
run curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
run chmod a+r /etc/apt/keyrings/docker.asc

echo "Adding the docker repository to Apt sources"
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
run apt-get update -y

echo "Installing Docker packages"
run apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Adding $MY_USERNAME to the docker group"
run usermod -aG docker $MY_USERNAME

echo "Enabling and starting Docker"
run systemctl enable docker
run systemctl start docker
run docker --version

echo "Installing k3d"
run wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
run k3d version

echo "Installing kubectl"
run curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
run curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
run sh -c 'echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check'
run install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
run kubectl version --client

echo "Installing helm"
run curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
run helm version

echo "Installing argocd-cli"
run curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
run sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64

echo "Updating /etc/hosts"
echo "127.0.0.1 argocd.sh" >> /etc/hosts
echo "127.0.0.1 playground.sh" >> /etc/hosts

echo "Done"
