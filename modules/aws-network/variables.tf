variable "name_prefix" {
  description = "Prefix for Name tags on all networking resources (e.g. the account name)"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet (IGW-routed, free)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet (no NAT / no egress by design)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "tags" {
  description = "Additional tags to merge onto every networking resource"
  type        = map(string)
  default     = {}
}
