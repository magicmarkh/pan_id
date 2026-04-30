variable "account_id" {
  description = "AWS account ID of the provisioned account"
  type        = string
}

variable "account_name" {
  description = "Name/label of the provisioned AWS account (used in role names)"
  type        = string
}

variable "environment" {
  description = "Environment tier (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner_team" {
  description = "Team responsible for this account"
  type        = string
}

variable "management_account_id" {
  description = "AWS management account ID — used as the trusted principal in cross-account role trust policies"
  type        = string
}

variable "require_mfa" {
  description = "Require MFA when assuming these roles (recommended for prod)"
  type        = bool
  default     = false
}
