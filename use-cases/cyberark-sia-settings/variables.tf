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
