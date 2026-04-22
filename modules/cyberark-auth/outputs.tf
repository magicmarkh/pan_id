# CyberArk Identity Authentication Outputs

output "authenticated" {
  description = "Indicates whether authentication was successful"
  value       = true # Placeholder
}

output "token_valid" {
  description = "Indicates whether the provided token is valid"
  value       = true # Placeholder
  sensitive   = true
}

output "aws_credentials" {
  description = "AWS credentials retrieved from CyberArk vault"
  value = {
    # Placeholder structure
    access_key_id     = ""
    secret_access_key = ""
    session_token     = ""
  }
  sensitive = true
}

output "permissions" {
  description = "Authorized permissions for the authenticated identity"
  value       = []
}
