import json
import urllib3
import os
import logging
from datetime import datetime
from typing import Dict, Any, Optional

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize HTTP client
http = urllib3.PoolManager()

# Constants
DISCORD_WEBHOOK_URL = os.environ.get('DISCORD_WEBHOOK_URL')
ENVIRONMENT = os.environ.get('ENVIRONMENT', 'unknown')
PROJECT = os.environ.get('PROJECT', 'AWS')
DEFAULT_USERNAME = os.environ.get('DEFAULT_USERNAME', 'AWS Notifications')
DEFAULT_AVATAR_URL = os.environ.get('DEFAULT_AVATAR_URL', '')

# Color codes for different message types - Read from environment variables
COLORS = {
    'success': int(os.environ.get('SUCCESS_COLOR', '3066993')),    # Green
    'warning': int(os.environ.get('WARNING_COLOR', '16776960')),   # Yellow  
    'error': int(os.environ.get('CRITICAL_COLOR', '15158332')),    # Red (use critical color for errors)
    'info': int(os.environ.get('DEFAULT_COLOR', '3447003')),       # Blue
    'critical': int(os.environ.get('CRITICAL_COLOR', '15158332'))  # Red
}

def lambda_handler(event, context):
    """
    Main Lambda handler function
    """
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        
        # Process each record in the event
        for record in event.get('Records', []):
            if record.get('EventSource') == 'aws:sns':
                process_sns_message(record['Sns'])
            else:
                # Handle direct invocation
                send_discord_message(event)
                
        return {
            'statusCode': 200,
            'body': json.dumps({'message': 'Notifications sent successfully'})
        }
        
    except Exception as e:
        logger.error(f"Error processing event: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({'error': str(e)})
        }

def process_sns_message(sns_message: Dict[str, Any]):
    """
    Process SNS message and extract relevant information
    """
    try:
        subject = sns_message.get('Subject', 'AWS Notification')
        message = sns_message.get('Message', '')
        timestamp = sns_message.get('Timestamp', '')
        
        # Try to parse message as JSON (for CloudWatch alarms, etc.)
        try:
            parsed_message = json.loads(message)
            discord_payload = format_structured_message(parsed_message, subject, timestamp)
            # If discord_payload is None (e.g., ECR events), don't send anything
            if discord_payload is None:
                logger.info("Skipping Discord notification (event ignored)")
                return
        except json.JSONDecodeError:
            # Handle as plain text
            discord_payload = format_plain_message(message, subject, timestamp)
            
        send_to_discord(discord_payload)
        
    except Exception as e:
        logger.error(f"Error processing SNS message: {str(e)}")
        raise

def format_structured_message(message: Dict[str, Any], subject: str, timestamp: str) -> Dict[str, Any]:
    """
    Format structured messages (like CloudWatch alarms)
    """
    # Handle CloudWatch Alarm
    if 'AlarmName' in message:
        return format_cloudwatch_alarm(message, timestamp)
    
    # Handle CodePipeline state change
    if 'source' in message and message['source'] == 'aws.codepipeline':
        return format_codepipeline_message(message, timestamp)
    
    # Handle CodeBuild state change
    if 'source' in message and message['source'] == 'aws.codebuild':
        return format_codebuild_message(message, timestamp)
    
    # Handle ECS Task State Change
    if 'source' in message and message['source'] == 'aws.ecs' and message.get('detail-type') == 'ECS Task State Change':
        return format_ecs_task_message(message, timestamp)
    
    # COMPLETELY IGNORE ECR EVENTS - DO NOT PROCESS AT ALL
    if 'source' in message and message['source'] == 'aws.ecr':
        logger.info("Ignoring ECR event per user request")
        return None

    
    # Handle custom structured message
    if 'title' in message or 'description' in message:
        return format_custom_message(message, subject, timestamp)
    
    # Default handling
    return format_plain_message(json.dumps(message, indent=2), subject, timestamp)

def format_cloudwatch_alarm(alarm: Dict[str, Any], timestamp: str) -> Dict[str, Any]:
    """
    Format CloudWatch alarm message
    """
    alarm_name = alarm.get('AlarmName', 'Unknown Alarm')
    alarm_description = alarm.get('AlarmDescription', '')
    new_state = alarm.get('NewStateValue', 'UNKNOWN')
    old_state = alarm.get('OldStateValue', 'UNKNOWN')
    reason = alarm.get('NewStateReason', '')
    
    # Determine color based on alarm state
    color = COLORS['error'] if new_state == 'ALARM' else COLORS['success'] if new_state == 'OK' else COLORS['warning']
    
    # Create status emoji
    status_emoji = '🚨' if new_state == 'ALARM' else '✅' if new_state == 'OK' else '⚠️'
    
    embed = {
        'title': f"{status_emoji} CloudWatch Alarm: {alarm_name}",
        'description': alarm_description,
        'color': color,
        'fields': [
            {
                'name': 'State Change',
                'value': f"{old_state} → {new_state}",
                'inline': True
            },
            {
                'name': 'Environment',
                'value': ENVIRONMENT.upper(),
                'inline': True
            },
            {
                'name': 'Reason',
                'value': reason,
                'inline': False
            }
        ],
        'timestamp': timestamp,
        'footer': {
            'text': f"{PROJECT} - {ENVIRONMENT}"
        }
    }
    
    return {
        'username': DEFAULT_USERNAME,
        'avatar_url': DEFAULT_AVATAR_URL,
        'embeds': [embed]
    }

