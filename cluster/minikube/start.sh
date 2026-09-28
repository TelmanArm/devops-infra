#!/bin/bash
set -e

PROFILE="devops-infra"

echo "Starting minikube cluster: $PROFILE"

minikube start \
  --profile="$PROFILE" \
  --driver=docker \
  --cpus=2 \
  --memory=4g \
  --kubernetes-version=v1.35.1

echo "Waiting for node to be Ready..."                      
kubectl wait --for=condition=Ready node --all --timeout=120s  

echo "Deploying resources..."                              
kubectl apply -k k8s/base                                   

echo "Waiting for Postgres..."                              
kubectl rollout status statefulset/db -n demo --timeout=120s 

echo "Cluster is ready:"
kubectl get nodes
kubectl get svc,statefulset,pods,pvc -n demo      