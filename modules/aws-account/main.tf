terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_organizations_account" "this" {
  name      = var.account_name
  email     = var.account_email
  role_name = "OrganizationAccountAccessRole"

  iam_user_access_to_billing = "ALLOW"
  parent_id                  = var.organizational_unit_id != "" ? var.organizational_unit_id : null

  tags = merge(
    {
      Name      = var.account_name
      ManagedBy = "Terraform"
    },
    var.tags
  )

  lifecycle {
    ignore_changes = [role_name]
  }
}
