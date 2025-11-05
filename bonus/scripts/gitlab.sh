#!/bin/bash
set -e
GITLAB_USER_USERNAME="uwywijas12qw4e"
GITLAB_USER_EMAIL="super.45548@gmail.fr"
GITLAB_USER_NAME="Ulrich Duterrage"
GITLAB_USER_PASSWORD="super_password2"

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

echo "Waiting for GitLab to be ready"
kubectl wait --namespace gitlab \
	--for=condition=available deployment/gitlab-webservice-default \
	--timeout=900s

echo "Creating GitLab Ingress"
kubectl apply -f confs/gitlab/ingress.yaml -n gitlab

echo -n "GitLab root password is "
echo ${PASSWORD} && kubectl get secret gitlab-gitlab-initial-root-password -n gitlab -o jsonpath='{.data.password}' | base64 --decode && echo ${RESET}
echo "GitLab available at https://gitlab.sh"

echo "Creating new GitLab user"
POD=$(kubectl get pods -n gitlab -l app=toolbox -o jsonpath='{.items[0].metadata.name}')
RUBY="u = Users::CreateService.new(nil,
  username: '${GITLAB_USER_USERNAME}',
  email: '${GITLAB_USER_EMAIL}',
  name: '${GITLAB_USER_NAME}',
  password: '${GITLAB_USER_PASSWORD}',
  password_confirmation: '${GITLAB_USER_PASSWORD}',
  organization_id: Organizations::Organization.first.id,
  skip_confirmation: true
).execute"
kubectl exec -n gitlab -c toolbox "$POD" -- gitlab-rails runner "$RUBY"
echo "username: ${EMAIL}${GITLAB_USER_USERNAME}${RESET}"
echo "password: ${PASSWORD}${GITLAB_USER_PASSWORD}${RESET}"

echo "Done"
