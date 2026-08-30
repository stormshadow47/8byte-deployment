variable "project" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (staging, production)"
  type        = string
}

variable "region" {
  description = "AWS region for resources"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "availability_zones" {
  description = "Availability zones for subnets"
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
}

variable "db_engine_version" {
  description = "PostgreSQL engine version"
  type        = string
}

variable "allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
}

variable "max_allocated_storage" {
  description = "Maximum allocated storage in GB (for autoscaling)"
  type        = number
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_username" {
  description = "Database master username"
  type        = string
  sensitive   = true
}

variable "db_password" {
  description = "Database master password"
  type        = string
  sensitive   = true
}

variable "multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
}

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
}

variable "instance_count" {
  description = "Number of RDS instances (0 for serverless, 1+ for provisioned)"
  type        = number
}

variable "deletion_protection" {
  description = "Enable deletion protection for RDS"
  type        = bool
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = null
}

variable "frontend_port" {
  description = "Frontend container port"
  type        = number
  default     = 3000
}

variable "backend_port" {
  description = "Backend container port"
  type        = number
  default     = 8000
}

variable "backend_container_image" {
  description = "Docker container image URL for backend"
  type        = string
}

variable "frontend_container_image" {
  description = "Docker container image URL for frontend"
  type        = string
}

variable "backend_cpu" {
  description = "CPU units for backend task definition"
  type        = number
}

variable "frontend_cpu" {
  description = "CPU units for frontend task definition"
  type        = number
}

variable "backend_memory" {
  description = "Memory for backend task definition in MB"
  type        = number
}

variable "frontend_memory" {
  description = "Memory for frontend task definition in MB"
  type        = number
}

variable "backend_desired_count" {
  description = "Desired number of backend tasks"
  type        = number
}

variable "frontend_desired_count" {
  description = "Desired number of frontend tasks"
  type        = number
}

variable "api_url" {
  description = "API URL for frontend (ALB DNS name) - now automatically set from ALB output"
  type        = string
  default     = null
}

variable "database_url" {
  description = "Database connection URL (from Secrets Manager) - now automatically set from RDS output"
  type        = string
  sensitive   = true
  default     = null
}

variable "cors_origins" {
  description = "CORS origins for the application - now automatically set from ALB output"
  type        = string
  default     = null
}

variable "secrets" {
  description = "Map of secret names to Secrets Manager ARNs for additional environment variables"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "health_check_path" {
  description = "Health check path for ALB"
  type        = string
  default     = "/health"
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state storage"
  type        = string
}

variable "terraform_lock_table" {
  description = "DynamoDB table for Terraform state locking"
  type        = string
}

variable "terraform_state_region" {
  description = "AWS region for Terraform state storage"
  type        = string
}
