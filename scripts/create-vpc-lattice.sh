#!/bin/bash

export GATEWAY_NAME=$1
export AWS_REGION=eu-central-1
export CLUSTER_NAME=mgr-deploy-test

aws vpc-lattice create-service-network --name $GATEWAY_NAME
SERVICE_NETWORK_ID=$(aws vpc-lattice list-service-networks --query "items[?name=="\'$GATEWAY_NAME\'"].id" | jq -r '.[]')
CLUSTER_VPC_ID=$(aws eks describe-cluster --name $CLUSTER_NAME | jq -r .cluster.resourcesVpcConfig.vpcId)
aws vpc-lattice create-service-network-vpc-association --service-network-identifier $SERVICE_NETWORK_ID --vpc-identifier $CLUSTER_VPC_ID
aws vpc-lattice list-service-network-vpc-associations --vpc-id $CLUSTER_VPC_ID