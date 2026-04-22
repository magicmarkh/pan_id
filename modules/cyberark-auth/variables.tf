# CyberArk Identity Authentication Variables

variable "cyberark_token" {
  description = "OAuth2 access token for CyberArk Identity authentication"
  type        = string
  sensitive   = true
}

variable "cyberark_tenant_url" {
  description = "CyberArk Identity tenant URL"
  type        = string
  default     = ""
}

variable "scope" {
  description = "OAuth2 scope for the authentication request"
  type        = string
  default     = "aws:provision"
}

variable "validate_token" {
  description = "Whether to validate the token against CyberArk Identity"
  type        = bool
  default     = true
}
