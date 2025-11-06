#!/bin/bash
set -e
GITLAB_USER_USERNAME=$(openssl rand -hex 10)
GITLAB_USER_EMAIL="${GITLAB_USER_USERNAME}@gmail.com"
GITLAB_USER_NAME="test user ${GITLAB_USER_USERNAME}"
GITLAB_USER_PASSWORD=$(openssl rand -hex 16)
GITLAB_PROJECT_NAME="iot_uwywijas_$(openssl rand -hex 6)"

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
puts \"User Creation Result\"
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
if u[:status] == :success
	puts \"User created successfully\"
else
	puts \"User creation failed\"
	exit 1
end

PersonalAccessToken.where(user: u[:user], name: 'glab-cli-token').destroy_all
token = PersonalAccessToken.create!(
    user: u[:user],
    name: 'glab-cli-token',
    scopes: ['api', 'read_user', 'write_repository'],
    expires_at: 30.days.from_now
)
puts token.token
"

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

echo "Gitlab config to skip TLS verification for gitlab.sh"
glab config set skip_tls_verify true --host gitlab.sh

export GITLAB_HOST=gitlab.sh
echo "Gitlab user login through glab with token"
glab auth login --token $ACCESS_TOKEN

echo "Creation of a new repository for the user"
glab repo create ${GITLAB_PROJECT_NAME} --public

mkdir -p ~/.ssh
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519 -N ""

glab ssh-key add ~/.ssh/id_ed25519.pub --title "iot_ssh_key"

git clone https://github.com/7f7b6ba1d8/xxxxiotnledergexxxx.git repo
cd repo

export GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519"
git remote add gitlab git@gitlab.sh:${GITLAB_USER_USERNAME}/${GITLAB_PROJECT_NAME}.git
git push gitlab main
