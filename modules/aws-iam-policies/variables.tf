# AWS IAM Policies Variables

variable "account_id" {
  description = "AWS account ID where policies will be created"
  type        = string
}

variable "environment" {
  description = "Environment type (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner_team" {
  description = "Team that owns this account"
  type        = string
}

variable "create_admin_role" {
  description = "Create an administrator role"
  type        = bool
  default     = true
}

variable "create_developer_role" {
  description = "Create a developer role with limited permissions"
  type        = bool
  default     = true
}

variable "create_readonly_role" {
  description = "Create a read-only role"
  type        = bool
  default     = true
}

variable "trusted_principals" {
  description = "List of AWS principals that can assume the created roles"
  type        = list(string)
  default     = []
}

variable "require_mfa" {
  description = "Require MFA for role assumption"
  type        = bool
  default     = true
}

variable "custom_policies" {
  description = "Map of custom IAM policies to create"
  type = map(object({
    description = string
    policy_json = string
  }))
  default = {}
}
