variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
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
