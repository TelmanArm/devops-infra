#!/bin/bash
set -euo pipefail

PROFILE="devops-infra"
NAMESPACE="demo"
LOCAL_PORT="${LOCAL_PORT:-8084}"

# repo root path
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# kubectl pinned to this cluster/namespace
KCTL=(kubectl --context="$PROFILE" --namespace="$NAMESPACE")

# start the minikube VM/cluster
minikube start \
  --profile="$PROFILE" \
  --driver=docker \
  --cpus=2 \
  --memory=7g \
  --kubernetes-version=v1.35.1

# wait until the node is ready
kubectl --context="$PROFILE" wait --for=condition=Ready node --all --timeout=120s

# deploy k8s manifests via kustomize
kubectl --context="$PROFILE" apply -k "$ROOT_DIR/k8s/base"

# wait until db and app are up
"${KCTL[@]}" rollout status statefulset/db --timeout=180s
"${KCTL[@]}" rollout status deployment/nopcommerce --timeout=300s

# forward app port to localhost
"${KCTL[@]}" port-forward svc/nopcommerce "$LOCAL_PORT":80
