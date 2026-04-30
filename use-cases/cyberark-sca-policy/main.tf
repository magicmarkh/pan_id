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

  account_id                    = var.account_id
  account_name                  = var.account_name
  requester_username            = var.requester_username
  power_user_permission_set_arn = var.power_user_permission_set_arn
  audit_permission_set_arn      = var.audit_permission_set_arn
  cloudops_permission_set_arn   = var.cloudops_permission_set_arn
  audit_group_name              = var.audit_group_name
  cloudops_group_name           = var.cloudops_group_name
  max_session_duration          = var.max_session_duration
}
