provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    region  = "ap-northeast-1"
    bucket  = "gha-test-terraform-state-dev"
    key     = "gha-test-common-prod.tfstate"
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
