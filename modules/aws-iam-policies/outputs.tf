# AWS IAM Policies Outputs

output "admin_role_arn" {
  description = "ARN of the administrator role"
  value       = "" # Placeholder
}

output "developer_role_arn" {
  description = "ARN of the developer role"
  value       = "" # Placeholder
}

output "readonly_role_arn" {
  description = "ARN of the read-only role"
  value       = "" # Placeholder
}

output "policy_arns" {
  description = "Map of created policy names to their ARNs"
  value       = {} # Placeholder
}

output "custom_policy_arns" {
  description = "ARNs of custom policies created"
  value       = {} # Placeholder
}
