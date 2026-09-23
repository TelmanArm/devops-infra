#!/bin/bash
set -e

PROFILE="slowroad"

echo "Starting minikube cluster: $PROFILE"

minikube start \
  --profile="$PROFILE" \
  --driver=docker \
  --cpus=2 \
  --memory=4g \
  --kubernetes-version=v1.35.1

echo "Cluster is ready:"
kubectl get nodes