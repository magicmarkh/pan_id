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

variable "target_ou_id" {
  description = "Organizational Unit ID where the account will be placed (optional)"
  type        = string
  default     = ""
}

variable "requester_username" {
  description = "GitHub / CyberArk Identity username of the engineer who opened the issue"
  type        = string
  default     = ""
}

# ── CyberArk Identity ─────────────────────────────────────────────────────────

variable "cyberark_tenant_url" {
  description = "CyberArk Identity tenant URL (e.g. https://abc1234.id.cyberark.cloud)"
  type        = string
  default     = ""
}

variable "cyberark_client_id" {
  description = "OAuth2 service account client ID"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cyberark_client_secret" {
  description = "OAuth2 service account client secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "cyberark_auditor_group" {
  description = "CyberArk Identity group to assign ReadOnly audit access"
  type        = string
  default     = ""
}

variable "cyberark_cloudops_group" {
  description = "CyberArk Identity group to assign Admin access"
  type        = string
  default     = ""
}
