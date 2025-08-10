#!/bin/bash

# =============================================================================
# ECS UAT Deployment and Verification Script
# Updates task definition to 8 vCPUs/16GB and verifies new instances use it
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="bongaquino-uat-cluster"
SERVICE_NAME="bongaquino-uat-service"
REGION="ap-southeast-1"
AWS_PROFILE="bongaquino"

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

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}🚀 ECS UAT Deployment for 2GB Files${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Check AWS profile connectivity
check_aws_profile() {
    print_status "Verifying AWS profile '$AWS_PROFILE' connectivity..."
    
    # Test AWS connectivity
    CALLER_IDENTITY=$(aws sts get-caller-identity --profile $AWS_PROFILE --output text --query 'Account' 2>/dev/null || echo "FAILED")
    
    if [ "$CALLER_IDENTITY" = "FAILED" ]; then
        print_error "❌ AWS profile '$AWS_PROFILE' not configured or accessible"
        echo "Please ensure the profile is configured:"
        echo "  aws configure --profile $AWS_PROFILE"
        exit 1
    else
        print_success "✅ AWS profile '$AWS_PROFILE' connected (Account: $CALLER_IDENTITY)"
    fi
    echo ""
}

# Check current task definition
check_current_config() {
    print_status "Checking current ECS configuration..."
    
    # Get current task definition ARN
    CURRENT_TASK_DEF=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --profile $AWS_PROFILE \
        --query 'services[0].taskDefinition' \
        --output text)
    
    # Get current task definition details
    CURRENT_CPU=$(aws ecs describe-task-definition \
        --task-definition $CURRENT_TASK_DEF \
        --region $REGION \
        --profile $AWS_PROFILE \
        --query 'taskDefinition.cpu' \
        --output text)
    
    CURRENT_MEMORY=$(aws ecs describe-task-definition \
        --task-definition $CURRENT_TASK_DEF \
        --region $REGION \
        --profile $AWS_PROFILE \
        --query 'taskDefinition.memory' \
        --output text)
    
    echo "Current Configuration:"
    echo "  Task Definition: $CURRENT_TASK_DEF"
    echo "  CPU: $CURRENT_CPU ($(($CURRENT_CPU / 1024)) vCPUs)"
    echo "  Memory: $CURRENT_MEMORY MB ($(($CURRENT_MEMORY / 1024)) GB)"
    echo ""
}

# Deploy infrastructure changes
deploy_changes() {
    print_status "Deploying ECS infrastructure changes..."
    
    # Set AWS profile for Terraform
    export AWS_PROFILE=$AWS_PROFILE
    
    # Initialize terraform and select workspace
    print_status "Initializing Terraform..."
    terraform init
    terraform workspace select uat 2>/dev/null || terraform workspace new uat
    
    # Run terraform plan first
    print_status "Running terraform plan..."
    terraform plan -out=ecs-update.tfplan
    
    echo ""
    read -p "Do you want to apply these changes? (y/N): " -n 1 -r
    echo ""
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Applying terraform changes..."
        terraform apply ecs-update.tfplan
        
        print_success "Terraform deployment completed!"
        echo ""
    else
        print_warning "Deployment cancelled"
        exit 1
    fi
}

# Wait for deployment to complete
wait_for_deployment() {
    print_status "Waiting for ECS service deployment to complete..."
    
    # Wait for service to stabilize
    aws ecs wait services-stable \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --profile $AWS_PROFILE
    
    print_success "ECS service deployment completed!"
    echo ""
}

# Verify new task definition is being used
verify_new_config() {
    print_status "Verifying new task definition configuration..."
    
    # Get new task definition ARN
    NEW_TASK_DEF=$(aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --profile $AWS_PROFILE \
        --query 'services[0].taskDefinition' \
        --output text)
    
    # Get new task definition details
    NEW_CPU=$(aws ecs describe-task-definition \
        --task-definition $NEW_TASK_DEF \
        --region $REGION \
        --profile $AWS_PROFILE \
        --query 'taskDefinition.cpu' \
        --output text)
    
    NEW_MEMORY=$(aws ecs describe-task-definition \
        --task-definition $NEW_TASK_DEF \
        --region $REGION \
        --profile $AWS_PROFILE \
        --query 'taskDefinition.memory' \
        --output text)
    
    echo "New Configuration:"
    echo "  Task Definition: $NEW_TASK_DEF"
    echo "  CPU: $NEW_CPU ($(($NEW_CPU / 1024)) vCPUs)"
    echo "  Memory: $NEW_MEMORY MB ($(($NEW_MEMORY / 1024)) GB)"
    echo ""
    
    # Verify expected values
    if [ "$NEW_CPU" = "8192" ] && [ "$NEW_MEMORY" = "16384" ]; then
        print_success "✅ Task definition correctly updated to 8 vCPUs / 16GB RAM"
    else
        print_error "❌ Task definition not updated correctly!"
        echo "Expected: 8192 CPU / 16384 Memory"
        echo "Actual: $NEW_CPU CPU / $NEW_MEMORY Memory"
        exit 1
    fi
}

