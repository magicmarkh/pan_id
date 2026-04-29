variable "account_id" {
  description = "12-digit AWS account ID"
  type        = string
}

variable "account_name" {
  description = "Label for this account assignment"
  type        = string
}

variable "requester_username" {
  description = "CyberArk username of the user who requested this account"
  type        = string
}

variable "power_user_role_arn" {
  description = "IAM role ARN for power user access in the account"
  type        = string
}

variable "audit_role_arn" {
  description = "IAM role ARN for read-only audit access in the account"
  type        = string
}

variable "cloudops_role_arn" {
  description = "IAM role ARN for admin access in the account"
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
  description = "Maximum session duration in seconds"
  type        = number
  default     = 3600
}
