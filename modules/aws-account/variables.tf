# AWS Account Provisioning Variables

variable "account_name" {
  description = "Name of the AWS account to be created"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.account_name))
    error_message = "Account name must contain only alphanumeric characters and hyphens."
  }
}

variable "account_email" {
  description = "Root email address for the AWS account (must be unique)"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.account_email))
    error_message = "Account email must be a valid email address."
  }
}

variable "environment" {
  description = "Environment type for the account"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner_team" {
  description = "Team or group responsible for this account"
  type        = string
}

variable "organizational_unit_id" {
  description = "AWS Organizations OU ID where the account should be placed"
  type        = string
  default     = ""
}

variable "enable_cloudtrail" {
  description = "Enable AWS CloudTrail in the new account"
  type        = bool
  default     = true
}

variable "enable_config" {
  description = "Enable AWS Config in the new account"
  type        = bool
  default     = true
}

variable "enable_guardduty" {
  description = "Enable Amazon GuardDuty in the new account"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to apply to the account"
  type        = map(string)
  default     = {}
}
