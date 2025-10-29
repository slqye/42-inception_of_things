#!/bin/bash
set -e

k3d cluster create cluster-p3
kubectl get all