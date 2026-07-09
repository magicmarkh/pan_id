variable "account_id" {
  description = "12-digit AWS account ID of the vended (child) account"
  type        = string
}

variable "account_name" {
  description = "Label for the vended account (used for VPC tags + SIA pool names)"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the VPC"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "cyberark_subdomain" {
  description = "ISP tenant subdomain name (prefix of <name>.cyberark.cloud)"
  type        = string
}

variable "cyberark_client_id" {
  description = "OAuth2 service account client ID (service_user)"
  type        = string
  sensitive   = true
}

variable "cyberark_client_secret" {
  description = "OAuth2 service account client secret (service_token)"
  type        = string
  sensitive   = true
}