def format_codepipeline_message(message: Dict[str, Any], timestamp: str) -> Dict[str, Any]:
    """
    Format CodePipeline state change message with detailed information
    """
    detail = message.get('detail', {})
    detail_type = message.get('detail-type', '')
    pipeline_name = detail.get('pipeline', 'Unknown Pipeline')
    state = detail.get('state', 'UNKNOWN')
    execution_id = detail.get('execution-id', 'N/A')
    region = message.get('region', 'ap-southeast-1')
    
    # Check if this is a stage-level event
    stage_name = detail.get('stage', None)
    action_name = detail.get('action', None)
    
    # Determine color and emoji based on state
    if state == 'SUCCEEDED':
        color = COLORS['success']
        emoji = '✅'
        description = "**Successfully completed!**"
    elif state == 'FAILED':
        color = COLORS['error']
        emoji = '❌'
        description = "**Failed!** Check logs for details."
        
        # Add detailed failure analysis for failed pipelines
        failure_reason = get_pipeline_failure_reason(detail, pipeline_name, stage_name, action_name)
        troubleshooting = get_pipeline_troubleshooting(pipeline_name, stage_name, action_name)
        
        description += f"\n\n🔍 **Failure Analysis:**\n{failure_reason}"
        description += f"\n\n🛠️ **Next Steps:**\n{troubleshooting}"
    elif state == 'STARTED':
        color = COLORS['info']
        emoji = '🚀'
        description = "**Started execution** - deploying changes..."
    elif state == 'CANCELED':
        color = COLORS['warning']
        emoji = '🛑'
        description = "**Execution canceled**"
    elif state == 'SUPERSEDED':
        color = COLORS['warning']
        emoji = '⏭️'
        description = "**Superseded** by newer execution"
    else:
        color = COLORS['warning']
        emoji = '⚠️'
        description = f"State changed to **{state}**"
    
    # Create AWS Console link
    console_url = f"https://{region}.console.aws.amazon.com/codesuite/codepipeline/pipelines/{pipeline_name}/view"
    if execution_id != 'N/A':
        console_url += f"?region={region}#execution-id:{execution_id}"
    
    # Determine title and context based on event type
    if 'Stage Execution' in detail_type and stage_name:
        title = f"{emoji} Pipeline Stage: {stage_name}"
        context = f"Stage **{stage_name}** in pipeline `{pipeline_name}`"
        if action_name:
            context += f" (Action: {action_name})"
    else:
        title = f"{emoji} Pipeline: {pipeline_name}"
        context = f"Pipeline `{pipeline_name}`"
    
    # Build fields with comprehensive information
    fields = [
        {
            'name': '📊 Current State',
            'value': f"**{state}**",
            'inline': True
        },
        {
            'name': '🌍 Environment',
            'value': ENVIRONMENT.upper(),
            'inline': True
        },
        {
            'name': '🆔 Execution ID',
            'value': f"`{execution_id[:8]}...`" if len(execution_id) > 8 else f"`{execution_id}`",
            'inline': True
        }
    ]
    
    # Add stage-specific information
    if stage_name:
        fields.append({
            'name': '🏗️ Stage',
            'value': f"**{stage_name}**",
            'inline': True
        })
    
    if action_name:
        fields.append({
            'name': '⚡ Action',
            'value': f"**{action_name}**",
            'inline': True
        })
    
    # Add helpful context based on pipeline name
    pipeline_info = get_pipeline_context(pipeline_name)
    if pipeline_info:
        fields.append({
            'name': '📋 Pipeline Info',
            'value': pipeline_info,
            'inline': False
        })
    
    # Add quick action buttons/links
    fields.append({
        'name': '🔗 Quick Actions',
        'value': f"[📱 View in Console]({console_url}) | [📊 CloudWatch Logs](https://{region}.console.aws.amazon.com/cloudwatch/home?region={region}#logsV2:log-groups)",
        'inline': False
    })
    
    embed = {
        'title': title,
        'description': f"{context}\n{description}",
        'color': color,
        'fields': fields,
        'timestamp': timestamp,
        'footer': {
            'text': f"{PROJECT} - {ENVIRONMENT} • CodePipeline"
        }
    }
    
    return {
        'username': DEFAULT_USERNAME,
        'avatar_url': DEFAULT_AVATAR_URL,
        'embeds': [embed]
    }

