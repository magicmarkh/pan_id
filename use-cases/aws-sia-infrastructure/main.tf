terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    idsec = {
      source  = "cyberark/idsec"
      version = ">= 0.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# Default (management-account) provider — creds come from OIDC in the workflow.
# No resources use it directly, but it anchors the child assume-role below.
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      UseCase   = "AWSSIAInfrastructure"
    }
  }
}

# Child-account provider — assumes OrganizationAccountAccessRole in the vended
# account so the VPC is created *inside* that account. No chicken-and-egg here:
# the account already exists by the time this apply runs (post-provision job).
provider "aws" {
  alias  = "child"
  region = var.aws_region

  assume_role {
    role_arn     = "arn:aws:iam::${var.account_id}:role/OrganizationAccountAccessRole"
    session_name = "GitHubActions-SIAInfra-${var.account_id}"
  }

  default_tags {
    tags = {
      ManagedBy = "Terraform"
      UseCase   = "AWSSIAInfrastructure"
    }
  }
}

provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = var.cyberark_client_id
  service_token = var.cyberark_client_secret
  subdomain     = var.cyberark_subdomain
}

# VPC scaffold in the child account (no NAT / no compute — all free)
module "network" {
  source = "../../modules/aws-network"

  providers = {
    aws = aws.child
  }

  name_prefix         = var.account_name
  vpc_cidr            = var.vpc_cidr
  public_subnet_cidr  = var.public_subnet_cidr
  private_subnet_cidr = var.private_subnet_cidr

  tags = {
    ProvisionedBy = "GitHubActions"
    AwsAccountId  = var.account_id
  }
}

# CyberArk SIA access policy (connector network + pool + scope identifiers)
module "sia" {
  source = "../../modules/cyberark-sia"

  account_id        = var.account_id
  account_name      = var.account_name
  vpc_id            = module.network.vpc_id
  private_subnet_id = module.network.private_subnet_id
}
