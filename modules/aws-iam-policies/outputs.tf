output "power_user_role_arn" {
  description = "ARN of the RequesterPowerUser cross-account role"
  value       = aws_iam_role.power_user.arn
}

output "auditor_role_arn" {
  description = "ARN of the AuditorReadOnly cross-account role"
  value       = aws_iam_role.auditor.arn
}

output "cloudops_admin_role_arn" {
  description = "ARN of the CloudOpsAdmin cross-account role"
  value       = aws_iam_role.cloudops_admin.arn
}

output "power_user_role_name" {
  description = "Name of the RequesterPowerUser role"
  value       = aws_iam_role.power_user.name
}

output "auditor_role_name" {
  description = "Name of the AuditorReadOnly role"
  value       = aws_iam_role.auditor.name
}

output "cloudops_admin_role_name" {
  description = "Name of the CloudOpsAdmin role"
  value       = aws_iam_role.cloudops_admin.name
}
