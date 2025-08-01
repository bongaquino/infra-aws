#!/bin/bash

# =============================================================================
# Deploy Complete AWS Monitoring to All Environments
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENTS=("uat" "staging")
REGION="ap-southeast-1"
PROJECT="koneksi"

echo -e "${BLUE}🚀 Deploying Complete AWS Monitoring to All Environments${NC}"
echo -e "${BLUE}==========================================================${NC}"

# Function to deploy to a specific environment
deploy_environment() {
    local env=$1
    local webhook_url=$2
    
    echo -e "\n${PURPLE}🔧 Deploying to $(echo ${env} | tr '[:lower:]' '[:upper:]') environment...${NC}"
    
    # 1. Deploy Discord Notifications
    echo -e "${YELLOW}📤 Deploying Discord notifications...${NC}"
    cd "envs/$env"
    
    # Initialize Terraform if needed
    if [ ! -d ".terraform" ]; then
        terraform init
    fi
    
    # Apply with webhook URL (only for UAT, staging uses hardcoded webhook)
    if [ "$env" = "uat" ]; then
        terraform apply -auto-approve -var="discord_webhook_url=$webhook_url"
    else
        terraform apply -auto-approve
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Discord notifications deployed for $env${NC}"
    else
        echo -e "${RED}❌ Failed to deploy Discord notifications for $env${NC}"
        return 1
    fi
    
    cd ../..
    
    # 2. Deploy ALB Integration
    echo -e "${YELLOW}🔧 Deploying ALB monitoring integration...${NC}"
    cd "../../alb/envs/$env"
    
    if [ -f "discord_integration.tf" ]; then
        terraform apply -auto-approve
        echo -e "${GREEN}✅ ALB monitoring deployed for $env${NC}"
    else
        echo -e "${YELLOW}⚠️ ALB integration not found for $env${NC}"
    fi
    
    cd "../../../discord_notifications"
    
    # 3. Deploy ECS Integration  
    echo -e "${YELLOW}🐳 Deploying ECS monitoring integration...${NC}"
    cd "../../ecs/envs/$env"
    
    if [ -f "discord_monitoring.tf" ]; then
        terraform apply -auto-approve
        echo -e "${GREEN}✅ ECS monitoring deployed for $env${NC}"
    else
        echo -e "${YELLOW}⚠️ ECS integration not found for $env${NC}"
    fi
    
    cd "../../../discord_notifications"
    
    # 4. Deploy CodePipeline Integration
    echo -e "${YELLOW}🚀 Deploying CI/CD monitoring integration...${NC}"
    cd "../../codepipeline/$env"
    
    if [ -f "discord_monitoring.tf" ]; then
        terraform apply -auto-approve
        echo -e "${GREEN}✅ CI/CD monitoring deployed for $env${NC}"
    else
        echo -e "${YELLOW}⚠️ CI/CD integration not found for $env${NC}"
    fi
    
    cd "../../discord_notifications"
    
    # 5. Deploy Application Monitoring
    echo -e "${YELLOW}📊 Deploying application monitoring...${NC}"
    cd "application_monitoring"
    
    # Create environment-specific variables
    cat > "terraform.tfvars" << EOF
environment = "$env"
api_response_time_threshold = 1000
active_users_threshold = 1000  
min_daily_active_users = 10
max_daily_storage_growth_gb = 50
EOF
    
    terraform init -reconfigure
    terraform apply -auto-approve
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Application monitoring deployed for $env${NC}"
    else
        echo -e "${RED}❌ Failed to deploy application monitoring for $env${NC}"
    fi
    
    cd ..
    
    echo -e "${GREEN}🎉 $env environment deployment complete!${NC}"
}

