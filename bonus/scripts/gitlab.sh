#!/bin/bash
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
echo "Cleaning up existing GitLab installation"
run helm uninstall gitlab -n gitlab 2>/dev/null || echo "No existing GitLab installation found"
run kubectl delete namespace gitlab --ignore-not-found=true
echo "Waiting for namespace deletion..."
sleep 5

echo "Creating GitLab namespace"
run kubectl create namespace gitlab

echo "Installing GitLab"
run helm repo add gitlab https://charts.gitlab.io/ 2>/dev/null || true
run helm repo update

echo "Deploying GitLab (minimal resources)"
run helm install gitlab gitlab/gitlab \
  -n gitlab \
  -f confs/gitlab/minimal-values.yaml \
  --timeout 600s

echo "Waiting for GitLab to be ready"
run kubectl wait --namespace gitlab \
	--for=condition=available deployment/gitlab-webservice-default \
	--timeout=900s

echo "Creating GitLab Ingress"
run kubectl apply -f confs/gitlab/ingress.yaml -n gitlab

echo "GitLab root password"
run kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode
echo "GitLab available at https://gitlab.sh"

echo "Done"
