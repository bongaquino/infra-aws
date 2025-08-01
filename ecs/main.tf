provider "aws" {
  region = var.region
}

# ECS Cluster
resource "aws_ecs_cluster" "main" {
  name = "${var.project}-${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name        = "${var.project}-${var.environment}-cluster"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.environment}-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-task-execution-role"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ECS Task Role
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.environment}-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "${var.project}-${var.environment}-task-role"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

data "aws_caller_identity" "current" {}

locals {
  # Use container secrets directly (they already have proper valueFrom ARNs)
  transformed_secrets = var.container_secrets
}

# ECS Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "${var.project}-${var.environment}-task"
  network_mode            = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                     = var.task_cpu
  memory                  = var.task_memory
  execution_role_arn      = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn           = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project}-${var.environment}-backend"
      image     = var.container_image
      essential = true

      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = var.container_environment

      secrets = local.transformed_secrets

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/${var.project}-${var.environment}"
          awslogs-region        = var.region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  # Allow CodePipeline to manage the container image
  # Temporarily commented out to allow MODE=release environment variable change
  # lifecycle {
  #   ignore_changes = [
  #     container_definitions
  #   ]
  # }

  tags = {
    Name        = "${var.project}-${var.environment}-task-definition"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "main" {
  name              = "/ecs/${var.project}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.project}-${var.environment}-log-group"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# ECS Service
resource "aws_ecs_service" "main" {
  name            = "${var.project}-${var.environment}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = var.service_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = "${var.project}-${var.environment}-backend"
      container_port   = var.container_port
    }
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  health_check_grace_period_seconds = var.target_group_arn != null ? 300 : null

  deployment_maximum_percent         = 200
  deployment_minimum_healthy_percent = 0

  # Ensure service waits for stable deployment
  wait_for_steady_state = true

  # Allow CodePipeline to manage the task definition - always use latest
  # Temporarily commented out to use new Terraform task definition
  # lifecycle {
  #   ignore_changes = [task_definition]
  # }

  tags = {
    Name        = "${var.project}-${var.environment}-service"
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "terraform"
  }
}

# Auto Scaling Target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = var.max_capacity
  min_capacity       = var.min_capacity
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# CPU Utilization Scaling Policy
resource "aws_appautoscaling_policy" "ecs_cpu_policy" {
  name               = "${var.project}-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.cpu_utilization_target
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

# Memory Utilization Scaling Policy
resource "aws_appautoscaling_policy" "ecs_memory_policy" {
  name               = "${var.project}-${var.environment}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.memory_utilization_target
    scale_in_cooldown  = var.scale_in_cooldown
    scale_out_cooldown = var.scale_out_cooldown
  }
}

resource "aws_iam_policy" "ssm_get_parameters" {
  name        = "${var.project}-${var.environment}-ssm-get-parameters"
  description = "Allow ECS task execution role to get SSM parameters"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/koneksi/${var.environment}/*"
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_task_execution_policy" {
  name        = "${var.project}-${var.environment}-task-execution-policy"
  description = "Additional permissions for ECS task execution role"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup",
          "logs:DescribeLogStreams"
        ],
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project}-${var.environment}:*",
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project}-${var.environment}:*:*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:DescribeImages",
          "ecr:DescribeImageScanFindings"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_get_parameters_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ssm_get_parameters.arn
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_execution_policy.arn
} 