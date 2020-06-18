
module "eks_cluster" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.eks_cluster_name
  vpc_id       = module.vpc.vpc_id
  subnets      = module.vpc.private_subnets

  tags = local.common_tags

  map_accounts = [var.account_id]
  map_users = [
    {
      userarn  = "arn:aws:iam::${var.account_id}:user/${var.ci_user}"
      username = "ci-user"
      groups   = ["system:masters"]
    }
  ]

  node_groups = [
    {
      additional_tags = local.common_tags
      k8s_labels = {
        Environment = "test"
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }
      instance_type    = "t3.medium"
      desired_capacity = 1
      min_capacity     = 1
      max_capacity     = 10
      subnets          = module.vpc.private_subnets
    }
  ]
}

resource "aws_iam_role_policy_attachment" "cluster_AWSXRayDaemonWriteAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
  role       = module.eks_cluster.worker_iam_role_name
}

//TODO: this is overkill, figure out a policy with less access
//https://docs.aws.amazon.com/eks/latest/userguide/cluster-autoscaler.html
resource "aws_iam_role_policy_attachment" "cluster_AutoScalingFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = module.eks_cluster.worker_iam_role_name
}

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_id
}