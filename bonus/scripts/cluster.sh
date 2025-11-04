#!/bin/bash
NAME=$(basename $0)
VERBOSE=0

if [ "$1" == "--verbose" ]; then
    VERBOSE=1
fi

# Functions
run() {
    if [ "$VERBOSE" -eq 1 ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

# Main
echo "Removing previous cluster"
run k3d cluster delete -a

echo "Creating new cluster"
run k3d cluster create cluster-p3 -p "443:443@loadbalancer" -p "80:80@loadbalancer"
run kubectl create namespace argocd
run kubectl create namespace dev

echo "Applying argocd"
run kubectl apply -f confs/argocd/argocd-install.yaml -n argocd
echo "Waiting for Argo CD to be ready"
run kubectl wait --namespace argocd --for=condition=ready pod --all --timeout=120s

echo "Setup ingress"
run kubectl apply -f confs/argocd/ingress.yaml -n argocd

echo "Waiting for Traefik to be ready"
until kubectl get pods --namespace kube-system --selector=app.kubernetes.io/name=traefik 2>/dev/null | grep -q traefik; do
	echo "..."
	sleep 5
done
run kubectl wait --namespace kube-system \
	--for=condition=ready pod \
	--selector=app.kubernetes.io/name=traefik \
	--timeout=120s

echo "Changing argocd-cli admin password"
INITIAL_PASSWORD=$(argocd admin initial-password -n argocd | head -n 1)
run argocd login argocd.sh --username admin --password $INITIAL_PASSWORD --grpc-web --insecure
NEW_PASSWORD=$(openssl rand -hex 16)
run argocd account update-password --current-password $INITIAL_PASSWORD --new-password $NEW_PASSWORD --grpc-web --insecure
echo "new password: $NEW_PASSWORD"

echo "Setup of argocd app"
run kubectl apply -f confs/argocd/application.yaml
run argocd logout argocd.sh

echo "Done"
