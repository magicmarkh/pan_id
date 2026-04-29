output "power_user_role_id" {
  description = "CyberArk Identity role ID for the Power User tier"
  value       = idsec_role.power_user.id
}

output "audit_role_id" {
  description = "CyberArk Identity role ID for the Audit (Read-Only) tier"
  value       = idsec_role.audit.id
}

output "cloudops_admin_role_id" {
  description = "CyberArk Identity role ID for the Cloud Ops Admin tier"
  value       = idsec_role.cloudops_admin.id
}

output "power_user_role_name" {
  description = "CyberArk Identity role name for the Power User tier"
  value       = idsec_role.power_user.name
}

output "audit_role_name" {
  description = "CyberArk Identity role name for the Audit tier"
  value       = idsec_role.audit.name
}

output "cloudops_admin_role_name" {
  description = "CyberArk Identity role name for the Cloud Ops Admin tier"
  value       = idsec_role.cloudops_admin.name
}
