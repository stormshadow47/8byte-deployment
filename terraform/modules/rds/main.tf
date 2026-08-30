resource "aws_db_subnet_group" "this" {
  name_prefix = "${var.project}-${var.environment}-"
  description = "Database subnet group for ${var.project} ${var.environment}"
  subnet_ids  = var.private_subnet_ids

  tags = {
    Name        = "${var.project}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_rds_cluster" "this" {
  engine                = "aurora-postgresql"
  engine_version        = var.db_engine_version
  database_name         = var.db_name
  master_username       = var.db_username
  manage_master_user_password = true
  storage_encrypted     = true
  backup_retention_period = var.backup_retention_period
  deletion_protection     = var.deletion_protection
  
  vpc_security_group_ids = [var.rds_security_group_id]
  db_subnet_group_name    = aws_db_subnet_group.this.name
  
  skip_final_snapshot      = var.environment == "staging"
  final_snapshot_identifier = var.environment == "production" ? "${var.project}-${var.environment}-final-snapshot" : null

  tags = {
    Name        = "${var.project}-${var.environment}-rds-cluster"
    Environment = var.environment
    Project     = var.project
  }
}

resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count
  
  identifier = "${var.project}-${var.environment}-rds-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = var.db_instance_class
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  
  db_subnet_group_name = aws_db_subnet_group.this.name
  
  publicly_accessible = false
  
  tags = {
    Name        = "${var.project}-${var.environment}-rds-instance-${count.index + 1}"
    Environment = var.environment
    Project     = var.project
  }
}