def get_pipeline_context(pipeline_name: str) -> str:
    """
    Get contextual information about what a pipeline does
    """
    pipeline_contexts = {
        'bongaquino-staging-backend-pipeline': '🖥️ **Backend API Deployment** - Deploys Go backend to staging ECS cluster',
        'bongaquino-uat-backend-pipeline': '🖥️ **Backend API Deployment** - Deploys Go backend to UAT ECS cluster',
        'bongaquino-staging-deploy-pipeline': '🚀 **Staging Deployment** - ECS deployment pipeline for staging environment',
        'bongaquino-uat-deploy-pipeline': '🚀 **UAT Deployment** - ECS deployment pipeline for UAT environment'
    }
    
    return pipeline_contexts.get(pipeline_name, '🔧 **Deployment Pipeline** - Application deployment automation')

def format_codebuild_message(message: Dict[str, Any], timestamp: str) -> Dict[str, Any]:
    """
    Format CodeBuild state change message with detailed information
    """
    detail = message.get('detail', {})
    project_name = detail.get('project-name', 'Unknown Project')
    build_status = detail.get('build-status', 'UNKNOWN')
    build_id = detail.get('build-id', 'N/A')
    region = message.get('region', 'ap-southeast-1')
    
    # Extract build number from build ID for display
    build_number = build_id.split(':')[-1] if ':' in build_id else build_id
    short_build_id = build_number[:8] + '...' if len(build_number) > 8 else build_number
    
    # Determine color and emoji based on build status
    if build_status == 'SUCCEEDED':
        color = COLORS['success']
        emoji = '✅'
        description = "**Build completed successfully!**"
    elif build_status == 'FAILED':
        color = COLORS['error']
        emoji = '❌'
        description = "**Build failed!** Check build logs for details."
        
        # Add detailed failure analysis for failed builds
        failure_reason = get_codebuild_failure_reason(detail, project_name)
        troubleshooting = get_codebuild_troubleshooting(project_name)
        
        description += f"\n\n🔍 **Failure Analysis:**\n{failure_reason}"
        description += f"\n\n🛠️ **Next Steps:**\n{troubleshooting}"
    elif build_status == 'IN_PROGRESS':
        color = COLORS['info']
        emoji = '🔄'
        description = "**Build in progress** - compiling and testing..."
    elif build_status == 'STOPPED':
        color = COLORS['warning']
        emoji = '🛑'
        description = "**Build stopped**"
    elif build_status == 'TIMED_OUT':
        color = COLORS['error']
        emoji = '⏰'
        description = "**Build timed out!**"
    else:
        color = COLORS['warning']
        emoji = '⚠️'
        description = f"Build status: **{build_status}**"
    
    # Create AWS Console links
    console_url = f"https://{region}.console.aws.amazon.com/codesuite/codebuild/projects/{project_name}/build/{build_id}/"
    logs_url = f"https://{region}.console.aws.amazon.com/cloudwatch/home?region={region}#logsV2:log-groups/log-group/$252Faws$252Fcodebuild$252F{project_name}"
    
    # Get build context
    build_info = get_build_context(project_name)
    
    # Build fields with comprehensive information
    fields = [
        {
            'name': '📊 Build Status',
            'value': f"**{build_status}**",
            'inline': True
        },
        {
            'name': '🌍 Environment',
            'value': ENVIRONMENT.upper(),
            'inline': True
        },
        {
            'name': '🆔 Build ID',
            'value': f"`{short_build_id}`",
            'inline': True
        }
    ]
    
    # Add build context information
    if build_info:
        fields.append({
            'name': '📋 Build Info',
            'value': build_info,
            'inline': False
        })
    
    # Add quick action links
    fields.append({
        'name': '🔗 Quick Actions',
        'value': f"[📱 View Build Details]({console_url}) | [📊 Build Logs]({logs_url})",
        'inline': False
    })
    
    embed = {
        'title': f"{emoji} Build: {project_name}",
        'description': f"CodeBuild project `{project_name}`\n{description}",
        'color': color,
        'fields': fields,
        'timestamp': timestamp,
        'footer': {
            'text': f"{PROJECT} - {ENVIRONMENT} • CodeBuild"
        }
    }
    
    return {
        'username': DEFAULT_USERNAME,
        'avatar_url': DEFAULT_AVATAR_URL,
        'embeds': [embed]
    }

