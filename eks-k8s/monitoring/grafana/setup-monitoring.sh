#!/bin/bash
set -e

NAMESPACE=monitoring

kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "🧹 Cleaning up old PVCs..."
kubectl delete pvc -n $NAMESPACE prometheus-server storage-prometheus-alertmanager-0 grafana --ignore-not-found

helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update

echo "🚀 Deploying Grafana..."
helm upgrade --install grafana grafana/grafana \
  -n $NAMESPACE -f values-grafana-aliyun-ephemeral.yaml

echo "✅ Grafana deployed in namespace '$NAMESPACE' (ephemeral storage)"
