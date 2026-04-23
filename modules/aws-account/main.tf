# AWS Account Provisioning Module
#
# This module provisions a new AWS account within an AWS Organization.
#
# NOTE: Baseline security resources (CloudTrail, GuardDuty, IAM account alias)
# will be implemented in a future phase. These resources require assuming a role
# into the new account, which creates a chicken-and-egg problem at provider
# initialization time since the account ID is not yet known. A two-phase approach
# or a separate module will be used to configure these resources after account creation.

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
