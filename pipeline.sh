#!/bin/bash

# Setup Inicial
set -e

export AWS_ACCOUNT="640948219319"
export AWS_PAGER=""
export APP_NAME="linuxtips-app"
export CLUSTER_NAME="containers-linuxtips"
export BRANCH_NAME=$(git rev-parse --abbrev-ref HEAD)

# CI da APP

echo "APP - CI"

cd app/

go install github.com/golangci/golangci-lint/cmd/golangci-lint@v1.61.0
golangci-lint run ./... -E errcheck

echo "APP - TEST"

go test -v ./...

# CI do Terraform

echo "TERRAFORM - CI"
cd ../terraform

echo "DEPLOY - TERRAFORM INIT"
terraform init -backend-config=./environment/$BRANCH_NAME/backend.tfvars

echo "TERRAFORM - FORMAT CHECK"
terraform fmt --recursive 

echo "TERRAFORM - VALIDATE"
terraform validate


# Build App

cd ../app

echo "BUILD - BUMP DE VERSAO"

GIT_COMMIT_HASH=$(git rev-parse --short HEAD)
echo $GIT_COMMIT_HASH

echo "BUILD - LOGIN NO ECR"

aws ecr get-login-password --profile blog --region us-east-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com

echo "BUILD - CREATE ECR IF NOT EXISTS"

REPOSITORY_NAME="linuxtips/$APP_NAME"

set +e

REPO_EXISTS=$(aws ecr describe-repositories --profile blog --repository-names $REPOSITORY_NAME 2>&1)

if [[ $REPO_EXISTS == *"RepositoryNotFoundException"* ]]; then
  echo "Repositório $REPOSITORY_NAME não encontrado. Criando..."
  
  # Criar o repositório
  aws ecr create-repository --profile blog --repository-name $REPOSITORY_NAME
  
  if [ $? -eq 0 ]; then
    echo "Repositório $REPOSITORY_NAME criado com sucesso."
  else
    echo "Falha ao criar o repositório $REPOSITORY_NAME."
    exit 1
  fi
else
  echo "Repositório $REPOSITORY_NAME já existe."
fi


set -e

echo "BUILD - DOCKER BUILD"

docker build -t $APP_NAME .
docker tag $APP_NAME:latest $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPOSITORY_NAME:$GIT_COMMIT_HASH

# Publish App

echo "BUILD - DOCKER PUBLISH"

docker push $AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPOSITORY_NAME:$GIT_COMMIT_HASH

# Apply Terraform 

cd ../terraform

REPOSITORY_TAG=$AWS_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/$REPOSITORY_NAME:$GIT_COMMIT_HASH

CLUSTER_NAME="containers-linuxtips"

echo "DEPLOY - TERRAFORM PLAN"
terraform plan -var-file=./environment/$BRANCH_NAME/terraform.tfvars -var=container_image=$REPOSITORY_TAG


echo "DEPLOY - TERRAFORM APPLY"
terraform apply --auto-approve -var-file=./environment/$BRANCH_NAME/terraform.tfvars -var=container_image=$REPOSITORY_TAG


echo "DEPLOY - WAIT DEPLOY"
aws ecs wait services-stable --profile blog --cluster $CLUSTER_NAME --services $APP_NAME