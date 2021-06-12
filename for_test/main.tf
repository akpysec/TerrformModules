# Provider 
provider "aws" {
  region = "us-east-1"
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

# Associating Public Subnets with Route Table
resource "aws_route_table_association" "public_routes_subnets_association" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_route_table.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}


