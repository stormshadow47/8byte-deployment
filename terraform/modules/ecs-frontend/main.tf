data "aws_region" "current" {}

resource "aws_ecs_cluster" "this" {
  name = "${var.project}-${var.environment}-frontend-cluster"

  tags = {
    Name        = "${var.project}-${var.environment}-frontend-cluster"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name_prefix = "/ecs/${var.project}-${var.environment}-frontend-"
  retention_in_days = var.environment == "production" ? 30 : 7

  tags = {
    Name        = "${var.project}-${var.environment}-frontend-logs"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project}-${var.environment}-frontend-execution-role"

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
    Name        = "${var.project}-${var.environment}-frontend-execution-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project}-${var.environment}-frontend-task-role"

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
    Name        = "${var.project}-${var.environment}-frontend-task-role"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.project}-${var.environment}-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.cpu
  memory                   = var.memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "${var.project}-frontend"
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
          name  = "NEXT_PUBLIC_API_URL"
          value = var.api_url
        },
        {
          name  = "NODE_ENV"
          value = "production"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "ecs-frontend"
        }
      }
    }
  ])

  tags = {
    Name        = "${var.project}-${var.environment}-frontend-task"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.project}-${var.environment}-frontend-service"
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
    target_group_arn = var.frontend_target_group_arn
    container_name   = "${var.project}-frontend"
    container_port   = var.container_port
  }

  tags = {
    Name        = "${var.project}-${var.environment}-frontend-service"
    Environment = var.environment
    Project     = var.project
  }
}
