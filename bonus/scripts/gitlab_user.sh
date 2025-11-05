#!/bin/bash
set -e

# Validate required environment variables
if [ -z "$GITLAB_USER_USERNAME" ]; then
	echo "Error: GITLAB_USER_USERNAME is not set"
	exit 1
fi

if [ -z "$GITLAB_USER_EMAIL" ]; then
	echo "Error: GITLAB_USER_EMAIL is not set"
	exit 1
fi

if [ -z "$GITLAB_USER_NAME" ]; then
	echo "Error: GITLAB_USER_NAME is not set"
	exit 1
fi

if [ -z "$GITLAB_USER_PASSWORD" ]; then
	echo "Error: GITLAB_USER_PASSWORD is not set"
	exit 1
fi

# Colors
EMAIL=$'\e[38;5;82m'
PASSWORD=$'\e[38;5;81m' 
RESET=$'\e[0m'

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
).execute
puts \"=== User Creation Result ===\"
puts \"Status: #{u[:status]}\"
if u[:user]
	puts \"User ID: #{u[:user].id}\"
	puts \"Username: #{u[:user].username}\"
	puts \"Email: #{u[:user].email}\"
	puts \"Name: #{u[:user].name}\"
	puts \"Created at: #{u[:user].created_at}\"
	puts \"Confirmed: #{u[:user].confirmed?}\"
else
	puts \"User: nil (creation failed)\"
end
if u[:message]
	puts \"Message: #{u[:message]}\"
end
if u[:user] && u[:user].errors.any?
	puts \"Errors: #{u[:user].errors.full_messages.join(', ')}\"
end
puts \"Full response: #{u.inspect}\""

kubectl exec -n gitlab -c toolbox "$POD" -- gitlab-rails runner "$RUBY"

echo "password: ${PASSWORD}${GITLAB_USER_PASSWORD}${RESET}"