terraform {
  required_version = ">= 1.7.0"

  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = "~> 1.0"
    }
  }
}

provider "idsec" {
  tenant_url    = var.cyberark_tenant_url
  client_id     = var.cyberark_client_id
  client_secret = var.cyberark_client_secret
}

module "cyberark_policy" {
  source = "../../modules/cyberark-policy"

  account_id           = var.account_id
  account_name         = var.account_name
  requester_username   = var.requester_username
  power_user_role_arn  = "arn:aws:iam::${var.account_id}:role/${var.power_user_role_name}"
  audit_role_arn       = "arn:aws:iam::${var.account_id}:role/${var.audit_role_name}"
  cloudops_role_arn    = "arn:aws:iam::${var.account_id}:role/${var.cloudops_role_name}"
  audit_group_name     = var.audit_group_name
  cloudops_group_name  = var.cloudops_group_name
  max_session_duration = var.max_session_duration
}
