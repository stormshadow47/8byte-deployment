variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ECS will be deployed"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security group ID for ECS tasks"
  type        = string
}

variable "frontend_target_group_arn" {
  description = "ARN of the frontend ALB target group"
  type        = string
}

variable "container_image" {
  description = "Docker container image URL for frontend"
  type        = string
}

variable "container_port" {
  description = "Container port for frontend"
  type        = number
  default     = 3000
}

variable "cpu" {
  description = "CPU units for task definition"
  type        = number
  default     = 256
}

variable "memory" {
  description = "Memory for task definition in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Desired number of tasks"
  type        = number
  default     = 1
}

variable "api_url" {
  description = "API URL for the frontend"
  type        = string
}