def get_build_context(project_name: str) -> str:
    """
    Get contextual information about what a build project does
    """
    build_contexts = {
        'bongaquino-staging-backend-build': '🏗️ **Backend Build** - Compiles Go backend and pushes to ECR for staging',
        'bongaquino-uat-backend-build': '🏗️ **Backend Build** - Compiles Go backend and pushes to ECR for UAT',
        'bongaquino-staging-deploy': '🚀 **Staging Build** - Builds and deploys to staging environment',
        'bongaquino-uat-deploy': '🚀 **UAT Build** - Builds and deploys to UAT environment'
    }
    
    return build_contexts.get(project_name, '🔧 **Build Project** - Compiles and packages application code')

def get_pipeline_failure_reason(detail: Dict[str, Any], pipeline_name: str, stage_name: str, action_name: str) -> str:
    """
    Analyze bongaquino CodePipeline failure and provide detailed reason
    """
    # Try to extract failure details from the event
    failure_details = detail.get('action-execution-result', {})
    error_code = failure_details.get('errorCode', '')
    error_message = failure_details.get('errorMessage', '')
    
    # Extract additional error details from external execution
    external_execution = failure_details.get('externalExecutionSummary', '')
    external_execution_id = failure_details.get('externalExecutionId', '')
    
    # Build the error message with actual details
    error_details = ""
    if error_message:
        error_details += f"\n📋 **Error Message:** `{error_message}`"
    if error_code:
        error_details += f"\n🔍 **Error Code:** `{error_code}`"
    if external_execution:
        error_details += f"\n📄 **Summary:** {external_execution}"
    if external_execution_id:
        error_details += f"\n🆔 **Execution ID:** `{external_execution_id}`"
    
    # Determine base analysis
    base_analysis = ""
    if 'CodeBuild' in action_name:
        if 'BUILD_FAILED' in error_code or 'build failed' in error_message.lower():
            base_analysis = "❌ **Build Failed**: The CodeBuild project failed to compile or execute. Check build logs for Go compilation errors, dependency issues, or test failures."
        elif 'TIMEOUT' in error_code:
            base_analysis = "⏱️ **Build Timeout**: The build exceeded the maximum allowed time. Consider optimizing Go build steps or increasing timeout limits."
        elif 'CLIENT_ERROR' in error_code:
            base_analysis = "🔧 **Configuration Error**: Build configuration issue detected. Check buildspec.yml, environment variables, or IAM permissions."
        elif 'DOCKER' in error_code or 'docker' in error_message.lower():
            base_analysis = "🐳 **Docker Error**: Docker build or ECR push failed. Check Dockerfile syntax, base image availability, or ECR permissions."
    
    elif 'Deploy' in stage_name or 'Deploy' in action_name:
        if 'INSUFFICIENT_PERMISSIONS' in error_code:
            base_analysis = "🔐 **Permission Denied**: IAM role lacks required permissions for ECS deployment. Check ECS, ECR, or service-specific permissions."
        elif 'SERVICE_NOT_FOUND' in error_code:
            base_analysis = "🖥️ **Service Not Found**: ECS service or cluster is unavailable. Verify ECS cluster status and service configuration."
        elif 'TASK_DEFINITION_NOT_FOUND' in error_code:
            base_analysis = "📦 **Task Definition Missing**: ECS task definition not found or invalid. Check task definition configuration and registration."
        elif 'DEPLOYMENT_FAILED' in error_code:
            base_analysis = "🚀 **Deployment Failed**: ECS service deployment failed. Check service logs, health checks, and resource allocation."
    
    elif 'Source' in stage_name:
        if 'GITHUB' in error_code or 'repository' in error_message.lower():
            base_analysis = "📁 **Source Error**: Cannot access GitHub repository. Check webhook configuration, branch existence, or repository permissions."
    
    # Fallback if no specific pattern matched
    if not base_analysis:
        if error_message:
            base_analysis = f"⚠️ **Pipeline Error**: {error_message[:200]}{'...' if len(error_message) > 200 else ''}"
        elif error_code:
            base_analysis = f"🔍 **Error Code**: {error_code}. Check AWS console for detailed error information."
        else:
            base_analysis = f"❌ **Pipeline Failed**: {stage_name} stage failed. Check the pipeline execution details for specific error information."
    
    # Combine base analysis with actual error details
    return base_analysis + error_details

