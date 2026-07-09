terraform {
  required_version = ">= 1.7.0"

  required_providers {
    idsec = {
      source  = "cyberark/idsec"
      version = ">= 0.4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

# 6-char suffix keyed on account_id so provision -> deprovision -> re-provision
# cycles of the same account_name get fresh, unique connector network/pool names
# (mirrors the SCA policy naming pattern in modules/cyberark-policy).
resource "random_string" "sia_suffix" {
  length  = 6
  upper   = false
  special = false

  keepers = {
    account_id = var.account_id
  }
}

locals {
  # Typed pool identifiers scope which infrastructure this SIA policy reaches.
  # Ported from murphys_lab connector_pools; trimmed to the AWS scope for this
  # account (no AD / RDS FQDN identifiers — none exist in this cost-free build).
  pool_identifiers = {
    "aws_vpc" = {
      value = var.vpc_id
      type  = "AWS_VPC"
    }
    "aws_subnet" = {
      value = "${var.vpc_id}/${var.private_subnet_id}"
      type  = "AWS_SUBNET"
    }
    "aws_account" = {
      value = var.account_id
      type  = "AWS_ACCOUNT_ID"
    }
  }
}

# Connector-manager network for this account
resource "idsec_cmgr_network" "this" {
  name = "aws-${var.account_name}-sia-net-${random_string.sia_suffix.result}"
}

# Connector-manager pool bound to the network — this is the SIA access policy
# object surfaced in the tenant for this account.
resource "idsec_cmgr_pool" "this" {
  name                 = "aws-${var.account_name}-sia-pool-${random_string.sia_suffix.result}"
  description          = "SIA access pool for ${var.account_name} (${var.account_id})"
  assigned_network_ids = [idsec_cmgr_network.this.network_id]
}

# Scope identifiers (VPC / subnet / account) attached to the pool
resource "idsec_cmgr_pool_identifier" "identifiers" {
  for_each = local.pool_identifiers

  value   = each.value.value
  pool_id = idsec_cmgr_pool.this.pool_id
  type    = each.value.type
}
