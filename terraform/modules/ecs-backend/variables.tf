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

variable "backend_target_group_arn" {
  description = "ARN of the backend ALB target group"
  type        = string
}

variable "container_image" {
  description = "Docker container image URL for backend"
  type        = string
}

variable "container_port" {
  description = "Container port for backend"
  type        = number
  default     = 8000
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

variable "database_url" {
  description = "Database connection URL (from Secrets Manager)"
  type        = string
  sensitive   = true
}

variable "cors_origins" {
  description = "CORS origins for the application"
  type        = string
}

variable "secrets" {
  description = "Map of secret names to Secrets Manager ARNs for additional environment variables"
  type        = map(string)
  default     = {}
  sensitive   = true
}
