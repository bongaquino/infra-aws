#!/bin/bash

# Script to manage SSH key access in AWS Secrets Manager
# Usage: ./manage_key_access.sh <environment> <action> [user/role]

set -e

# Check if required arguments are provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <environment> <action> [user/role]"
    echo "Actions: grant, revoke, list"
    echo "Example: $0 staging grant arn:aws:iam::123456789012:user/developer"
    exit 1
fi

ENVIRONMENT=$1
ACTION=$2
PRINCIPAL=$3

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(staging|uat|prod)$ ]]; then
    echo "Invalid environment. Must be one of: staging, uat, prod"
    exit 1
fi

# Validate action
if [[ ! "$ACTION" =~ ^(grant|revoke|list)$ ]]; then
    echo "Invalid action. Must be one of: grant, revoke, list"
    exit 1
fi

# Set secret name
SECRET_NAME="bongaquino/${ENVIRONMENT}/ssh-key"

# Function to list current access
list_access() {
    echo "Current access for $SECRET_NAME:"
    aws secretsmanager get-resource-policy --secret-id "$SECRET_NAME" \
        --query 'ResourcePolicy' --output text 2>/dev/null || echo "No policy found"
}

# Function to grant access
grant_access() {
    if [ -z "$PRINCIPAL" ]; then
        echo "Error: Principal (user/role) must be specified for grant action"
        exit 1
    fi

    # Create or update policy
    POLICY=$(cat <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "$PRINCIPAL"
            },
            "Action": [
                "secretsmanager:GetSecretValue"
            ],
            "Resource": "*"
        }
    ]
}
EOF
)

    aws secretsmanager put-resource-policy \
        --secret-id "$SECRET_NAME" \
        --resource-policy "$POLICY"

    echo "Access granted to $PRINCIPAL for $SECRET_NAME"
}

# Function to revoke access
revoke_access() {
    if [ -z "$PRINCIPAL" ]; then
        echo "Error: Principal (user/role) must be specified for revoke action"
        exit 1
    fi

    # Get current policy
    CURRENT_POLICY=$(aws secretsmanager get-resource-policy \
        --secret-id "$SECRET_NAME" \
        --query 'ResourcePolicy' --output text 2>/dev/null || echo "{}")

    # Remove the principal from the policy
    # This is a simplified version - in production, you'd want to use a proper JSON parser
    NEW_POLICY=$(echo "$CURRENT_POLICY" | sed "s/\"$PRINCIPAL\"//g")

    aws secretsmanager put-resource-policy \
        --secret-id "$SECRET_NAME" \
        --resource-policy "$NEW_POLICY"

    echo "Access revoked for $PRINCIPAL from $SECRET_NAME"
}

# Execute requested action
case $ACTION in
    "list")
        list_access
        ;;
    "grant")
        grant_access
        ;;
    "revoke")
        revoke_access
        ;;
esac 