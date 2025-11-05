#!/bin/bash
set -e

# Colors
EMAIL=$'\e[38;5;82m'
PASSWORD=$'\e[38;5;81m' 
RESET=$'\e[0m'

# Main
echo "Cleaning up existing GitLab installation"
helm uninstall gitlab -n gitlab 2>/dev/null || echo "No existing GitLab installation found"
kubectl delete namespace gitlab --ignore-not-found=true
echo "Waiting for namespace deletion..."
sleep 5

echo "Creating GitLab namespace"
kubectl create namespace gitlab

echo "Installing GitLab"
helm repo add gitlab https://charts.gitlab.io/ 2>/dev/null || true
helm repo update

echo "Deploying GitLab (minimal resources)"
helm install gitlab gitlab/gitlab \
  -n gitlab \
  -f confs/gitlab/minimal-values.yaml \
  --timeout 600s

echo "Waiting for GitLab to be ready (This may take a while...)"
kubectl wait --namespace gitlab \
	--for=condition=available deployment/gitlab-webservice-default \
	--timeout=900s

echo "Creating GitLab Ingress"
kubectl apply -f confs/gitlab/ingress.yaml -n gitlab

echo -n "GitLab root password is "
echo ${PASSWORD} && kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode && echo ${RESET}
echo "GitLab available at https://gitlab.sh"
