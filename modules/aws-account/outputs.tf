# AWS Account Provisioning Outputs

output "account_id" {
  description = "The AWS account ID of the newly created account"
  value       = "" # Placeholder
}

output "account_arn" {
  description = "The ARN of the newly created account"
  value       = "" # Placeholder
}

output "account_name" {
  description = "The name of the AWS account"
  value       = var.account_name
}

output "account_email" {
  description = "The root email address of the AWS account"
  value       = var.account_email
  sensitive   = true
}

output "environment" {
  description = "The environment type of the account"
  value       = var.environment
}

output "owner_team" {
  description = "The team responsible for the account"
  value       = var.owner_team
}

output "account_status" {
  description = "The status of the account creation"
  value       = "ACTIVE" # Placeholder
}

output "join_method" {
  description = "The method by which the account joined the organization"
  value       = "CREATED" # Placeholder
}
