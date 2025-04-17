#!/bin/bash
CLUSTER_NAME=$1

eksctl delete cluster --name=$CLUSTER_NAME
kubectl config delete-context $CLUSTER_NAME