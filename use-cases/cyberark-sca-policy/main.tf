terraform {
  required_version = ">= 1.7.0"

  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = ">= 0.1.0"
    }
  }
}

provider "idsec" {
  auth_method   = "identity_service_user"
  service_user  = var.cyberark_client_id
  service_token = var.cyberark_client_secret
  subdomain     = var.cyberark_subdomain
}

module "cyberark_policy" {
  source = "../../modules/cyberark-policy"

  account_id                    = var.account_id
  account_name                  = var.account_name
  org_management_account_id     = var.org_management_account_id
  power_user_role_name         = var.power_user_role_name
  power_user_permission_set_arn = var.power_user_permission_set_arn
  audit_permission_set_arn      = var.audit_permission_set_arn
  cloudops_permission_set_arn   = var.cloudops_permission_set_arn
  audit_role_name              = var.audit_role_name
  cloudops_role_name           = var.cloudops_role_name
  max_session_duration          = var.max_session_duration
}
