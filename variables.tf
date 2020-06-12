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

variable "account_id" {
  description = "AWS Account number"
  type        = string
}

variable "ci_user" {
  description = "The AWS IAM Username for the CI"
  type        = string
}

variable "domain_base" {
  description = "The base domain"
  type        = string
  default     = "miiingle.net"
}