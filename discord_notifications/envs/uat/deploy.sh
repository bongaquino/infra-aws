#!/bin/bash

# Discord Notifications Deployment Script for UAT Environment
# Usage: ./deploy.sh [discord_webhook_url]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Discord webhook URL is provided
if [ -z "$1" ]; then
    print_error "Discord webhook URL is required!"
    echo "Usage: $0 <discord_webhook_url>"
    echo "Example: $0 https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN"
    exit 1
fi

DISCORD_WEBHOOK_URL="$1"
ENVIRONMENT="uat"
PROJECT="bongaquino"

print_status "🚀 Starting Discord Notifications deployment for $ENVIRONMENT environment..."

# Validate webhook URL format
if [[ ! "$DISCORD_WEBHOOK_URL" =~ ^https://discord.com/api/webhooks/ ]]; then
    print_error "Invalid Discord webhook URL format!"
    echo "Expected format: https://discord.com/api/webhooks/WEBHOOK_ID/WEBHOOK_TOKEN"
    exit 1
fi

print_success "✅ Discord webhook URL validated"

# Check if we're in the right directory
if [[ ! -f "main.tf" ]]; then
    print_error "main.tf not found! Please run this script from the UAT environment directory."
    exit 1
fi

# Initialize Terraform
print_status "🔧 Initializing Terraform..."
if terraform init; then
    print_success "✅ Terraform initialized successfully"
else
    print_error "❌ Terraform initialization failed"
    exit 1
fi

# Create terraform.tfvars if it doesn't exist
if [[ ! -f "terraform.tfvars" ]]; then
    print_status "📝 Creating terraform.tfvars file..."
    cp terraform.tfvars.example terraform.tfvars
    
    # Update the webhook URL in terraform.tfvars
    sed -i.bak "s|discord_webhook_url = \".*\"|discord_webhook_url = \"$DISCORD_WEBHOOK_URL\"|" terraform.tfvars
    rm terraform.tfvars.bak
    
    print_success "✅ terraform.tfvars created with your webhook URL"
else
    print_warning "⚠️  terraform.tfvars already exists. Please verify your Discord webhook URL is correct."
fi

# Plan the deployment
print_status "📋 Planning Terraform deployment..."
if terraform plan -var="discord_webhook_url=$DISCORD_WEBHOOK_URL" -out=tfplan; then
    print_success "✅ Terraform plan completed successfully"
else
    print_error "❌ Terraform plan failed"
    exit 1
fi

# Ask for confirmation
echo ""
print_warning "⚠️  Review the plan above carefully!"
read -p "Do you want to apply these changes? (yes/no): " confirm

if [[ $confirm != "yes" ]]; then
    print_status "❌ Deployment cancelled by user"
    exit 0
fi

# Apply the deployment
print_status "🚀 Applying Terraform deployment..."
if terraform apply tfplan; then
    print_success "✅ Terraform apply completed successfully"
else
    print_error "❌ Terraform apply failed"
    exit 1
fi

# Get outputs
print_status "📊 Getting deployment outputs..."
SNS_TOPIC_ARN=$(terraform output -raw sns_topic_arn 2>/dev/null || echo "N/A")
LAMBDA_FUNCTION_NAME=$(terraform output -raw lambda_function_name 2>/dev/null || echo "N/A")

# Display success message and usage instructions
echo ""
print_success "🎉 Discord Notifications deployed successfully!"
echo ""
print_status "📋 Deployment Summary:"
echo "  Environment: $ENVIRONMENT"
echo "  Project: $PROJECT"
echo "  SNS Topic ARN: $SNS_TOPIC_ARN"
echo "  Lambda Function: $LAMBDA_FUNCTION_NAME"
echo ""

print_status "🧪 Testing the deployment..."
if [[ "$SNS_TOPIC_ARN" != "N/A" ]]; then
    print_status "Sending test message to Discord..."
    
    if aws sns publish \
        --topic-arn "$SNS_TOPIC_ARN" \
        --message "🎉 Discord notifications are now active for the $ENVIRONMENT environment!" \
        --subject "Discord Notifications - Test Message" > /dev/null 2>&1; then
        print_success "✅ Test message sent successfully! Check your Discord channel."
    else
        print_warning "⚠️  Test message failed. Check your AWS credentials and permissions."
    fi
else
    print_warning "⚠️  Could not retrieve SNS topic ARN for testing."
fi

echo ""
print_status "📚 Usage Examples:"
echo ""
echo "1. Send a simple notification:"
echo "   aws sns publish --topic-arn \"$SNS_TOPIC_ARN\" --message \"Deployment completed!\" --subject \"UAT Update\""
echo ""
echo "2. Send a structured notification:"
echo "   aws sns publish --topic-arn \"$SNS_TOPIC_ARN\" --message '{\"title\":\"Database Migration\",\"description\":\"Migration completed successfully\",\"type\":\"success\"}' --subject \"DB Update\""
echo ""
echo "3. Add to CloudWatch alarms:"
echo "   alarm_actions = [\"$SNS_TOPIC_ARN\"]"
echo ""

print_status "🔍 Monitor logs at: /aws/lambda/$LAMBDA_FUNCTION_NAME"
print_success "🎯 Deployment complete! Your Discord notifications are ready to use." 