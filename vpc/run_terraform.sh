#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 <environment> <command>"
    echo "Environment: staging, uat, prod"
    echo "Command: init, plan, apply, destroy"
    exit 1
}

# Check if environment and command are provided
if [ "$#" -ne 2 ]; then
    usage
fi

ENV=$1
CMD=$2

# Validate environment
if [[ ! "$ENV" =~ ^(staging|uat|prod)$ ]]; then
    echo "Error: Environment must be staging, uat, or prod"
    usage
fi

# Validate command
if [[ ! "$CMD" =~ ^(init|plan|apply|destroy)$ ]]; then
    echo "Error: Command must be init, plan, apply, or destroy"
    usage
fi

# Set environment-specific variables
BACKEND_CONFIG="envs/${ENV}/backend.tf"
VAR_FILE="envs/${ENV}/terraform.tfvars"

echo "Running Terraform for environment: ${ENV}"
echo "Using backend config: ${BACKEND_CONFIG}"
echo "Using var file: ${VAR_FILE}"

# Execute the command
case $CMD in
    init)
        terraform init -backend-config=${BACKEND_CONFIG}
        ;;
    plan)
        terraform plan -var-file=${VAR_FILE}
        ;;
    apply)
        terraform apply -var-file=${VAR_FILE}
        ;;
    destroy)
        terraform destroy -var-file=${VAR_FILE}
        ;;
esac 