provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    region  = "ap-northeast-1"
    bucket  = "test-274-terraform-state-dev"
    key     = "infrastructure.tfstate"
    encrypt = true
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "now" {}
locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.now.name
  stage      = "dev"
}

resource "aws_ecr_repository" "main" {
  name                 = "test-274-ecr-repository"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
}

output "repository_name" {
  value = aws_ecr_repository.main.name
}
output "repository_url" {
  value = aws_ecr_repository.main.repository_url
}
