#!/bin/bash
set -e
NAME=$(basename $0)

# Main
echo "Removing previous cluster"
k3d cluster delete -a

echo "Creating new cluster"
k3d cluster create cluster-p3 -p "80:80@loadbalancer" -p "443:443@loadbalancer" -p "32022:32022@loadbalancer"
kubectl create namespace argocd
kubectl create namespace dev

echo "Applying argocd"
kubectl apply -f confs/argocd/argocd-install.yaml -n argocd
echo "Waiting for Argo CD to be ready"
kubectl wait --namespace argocd --for=condition=ready pod --all --timeout=120s

echo "Setup ingress"
kubectl apply -f confs/argocd/ingress.yaml -n argocd

echo "Waiting for Traefik to be ready"
until kubectl get pods --namespace kube-system --selector=app.kubernetes.io/name=traefik 2>/dev/null | grep -q traefik; do
	echo "..."
	sleep 5
done
kubectl wait --namespace kube-system \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/name=traefik \
	--timeout=120s

echo "Done"
