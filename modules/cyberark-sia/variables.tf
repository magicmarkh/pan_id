variable "account_id" {
  description = "12-digit AWS account ID this SIA policy scopes access to"
  type        = string
}

variable "account_name" {
  description = "Label for this account (used in connector network/pool names)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC this SIA policy scopes access to"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet (combined with vpc_id for the AWS_SUBNET identifier)"
  type        = string
}
