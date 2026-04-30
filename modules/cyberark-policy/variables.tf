variable "account_id" {
  description = "AWS account ID of the provisioned account"
  description = "12-digit AWS account ID"
  type        = string
}

variable "account_name" {
  description = "Name/label of the provisioned AWS account (used in role names)"
  type        = string
}

variable "environment" {
  description = "Environment tier (dev, staging, prod)"
  type        = string
}

variable "requester_username" {
  description = "CyberArk Identity username of the engineer who requested the account"
  type        = string
}

variable "auditor_group" {
  description = "CyberArk Identity group to assign ReadOnly audit access (leave empty to skip)"
  type        = string
  default     = ""
}

variable "cloudops_group" {
  description = "CyberArk Identity group to assign Admin access (leave empty to skip)"
  type        = string
  default     = ""
}
