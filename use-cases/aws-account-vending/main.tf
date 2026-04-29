# AWS Account Vending — Root Configuration
#
# Orchestrates: account creation → IAM access roles → CyberArk Identity policies
# All three layers are defined as code so access governance lives alongside
# the infrastructure it governs.
#
# TODO: Replace cyberark-policy module with Secure Cloud Access (SCA) resources
#       once the correct idsec provider resource types are confirmed.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 1.0"
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

# ── Providers ─────────────────────────────────────────────────────────────────

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

provider "idsec" {
  tenant_url    = var.cyberark_tenant_url
  client_id     = var.cyberark_client_id
  client_secret = var.cyberark_client_secret
}

# ── AWS Account ───────────────────────────────────────────────────────────────

module "aws_account" {
  source = "../../modules/aws-account"

  account_name  = var.account_name
  account_email = var.account_email
  environment   = var.environment
  owner_team    = var.owner_team

  tags = {
    ProvisionedBy   = "GitHubActions"
    RequesterGitHub = var.requester_username
    Timestamp       = timestamp()
  }
}

# ── IAM Cross-Account Access Roles ───────────────────────────────────────────

module "aws_iam_policies" {
  source = "../../modules/aws-iam-policies"

  account_id            = module.aws_account.account_id
  account_name          = var.account_name
  environment           = var.environment
  owner_team            = var.owner_team
  management_account_id = data.aws_caller_identity.current.account_id
  require_mfa           = var.environment == "prod"

  depends_on = [module.aws_account]
}

# ── CyberArk Identity Access Policies ────────────────────────────────────────
# TODO: Replace with SCA-native resources — idsec_role is a placeholder.

module "cyberark_policy" {
  source = "../../modules/cyberark-policy"

  account_id         = module.aws_account.account_id
  account_name       = var.account_name
  environment        = var.environment
  requester_username = var.requester_username
  auditor_group      = var.cyberark_auditor_group
  cloudops_group     = var.cyberark_cloudops_group

  depends_on = [module.aws_account]
}

# ── Data sources ──────────────────────────────────────────────────────────────

data "aws_caller_identity" "current" {}
