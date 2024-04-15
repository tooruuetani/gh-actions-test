provider "aws" {
  region = "ap-northeast-1"
}

terraform {
  backend "s3" {
    region  = "ap-northeast-1"
    bucket  = "gha-test-terraform-state-dev"
    key     = "gha-test-account-stg.tfstate"
    encrypt = true
  }
}

data "aws_caller_identity" "current" {}
data "aws_region" "now" {}
locals {
  account_id     = data.aws_caller_identity.current.account_id
  region         = data.aws_region.now.name
  stage          = "stg"
  oai_id         = aws_cloudfront_origin_access_identity.main.id
  oai_path       = aws_cloudfront_origin_access_identity.main.cloudfront_access_identity_path
  repository_url = "082954585471.dkr.ecr.ap-northeast-1.amazonaws.com/gha-test-account-lambda"
}

resource "aws_s3_bucket" "main" {
  bucket = "cloudfornt-origin-for-gha-test-${local.stage}"
}

resource "aws_s3_bucket_ownership_controls" "main" {
  bucket = aws_s3_bucket.main.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id
  policy = jsonencode({
    "Version" : "2008-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::cloudfront:user/CloudFront Origin Access Identity ${local.oai_id}"
        },
        "Action" : "s3:GetObject",
        "Resource" : "arn:aws:s3:::${aws_s3_bucket.main.bucket}/*"
      }
    ]
  })
}

resource "aws_cloudfront_distribution" "main" {
  comment = "[${local.stage}]Frontend for gha-test"
  custom_error_response {
    error_caching_min_ttl = "300"
    error_code            = "403"
    response_code         = "200"
    response_page_path    = "/index.html"
  }

  default_cache_behavior {
    allowed_methods = ["GET", "HEAD"]
    cached_methods  = ["GET", "HEAD"]
    forwarded_values {
      cookies {
        forward = "none"
      }
      query_string = false
    }
    target_origin_id       = aws_s3_bucket.main.id
    viewer_protocol_policy = "redirect-to-https"
  }

  default_root_object = "index.html"
  enabled             = true
  http_version        = "http1.1"
  is_ipv6_enabled     = true

  origin {
    domain_name = aws_s3_bucket.main.bucket_regional_domain_name
    origin_id   = aws_s3_bucket.main.id
    s3_origin_config {
      origin_access_identity = local.oai_path
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_origin_access_identity" "main" {
}

resource "aws_iam_role" "main" {
  name = "gha-test-lambda-role-${local.stage}"
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
    name = "gha-test-lambda-role-inline-${local.stage}"
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
  function_name = "gha-test-lambda-${local.stage}"
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

output "cloudfront_bucket" {
  value = aws_s3_bucket.main.bucket
}
output "cloudfront_id" {
  value = aws_cloudfront_distribution.main.id
}
output "lambda_name" {
  value = aws_lambda_function.main.function_name
}
output "lambda_role_arn" {
  value = aws_iam_role.main.arn
}
output "repository_name" {
  value = "gha-test-account-lambda"
}
output "repository_url" {
  value = local.repository_url
}
