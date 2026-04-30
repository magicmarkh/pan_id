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
