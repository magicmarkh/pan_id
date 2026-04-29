# AWS IAM Policies Module
#
# Creates three cross-account IAM roles in the management account that map to
# CyberArk Identity access tiers for a provisioned AWS account.
#
# Role mapping:
#   RequesterPowerUser  → PowerUserAccess managed policy
#   AuditorReadOnly     → ReadOnlyAccess + SecurityAudit managed policies
#   CloudOpsAdmin       → AdministratorAccess managed policy

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  role_prefix = "lab-${var.account_name}-${var.environment}"
}

# ── Trust policy ─────────────────────────────────────────────────────────────
# Allows principals from the management account to assume these roles.
# In production this would be scoped to a CyberArk SAML identity provider.

data "aws_iam_policy_document" "cross_account_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.management_account_id}:root"]
    }

    dynamic "condition" {
      for_each = var.require_mfa ? [1] : []
      content {
        test     = "Bool"
        variable = "aws:MultiFactorAuthPresent"
        values   = ["true"]
      }
    }
  }
}

# ── Power User role ───────────────────────────────────────────────────────────

resource "aws_iam_role" "power_user" {
  name               = "${local.role_prefix}-RequesterPowerUser"
  description        = "Power user access for ${var.account_name} — requester tier"
  assume_role_policy = data.aws_iam_policy_document.cross_account_trust.json

  tags = {
    AccountName = var.account_name
    Environment = var.environment
    OwnerTeam   = var.owner_team
    AccessTier  = "PowerUser"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "power_user" {
  role       = aws_iam_role.power_user.name
  policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
}

# ── Audit (Read-Only) role ────────────────────────────────────────────────────

resource "aws_iam_role" "auditor" {
  name               = "${local.role_prefix}-AuditorReadOnly"
  description        = "Read-only audit access for ${var.account_name} — auditor tier"
  assume_role_policy = data.aws_iam_policy_document.cross_account_trust.json

  tags = {
    AccountName = var.account_name
    Environment = var.environment
    OwnerTeam   = var.owner_team
    AccessTier  = "AuditReadOnly"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "auditor_readonly" {
  role       = aws_iam_role.auditor.name
  policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "auditor_security_audit" {
  role       = aws_iam_role.auditor.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

# ── Cloud Ops Admin role ──────────────────────────────────────────────────────

resource "aws_iam_role" "cloudops_admin" {
  name               = "${local.role_prefix}-CloudOpsAdmin"
  description        = "Admin access for ${var.account_name} — cloud-ops team"
  assume_role_policy = data.aws_iam_policy_document.cross_account_trust.json

  tags = {
    AccountName = var.account_name
    Environment = var.environment
    OwnerTeam   = var.owner_team
    AccessTier  = "CloudOpsAdmin"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_role_policy_attachment" "cloudops_admin" {
  role       = aws_iam_role.cloudops_admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
