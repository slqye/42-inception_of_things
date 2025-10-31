#!/bin/bash
set -e

k3d cluster delete -a
k3d cluster create cluster-p3 -p "443:443@loadbalancer" -p "80:80@loadbalancer"

kubectl create namespace argocd
kubectl create namespace dev

# Argo cd
kubectl apply -f confs/argocd/argocd-install.yaml -n argocd
echo "=== Waiting for Argo CD to be ready ==="
kubectl wait --namespace argocd --for=condition=ready pod --all --timeout=120s

# Set up Ingress
kubectl apply -f confs/argocd/ingress.yaml -n argocd

# Wait for Traefik to be ready
echo "=== Waiting for Traefik to be ready ==="
until kubectl get pods --namespace kube-system --selector=app.kubernetes.io/name=traefik 2>/dev/null | grep -q traefik; do
	echo "Waiting for Traefik pods to be created..."
	sleep 5
done
kubectl wait --namespace kube-system \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/name=traefik \
	--timeout=120s

# Argo cd CLI - change admin password
INITIAL_PASSWORD=$(argocd admin initial-password -n argocd | head -n 1)
argocd login argocd.sh --username admin --password $INITIAL_PASSWORD --grpc-web --insecure
NEW_PASSWORD=$(openssl rand -hex 16)
argocd account update-password --current-password $INITIAL_PASSWORD --new-password $NEW_PASSWORD --grpc-web --insecure
echo "Admin password updated to: $NEW_PASSWORD"

## Argo cd CLI - set argocd app
kubectl apply -f confs/argocd/application.yaml
argocd logout argocd.sh
