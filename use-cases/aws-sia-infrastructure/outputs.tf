output "vpc_id" {
  description = "ID of the VPC created in the child account"
  value       = module.network.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.network.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.network.private_subnet_id
}

output "sia_pool_id" {
  description = "ID of the CyberArk SIA connector-manager pool"
  value       = module.sia.pool_id
}

output "sia_pool_name" {
  description = "Name of the CyberArk SIA connector-manager pool"
  value       = module.sia.pool_name
}
