# AWS Account Provisioning Outputs

output "account_id" {
  description = "The AWS account ID of the newly created account"
  value       = aws_organizations_account.this.id
}

output "account_arn" {
  description = "The ARN of the newly created account"
  value       = aws_organizations_account.this.arn
}

output "account_name" {
  description = "The name of the AWS account"
  value       = aws_organizations_account.this.name
}

output "account_email" {
  description = "The root email address of the AWS account"
  value       = aws_organizations_account.this.email
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
  value       = aws_organizations_account.this.status
}

output "join_method" {
  description = "The method by which the account joined the organization"
  value       = aws_organizations_account.this.joined_method
}

output "cross_account_role_arn" {
  description = "ARN of the OrganizationAccountAccessRole in the new account — used by later modules to assume role"
  value       = "arn:aws:iam::${aws_organizations_account.this.id}:role/OrganizationAccountAccessRole"
}
