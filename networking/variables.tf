variable "region_select" {
  # default = "us-east-1"
  type        = string
  description = "Region for Deployment"
}

variable "environment" {
  type        = string
  description = "Name you ENVIRONMENT"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  type        = string
  description = "Your VPC CIDR"
}

variable "public_subnet_cidrs" {
  default = [
    "10.0.100.0/24",
    "10.0.101.0/24",
  ]
}

variable "private_subnet_cidrs" {
  default = [
    "10.0.1.0/24",
    "10.0.2.0/24",
  ]
}
