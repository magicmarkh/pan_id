# AWS Account Vending - Outputs

output "account_id" {
  description = "The AWS account ID of the newly created account"
  value       = module.aws_account.account_id
}

output "account_arn" {
  description = "The ARN of the newly created account"
  value       = module.aws_account.account_arn
}

output "account_name" {
  description = "The name of the AWS account"
  value       = module.aws_account.account_name
}

output "environment" {
  description = "The environment type of the account"
  value       = module.aws_account.environment
}

output "owner_team" {
  description = "The team responsible for the account"
  value       = module.aws_account.owner_team
}

output "admin_role_arn" {
  description = "ARN of the administrator role"
  value       = module.aws_iam_policies.admin_role_arn
}

output "developer_role_arn" {
  description = "ARN of the developer role"
  value       = module.aws_iam_policies.developer_role_arn
}

output "readonly_role_arn" {
  description = "ARN of the read-only role"
  value       = module.aws_iam_policies.readonly_role_arn
}

output "provisioning_summary" {
  description = "Summary of the provisioned resources"
  value = {
    account_id   = module.aws_account.account_id
    account_name = module.aws_account.account_name
    environment  = module.aws_account.environment
    owner_team   = module.aws_account.owner_team
    status       = module.aws_account.account_status
  }
}
