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
  # Mon-Fri 08:00-18:00 UTC. Date portion is ignored for recurring policies.
  access_window = {
    days_of_the_week = [1, 2, 3, 4, 5]
    from_hour        = "2024-01-01T08:00:00"
    to_hour          = "2024-01-01T18:00:00"
  }
}

resource "idsec_policy_cloud_access" "power_user" {
  metadata = {
    name        = "aws-${var.account_name}-poweruser"
    description = "Power user access to ${var.account_name} (${var.account_id})"
    policy_entitlement = {
      target_category = "Cloud console"
      location_type   = "AWS"
      policy_type     = "Recurring"
    }
    time_zone = "UTC"
  }

  delegation_classification = "Unrestricted"

  principals = [
    {
      name = var.requester_username
      type = "USER"
    }
  ]

  targets = {
    aws_account_targets = [
      {
        role_id      = var.power_user_permission_set_arn
        workspace_id = var.account_id
      }
    ]
  }

  conditions = {
    max_session_duration = var.max_session_duration
    access_window        = local.access_window
  }
}

resource "idsec_policy_cloud_access" "audit" {
  metadata = {
    name        = "aws-${var.account_name}-audit"
    description = "Read-only audit access to ${var.account_name} (${var.account_id})"
    policy_entitlement = {
      target_category = "Cloud console"
      location_type   = "AWS"
      policy_type     = "Recurring"
    }
    time_zone = "UTC"
  }

  delegation_classification = "Unrestricted"

  principals = [
    {
      name = var.audit_group_name
      type = "GROUP"
    }
  ]

  targets = {
    aws_account_targets = [
      {
        role_id      = var.audit_permission_set_arn
        workspace_id = var.account_id
      }
    ]
  }

  conditions = {
    max_session_duration = var.max_session_duration
    access_window        = local.access_window
  }
}

resource "idsec_policy_cloud_access" "cloudops" {
  metadata = {
    name        = "aws-${var.account_name}-cloudops"
    description = "Cloud ops admin access to ${var.account_name} (${var.account_id})"
    policy_entitlement = {
      target_category = "Cloud console"
      location_type   = "AWS"
      policy_type     = "Recurring"
    }
    time_zone = "UTC"
  }

  delegation_classification = "Unrestricted"

  principals = [
    {
      name = var.cloudops_group_name
      type = "GROUP"
    }
  ]

  targets = {
    aws_account_targets = [
      {
        role_id      = var.cloudops_permission_set_arn
        workspace_id = var.account_id
      }
    ]
  }

  conditions = {
    max_session_duration = var.max_session_duration
    access_window        = local.access_window
  }
}
