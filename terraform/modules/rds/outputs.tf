output "rds_cluster_endpoint" {
  description = "RDS cluster endpoint"
  value       = aws_rds_cluster.this.endpoint
}

output "rds_cluster_port" {
  description = "RDS cluster port"
  value       = aws_rds_cluster.this.port
}

output "rds_cluster_id" {
  description = "RDS cluster identifier"
  value       = aws_rds_cluster.this.cluster_identifier
}

output "rds_cluster_arn" {
  description = "RDS cluster ARN"
  value       = aws_rds_cluster.this.arn
}

output "master_user_secret_arn" {
  description = "ARN of the RDS-managed Secrets Manager credential"
  value       = aws_rds_cluster.this.master_user_secret[0].secret_arn
}
