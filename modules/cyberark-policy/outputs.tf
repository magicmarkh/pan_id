output "power_user_policy_id" {
  description = "ID of the CyberArk SCA policy for power user access"
  value       = idsec_policy_cloud_access.power_user.id
}

output "audit_policy_id" {
  description = "ID of the CyberArk SCA policy for audit access"
  value       = idsec_policy_cloud_access.audit.id
}

output "cloudops_policy_id" {
  description = "ID of the CyberArk SCA policy for cloud ops access"
  value       = idsec_policy_cloud_access.cloudops.id
}