# Function to test environment
test_environment() {
    local env=$1
    
    echo -e "\n${BLUE}🧪 Testing $env environment...${NC}"
    
    # Get SNS topic ARN
    SNS_TOPIC_ARN="arn:aws:sns:$REGION:985869370256:koneksi-$env-$env-discord-notifications"
    
    # Send test message
    aws sns publish \
        --region "$REGION" \
        --topic-arn "$SNS_TOPIC_ARN" \
        --message "{
            \"title\": \"🎯 $env Environment Test\",
            \"description\": \"Automated deployment test for $env environment\",
            \"type\": \"info\",
            \"details\": {
                \"Environment\": \"$env\",
                \"Deployment Time\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
                \"Status\": \"Deployment Complete\"
            }
        }" \
        --subject "🎯 $env Environment Test" > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Test message sent to $env Discord channel${NC}"
    else
        echo -e "${RED}❌ Failed to send test message to $env${NC}"
    fi
}

# Function to display webhook configuration instructions
show_webhook_instructions() {
    echo -e "\n${BLUE}📱 Discord Webhook Configuration${NC}"
    echo -e "${BLUE}=================================${NC}"
    echo -e "${YELLOW}You need to configure Discord webhook URLs for each environment:${NC}"
    echo -e ""
    echo -e "${GREEN}1. UAT (Already configured):${NC}"
    echo -e "   https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h"
    echo -e ""
    echo -e "${GREEN}2. Staging (Uses same webhook as UAT):${NC}"
    echo -e "   - Uses #koneksi-alerts channel (same as UAT)"
    echo -e "   - Uses same webhook URL as UAT"
    echo -e "   - Different bot name: '🟡 Koneksi Staging Bot'"
    echo -e ""
    echo -e "${YELLOW}To create webhooks:${NC}"
    echo -e "1. Go to Discord Server Settings > Integrations > Webhooks"
    echo -e "2. Click 'New Webhook'"
    echo -e "3. Choose channel and copy webhook URL"
    echo -e ""
}

# Function to deploy specific environment
deploy_specific_env() {
    local env=$1
    
    case $env in
        "uat")
            WEBHOOK_URL="https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h"
            ;;
        "staging")
            WEBHOOK_URL="https://discord.com/api/webhooks/1389071411087151207/WtPm43jiQUEzdyisH9rNcP4pt4OBX14aryy5WnfrHDzdGwHf1NmwqjD9ksrEZoPo30-h"
            echo -e "${GREEN}✅ Using same webhook as UAT for staging${NC}"
            ;;
        *)
            echo -e "${RED}Invalid environment: $env${NC}"
            return 1
            ;;
    esac
    
    if [ -z "$WEBHOOK_URL" ]; then
        echo -e "${RED}Webhook URL is required${NC}"
        return 1
    fi
    
    deploy_environment "$env" "$WEBHOOK_URL"
    test_environment "$env"
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}🎯 Deployment Options${NC}"
    echo -e "${BLUE}===================${NC}"
    echo -e "${GREEN}1.${NC} Deploy UAT only (webhook already configured)"
    echo -e "${GREEN}2.${NC} Deploy Staging only"
    echo -e "${GREEN}3.${NC} Deploy Both UAT & Staging"
    echo -e "${GREEN}5.${NC} Test Existing Environments"
    echo -e "${GREEN}6.${NC} Show webhook configuration instructions"
    echo -e "${GREEN}7.${NC} Create deployment summary"
    echo -e "${GREEN}0.${NC} Exit"
    echo -e ""
    read -p "Choose option [0-7]: " choice
}

# Handle menu choice
handle_choice() {
    case $choice in
        1)
            echo -e "${BLUE}🎯 Deploying UAT environment...${NC}"
            deploy_specific_env "uat"
            ;;
        2)
            echo -e "${BLUE}🎯 Deploying Staging environment...${NC}"
            deploy_specific_env "staging"
            ;;
        3)
            echo -e "${BLUE}🎯 Deploying Both UAT & Staging...${NC}"
            show_webhook_instructions
            echo -e "${YELLOW}Continue with both environments? (y/n):${NC}"
            read -p "" confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                for env in "${ENVIRONMENTS[@]}"; do
                    deploy_specific_env "$env"
                done
            fi
            ;;
        5)
            echo -e "${BLUE}🧪 Testing All Environments...${NC}"
            for env in "${ENVIRONMENTS[@]}"; do
                test_environment "$env"
            done
            ;;
        6)
            show_webhook_instructions
            ;;
        7)
            create_deployment_summary
            ;;
        0)
            echo -e "${GREEN}✨ Goodbye!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid choice. Please try again.${NC}"
            ;;
    esac
}

