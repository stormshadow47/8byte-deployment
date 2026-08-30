terraform {
  backend "s3" {
    bucket         = "todoapp-production-terraform-state-677767959819"
    key            = "production/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "todoapp-production-terraform-locks"
  }
}
