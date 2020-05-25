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
}

variable "create_bastion" {
  description = "Whether to create a bastion or not"
  type        = bool
  default     = false
}

variable "eks_cluster_name" {
  description = "EKS Cluster name"
  type        = string
  default     = "terraform-cluster"
}

provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

variable "account_id" {
  description = "AWS Account number"
  type        = string
}

variable "ci_user" {
  description = "The AWS IAM Username for the CI"
  type        = string
}

//variable "map_roles" {
//  description = "Additional IAM roles to add to the aws-auth configmap."
//  type = list(object({
//    rolearn  = string
//    username = string
//    groups   = list(string)
//  }))
//
//  default = [
//    {
//      rolearn  = "arn:aws:iam::66666666666:role/role1"
//      username = "role1"
//      groups   = ["system:masters"]
//    },
//  ]
//}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "random" {
  version = "~> 2.1"
}

provider "local" {
  version = "~> 1.2"
}

provider "null" {
  version = "~> 2.1"
}

provider "template" {
  version = "~> 2.1"
}