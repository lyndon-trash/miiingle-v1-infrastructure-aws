
module "eks_cluster" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.eks_cluster_name
  vpc_id       = aws_vpc.main.id
  subnets      = aws_subnet.private.*.id

  tags = local.common_tags

  //  map_roles    = var.map_roles
  //  map_users    = var.map_users
  //  map_accounts = var.map_accounts

  node_groups = [
    {
      name            = "worker-group-1"
      additional_tags = local.common_tags
      k8s_labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      instance_type    = "m5.large"
      desired_capacity = 1
      min_capacity     = 1
      max_capacity     = 10
      subnets          = aws_subnet.private.*.id
    }
  ]
}

//this is how you attach an extra policy in case you want extra powers for your nodes
//resource "aws_iam_role_policy_attachment" "cluster_AWSXRayDaemonWriteAccess" {
//  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
//  role       = module.eks_cluster.worker_iam_role_name
//}

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_id
}