#!/bin/bash 

echo "Create SSM parameters for backend deployment"

AWS_REGION=${1:-"ap-southeast-1"}

aws ssm create-document \
  --name DeployBackend \
  --document-type Command \
  --document-format YAML \
  --content file://deploy-backend.yml \
  --region ${AWS_REGION}