def get_pipeline_troubleshooting(pipeline_name: str, stage_name: str, action_name: str) -> str:
    """
    Provide troubleshooting recommendations for bongaquino pipeline failures
    """
    # Project-specific troubleshooting for bongaquino
    if 'backend' in pipeline_name:
        if 'Deploy' in stage_name:
            return """• Check ECS service health and task status in AWS console
• Verify task definition has correct Go app configuration
• Ensure environment variables are properly set for Go app
• Check ECS service logs for Go application startup errors
• Verify ECR image was pushed successfully and is accessible"""
        elif 'CodeBuild' in action_name:
            return """• Review build logs for Go compilation errors (go build, go mod)
• Check if Go dependencies can be downloaded (go mod download)
• Verify Dockerfile builds Go binary correctly
• Ensure ECR repository permissions allow push
• Check if Go version in buildspec.yml matches project requirements"""
    
    elif 'staging' in pipeline_name or 'uat' in pipeline_name:
        if 'Deploy' in stage_name:
            return """• Verify ECS cluster has sufficient capacity for deployment
• Check if new task definition can start successfully
• Review ALB health check configuration and endpoints
• Ensure security groups allow traffic to ECS tasks
• Check if database connections are properly configured"""
        elif 'CodeBuild' in action_name:
            return """• Check Go module dependencies and version compatibility
• Verify Docker base image (golang:alpine) is available
• Review ECR authentication and push permissions
• Ensure buildspec.yml has correct Go build commands
• Check if tests pass locally before pushing"""
    
    # Generic troubleshooting steps for bongaquino
    return """• Check CloudWatch logs for detailed error messages
• Verify IAM roles have required ECS and ECR permissions
• Review recent code changes that might have caused the failure
• Test Go application locally with same configuration
• Check if ECS service can pull the latest ECR image
• Contact the development team if issue persists"""

def get_codebuild_failure_reason(detail: Dict[str, Any], project_name: str) -> str:
    """
    Analyze bongaquino CodeBuild failure and provide detailed reason
    """
    # Extract build phases to identify where failure occurred
    build_complete_detail = detail.get('additional-information', {})
    phases = build_complete_detail.get('phases', [])
    
    # Extract actual error message and log details
    current_phase = detail.get('current-phase', '')
    current_phase_context = detail.get('current-phase-context', '')
    build_id = detail.get('build-id', '')
    
    # Look for phase-specific error messages
    failed_phase = None
    phase_error_message = ""
    for phase in phases:
        if phase.get('phase-status') == 'FAILED':
            failed_phase = phase.get('phase-type')
            # Try to extract context or error details from the phase
            phase_contexts = phase.get('contexts', [])
            if phase_contexts:
                phase_error_message = phase_contexts[0].get('message', '')
            break
    
    # Build error details section
    error_details = ""
    if current_phase:
        error_details += f"\n📍 **Failed Phase:** `{current_phase}`"
    if current_phase_context:
        error_details += f"\n📝 **Phase Context:** {current_phase_context}"
    if phase_error_message:
        error_details += f"\n⚠️ **Phase Error:** `{phase_error_message}`"
    if build_id:
        short_build_id = build_id.split(':')[-1][:12] if ':' in build_id else build_id[:12]
        error_details += f"\n🆔 **Build ID:** `{short_build_id}...`"
    
    # Determine base analysis
    base_analysis = ""
    if failed_phase:
        if failed_phase == 'SUBMITTED':
            base_analysis = "🚀 **Submission Failed**: Build could not be queued. Check service limits or IAM permissions."
        elif failed_phase == 'PROVISIONING':
            base_analysis = "⚙️ **Provisioning Failed**: Could not start build environment. Check compute type availability or VPC configuration."
        elif failed_phase == 'DOWNLOAD_SOURCE':
            base_analysis = "📥 **Source Download Failed**: Cannot access GitHub repository. Verify GitHub permissions or webhook configuration."
        elif failed_phase == 'INSTALL':
            base_analysis = "📦 **Install Phase Failed**: Dependency installation failed. Check go.mod, Docker base image, or system dependencies."
        elif failed_phase == 'PRE_BUILD':
            base_analysis = "🔧 **Pre-build Failed**: Pre-build commands failed. Review Docker login, Go module downloads, or configuration scripts."
        elif failed_phase == 'BUILD':
            base_analysis = "🔨 **Build Phase Failed**: Go compilation or Docker build failed. Check Go syntax errors, dependency issues, or Dockerfile problems."
        elif failed_phase == 'POST_BUILD':
            base_analysis = "📋 **Post-build Failed**: ECR push or cleanup failed. Review ECR authentication, image tagging, or post-build scripts."
        elif failed_phase == 'UPLOAD_ARTIFACTS':
            base_analysis = "📤 **Artifact Upload Failed**: Cannot upload build artifacts. Check S3 permissions or artifact paths."
        elif failed_phase == 'FINALIZING':
            base_analysis = "🏁 **Finalization Failed**: Build cleanup failed. Usually indicates resource cleanup issues."
    
    # Fallback for unknown failures
    if not base_analysis:
        base_analysis = "❌ **Build Failed**: Check CloudWatch logs for detailed Go compilation errors, Docker build issues, or ECR push failures."
    
    # Combine base analysis with actual error details
    return base_analysis + error_details

