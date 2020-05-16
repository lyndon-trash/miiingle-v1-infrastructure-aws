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
  default     = ["us-east-1a", "us-east-1b"]
}

variable "base_cidr_block" {
  description = "A /16 CIDR range definition, such as 10.1.0.0/16, that the VPC will use"
  default     = "20.10.0.0/16"
}

//this should only be your dev/CI machine's IP
//terraform apply -var='bastion_source_ips=["0.0.0.0/0"]'
variable "bastion_source_ips" {
  description = "The IP Address to whitelist for bastion access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

//use env variables for the actual value, or parameterize this
variable "bastion_public_key" {
  description = "The Public Key with access to the bastion host"
  type        = string
  default     = "ssh-rsa <insert public key here> <user>@<machine>"
}

provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}