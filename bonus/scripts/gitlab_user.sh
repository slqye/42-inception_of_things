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

echo "Creating new GitLab user and issuing gitlab PAT"
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
if u[:status] != :success
	puts \"User creation failed\"
	if u[:message]
		puts \"Message: #{u[:message]}\"
	end
	if u[:user] && u[:user].errors.any?
		puts \"Errors: #{u[:user].errors.full_messages.join(', ')}\"
	end
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

# Capture output and exit code separately
TEMP_OUTPUT=$(kubectl exec -n gitlab -c toolbox "$POD" -- gitlab-rails runner "$RUBY" 2>&1)

if [ $? -ne 0 ]; then
	echo "Error: Failed to create user and issue gitlab PAT"
	echo "Full output: $TEMP_OUTPUT"
	exit 1
fi

echo "User created successfully"
echo "username: ${USERNAME}${GITLAB_USER_USERNAME}${RESET}"
echo "password: ${PASSWORD}${GITLAB_USER_PASSWORD}${RESET}"

ACCESS_TOKEN=$(echo "$TEMP_OUTPUT" | tail -n 1 | tr -d '\r\n')
echo "token: ${TOKEN}${ACCESS_TOKEN}${RESET}"

echo "Gitlab config to skip TLS verification for gitlab.sh"
glab config set skip_tls_verify true --host gitlab.sh

export GITLAB_HOST=gitlab.sh
echo "Gitlab user login through glab with token"

if glab auth status --hostname gitlab.sh 2>/dev/null; then
	echo "Already logged in, logging out..."
	glab auth logout --hostname gitlab.sh
fi

glab auth login --token "${ACCESS_TOKEN}" --hostname gitlab.sh
glab auth status --hostname gitlab.sh

echo "Creation of a new repository for the user"
glab repo create ${GITLAB_PROJECT_NAME} --public

rm -rf .ssh repo
mkdir -p .ssh
chmod 700 .ssh
ssh-keygen -q -t ed25519 -f .ssh/id_ed25519 -N ""
chmod 600 .ssh/id_ed25519
glab ssh-key add .ssh/id_ed25519.pub --title "iot_ssh_key"
glab ssh-key list

ssh-keyscan gitlab.sh >> .ssh/known_hosts

echo "Cloning repository from original repository"
git clone https://github.com/7f7b6ba1d8/xxxxiotnledergexxxx.git repo
cd repo

export GIT_SSH_COMMAND="ssh -i $PWD/../.ssh/id_ed25519 -o UserKnownHostsFile=$PWD/../.ssh/known_hosts -o StrictHostKeyChecking=no"
echo "Pushing to GitLab repository"
git remote add gitlab ssh://git@gitlab.sh:32022/${GITLAB_USER_USERNAME}/${GITLAB_PROJECT_NAME}.git
git push gitlab main

cd ..

echo "Changing argocd-cli admin password"
INITIAL_PASSWORD=$(argocd admin initial-password -n argocd | head -n 1)
argocd login argocd.sh --username admin --password $INITIAL_PASSWORD --grpc-web --insecure
NEW_PASSWORD=$(openssl rand -hex 16)
argocd account update-password --current-password $INITIAL_PASSWORD --new-password $NEW_PASSWORD --grpc-web --insecure
echo "new password is ${PASSWORD}$NEW_PASSWORD${RESET}"

echo "Setup of argocd app"
sed -i "s|<repo_url_placeholder>|https://gitlab.sh/${GITLAB_USER_USERNAME}/${GITLAB_PROJECT_NAME}.git|g" confs/argocd/application.yaml
kubectl apply -f confs/argocd/application.yaml
argocd logout argocd.sh
