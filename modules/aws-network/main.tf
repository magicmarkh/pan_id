terraform {
  required_version = ">= 1.7.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Resolve region + AZs from whichever provider is passed in (typically aws.child)
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# ── VPC ──────────────────────────────────────────────────────────────────────
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      Name      = "${var.name_prefix}-vpc"
      ManagedBy = "Terraform"
    },
    var.tags
  )
}

# ── Subnets ──────────────────────────────────────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = merge(
    {
      Name      = "${var.name_prefix}-public-subnet"
      ManagedBy = "Terraform"
      Tier      = "public"
    },
    var.tags
  )
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.this.id
  cidr_block              = var.private_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = false

  tags = merge(
    {
      Name      = "${var.name_prefix}-private-subnet"
      ManagedBy = "Terraform"
      Tier      = "private"
    },
    var.tags
  )
}

# ── Internet Gateway + public routing (free) ─────────────────────────────────
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name      = "${var.name_prefix}-igw"
      ManagedBy = "Terraform"
    },
    var.tags
  )
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = merge(
    {
      Name      = "${var.name_prefix}-public-rt"
      ManagedBy = "Terraform"
    },
    var.tags
  )
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Private routing ──────────────────────────────────────────────────────────
# NOTE: intentionally NO NAT gateway (would incur ~$32/mo). The private subnet
# has no default route to the internet; free S3 access is via the gateway
# endpoint below. When compute is added later, place internet-facing hosts in
# the public subnet (IGW, free) rather than adding a NAT gateway.
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  tags = merge(
    {
      Name      = "${var.name_prefix}-private-rt"
      ManagedBy = "Terraform"
    },
    var.tags
  )
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Gateway VPC endpoint for S3 — free (unlike Interface/PrivateLink endpoints)
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]

  tags = merge(
    {
      Name      = "${var.name_prefix}-s3-gateway-endpoint"
      ManagedBy = "Terraform"
    },
    var.tags
  )
}

# ── Security groups (free) ───────────────────────────────────────────────────
# Ingress scoped to the VPC CIDR only; these front future SIA targets.
resource "aws_security_group" "ssh" {
  name_prefix = "${var.name_prefix}-ssh-"
  description = "SSH access to SIA Linux targets (intra-VPC)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "SSH from within the VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "${var.name_prefix}-ssh-sg", ManagedBy = "Terraform" },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "rdp" {
  name_prefix = "${var.name_prefix}-rdp-"
  description = "RDP access to SIA Windows targets (intra-VPC)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "RDP from within the VPC"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SMB + RPC — required for SIA RDP ephemeral-user provisioning on Windows
  ingress {
    description = "SMB from within the VPC"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "RPC endpoint mapper from within the VPC"
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "${var.name_prefix}-rdp-sg", ManagedBy = "Terraform" },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "database" {
  name_prefix = "${var.name_prefix}-db-"
  description = "Database access to SIA DB targets (intra-VPC)"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "PostgreSQL from within the VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "MySQL from within the VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "MSSQL from within the VPC"
    from_port   = 1433
    to_port     = 1433
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "${var.name_prefix}-db-sg", ManagedBy = "Terraform" },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}
