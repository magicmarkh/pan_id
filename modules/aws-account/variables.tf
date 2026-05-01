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

variable "organizational_unit_id" {
  description = "AWS Organizations OU ID where the account should be placed"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Additional tags to apply to the account"
  type        = map(string)
  default     = {}
}
