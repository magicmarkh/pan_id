variable "cyberark_subdomain" {
  description = "CyberArk Identity tenant subdomain (e.g. 'abc1234' from abc1234.id.cyberark.cloud)"
  type        = string
}

variable "cyberark_client_id" {
  description = "CyberArk Identity service user (OAuth2 client ID / app ID)"
  type        = string
  sensitive   = true
}

variable "cyberark_client_secret" {
  description = "CyberArk Identity service token (OAuth2 client secret)"
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "12-digit AWS account ID"
  type        = string
}

variable "account_name" {
  description = "Label for this account assignment"
  type        = string
}

variable "power_user_group_name" {
  description = "CyberArk group name for power user access"
  type        = string
}

variable "power_user_permission_set_arn" {
  description = "IAM Identity Center permission set ARN for power user access"
  type        = string
}

variable "audit_permission_set_arn" {
  description = "IAM Identity Center permission set ARN for audit read-only access"
  type        = string
}

variable "cloudops_permission_set_arn" {
  description = "IAM Identity Center permission set ARN for cloud ops admin access"
  type        = string
}

variable "audit_group_name" {
  description = "CyberArk group name for auditors"
  type        = string
}

variable "cloudops_group_name" {
  description = "CyberArk group name for cloud ops"
  type        = string
}

variable "max_session_duration" {
  description = "Maximum session duration in hours"
  type        = number
  default     = 1
}
