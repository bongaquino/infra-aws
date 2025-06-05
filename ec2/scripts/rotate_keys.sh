#!/bin/bash

# Script to rotate SSH keys for different environments
# Usage: ./rotate_keys.sh <environment> [--force]

set -e

# Check if environment is provided
if [ -z "$1" ]; then
    echo "Usage: $0 <environment> [--force]"
    echo "Environments: staging, uat, prod"
    exit 1
fi

ENVIRONMENT=$1
FORCE=false

# Check if --force flag is provided
if [ "$2" == "--force" ]; then
    FORCE=true
fi

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(staging|uat|prod)$ ]]; then
    echo "Invalid environment. Must be one of: staging, uat, prod"
    exit 1
fi

# Set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYS_DIR="$SCRIPT_DIR/../keys"
BACKUP_DIR="$KEYS_DIR/backup"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Backup existing key if it exists
if [ -f "$KEYS_DIR/$ENVIRONMENT.pub" ]; then
    if [ "$FORCE" = false ]; then
        read -p "Backup existing key for $ENVIRONMENT? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled"
            exit 1
        fi
    fi
    cp "$KEYS_DIR/$ENVIRONMENT.pub" "$BACKUP_DIR/${ENVIRONMENT}_${TIMESTAMP}.pub"
    echo "Backed up existing key to $BACKUP_DIR/${ENVIRONMENT}_${TIMESTAMP}.pub"
fi

# Generate new key pair
echo "Generating new key pair for $ENVIRONMENT..."
ssh-keygen -t rsa -b 4096 -f "$KEYS_DIR/koneksi-${ENVIRONMENT}-key" -N "" -C "koneksi-${ENVIRONMENT}-key-${TIMESTAMP}"

# Move public key to the correct location
mv "$KEYS_DIR/koneksi-${ENVIRONMENT}-key.pub" "$KEYS_DIR/$ENVIRONMENT.pub"

echo "New key pair generated:"
echo "Public key: $KEYS_DIR/$ENVIRONMENT.pub"
echo "Private key: $KEYS_DIR/koneksi-${ENVIRONMENT}-key"

# Store private key in AWS Secrets Manager
echo "Storing private key in AWS Secrets Manager..."
aws secretsmanager create-secret \
    --name "koneksi/${ENVIRONMENT}/ssh-key" \
    --description "SSH private key for $ENVIRONMENT environment" \
    --secret-string "file://$KEYS_DIR/koneksi-${ENVIRONMENT}-key" \
    --tags "Key=Environment,Value=$ENVIRONMENT" "Key=Project,Value=koneksi" \
    || aws secretsmanager update-secret \
    --secret-id "koneksi/${ENVIRONMENT}/ssh-key" \
    --secret-string "file://$KEYS_DIR/koneksi-${ENVIRONMENT}-key"

# Remove private key from local filesystem
rm "$KEYS_DIR/koneksi-${ENVIRONMENT}-key"

echo "Key rotation completed successfully!"
echo "Next steps:"
echo "1. Run 'terraform apply' to update the key pair in AWS"
echo "2. Update any instances to use the new key pair"
echo "3. Document this key rotation in your change management system" 