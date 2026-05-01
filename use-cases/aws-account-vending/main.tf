terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      UseCase   = "AWSAccountVending"
    }
  }
}

module "aws_account" {
  source = "../../modules/aws-account"

  account_name           = var.account_name
  account_email          = var.account_email
  organizational_unit_id = var.target_ou_id

  tags = {
    ProvisionedBy = "GitHubActions"
  }
}
