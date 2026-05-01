terraform {
  required_version = ">= 1.7.0"

  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = ">= 0.1.0"
    }
  }
}

locals {
  access_window = {
    days_of_the_week = [1, 2, 3, 4, 5]
    from_hour        = var.access_window_from_hour
    to_hour          = var.access_window_to_hour
  }

  # Strip wrapping single/double quotes and whitespace from role names —
  # SCA matches principals by exact string, so `'ML-Cloud-Ops'` (literal
  # quotes from a sloppily-stored secret) silently fails to resolve.
  power_user_role_name = trim(trimspace(var.power_user_role_name), "'\"")
  audit_role_name      = trim(trimspace(var.audit_role_name), "'\"")
  cloudops_role_name   = trim(trimspace(var.cloudops_role_name), "'\"")
}

resource "idsec_policy_cloud_access" "power_user" {
  metadata = {
    name        = "aws-${var.account_name}-poweruser-1"
    description = "PowerUser-access-${var.account_name}-${var.account_id}"
    status = {
      status = "Active"
    }
    policy_entitlement = {
      target_category = "Cloud console"
      location_type   = "AWS"
    }
    time_zone = var.time_zone
  }

  principals = [
    {
      name = local.power_user_role_name
      type = "ROLE"
    }
  ]

  conditions = {
    max_session_duration = var.max_session_duration
    access_window        = local.access_window
  }

  targets = {
    aws_organization_targets = [
      {
        role_id      = var.power_user_permission_set_arn
        workspace_id = var.account_id
        org_id       = var.org_management_account_id
      }
    ]
  }
}

resource "idsec_policy_cloud_access" "audit" {
  metadata = {
    name        = "aws-${var.account_name}-audit"
    description = "Audit-readonly-access-${var.account_name}-${var.account_id}"
    status = {
      status = "Active"
    }
    policy_entitlement = {
      target_category = "Cloud console"
      location_type   = "AWS"
    }
    time_zone = var.time_zone
  }

  principals = [
    {
      name = local.audit_role_name
      type = "ROLE"
    }
  ]

  conditions = {
    max_session_duration = var.max_session_duration
    access_window        = local.access_window
  }

  targets = {
    aws_organization_targets = [
      {
        role_id      = var.audit_permission_set_arn
        workspace_id = var.account_id
        org_id       = var.org_management_account_id
      }
    ]
  }
}

resource "idsec_policy_cloud_access" "cloudops" {
  metadata = {
    name        = "aws-${var.account_name}-cloudops-1"
    description = "CloudOps-admin-access-${var.account_name}-${var.account_id}"
    status = {
      status = "Active"
    }
    policy_entitlement = {
      target_category = "Cloud console"
      location_type   = "AWS"
    }
    time_zone = var.time_zone
  }

  principals = [
    {
      name = local.cloudops_role_name
      type = "ROLE"
    }
  ]

  conditions = {
    max_session_duration = var.max_session_duration
    access_window        = local.access_window
  }

  targets = {
    aws_organization_targets = [
      {
        role_id      = var.cloudops_permission_set_arn
        workspace_id = var.account_id
        org_id       = var.org_management_account_id
      }
    ]
  }
}
