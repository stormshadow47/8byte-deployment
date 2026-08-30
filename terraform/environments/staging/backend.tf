terraform {
  backend "s3" {
    bucket         = "todoapp-terraform-state-677767959819"
    key            = "staging/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "todoapp-terraform-locks"
  }
}
