#!/bin/bash
set -euo pipefail

PROFILE="devops-infra"
NAMESPACE="demo"
LOCAL_PORT="${LOCAL_PORT:-8084}"
ARGOCD_PORT="${ARGOCD_PORT:-8085}"

# repo root path
ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
# kubectl pinned to this cluster/namespace
KCTL=(kubectl --context="$PROFILE" --namespace="$NAMESPACE")
# kubectl pinned to the argocd namespace
ARGO=(kubectl --context="$PROFILE" --namespace=argocd)

# start the minikube VM/cluster
minikube start \
  --profile="$PROFILE" \
  --driver=docker \
  --cpus=2 \
  --memory=7g \
  --kubernetes-version=v1.35.1

# wait until the node is ready
kubectl --context="$PROFILE" wait --for=condition=Ready node --all --timeout=120s

# install Argo CD
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --kube-context "$PROFILE" \
  --namespace argocd --create-namespace
"${ARGO[@]}" rollout status deployment/argocd-server --timeout=300s

# hand the app over to Argo CD
kubectl --context="$PROFILE" apply -f "$ROOT_DIR/argocd/apps/slowroad.yaml"

# wait until Argo CD has created the workloads
until "${KCTL[@]}" get statefulset/db deployment/slowroad >/dev/null 2>&1; do
  echo "waiting for Argo CD to sync..."
  sleep 5
done

# wait until db and app are up
"${KCTL[@]}" rollout status statefulset/db --timeout=180s
"${KCTL[@]}" rollout status deployment/slowroad --timeout=300s

# Argo CD credentials and UI in the background
echo "Argo CD user: admin"
echo -n "Argo CD password: "
"${ARGO[@]}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
"${ARGO[@]}" port-forward svc/argocd-server "$ARGOCD_PORT":443 >/dev/null 2>&1 &
echo "Argo CD UI: https://localhost:$ARGOCD_PORT"

# forward app port to localhost (keeps running)
echo "App: http://localhost:$LOCAL_PORT"
"${KCTL[@]}" port-forward svc/slowroad "$LOCAL_PORT":80

# create admin Secret from local .env (not in git)
kubectl --context="$PROFILE" create namespace "$NAMESPACE" \
     --dry-run=client -o yaml | kubectl --context="$PROFILE" apply -f -
kubectl --context="$PROFILE" -n "$NAMESPACE" create secret generic slowroad-app \
     --from-env-file="$ROOT_DIR/.env" \
     --dry-run=client -o yaml | kubectl --context="$PROFILE" apply -f -
kubectl --context="$PROFILE" wait --for=condition=Ready node --all --timeout=120s