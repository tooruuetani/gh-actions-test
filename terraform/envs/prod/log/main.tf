provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    region  = "ap-northeast-1"
    bucket  = "gha-test-terraform-state-dev"
    key     = "gha-test-log-prod.tfstate"
    encrypt = true
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "now" {}
locals {
  account_id     = data.aws_caller_identity.current.account_id
  region         = data.aws_region.now.name
  stage          = "prod"
  repository_url = "082954585471.dkr.ecr.ap-northeast-1.amazonaws.com/gha-test-log-lambda"
}

resource "aws_iam_role" "main" {
  name = "gha-test-log-role-${local.stage}"
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
  ]

  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        }
      }
    ]
  })

  inline_policy {
    name = "gha-test-log-role-inline-${local.stage}"
    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogStream",
            "logs:CreateLogGroup"
          ],
          "Resource" : [
            "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.stage}-*:*"
          ],
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "logs:PutLogEvents"
          ],
          "Resource" : [
            "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.stage}-*:*"
          ],
          "Effect" : "Allow"
        },
        {
          "Action" : [
            "secretsmanager:GetSecretValue"
          ],
          "Resource" : "*",
          "Effect" : "Allow"
        }
      ]
    })
  }
}

resource "aws_lambda_function" "main" {
  for_each      = toset(["A01", "A02", "A03"])
  function_name = "gha-test-log-${local.stage}-${each.value}"
  package_type  = "Image"
  role          = aws_iam_role.main.arn
  image_uri     = "${local.repository_url}:${local.stage}"

  image_config {
    command = ["handler.lambda_handler"]
  }

  lifecycle {
    ignore_changes = [
      environment,
      image_config,
      image_uri,
      memory_size,
      tags,
      tags_all,
      timeout,
    ]
  }
}

output "lambda_name" {
  value = "gha-test-log-${local.stage}"
}
output "lambda_role_arn" {
  value = aws_iam_role.main.arn
}
output "kinesis_stream_name" {
  value = "dummy_kinesis_stream_name"
}
output "opensearch_role" {
  value = "dummy_opensearch_role"
}
output "opensearch_url" {
  value = "dummy_opensearch_url"
}
output "repository_name" {
  value = "gha-test-log-lambda"
}
output "repository_url" {
  value = local.repository_url
}
output "s3_bucket_name_tmp" {
  value = "dummy_s3_bucket_name_tmp"
}
output "s3_bucket_name_archive" {
  value = "dummy_s3_bucket_name_archive"
}
output "s3_bucket_name_failed" {
  value = "dummy_s3_bucket_name_failed"
}
