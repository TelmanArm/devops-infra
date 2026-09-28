#!/bin/bash
set -e   # stop if any command fails

# ---- Settings ----
PROFILE="devops-infra"
NAMESPACE="demo"
LOCAL_PORT=8084

# Repo root = two folders up from this script (works from any folder)
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"

# ---- 1. Start the cluster ----
echo "Starting minikube cluster: $PROFILE"
minikube start \
  --profile="$PROFILE" \
  --driver=docker \
  --cpus=2 \
  --memory=6g \
  --kubernetes-version=v1.35.1

# ---- 2. Wait for the node ----
echo "Waiting for node to be Ready..."
kubectl wait --for=condition=Ready node --all --timeout=120s

# ---- 3. Deploy everything (Kustomize) ----
echo "Deploying resources..."
kubectl apply -k "$ROOT_DIR/k8s/base"

# ---- 4. Wait for the apps ----
echo "Waiting for Postgres..."
kubectl rollout status statefulset/db -n "$NAMESPACE" --timeout=120s

echo "Waiting for nopCommerce (first image pull can be slow)..."
kubectl rollout status deployment/nopcommerce -n "$NAMESPACE" --timeout=300s

# ---- 5. Show the result ----
echo "Cluster is ready:"
kubectl get nodes
kubectl get deploy,statefulset,svc,pods,pvc -n "$NAMESPACE"

# ---- 6. Wait until the nopCommerce pod is really running ----
echo "Waiting for nopCommerce pod to be Ready..."
kubectl wait --for=condition=Ready pod -l app=nopcommerce -n "$NAMESPACE" --timeout=300s

# ---- 7. Open access from your Mac ----
echo "Open http://localhost:$LOCAL_PORT  (Ctrl+C to stop)"
kubectl port-forward -n "$NAMESPACE" svc/nopcommerce "$LOCAL_PORT":80