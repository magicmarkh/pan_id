# CyberArk Identity — Access Policy Module
#
# Creates one CyberArk Identity role per access tier for a provisioned AWS account.
# All access is defined as code alongside the infrastructure it governs — changes
# flow through version control and the same approval gate as account creation.
#
# Role naming convention: aws-{account_name}-{tier}
#   poweruser      → RequesterPowerUser  (PowerUserAccess in AWS)
#   audit          → AuditorReadOnly     (ReadOnlyAccess + SecurityAudit in AWS)
#   cloudopsadmin  → CloudOpsAdmin       (AdministratorAccess in AWS)
#
# TODO: Replace idsec_role / idsec_role_member with Secure Cloud Access (SCA)
#       policy resources once the correct resource types are confirmed.

terraform {
  required_version = ">= 1.7.0"

  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 1.0"
    }
  }
}

# ── CyberArk Identity Roles ───────────────────────────────────────────────────

resource "idsec_role" "power_user" {
  name        = "aws-${var.account_name}-poweruser"
  description = "Power user access to AWS account ${var.account_name} (${var.account_id}) — ${var.environment}"
}

resource "idsec_role" "audit" {
  name        = "aws-${var.account_name}-audit"
  description = "Read-only audit access to AWS account ${var.account_name} (${var.account_id})"
}

resource "idsec_role" "cloudops_admin" {
  name        = "aws-${var.account_name}-cloudopsadmin"
  description = "Admin access to AWS account ${var.account_name} (${var.account_id}) — cloud-ops team"
}

# ── Role Membership ───────────────────────────────────────────────────────────

resource "idsec_role_member" "requester_power_user" {
  role_id     = idsec_role.power_user.id
  member_name = var.requester_username
  member_type = "User"
}

resource "idsec_role_member" "auditor_group" {
  count = var.auditor_group != "" ? 1 : 0

  role_id     = idsec_role.audit.id
  member_name = var.auditor_group
  member_type = "Group"
}

resource "idsec_role_member" "cloudops_group" {
  count = var.cloudops_group != "" ? 1 : 0

  role_id     = idsec_role.cloudops_admin.id
  member_name = var.cloudops_group
  member_type = "Group"
}
