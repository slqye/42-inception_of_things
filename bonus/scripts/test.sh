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