def get_codebuild_troubleshooting(project_name: str) -> str:
    """
    Provide troubleshooting recommendations for bongaquino CodeBuild failures
    """
    # Project-specific troubleshooting for bongaquino
    if 'backend' in project_name:
        return """• Check Go version compatibility (ensure correct version in buildspec.yml)
• Verify go.mod and go.sum files are up to date (go mod tidy)
• Review Go compilation errors and dependency issues
• Ensure Docker build succeeds with Go binary compilation
• Check ECR authentication and repository permissions
• Verify environment variables for Go application are set correctly"""
    
    elif 'staging' in project_name or 'uat' in project_name:
        return """• Review ECS task definition and service configuration
• Check if Go application builds and runs locally
• Verify Docker image tags and ECR repository access
• Ensure ALB and security group configurations are correct
• Check database connection strings and credentials
• Verify all required environment variables are configured"""
    
    # Generic troubleshooting for bongaquino
    return """• Review CloudWatch logs for specific Go compilation errors
• Check buildspec.yml syntax and Go build commands
• Verify IAM service role has required ECR and ECS permissions
• Test Go build commands locally in similar environment
• Check if recent Go dependency updates broke the build
• Ensure build environment has sufficient resources for Go compilation
• Verify Docker base image (golang:alpine) is accessible"""

def format_ecs_task_message(message: Dict[str, Any], timestamp: str) -> Dict[str, Any]:
    """
    Format ECS Task State Change message with task definition details
    """
    detail = message.get('detail', {})
    last_status = detail.get('lastStatus', 'UNKNOWN')
    desired_status = detail.get('desiredStatus', 'UNKNOWN')
    task_arn = detail.get('taskArn', 'N/A')
    task_definition_arn = detail.get('taskDefinitionArn', 'N/A')
    cluster_arn = detail.get('clusterArn', 'N/A')
    stopped_reason = detail.get('stoppedReason', '')
    stopped_at = detail.get('stoppedAt', '')
    started_at = detail.get('startedAt', '')
    region = message.get('region', 'ap-southeast-1')
    
    # Extract useful info from ARNs
    task_id = task_arn.split('/')[-1][:12] if '/' in task_arn else 'N/A'
    cluster_name = cluster_arn.split('/')[-1] if '/' in cluster_arn else 'N/A'
    
    # Extract task definition info
    if task_definition_arn != 'N/A':
        td_parts = task_definition_arn.split('/')[-1].split(':')
        td_family = td_parts[0] if td_parts else 'N/A'
        td_revision = td_parts[1] if len(td_parts) > 1 else 'N/A'
    else:
        td_family = 'N/A'
        td_revision = 'N/A'
    
    # Determine color and emoji based on task status
    if last_status == 'RUNNING':
        color = COLORS['success']
        emoji = '🟢'
        description = f"**Task started successfully!**"
        status_detail = f"Task is now **{last_status}**"
    elif last_status == 'STOPPED':
        color = COLORS['error'] if desired_status == 'RUNNING' else COLORS['warning']
        emoji = '🛑'
        description = f"**Task stopped**"
        status_detail = f"Task **{last_status}** (desired: {desired_status})"
    elif last_status == 'PENDING':
        color = COLORS['info']
        emoji = '🔄'
        description = f"**Task starting up**"
        status_detail = f"Task **{last_status}** (desired: {desired_status})"
    else:
        color = COLORS['warning']
        emoji = '⚠️'
        description = f"**Task state changed**"
        status_detail = f"Task **{last_status}** (desired: {desired_status})"
    
    # Create console links
    console_url = f"https://{region}.console.aws.amazon.com/ecs/v2/clusters/{cluster_name}/tasks/{task_id.split('-')[0]}/details"
    cluster_url = f"https://{region}.console.aws.amazon.com/ecs/v2/clusters/{cluster_name}/services"
    
    # Build fields
    fields = [
        {
            'name': '📊 Current Status',
            'value': status_detail,
            'inline': True
        },
        {
            'name': '🌍 Environment',
            'value': ENVIRONMENT.upper(),
            'inline': True
        },
        {
            'name': '🆔 Task ID',
            'value': f"`{task_id}`",
            'inline': True
        },
        {
            'name': '📋 Task Definition',
            'value': f"**{td_family}** (revision: `{td_revision}`)",
            'inline': True
        },
        {
            'name': '🏠 Cluster',
            'value': f"`{cluster_name}`",
            'inline': True
        }
    ]
    
    # Add timing information
    if last_status == 'STOPPED' and stopped_at:
        fields.append({
            'name': '⏰ Stopped At',
            'value': stopped_at,
            'inline': True
        })
    elif last_status == 'RUNNING' and started_at:
        fields.append({
            'name': '⏰ Started At', 
            'value': started_at,
            'inline': True
        })
    
    # Add stopped reason if available
    if stopped_reason:
        fields.append({
            'name': '📝 Reason',
            'value': stopped_reason,
            'inline': False
        })
    
    # Add console links
    fields.append({
        'name': '🔗 Quick Actions',
        'value': f"[📱 View Task Details]({console_url}) | [🏠 View Cluster]({cluster_url})",
        'inline': False
    })
    
    embed = {
        'title': f"{emoji} ECS Task State Change",
        'description': f"ECS task `{task_id}` in cluster `{cluster_name}`\n{description}",
        'color': color,
        'fields': fields,
        'timestamp': timestamp,
        'footer': {
            'text': f"{PROJECT} - {ENVIRONMENT} • ECS"
        }
    }
    
    return {
        'username': DEFAULT_USERNAME,
        'avatar_url': DEFAULT_AVATAR_URL,
        'embeds': [embed]
    }

