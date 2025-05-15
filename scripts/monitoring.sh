#!/bin/bash
set -x
export MONITOR_NS=monitoring
echo "Creating namespace"
kubectl create namespace $MONITOR_NS
echo "Adding helm repo"
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts#

helm repo update
echo "Installing prometheus"
helm install prometheus prometheus-community/prometheus --namespace monitoring --set server.persistentVolume.enabled=false
kubectl patch svc prometheus-server --namespace=monitoring -p '{"spec": {"type": "LoadBalancer"}}'
echo "Installing grafana"
helm install grafana grafana/grafana --namespace monitoring
kubectl patch svc grafana --namespace=monitoring -p '{"spec": {"type": "LoadBalancer"}}'

sleep 20

prometheus_addr=$(yq '.status.loadBalancer.ingress[0].hostname' <<< $(kubectl get  svc prometheus-server -n monitoring -o yaml))
grafana_addr=$(yq '.status.loadBalancer.ingress[0].hostname' <<< $(kubectl get  svc grafana -n monitoring -o yaml))
grafana_pass=$(kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo)

echo "Prometheus address: $prometheus_addr"
echo "Grafana address: $grafana_addr"
echo "Grafana password: $grafana_pass"
