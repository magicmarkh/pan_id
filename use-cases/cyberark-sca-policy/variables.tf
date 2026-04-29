variable "cyberark_tenant_url" {
  description = "CyberArk Identity tenant URL"
  type        = string
  sensitive   = true
}

variable "cyberark_client_id" {
  description = "OAuth2 client ID for CyberArk authentication"
  type        = string
  sensitive   = true
}

variable "cyberark_client_secret" {
  description = "OAuth2 client secret for CyberArk authentication"
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

variable "requester_username" {
  description = "CyberArk username of the requester"
  type        = string
}

variable "power_user_role_name" {
  description = "IAM role name for power user access (pre-configured in pool accounts)"
  type        = string
}

variable "audit_role_name" {
  description = "IAM role name for audit access (pre-configured in pool accounts)"
  type        = string
}

variable "cloudops_role_name" {
  description = "IAM role name for cloud ops admin access (pre-configured in pool accounts)"
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
