#!/bin/bash
set -e
GITLAB_USER_USERNAME='testuser1'
GITLAB_USER_EMAIL='testuser1@gmail.com'
GITLAB_USER_NAME='test user'
GITLAB_USER_PASSWORD='tasdfasbd713440+sdansd'

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
USERNAME=$'\e[38;5;82m'
TOKEN=$'\e[38;5;226m'
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
exit(u[:status] == :success ? 0 : 1)"

kubectl exec -n gitlab -c toolbox "$POD" -- gitlab-rails runner "$RUBY"
if [ $? -ne 0 ]; then
	echo "Error: Failed to create GitLab user"
	exit 1
fi

echo "User created successfully"
echo "username: ${USERNAME}${GITLAB_USER_USERNAME}${RESET}"
echo "password: ${PASSWORD}${GITLAB_USER_PASSWORD}${RESET}"

echo "Issuing user gitlab PAT"
TOKEN_RUBY="user = User.find_by(username: '${GITLAB_USER_USERNAME}')
if user.nil?
    puts 'Error: User not found'
    exit 1
end
PersonalAccessToken.where(user: user, name: 'glab-cli-token').destroy_all
token = PersonalAccessToken.create!(
    user: user,
    name: 'glab-cli-token',
    scopes: ['api', 'read_user', 'write_repository'],
    expires_at: 30.days.from_now
)
puts token.token"
    
# Capture output and exit code separately
TEMP_OUTPUT=$(kubectl exec -n gitlab -c toolbox "$POD" -- gitlab-rails runner "$TOKEN_RUBY" 2>&1)

if [ $? -ne 0 ]; then
	echo "Error: Failed to issue user gitlab PAT"
	echo "Message: $TEMP_OUTPUT"
	exit 1
fi
ACCESS_TOKEN=$(echo "$TEMP_OUTPUT" | tail -n 1 | tr -d '\r\n')
echo "token: ${TOKEN}${ACCESS_TOKEN}${RESET}"