# Create deployment summary
create_deployment_summary() {
    echo -e "\n${BLUE}📊 Creating Deployment Summary...${NC}"
    
    SUMMARY_FILE="deployment_summary_$(date +%Y%m%d_%H%M%S).md"
    
    cat > "$SUMMARY_FILE" << EOF
# AWS Discord Monitoring Deployment Summary

**Deployment Date:** $(date)
**Project:** Koneksi
**Region:** ap-southeast-1

## 🌍 Environments Deployed

### UAT Environment
- **Status:** ✅ Active
- **Discord Channel:** #koneksi-alerts
- **SNS Topic:** koneksi-uat-uat-discord-notifications
- **Components:**
  - ✅ Discord Notifications
  - ✅ ALB Monitoring
  - ✅ ECS Monitoring
  - ✅ CI/CD Pipeline Monitoring
  - ✅ Security Monitoring
  - ✅ Cost Monitoring
  - ✅ Application Monitoring

### Staging Environment
- **Status:** 🔄 Ready for deployment
- **Discord Channel:** #koneksi-alerts (same as UAT)
- **Bot Name:** 🟡 Koneksi Staging Bot
- **SNS Topic:** koneksi-staging-staging-discord-notifications



## 📊 Monitoring Coverage

### Infrastructure Monitoring
- ALB error rates and latency
- ECS CPU, memory, and task health
- Application log error detection
- CloudWatch anomaly detection

### CI/CD Monitoring
- CodePipeline execution status
- CodeBuild project status
- ECR image security scans
- Deployment approval notifications

### Security Monitoring
- Root user activity detection
- Failed authentication attempts
- IAM policy changes
- Security group modifications
- GuardDuty findings

### Cost Monitoring
- Monthly budget alerts
- Cost anomaly detection
- Service-specific cost tracking
- Resource optimization alerts

### Application Monitoring
- API response time tracking
- File upload success rates
- Database connection pool monitoring
- Active user metrics
- Memory and resource usage

## 🔧 Next Steps

 1. **Complete Staging Setup:**
    - Create Discord channel for staging (#koneksi-staging-alerts)
    - Generate webhook URL for staging environment  
    - Deploy monitoring to staging environment

2. **Backend Integration:**
   - Add Go monitoring package to koneksi-backend
   - Implement custom metrics in application code
   - Configure environment-specific thresholds

3. **Team Onboarding:**
   - Train team on Discord alerts
   - Set up @role mentions for critical alerts
   - Create escalation procedures

4. **Optimization:**
   - Monitor alert volume and adjust thresholds
   - Create custom dashboards
   - Set up automated remediation for common issues

## 📞 Support

For issues or questions:
- Check CloudWatch logs: /aws/lambda/koneksi-*-discord-notifier
- Test with: \`aws sns publish --topic-arn <SNS_TOPIC_ARN> --message "test"\`
- Review Terraform state: \`terraform show\`

---

Generated by: AWS Discord Monitoring Deployment Script
EOF

    echo -e "${GREEN}✅ Summary created: $SUMMARY_FILE${NC}"
    echo -e "${YELLOW}📄 Open this file for detailed deployment information${NC}"
}

# Main execution
main() {
    echo -e "${GREEN}Welcome to AWS Discord Monitoring Deployment!${NC}"
    
    while true; do
        show_menu
        handle_choice
        echo -e "\n${YELLOW}Press Enter to continue...${NC}"
        read
    done
}

# Check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI.${NC}"
        exit 1
    fi
    
    # Check Terraform
    if ! command -v terraform &> /dev/null; then
        echo -e "${RED}❌ Terraform not found. Please install Terraform.${NC}"
        exit 1
    fi
    
    # Check AWS credentials
    if ! aws sts get-caller-identity &> /dev/null; then
        echo -e "${RED}❌ AWS credentials not configured. Please run 'aws configure'.${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}✅ All prerequisites met${NC}"
}

# Run prerequisite checks
check_prerequisites

# Run main function
main 