#!/bin/bash
set -e

echo "Configuring CoreDNS for gitlab.sh"
TRAEFIK_IP=$(kubectl get svc traefik -n kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
CURRENT_HOSTS=$(kubectl get configmap coredns -n kube-system -o jsonpath='{.data.NodeHosts}' | tr '\n' ' ')
NEW_HOSTS="${CURRENT_HOSTS}${TRAEFIK_IP} gitlab.sh ${TRAEFIK_IP} gitlab.gitlab.sh"
kubectl patch configmap coredns -n kube-system --type merge -p "{\"data\":{\"NodeHosts\":\"${NEW_HOSTS}\"}}"
kubectl rollout restart deployment coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system --timeout=60s