def format_ecr_scan_message(message: Dict[str, Any], timestamp: str) -> Dict[str, Any]:
    """
    Format ECR Image Scan result message
    """
    detail = message.get('detail', {})
    repository_name = detail.get('repository-name', 'Unknown Repository')
    scan_status = detail.get('scan-status', 'UNKNOWN')
    finding_counts = detail.get('finding-severity-counts', {})
    image_digest = detail.get('image-digest', '')
    image_tags = detail.get('image-tags', [])
    
    # Determine color and emoji based on scan results
    critical_count = finding_counts.get('CRITICAL', 0)
    high_count = finding_counts.get('HIGH', 0)
    medium_count = finding_counts.get('MEDIUM', 0)
    low_count = finding_counts.get('LOW', 0)
    
    total_findings = critical_count + high_count + medium_count + low_count
    
    if scan_status == 'COMPLETE':
        if critical_count > 0:
            color = COLORS['critical']  # Red
            emoji = '🚨'
            status_text = 'Critical Vulnerabilities Found'
        elif high_count > 0:
            color = COLORS['error']  # Red
            emoji = '⚠️'
            status_text = 'High Vulnerabilities Found'
        elif medium_count > 0:
            color = COLORS['warning']  # Yellow
            emoji = '⚠️'
            status_text = 'Medium Vulnerabilities Found'
        elif low_count > 0:
            color = COLORS['info']  # Blue
            emoji = '🔍'
            status_text = 'Low Vulnerabilities Found'
        else:
            color = COLORS['success']  # Green
            emoji = '✅'
            status_text = 'No Vulnerabilities Found'
    else:
        color = COLORS['warning']
        emoji = '⏳'
        status_text = f'Scan Status: {scan_status}'
    
    # Format image tags for display
    tags_display = ', '.join(image_tags) if image_tags else 'latest'
    if len(tags_display) > 100:
        tags_display = tags_display[:97] + '...'
    
    # Short digest for display
    short_digest = image_digest[-12:] if image_digest else 'N/A'
    
    embed = {
        'title': f"{emoji} ECR Security Scan: {repository_name}",
        'description': f"**{status_text}**\n\nImage scan completed for repository `{repository_name}`",
        'color': color,
        'fields': [
            {
                'name': '🏷️ Image Tags',
                'value': f"`{tags_display}`",
                'inline': True
            },
            {
                'name': '📋 Image Digest',
                'value': f"`...{short_digest}`",
                'inline': True
            },
            {
                'name': '📊 Scan Status',
                'value': scan_status,
                'inline': True
            }
        ],
        'timestamp': timestamp,
        'footer': {
            'text': f"{PROJECT} - {ENVIRONMENT} • ECR Scan"
        }
    }
    
    # Add vulnerability summary if there are findings
    if total_findings > 0:
        vulnerability_summary = []
        if critical_count > 0:
            vulnerability_summary.append(f"🚨 **Critical**: {critical_count}")
        if high_count > 0:
            vulnerability_summary.append(f"⚠️ **High**: {high_count}")
        if medium_count > 0:
            vulnerability_summary.append(f"🔶 **Medium**: {medium_count}")
        if low_count > 0:
            vulnerability_summary.append(f"🔷 **Low**: {low_count}")
        
        embed['fields'].append({
            'name': '🛡️ Vulnerability Summary',
            'value': '\n'.join(vulnerability_summary),
            'inline': False
        })
        
        embed['fields'].append({
            'name': '📈 Total Findings',
            'value': f"**{total_findings}** vulnerabilities detected",
            'inline': True
        })
    else:
        embed['fields'].append({
            'name': '🛡️ Security Status',
            'value': '✅ **Clean** - No vulnerabilities detected',
            'inline': False
        })
    
    return {
        'username': DEFAULT_USERNAME,
        'avatar_url': DEFAULT_AVATAR_URL,
        'embeds': [embed]
    }

