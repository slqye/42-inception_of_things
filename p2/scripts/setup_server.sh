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

# Wait for K3s to be ready and configure kubeconfig
echo "=== Waiting for K3s to be ready ==="
while ! kubectl get nodes --no-headers | grep -q "Ready"; do
	echo "Waiting for node to be ready..."
	sleep 5
done

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

# Test kubectl access
kubectl get nodes

# Add Helm repositories
echo "=== Adding Helm repositories ==="
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# Clone hello-kubernetes repository
echo "=== Cloning hello-kubernetes repository ==="
cd /tmp
git clone https://github.com/paulbouwer/hello-kubernetes.git
cd hello-kubernetes/deploy/helm

# Install NGINX Ingress Controller
echo "=== Installing NGINX Ingress Controller ==="
helm install nginx-ingress ingress-nginx/ingress-nginx \
	--create-namespace --namespace ingress-nginx \
	--set controller.replicaCount=1 \
	--set controller.service.type=NodePort \
	--set controller.service.nodePorts.http=30080

# Wait for ingress controller to be ready
echo "=== Waiting for Ingress Controller to be ready ==="
kubectl wait --namespace ingress-nginx \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/component=controller \
	--timeout=120s

# Ingress controller is accessible via NodePort 30080
echo "=== Ingress Controller Setup Complete ==="
echo "Ingress controller is running on NodePort 30080"
echo "Access your apps via: http://192.168.56.110:30080"

# Deploy the three hello-kubernetes applications
echo "=== Deploying hello-kubernetes applications ==="

# Deploy app1
helm install app1 ./hello-kubernetes \
	--create-namespace --namespace hello-kubernetes \
	--set replicaCount=1 \
	--set message="Hello from app1" \
	--set service.type=ClusterIP

# Deploy app2
helm install app2 ./hello-kubernetes \
	--namespace hello-kubernetes \
	--set replicaCount=3 \
	--set message="Hello from app2" \
	--set service.type=ClusterIP

# Deploy app3
helm install app3 ./hello-kubernetes \
	--namespace hello-kubernetes \
	--set replicaCount=1 \
	--set message="Hello from app3" \
	--set service.type=ClusterIP

# Wait for apps to be ready
echo "=== Waiting for applications to be ready ==="
kubectl wait --namespace hello-kubernetes \
	--for=condition=ready pod \
	--all \
	--timeout=120s

# Apply the Ingress resource
echo "=== Applying Ingress resource ==="
kubectl apply -f /vagrant/hello-kubernetes-ingress.yaml

echo "=== Deployment completed successfully ==="
echo "=== Testing instructions ==="
echo "Ingress controller is accessible via NodePort 30080"
echo "Test each app with:"
echo "  curl -H \"Host: app1.com\" http://192.168.56.110:30080"
echo "  curl -H \"Host: app2.com\" http://192.168.56.110:30080"
echo "  curl -H \"Host: app3.com\" http://192.168.56.110:30080"
echo ""
echo "All applications are running and accessible via the ingress controller!"
