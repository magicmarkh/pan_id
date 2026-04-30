terraform {
  required_version = ">= 1.7.0"

  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = ">= 0.1.0"
    }
  }
}

resource "idsec_policy_cloud_access" "power_user" {
  metadata = {
    name   = "aws-${var.account_name}-poweruser"
    status = "Active"
    policy_entitlement = {
      target_category = "AWS"
      location_type   = "Public Cloud"
      policy_type     = "Privileged Access"
    }
    time_zone = "UTC"
  }

  delegation_classification = "Privileged"

  principals = [
    {
      name = var.requester_username
      type = "User"
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
    time_restrictions = {
      enforcement_type = "Recurring"
      from             = "08:00"
      to               = "18:00"
      days             = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
    max_session_duration = var.max_session_duration
  }
}

resource "idsec_policy_cloud_access" "audit" {
  metadata = {
    name   = "aws-${var.account_name}-audit"
    status = "Active"
    policy_entitlement = {
      target_category = "AWS"
      location_type   = "Public Cloud"
      policy_type     = "Privileged Access"
    }
    time_zone = "UTC"
  }

  delegation_classification = "Privileged"

  principals = [
    {
      name = var.audit_group_name
      type = "Group"
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
    time_restrictions = {
      enforcement_type = "Recurring"
      from             = "08:00"
      to               = "18:00"
      days             = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
    max_session_duration = var.max_session_duration
  }
}

resource "idsec_policy_cloud_access" "cloudops" {
  metadata = {
    name   = "aws-${var.account_name}-cloudops"
    status = "Active"
    policy_entitlement = {
      target_category = "AWS"
      location_type   = "Public Cloud"
      policy_type     = "Privileged Access"
    }
    time_zone = "UTC"
  }

  delegation_classification = "Privileged"

  principals = [
    {
      name = var.cloudops_group_name
      type = "Group"
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
    time_restrictions = {
      enforcement_type = "Recurring"
      from             = "08:00"
      to               = "18:00"
      days             = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
    }
    max_session_duration = var.max_session_duration
  }
}
