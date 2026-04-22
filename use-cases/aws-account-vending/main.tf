# AWS Account Vending - Root Configuration
#
# This is the root Terraform configuration that orchestrates AWS account
# provisioning using CyberArk Identity authentication.

terraform {
  required_version = ">= 1.6.0"

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

# Configure AWS Provider
# Assumes credentials are provided via environment or IAM role
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

# Authenticate with CyberArk Identity
module "cyberark_auth" {
  source = "../../modules/cyberark-auth"

  cyberark_token = var.cyberark_token
}

# Provision AWS Account
module "aws_account" {
  source = "../../modules/aws-account"

  account_name  = var.account_name
  account_email = var.account_email
  environment   = var.environment
  owner_team    = var.owner_team

  # Use authentication from CyberArk
  # depends_on = [module.cyberark_auth]

  tags = {
    ProvisionedBy = "GitHubActions"
    Timestamp     = timestamp()
  }
}

# Configure IAM Policies and Roles
module "aws_iam_policies" {
  source = "../../modules/aws-iam-policies"

  account_id  = module.aws_account.account_id
  environment = var.environment
  owner_team  = var.owner_team

  create_admin_role     = true
  create_developer_role = true
  create_readonly_role  = true
  require_mfa           = var.environment == "prod" ? true : false

  # depends_on = [module.aws_account]
}
