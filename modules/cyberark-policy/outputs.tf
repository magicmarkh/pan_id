output "power_user_policy_id" {
  description = "ID of the power user SCA policy"
  value       = idsec_policy_cloud_access.power_user.id
}

output "audit_policy_id" {
  description = "ID of the audit SCA policy"
  value       = idsec_policy_cloud_access.audit.id
}

output "cloudops_policy_id" {
  description = "ID of the cloudops SCA policy"
  value       = idsec_policy_cloud_access.cloudops.id
}
