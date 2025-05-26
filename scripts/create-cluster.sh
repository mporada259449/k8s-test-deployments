#!/bin/bash

export AWS_REGION=eu-central-1
export CLUSTER_NAME=$1
echo "Creating cluster named ${CLUSTER_NAME} at ${AWS_REGION}"
eksctl create cluster --region $AWS_REGION --name $CLUSTER_NAME --enable-auto-mode &
echo "Waiting for cluster"
wait "$!"
echo "Update of kubectl configuration"
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
echo "Applying new configuration for cluster - gateway api controller"
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.0/standard-install.yaml

kubectl create namespace istio-system
istioctl install --set profile=minimal -y
echo "Applying ArgoCD configuration"
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
echo "Waiting for LoadBalacer to be available"
while true; do
    ARGO_DNS_ADDRESS=$(k get svc -A | grep  -o "[a-z0-9-]*.${AWS_REGION}.elb.amazonaws.com")
    if [[ -n "$ARGO_DNS_ADDRESS" ]]; then
      echo "LoadBalancer is available at: $ARGO_DNS_ADDRESS"
      break
    else
      echo "Still waiting for LoadBalancer..."
      sleep 5
    fi
done

echo "Password change in for user admin"
kubectl config set-context --current --namespace=argocd
ARGO_INIT_PASS=$(argocd admin initial-password | head -n 1)

argocd login --username admin --password "${ARGO_INIT_PASS}" "$ARGO_DNS_ADDRESS"

argocd account update-password --current-password "${ARGO_INIT_PASS}" --new-password "${ARGO_PASS}
kubectl config set-context --current --namespace=default