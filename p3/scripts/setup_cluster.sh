#!/bin/bash
set -e

k3d cluster delete -a
k3d cluster create cluster-p3 -p "443:443@loadbalancer"

# Argo cd
kubectl create namespace argocd
kubectl apply -f confs/argocd.yaml -n argocd
echo "=== Waiting for Argo CD to be ready ==="
kubectl wait --namespace argocd --for=condition=ready pod --all --timeout=120s

# Set up Ingress
kubectl apply -f confs/ingress.yaml -n argocd

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
