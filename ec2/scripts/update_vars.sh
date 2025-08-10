#!/bin/bash

# Function to get VPC ID
get_vpc_id() {
    local vpc_id=$(aws ec2 describe-vpcs \
        --filters "Name=tag:Project,Values=bongaquino" "Name=tag:Environment,Values=$1" \
        --query 'Vpcs[0].VpcId' \
        --output text)
    echo "$vpc_id"
}

# Function to get subnet ID
get_subnet_id() {
    local vpc_id=$1
    local subnet_id=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$vpc_id" "Name=tag:Name,Values=*public*" \
        --query 'Subnets[0].SubnetId' \
        --output text)
    echo "$subnet_id"
}

# Function to update terraform.tfvars
update_tfvars() {
    local env=$1
    local vpc_id=$2
    local subnet_id=$3
    
    # Create backup of original file
    cp "envs/$env/terraform.tfvars" "envs/$env/terraform.tfvars.bak"
    
    # Update the values
    sed -i '' "s/vpc_id = \".*\"/vpc_id = \"$vpc_id\"/" "envs/$env/terraform.tfvars"
    sed -i '' "s/subnet_id = \".*\"/subnet_id = \"$subnet_id\"/" "envs/$env/terraform.tfvars"
    
    echo "Updated terraform.tfvars for $env environment"
    echo "VPC ID: $vpc_id"
    echo "Subnet ID: $subnet_id"
}

# Main script
ENV=${1:-staging}  # Default to staging if no environment specified

echo "Updating variables for $ENV environment..."

# Get VPC ID
VPC_ID=$(get_vpc_id "$ENV")
if [ -z "$VPC_ID" ]; then
    echo "Error: Could not find VPC for $ENV environment"
    exit 1
fi

# Get subnet ID
SUBNET_ID=$(get_subnet_id "$VPC_ID")
if [ -z "$SUBNET_ID" ]; then
    echo "Error: Could not find subnet for VPC $VPC_ID"
    exit 1
fi

# Update terraform.tfvars
update_tfvars "$ENV" "$VPC_ID" "$SUBNET_ID"

echo "Done!" 