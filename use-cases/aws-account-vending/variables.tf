# AWS Account Vending - Variables

variable "account_name" {
  description = "Name of the AWS account to be created"
  type        = string
}

variable "account_email" {
  description = "Root email address for the AWS account (must be unique)"
  type        = string
}

variable "environment" {
  description = "Environment type for the account (dev, staging, prod)"
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

variable "cyberark_token" {
  description = "OAuth2 access token from CyberArk Identity"
  type        = string
  sensitive   = true
}
