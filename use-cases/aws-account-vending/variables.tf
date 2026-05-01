variable "account_name" {
  description = "Name of the AWS account to be created"
  type        = string
}

variable "account_email" {
  description = "Root email address for the AWS account (must be unique)"
  type        = string
}

variable "target_ou_id" {
  description = "Organizational Unit ID where the account will be placed"
  type        = string
  default     = ""
}
