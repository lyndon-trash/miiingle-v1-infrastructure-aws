
module "eks_cluster" {
  source       = "terraform-aws-modules/eks/aws"
  cluster_name = var.eks_cluster_name
  vpc_id       = aws_vpc.main.id
  subnets      = aws_subnet.private.*.id

  tags = local.common_tags

  node_groups = [
    {
      name             = "worker-group-1"
      iam_role_arn     = aws_iam_role.eks_node_worker_role.arn
      additional_tags  = local.common_tags
      desired_capacity = 2
      subnets          = aws_subnet.private.*.id
    }
  ]
}

resource "aws_iam_role" "eks_node_worker_role" {
  name               = "eks_node_worker_role"
  assume_role_policy = data.aws_iam_policy_document.eks_node_worker_role_policy.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "eks_node_worker_role_policy" {

  //EC2
  statement {
    sid = "EKSWorkerNodeDescribeEC2"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DescribeVpcs",
      "eks:DescribeCluster",
    ]

    resources = [
      "*",
    ]
  }

  //Container Registry
  statement {
    sid = "EKSWorkerNodePullImageFromECR"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:GetLifecyclePolicy",
      "ecr:GetLifecyclePolicyPreview",
      "ecr:ListTagsForResource",
      "ecr:DescribeImageScanFindings",
    ]

    resources = [
      "*",
    ]
  }

  //Tracing
  statement {
    sid = "EKSWorkerNodeSendXRayTrace"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries",
    ]

    resources = [
      "*",
    ]
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks_cluster.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks_cluster.cluster_id
}