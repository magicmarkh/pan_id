output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.this.id
}

output "vpc_cidr" {
  description = "CIDR block of the created VPC"
  value       = aws_vpc.this.cidr_block
}

output "public_subnet_id" {
  description = "ID of the public subnet (IGW-routed)"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "ID of the private subnet (no egress by design)"
  value       = aws_subnet.private.id
}

output "security_group_ids" {
  description = "Map of purpose -> security group ID"
  value = {
    ssh      = aws_security_group.ssh.id
    rdp      = aws_security_group.rdp.id
    database = aws_security_group.database.id
  }
}
