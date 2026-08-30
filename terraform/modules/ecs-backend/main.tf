data "aws_region" "current" {}

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-backend-cluster"

  tags = {
    Name        = "${var.project}-${var.environment}-backend-cluster"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name_prefix = "/ecs/${var.project}-${var.environment}-backend-"
  retention_in_days = var.environment == "production" ? 30 : 7

  tags = {
    Name        = "${var.project}-${var.environment}-backend-logs"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.environment}-backend-execution-role"

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
    Name        = "${var.project}-${var.environment}-backend-execution-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "ecs_task_execution_secrets_policy" {
  name = "${var.project}-${var.environment}-backend-execution-secrets-policy"
  role = aws_iam_role.ecs_task_execution_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = concat(
          var.database_url != null ? ["${var.database_url}*"] : [],
          [for secret_arn in values(var.secrets) : "${secret_arn}*"]
        )
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.environment}-backend-task-role"

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
    Name        = "${var.project}-${var.environment}-backend-task-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy" "ecs_task_secrets_policy" {
  name = "${var.project}-${var.environment}-backend-secrets-policy"
  role = aws_iam_role.ecs_task_role.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = concat(
          var.database_url != null ? ["${var.database_url}*"] : [],
          [for secret_arn in values(var.secrets) : "${secret_arn}*"]
        )
      }
    ]
  })
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project}-${var.environment}-backend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project}-backend"
      image     = var.container_image
      cpu       = var.cpu
      memory    = var.memory
      essential = true
      portMappings = [
        {
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "CORS_ORIGINS"
          value = var.cors_origins
        }
      ]
      secrets = concat(
        [
          {
            name      = "DATABASE_URL"
            valueFrom = var.database_url
          }
        ],
        [
          for secret_name, secret_arn in var.secrets : {
            name      = secret_name
            valueFrom = secret_arn
          }
        ]
      )
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs-backend"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project}-${var.environment}-backend-task"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.project}-${var.environment}-backend-service"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = var.desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_security_group_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.backend_target_group_arn
    container_name   = "${var.project}-backend"
    container_port   = var.container_port
  }

  tags = {
    Name        = "${var.project}-${var.environment}-backend-service"
    Environment = var.environment
    Project     = var.project
  }
}
