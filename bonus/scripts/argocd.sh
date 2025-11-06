#!/bin/bash
set -e

# Colors
PASSWORD=$'\e[38;5;81m' 
RESET=$'\e[0m'

# Main
echo "Changing argocd-cli admin password"
INITIAL_PASSWORD=$(argocd admin initial-password -n argocd | head -n 1)
argocd login argocd.sh --username admin --password $INITIAL_PASSWORD --grpc-web --insecure
NEW_PASSWORD=$(openssl rand -hex 16)
argocd account update-password --current-password $INITIAL_PASSWORD --new-password $NEW_PASSWORD --grpc-web --insecure
echo "new password is ${PASSWORD}$NEW_PASSWORD${RESET}"
