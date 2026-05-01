variable "account_id" {
  description = "12-digit AWS account ID (workspace_id)"
  type        = string
}

variable "account_name" {
  description = "Label for this account assignment"
  type        = string
}

variable "org_management_account_id" {
  description = "AWS Organizations management account ID (used as org_id in policy targets)"
  type        = string
}

variable "power_user_role_name" {
  description = "CyberArk Identity role name for power user access"
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

variable "audit_role_name" {
  description = "CyberArk Identity role name for auditors"
  type        = string
}

variable "cloudops_role_name" {
  description = "CyberArk Identity role name for cloud ops"
  type        = string
}

variable "max_session_duration" {
  description = "Maximum session duration in hours"
  type        = number
  default     = 1
}

variable "time_zone" {
  description = "IANA timezone name (e.g. America/New_York, Etc/UTC)"
  type        = string
  default     = "America/New_York"
}

variable "access_window_from_hour" {
  description = "Access window start time, HH:MM:SS"
  type        = string
  default     = "08:00:00"
}

variable "access_window_to_hour" {
  description = "Access window end time, HH:MM:SS"
  type        = string
  default     = "18:00:00"
}