# Check running tasks are using new definition
verify_running_tasks() {
    print_status "Verifying running tasks are using new definition..."
    
    # Get running tasks
    RUNNING_TASKS=$(aws ecs list-tasks \
        --cluster $CLUSTER_NAME \
        --service-name $SERVICE_NAME \
        --region $REGION \
        --profile $AWS_PROFILE \
        --desired-status RUNNING \
        --query 'taskArns' \
        --output text)
    
    if [ -z "$RUNNING_TASKS" ]; then
        print_error "No running tasks found!"
        exit 1
    fi
    
    # Check each running task
    echo "Running Tasks:"
    for task_arn in $RUNNING_TASKS; do
        TASK_DEF=$(aws ecs describe-tasks \
            --cluster $CLUSTER_NAME \
            --tasks $task_arn \
            --region $REGION \
            --profile $AWS_PROFILE \
            --query 'tasks[0].taskDefinitionArn' \
            --output text)
        
        TASK_CPU=$(aws ecs describe-task-definition \
            --task-definition $TASK_DEF \
            --region $REGION \
            --profile $AWS_PROFILE \
            --query 'taskDefinition.cpu' \
            --output text)
        
        TASK_MEMORY=$(aws ecs describe-task-definition \
            --task-definition $TASK_DEF \
            --region $REGION \
            --profile $AWS_PROFILE \
            --query 'taskDefinition.memory' \
            --output text)
        
        TASK_ID=$(echo $task_arn | cut -d'/' -f3)
        echo "  Task $TASK_ID: $TASK_CPU CPU / $TASK_MEMORY Memory ($(($TASK_CPU / 1024)) vCPUs / $(($TASK_MEMORY / 1024)) GB)"
        
        if [ "$TASK_CPU" = "8192" ] && [ "$TASK_MEMORY" = "16384" ]; then
            print_success "  ✅ Task using new definition"
        else
            print_warning "  ⚠️  Task using old definition (will be replaced)"
        fi
    done
    echo ""
}

# Test health check with new configuration
test_health_check() {
    print_status "Testing application health with new configuration..."
    
    # Get ALB endpoint
    ALB_ENDPOINT="https://server-uat.example.com"
    
    # Test health check
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$ALB_ENDPOINT/check-health" || echo "000")
    
    if [ "$HTTP_STATUS" = "200" ]; then
        print_success "✅ Health check passed (HTTP $HTTP_STATUS)"
        
        # Show response details
        HEALTH_RESPONSE=$(curl -s "$ALB_ENDPOINT/check-health")
        echo "Response: $HEALTH_RESPONSE"
    else
        print_error "❌ Health check failed (HTTP $HTTP_STATUS)"
        echo "URL: $ALB_ENDPOINT/check-health"
    fi
    echo ""
}

# Show service summary
show_summary() {
    print_status "Final ECS Service Summary:"
    
    # Service details
    aws ecs describe-services \
        --cluster $CLUSTER_NAME \
        --services $SERVICE_NAME \
        --region $REGION \
        --profile $AWS_PROFILE \
        --query 'services[0].{
            DesiredCount:desiredCount,
            RunningCount:runningCount,
            PendingCount:pendingCount,
            TaskDefinition:taskDefinition,
            Status:status
        }' \
        --output table
    
    echo ""
    print_success "🎉 ECS service updated successfully!"
    echo ""
    echo "Next Steps:"
    echo "1. 🧪 Test 2GB file uploads to verify 502 errors are resolved"
    echo "2. 📊 Monitor CPU utilization (should be <80% now)"
    echo "3. 🚀 Run stress test with multiple users"
    echo ""
    echo "Monitoring Commands:"
    echo "# Watch CPU utilization"
    echo "aws cloudwatch get-metric-statistics --namespace AWS/ECS --metric-name CPUUtilization --dimensions Name=ServiceName,Value=$SERVICE_NAME Name=ClusterName,Value=$CLUSTER_NAME --start-time \$(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) --end-time \$(date -u +%Y-%m-%dT%H:%M:%S) --period 300 --statistics Average --region $REGION --profile $AWS_PROFILE"
    echo ""
    echo "# Check service status"
    echo "aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE_NAME --region $REGION --profile $AWS_PROFILE"
}

# Main execution
main() {
    print_header
    
    # Pre-deployment checks
    check_aws_profile
    check_current_config
    
    # Deploy changes
    deploy_changes
    
    # Wait for deployment
    wait_for_deployment
    
    # Verify new configuration
    verify_new_config
    
    # Check running tasks
    verify_running_tasks
    
    # Test application
    test_health_check
    
    # Show summary
    show_summary
}

# Run main function
main "$@" 