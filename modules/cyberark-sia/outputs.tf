output "network_id" {
  description = "ID of the CyberArk SIA connector-manager network"
  value       = idsec_cmgr_network.this.network_id
}

output "pool_id" {
  description = "ID of the CyberArk SIA connector-manager pool (the access policy object)"
  value       = idsec_cmgr_pool.this.pool_id
}

output "pool_name" {
  description = "Name of the CyberArk SIA connector-manager pool"
  value       = idsec_cmgr_pool.this.name
}
