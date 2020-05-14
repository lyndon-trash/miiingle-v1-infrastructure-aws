locals {
  vpc_name = "Prod VPC"

  common_tags = {
    Project     = "Miiingle.NET"
    Owner       = "terraform"
    BillingCode = "MN_PROD-01"
  }
}

variable "aws_region" {
  description = "The AWS Region for the Main VPC"
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "A list of availability zones in which to create subnets"
  type        = list(string)
  default     = ["us-east-1a", "us-east-2b"]
}

variable "base_cidr_block" {
  description = "A /16 CIDR range definition, such as 10.1.0.0/16, that the VPC will use"
  default     = "20.10.0.0/16"
}

provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

# Create a VPC
# Reference:
# https://www.terraform.io/docs/providers/aws/d/vpc.html
resource "aws_vpc" "main" {
  cidr_block = var.base_cidr_block
  tags = merge(
    {
      Name = local.vpc_name
    },
    local.common_tags
  )
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 1 + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name       = format("%s-Subnet-Private-%d", local.vpc_name, count.index + 1)
      SubnetType = "private"
    },
    local.common_tags
  )
}

resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 4, count.index + 1)
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    {
      Name       = format("%s-Subnet-Public-%d", local.vpc_name, count.index + 1)
      SubnetType = "public"
    },
    local.common_tags
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    {
      Name = format("%s-IGW", local.vpc_name)
    },
    local.common_tags
  )
}