def format_custom_message(message: Dict[str, Any], subject: str, timestamp: str) -> Dict[str, Any]:
    """
    Format custom structured message
    """
    title = message.get('title', subject)
    description = message.get('description', message.get('message', ''))
    color_type = message.get('type', 'info')
    color = COLORS.get(color_type, COLORS['info'])
    
    # Debug logging to help troubleshoot color issues
    logger.info(f"DEBUG: color_type={color_type}, color={color}, COLORS={COLORS}")
    
    # Add emoji based on type
    emoji_map = {
        'success': '✅',
        'error': '❌',
        'warning': '⚠️',
        'info': 'ℹ️',
        'critical': '🚨'
    }
    emoji = emoji_map.get(color_type, 'ℹ️')
    
    embed = {
        'title': f"{emoji} {title}",
        'description': description,
        'color': color,
        'fields': [
            {
                'name': 'Environment',
                'value': ENVIRONMENT.upper(),
                'inline': True
            }
        ],
        'timestamp': timestamp,
        'footer': {
            'text': f"{PROJECT} - {ENVIRONMENT}"
        }
    }
    
    # Process details field if present
    if 'details' in message and isinstance(message['details'], dict):
        details = message['details']
        
        # Add each detail as a separate field
        for key, value in details.items():
            if isinstance(value, (list, dict)):
                # Format complex values nicely
                if isinstance(value, list):
                    formatted_value = '\n'.join([f"• {item}" for item in value])
                else:
                    formatted_value = '\n'.join([f"**{k}**: {v}" for k, v in value.items()])
            else:
                formatted_value = str(value)
            
            # Limit field value length (Discord limit is 1024 characters per field)
            if len(formatted_value) > 1020:
                formatted_value = formatted_value[:1020] + "..."
            
            embed['fields'].append({
                'name': key.replace('_', ' ').title(),
                'value': formatted_value,
                'inline': True if len(formatted_value) < 50 else False
            })
    
    # Add custom fields if provided (and not already processed as details)
    if 'fields' in message:
        embed['fields'].extend(message['fields'])
    
    return {
        'username': DEFAULT_USERNAME,
        'avatar_url': DEFAULT_AVATAR_URL,
        'embeds': [embed]
    }

def format_plain_message(message: str, subject: str, timestamp: str) -> Dict[str, Any]:
    """
    Format plain text message
    """
    # Try to detect if this is actually JSON that failed to parse properly
    if message.strip().startswith('{') and message.strip().endswith('}'):
        try:
            # Try to parse and format nicely
            parsed = json.loads(message)
            if isinstance(parsed, dict):
                # If it has typical structured message fields, format as custom message
                if any(key in parsed for key in ['title', 'description', 'details']):
                    return format_custom_message(parsed, subject, timestamp)
        except json.JSONDecodeError:
            pass  # Continue with plain formatting
    
    # Clean up the message for better display
    clean_message = message
    if len(clean_message) > 2000:  # Discord description limit
        clean_message = clean_message[:1997] + "..."
    
    embed = {
        'title': f"📋 {subject}",
        'description': clean_message,
        'color': COLORS['info'],
        'fields': [
            {
                'name': 'Environment',
                'value': ENVIRONMENT.upper(),
                'inline': True
            }
        ],
        'timestamp': timestamp,
        'footer': {
            'text': f"{PROJECT} - {ENVIRONMENT}"
        }
    }
    
    return {
        'username': DEFAULT_USERNAME,
        'avatar_url': DEFAULT_AVATAR_URL,
        'embeds': [embed]
    }

def send_discord_message(message: Dict[str, Any]):
    """
    Send message directly (for direct Lambda invocation)
    """
    timestamp = datetime.utcnow().isoformat()
    
    if isinstance(message, str):
        discord_payload = format_plain_message(message, "Direct Notification", timestamp)
    else:
        discord_payload = format_custom_message(message, "Direct Notification", timestamp)
    
    send_to_discord(discord_payload)

def send_to_discord(payload: Dict[str, Any]):
    """
    Send payload to Discord webhook
    """
    if not DISCORD_WEBHOOK_URL:
        logger.error("Discord webhook URL not configured")
        raise ValueError("Discord webhook URL not configured")
    
    try:
        encoded_payload = json.dumps(payload).encode('utf-8')
        
        response = http.request(
            'POST',
            DISCORD_WEBHOOK_URL,
            body=encoded_payload,
            headers={'Content-Type': 'application/json'}
        )
        
        if response.status == 200 or response.status == 204:
            logger.info("Message sent to Discord successfully")
        else:
            logger.error(f"Failed to send message to Discord. Status: {response.status}, Response: {response.data}")
            raise Exception(f"Discord webhook returned status {response.status}")
            
    except Exception as e:
        logger.error(f"Error sending message to Discord: {str(e)}")
        raise 