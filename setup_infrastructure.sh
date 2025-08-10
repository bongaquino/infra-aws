#!/bin/bash

# List of modules to process
MODULES=("vpc" "s3" "ec2" "dynamodb" "elasticache" "iam" "route53" "amplify" "cloudfront" "acm")

# Function to check for destructive changes
check_destructive_changes() {
    local module=$1
    local env=$2
    
    echo "Checking changes in $module ($env)..."
    
    # Run terraform plan and capture output
    PLAN_OUTPUT=$(terraform plan -no-color 2>&1)
    
    # Check for destroy operations
    if echo "$PLAN_OUTPUT" | grep -q "destroy"; then
        echo "WARNING: Resources will be destroyed in $module ($env)!"
        echo "The following resources will be destroyed:"
        echo "$PLAN_OUTPUT" | grep -A 5 "destroy"
        echo
        read -p "Do you want to continue? (yes/no): " response
        if [[ "$response" != "yes" ]]; then
            echo "Operation cancelled."
            exit 1
        fi
    fi
}

# Function to setup a module
setup_module() {
    local module=$1
    echo "Setting up $module module..."
    
    # Create module directory if it doesn't exist
    mkdir -p "$module"
    
    # Create environment directories
    mkdir -p "$module/envs/staging"
    mkdir -p "$module/envs/uat"
    mkdir -p "$module/envs/prod"
    
    # Create backend.tf in module root with dynamic key
    cat > "$module/backend.tf" << EOF
terraform {
  backend "s3" {
    bucket         = "placeholder"
    key            = "$module/\${terraform.workspace}/terraform.tfstate"
    region         = "placeholder"
    encrypt        = true
    dynamodb_table = "placeholder"
  }
}
EOF
    
    # Create environment-specific backend config files (no key)
    for env in staging uat prod; do
        cat > "$module/envs/$env/backend.tf" << EOF
bucket         = "bongaquino-terraform-state"
region         = "ap-southeast-1"
encrypt        = true
dynamodb_table = "bongaquino-terraform-locks"
EOF
        
        # Create terraform.tfvars for each environment
        cat > "$module/envs/$env/terraform.tfvars" << EOF
# =============================================================================
# Environment Configuration
# =============================================================================
environment = "$env"
<<<<<<< HEAD
project     = "bongaquino"
=======
project     = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435

# =============================================================================
# Tags
# =============================================================================
tags = {
  Environment = "$env"
<<<<<<< HEAD
  Project     = "bongaquino"
=======
  Project     = "bongaquino"
>>>>>>> 15079af045cfc1027366c5a44e9882723e779435
  ManagedBy   = "terraform"
}
EOF
    done
    
    # Create workspaces
    cd "$module"
    terraform workspace new staging 2>/dev/null || true
    terraform workspace new uat 2>/dev/null || true
    terraform workspace new prod 2>/dev/null || true
    cd ..
    
    echo "Setup completed for $module module"
}

# Function to verify module setup
verify_module() {
    local module=$1
    local env=$2
    echo "Verifying $module module for $env environment..."
    
    cd "$module"
    
    # Select workspace
    terraform workspace select "$env"
    
    # Initialize with environment-specific backend config
    terraform init -backend-config="envs/$env/backend.tf" -reconfigure
    
    # Check for destructive changes before proceeding
    check_destructive_changes "$module" "$env"
    
    cd ..
    echo "Verification completed for $module module in $env environment"
}

# Main execution
echo "Starting infrastructure setup..."

# Setup each module
for module in "${MODULES[@]}"; do
    setup_module "$module"
done

echo "Module setup complete!"

# Verify setup for each module and environment
for module in "${MODULES[@]}"; do
    for env in staging uat prod; do
        verify_module "$module" "$env"
    done
done

echo "Infrastructure setup and verification complete!" 