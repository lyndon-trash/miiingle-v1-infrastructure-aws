
module "eks_cluster" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.eks_cluster_name
  vpc_id       = aws_vpc.main.id
  subnets      = aws_subnet.private.*.id

  tags = local.common_tags

  node_groups = [
    {
      name = "worker-group-1"
      additional_tags  = local.common_tags
      desired_capacity = 2
      subnets          = aws_subnet.private.*.id
    }
  ]
}

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_id
}