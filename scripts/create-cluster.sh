#!/bin/bash

export AWS_REGION=eu-central-1
export CLUSTER_NAME=mgr-deploy-test

eksctl create cluster --region $AWS_REGION --name $CLUSTER_NAME
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME