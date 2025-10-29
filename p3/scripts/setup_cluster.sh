#!/bin/bash
set -e

k3d cluster delete -a
k3d cluster create cluster-p3 -p "8443:443@loadbalancer"

# Argo cd
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl wait --namespace argocd --for=condition=ready pod --all --timeout=120s
kubectl apply -f confs/ingress.yaml
