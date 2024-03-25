# VPC resource
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-my-eks-vpc"
    }
  )
}

# VPC Public Subnet Resource
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.vpc_public_subnets)
  cidr_block              = element(var.vpc_public_subnets, count.index)
  availability_zone       = element(var.vpc_availability_zones, count.index)
  map_public_ip_on_launch = true
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-my-eks-vpc-public-subnet-${count.index + 1}"
    }
  )
}

# VPC Private Subnet Resource
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.vpc.id
  count             = length(var.vpc_private_subnets)
  cidr_block        = element(var.vpc_private_subnets, count.index)
  availability_zone = element(var.vpc_availability_zones, count.index)
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-my-eks-vpc-private-subnet-${count.index + 1}"
    }
  )
}

# VPC Database Subnet Resource
resource "aws_subnet" "database_subnet" {
  vpc_id            = aws_vpc.vpc.id
  count             = length(var.vpc_database_subnets)
  cidr_block        = element(var.vpc_database_subnets, count.index)
  availability_zone = element(var.vpc_availability_zones, count.index)
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-my-eks-vpc-db-subnet-${count.index + 1}"
    }
  )
}

# VPC Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-igw"
    }
  )
}

# VPC Public Routing Table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-public-route-table"
    }
  )
}

# Route table associations for all Public subnets
resource "aws_route_table_association" "public" {
  count          = length(var.vpc_public_subnets)
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = aws_route_table.public_route_table.id
}

# Elastic-IP (eip) for NAT
resource "aws_eip" "nat_eip" {
  count      = length(var.vpc_public_subnets)
  depends_on = [aws_internet_gateway.gw]
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-my-eks-eip"
    }
  )
}

# VPC NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip[count.index].id
  count         = length(var.vpc_public_subnets)
  subnet_id     = element(aws_subnet.public_subnet[*].id, count.index)
  depends_on    = [aws_internet_gateway.gw]
  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-nat-gateway-${count.index + 1}"
    }
  )
}

# VPC Private Routing Table For Private Subnet-1
resource "aws_route_table" "private_route_table_01" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-private-route-table-1"
    }
  )
}

# VPC Private Routing Table For Private Subnet-2
resource "aws_route_table" "private_route_table_02" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat[1].id
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name}-private-route-table-2"
    }
  )
}

# # VPC Private Routing Table For Private Subnet-3
# resource "aws_route_table" "private_route_table_03" {
#   vpc_id = aws_vpc.vpc.id

#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_nat_gateway.nat[2].id
#   }

#   tags = merge(
#     local.common_tags,
#     {
#       Name = "${local.name}-private-route-table-3"
#     }
#   )
# }

# Resource To Create An Association Between A Route Table And A Subnet-1
resource "aws_route_table_association" "private_01" {
  subnet_id      = aws_subnet.private_subnet[0].id
  route_table_id = aws_route_table.private_route_table_01.id
}

# Resource To Create An Association Between A Route Table And A Subnet-2
resource "aws_route_table_association" "private_02" {
  subnet_id      = aws_subnet.private_subnet[1].id
  route_table_id = aws_route_table.private_route_table_02.id
}

# # Resource To Create An Association Between A Route Table And A Subnet-3
# resource "aws_route_table_association" "private_03" {
#   subnet_id      = aws_subnet.private_subnet[2].id
#   route_table_id = aws_route_table.private_route_table_03.id
# }
