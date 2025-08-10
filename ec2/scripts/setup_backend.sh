#!/bin/bash

# Script to set up Terraform backend infrastructure
# Usage: ./setup_backend.sh

set -e

# Variables
BUCKET_NAME="bongaquino-terraform-state"
DYNAMODB_TABLE="bongaquino-terraform-locks"
REGION="ap-southeast-1"

echo "Setting up Terraform backend infrastructure..."

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION

# Enable versioning
echo "Enabling versioning on S3 bucket"
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Enable server-side encryption
echo "Enabling server-side encryption on S3 bucket"
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

# Create DynamoDB table
echo "Creating DynamoDB table: $DYNAMODB_TABLE"
aws dynamodb create-table \
    --table-name $DYNAMODB_TABLE \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
    --region $REGION

# Add bucket policy
echo "Adding bucket policy"
aws s3api put-bucket-policy \
    --bucket $BUCKET_NAME \
    --policy '{
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "EnforceTLS",
                "Effect": "Deny",
                "Principal": "*",
                "Action": "s3:*",
                "Resource": [
                    "arn:aws:s3:::'$BUCKET_NAME'",
                    "arn:aws:s3:::'$BUCKET_NAME'/*"
                ],
                "Condition": {
                    "Bool": {
                        "aws:SecureTransport": "false"
                    }
                }
            }
        ]
    }'

echo "Backend infrastructure setup completed!"
echo "S3 bucket: $BUCKET_NAME"
echo "DynamoDB table: $DYNAMODB_TABLE" 