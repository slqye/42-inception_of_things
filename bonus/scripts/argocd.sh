#!/bin/bash
VERBOSE=0

# Functions
run() {
    if [ "$VERBOSE" -eq 1 ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

# Main
echo "Changing argocd-cli admin password"
INITIAL_PASSWORD=$(argocd admin initial-password -n argocd | head -n 1)
run argocd login argocd.sh --username admin --password $INITIAL_PASSWORD --grpc-web --insecure
NEW_PASSWORD=$(openssl rand -hex 16)
run argocd account update-password --current-password $INITIAL_PASSWORD --new-password $NEW_PASSWORD --grpc-web --insecure
echo "Password: $NEW_PASSWORD"

echo "Setup of argocd app"
run kubectl apply -f confs/argocd/application.yaml
run argocd logout argocd.sh

echo "Done"
