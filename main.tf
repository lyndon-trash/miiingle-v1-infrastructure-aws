locals {
  vpc_name = "Prod VPC"

  common_tags = {
    Project     = "Miiingle.NET"
    Owner       = "terraform"
    BillingCode = "MN_PROD-01"
  }
}

provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
}

provider "kubernetes" {
  config_path = module.eks_cluster.kubeconfig_filename
}

provider "helm" {
  kubernetes {
    config_path = module.eks_cluster.kubeconfig_filename
  }
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