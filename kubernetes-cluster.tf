//TODO:
//follow this guide
//https://github.com/hashicorp/learn-terraform-provision-eks-cluster

data "aws_subnet_ids" "private_subnets" {
  vpc_id = aws_vpc.main

  filter {
    name   = "tag:SubnetType"
    values = ["private"]
  }
}

resource "aws_eks_cluster" "main" {
  name     = "main-cluster"
  role_arn = "arn:aws:iam::xx:role/xx"

  vpc_config {
    subnet_ids = data.aws_subnet_ids.private_subnets
  }

  tags = merge(
    {
      Name = format("%s-Main-EKS-Cluster", local.vpc_name)
    },
    local.common_tags
  )
}