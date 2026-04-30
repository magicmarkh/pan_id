output "power_user_policy_id" {
  description = "ID of the CyberArk SCA policy for power user access"
  value       = idsec_policy_cloud_access.power_user.metadata.policy_id
}

output "audit_policy_id" {
  description = "ID of the CyberArk SCA policy for audit access"
  value       = idsec_policy_cloud_access.audit.metadata.policy_id
}

output "cloudops_policy_id" {
  description = "ID of the CyberArk SCA policy for cloud ops access"
  value       = idsec_policy_cloud_access.cloudops.metadata.policy_id
}
