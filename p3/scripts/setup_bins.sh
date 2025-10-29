#!/bin/bash
set -e
export USE_SUDO=false
export INSTALL_DIR="$HOME/iot_bins"

mkdir -p "$INSTALL_DIR"
export PATH="$INSTALL_DIR:$PATH"

export K3D_INSTALL_DIR="$INSTALL_DIR"
wget -q -O - https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

k3d version

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl "$INSTALL_DIR/kubectl"

kubectl version --client

echo "export PATH=$INSTALL_DIR:\$PATH" >> ~/.zshrc

echo "Don't forget to 'source ~/.zshrc' to update your PATH"
