# AWS Account Provisioning Module
#
# This module provisions a new AWS account within an AWS Organization
# and configures baseline settings.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Create AWS Organizations Account
# Uses the default provider (management account)
resource "aws_organizations_account" "this" {
  name      = var.account_name
  email     = var.account_email
  role_name = "OrganizationAccountAccessRole"

  iam_user_access_to_billing = "ALLOW"
  parent_id                   = var.organizational_unit_id != "" ? var.organizational_unit_id : null

  tags = merge(
    {
      Name        = var.account_name
      Environment = var.environment
      OwnerTeam   = var.owner_team
      ManagedBy   = "Terraform"
    },
    var.tags
  )

  lifecycle {
    ignore_changes = [role_name]
  }
}

# Provider alias for assuming role into the newly created account
provider "aws" {
  alias  = "child"
  region = "us-east-1"

  assume_role {
    role_arn = "arn:aws:iam::${aws_organizations_account.this.id}:role/OrganizationAccountAccessRole"
  }
}

# CloudTrail Configuration (Conditional)
resource "aws_s3_bucket" "cloudtrail_logs" {
  count = var.enable_cloudtrail ? 1 : 0

  provider      = aws.child
  bucket        = "${var.account_name}-cloudtrail-logs-${aws_organizations_account.this.id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  count = var.enable_cloudtrail ? 1 : 0

  provider = aws.child
  bucket   = aws_s3_bucket.cloudtrail_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "cloudtrail_bucket_policy" {
  count = var.enable_cloudtrail ? 1 : 0

  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.cloudtrail_logs[0].arn]
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.cloudtrail_logs[0].arn}/AWSLogs/${aws_organizations_account.this.id}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}

resource "aws_s3_bucket_policy" "cloudtrail_logs" {
  count = var.enable_cloudtrail ? 1 : 0

  provider = aws.child
  bucket   = aws_s3_bucket.cloudtrail_logs[0].id
  policy   = data.aws_iam_policy_document.cloudtrail_bucket_policy[0].json
}

resource "aws_cloudtrail" "baseline" {
  count = var.enable_cloudtrail ? 1 : 0

  provider = aws.child
  name     = "${var.account_name}-baseline-trail"

  s3_bucket_name = aws_s3_bucket.cloudtrail_logs[0].id

  is_multi_region_trail         = true
  enable_log_file_validation    = true
  include_global_service_events = true

  depends_on = [aws_s3_bucket_policy.cloudtrail_logs]
}

# GuardDuty Configuration (Conditional)
resource "aws_guardduty_detector" "baseline" {
  count = var.enable_guardduty ? 1 : 0

  provider = aws.child
  enable   = true
}

# IAM Account Alias
resource "aws_iam_account_alias" "this" {
  provider      = aws.child
  account_alias = var.account_name
}
