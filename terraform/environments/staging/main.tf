terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

module "ecr" {
  source = "../../modules/ecr"

  project_name = var.project
  environment   = var.environment
}

module "vpc" {
  source = "../../modules/vpc"

  project         = var.project
  environment     = var.environment
  region          = var.region
  vpc_cidr        = var.vpc_cidr

  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones    = var.availability_zones
}

module "security_groups" {
  source = "../../modules/security-groups"

  project         = var.project
  environment     = var.environment
  vpc_id          = module.vpc.vpc_id
  frontend_port   = var.frontend_port
  backend_port    = var.backend_port
}

module "rds" {
  source = "../../modules/rds"

  project                   = var.project
  environment               = var.environment
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  availability_zones        = module.vpc.availability_zones
  rds_security_group_id     = module.security_groups.rds_security_group_id
  db_instance_class         = var.db_instance_class
  db_engine_version         = var.db_engine_version
  db_name                   = var.db_name
  db_username               = var.db_username
  backup_retention_period   = var.backup_retention_period
  instance_count            = var.instance_count
  deletion_protection       = var.deletion_protection
}

module "alb" {
  source = "../../modules/alb"

  project               = var.project
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  alb_security_group_id = module.security_groups.alb_security_group_id
  certificate_arn       = var.certificate_arn
  frontend_port         = var.frontend_port
  backend_port          = var.backend_port
}

module "ecs_backend" {
  source = "../../modules/ecs-backend"

  project                 = var.project
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  ecs_security_group_id   = module.security_groups.backend_security_group_id
  backend_target_group_arn = module.alb.backend_target_group_arn
  container_image         = var.backend_container_image
  container_port          = var.backend_port
  cpu                     = var.backend_cpu
  memory                  = var.backend_memory
  desired_count           = var.backend_desired_count
  database_url            = var.database_url
  cors_origins            = var.cors_origins != null ? var.cors_origins : "http://${module.alb.alb_dns_name}"
  secrets                 = var.secrets
}

module "ecs_frontend" {
  source = "../../modules/ecs-frontend"

  project                 = var.project
  environment             = var.environment
  vpc_id                  = module.vpc.vpc_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  ecs_security_group_id   = module.security_groups.frontend_security_group_id
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  container_image         = var.frontend_container_image
  container_port          = var.frontend_port
  cpu                     = var.frontend_cpu
  memory                  = var.frontend_memory
  desired_count           = var.frontend_desired_count
  api_url                 = var.api_url != null ? var.api_url : "http://${module.alb.alb_dns_name}"
}
