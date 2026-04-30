# AWS Account Vending - Root Configuration
#
# This is the root Terraform configuration that orchestrates AWS account
# provisioning using CyberArk Identity authentication.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # TODO: Configure backend for state management
  # backend "s3" {
  #   bucket         = "your-terraform-state-bucket"
  #   key            = "aws-account-vending/terraform.tfstate"
  #   region         = "us-east-1"
  #   encrypt        = true
  #   dynamodb_table = "terraform-state-lock"
  # }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      ManagedBy   = "Terraform"
      UseCase     = "AWSAccountVending"
      Environment = var.environment
      OwnerTeam   = var.owner_team
    }
  }
}

module "aws_account" {
  source = "../../modules/aws-account"

  account_name           = var.account_name
  account_email          = var.account_email
  environment            = var.environment
  owner_team             = var.owner_team
  organizational_unit_id = var.target_ou_id

  tags = {
    ProvisionedBy = "GitHubActions"
    Timestamp     = timestamp()
  }
}
