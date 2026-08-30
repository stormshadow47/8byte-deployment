output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = module.alb.alb_dns_name
}

output "rds_cluster_endpoint" {
  description = "Database endpoint"
  value       = module.rds.rds_cluster_endpoint
  sensitive   = true
}

output "backend_ecs_cluster_id" {
  description = "ID of the backend ECS cluster"
  value       = module.ecs_backend.cluster_id
}

output "frontend_ecs_cluster_id" {
  description = "ID of the frontend ECS cluster"
  value       = module.ecs_frontend.cluster_id
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}
