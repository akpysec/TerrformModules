# Provider 
provider "aws" {
  region = var.region_select
}

# Where to store the tfstate
terraform {
  backend "s3" {
    bucket = "my-s3-bucket-for-terraform"
    key    = "modules/network/terraform.tfstate"
    region = "us-east-1"
  }
}

# Getting A-Z's from a Region specified
data "aws_availability_zones" "available" {}

# Creating a VPC, Tagging with given name for the environment
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.environment}-VPC"
  }
}

# Creating Internet Gateway attached to VPC created ^
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${var.environment}-IGW"
  }
}

# Creating Public Subnets in a VPC ^
resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.environment}-PUBLIC-SUBNET-${count.index + 1}"
  }
}

# Creating Private Subnets in a VPC ^
resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.environment}-PRIVATE-SUBNET-${count.index + 1}"
  }
}

# Creating a Route Table for public subnets ^
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "${var.environment}-PUBLIC-ROUTE-TABLE"
  }
}

# Creating a Route Table for private subnets ^
resource "aws_route_table" "private_subnets" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }
  tags = {
    Name = "${var.environment}-PRIVATE-ROUTE-TABLE-${count.index + 1}"
  }
}

# Associating Public Subnets with Route Table
resource "aws_route_table_association" "public_routes_subnets_association" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}

# Associating Private Subnets with Route Table
resource "aws_route_table_association" "private_routes_subnets_association" {
  count          = length(aws_subnet.private_subnets[*].id)
  route_table_id = aws_route_table.private_subnets[count.index].id
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}

# EIP for NAT
resource "aws_eip" "eip_nat" {
  count = length(var.private_subnet_cidrs)
  vpc   = true
  tags = {
    Name = "${var.environment}-NAT-EIP-${count.index + 1}"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gw" {
  count         = length(var.private_subnet_cidrs)
  allocation_id = aws_eip.eip_nat[count.index].id
  subnet_id     = element(aws_subnet.public_subnets[*].id, count.index)
  tags = {
    Name = "${var.environment}-NAT-GW-${count.index + 1}"
  }
}
