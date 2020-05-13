# Configure the AWS Provider
provider "aws" {
  version = "~> 2.0"
  region  = "us-east-1"
}

# Create a VPC
# Reference:
# https://www.terraform.io/docs/providers/aws/d/vpc.html
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name  = "Test VPC"
  }
}