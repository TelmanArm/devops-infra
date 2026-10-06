#!/bin/bash
set -euo pipefail

PROFILE="devops-infra"
NAMESPACE="slowroad"
LOCAL_PORT="${LOCAL_PORT:-8084}"
ARGOCD_PORT="${ARGOCD_PORT:-8085}"

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
KCTL=(kubectl --context="$PROFILE" --namespace="$NAMESPACE")
ARGO=(kubectl --context="$PROFILE" --namespace=argocd)

minikube start \
  --profile="$PROFILE" \
  --driver=docker \
  --cpus=4 \
  --memory=7g \
  --kubernetes-version=v1.35.1

kubectl --context="$PROFILE" wait --for=condition=Ready node --all --timeout=120s


# admin Secret, values come from terraform/local/terraform.tfvars
terraform -chdir="$ROOT_DIR/terraform/local" init -input=false
terraform -chdir="$ROOT_DIR/terraform/local" apply -input=false -auto-approve

helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm upgrade --install argocd argo/argo-cd \
  --kube-context "$PROFILE" \
  --namespace argocd --create-namespace
"${ARGO[@]}" rollout status deployment/argocd-server --timeout=300s

# from here on the app is Argo CD's job
kubectl --context="$PROFILE" apply -f "$ROOT_DIR/argocd/apps/slowroad.yaml"

# rollout status errors out if the objects aren't there yet, so wait for the first sync
until "${KCTL[@]}" get statefulset/db deployment/slowroad >/dev/null 2>&1; do
  echo "waiting for Argo CD to sync..."
  sleep 5
done

"${KCTL[@]}" rollout status statefulset/db --timeout=180s
"${KCTL[@]}" rollout status deployment/slowroad --timeout=300s

echo "Argo CD user: admin"
echo -n "Argo CD password: "
"${ARGO[@]}" get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

"${ARGO[@]}" port-forward svc/argocd-server "$ARGOCD_PORT":443 >/dev/null 2>&1 &
echo "Argo CD UI: https://localhost:$ARGOCD_PORT"

echo "App: http://localhost:$LOCAL_PORT"
"${KCTL[@]}" port-forward svc/slowroad "$LOCAL_PORT":80
