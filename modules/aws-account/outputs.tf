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

output "account_status" {
  description = "The status of the account creation"
  value       = aws_organizations_account.this.status
}
