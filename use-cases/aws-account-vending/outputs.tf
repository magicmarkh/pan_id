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
