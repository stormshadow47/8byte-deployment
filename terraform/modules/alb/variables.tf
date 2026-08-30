variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where ALB will be deployed"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for ALB"
  type        = list(string)
}

variable "alb_security_group_id" {
  description = "Security group ID for ALB"
  type        = string
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = null
}

variable "frontend_port" {
  description = "Port exposed by the frontend container"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Port exposed by the backend container"
  type        = number
  default     = 8000
}

variable "health_check_path" {
  description = "Health check path for target groups"
  type        = string
  default     = "/health"
}
