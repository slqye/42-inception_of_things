#!/bin/bash
export DEBIAN_FRONTEND=noninteractive
set -e

apt-get update -y
apt-get upgrade -y
apt-get install curl git -y

curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="server" sh -s - --write-kubeconfig-mode 644 --node-ip 192.168.56.110

echo "=== K3s Server installed successfully ==="

curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version

echo "=== Helm installed successfully ==="

# Wait for Traefik to be ready
echo "=== Waiting for Traefik to be ready ==="
kubectl wait --namespace kube-system \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/name=traefik \
	--timeout=120s

echo "=== Traefik is ready ==="

# Ensure kubeconfig is properly set
echo "=== Configuring kubeconfig ==="
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /home/vagrant/.bashrc
echo "export KUBECONFIG=/etc/rancher/k3s/k3s.yaml" >> /root/.bashrc

# Copy kubeconfig to vagrant user's home directory
sudo mkdir -p /home/vagrant/.kube
sudo cp /etc/rancher/k3s/k3s.yaml /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config
sudo chmod 600 /home/vagrant/.kube/config

# Clone hello-kubernetes repository
echo "=== Cloning hello-kubernetes repository ==="
cd /tmp
git clone https://github.com/paulbouwer/hello-kubernetes.git
cd hello-kubernetes/deploy/helm

# Deploy the three hello-kubernetes applications
echo "=== Deploying hello-kubernetes applications ==="

# Deploy app1
helm install app1 ./hello-kubernetes \
	--create-namespace --namespace hello-kubernetes \
	--set deployment.replicaCount=1 \
	--set message="Hello from app1" \
	--set service.type=ClusterIP

# Deploy app2
helm install app2 ./hello-kubernetes \
	--namespace hello-kubernetes \
	--set deployment.replicaCount=3 \
	--set message="Hello from app2" \
	--set service.type=ClusterIP

# Deploy app3
helm install app3 ./hello-kubernetes \
	--namespace hello-kubernetes \
	--set deployment.replicaCount=1 \
	--set message="Hello from app3" \
	--set service.type=ClusterIP

# Apply the Ingress resource
echo "=== Applying Ingress resource ==="
kubectl apply -f /vagrant/hello-kubernetes-ingress.yaml

echo "=== Deployment completed successfully ==="
echo "=== Testing instructions ==="
echo "Test each app with:"
echo "  curl -H \"Host: app1.com\" http://192.168.56.110"
echo "  curl -H \"Host: app2.com\" http://192.168.56.110"
echo "  curl -H \"Host: app3.com\" http://192.168.56.110"
echo ""
