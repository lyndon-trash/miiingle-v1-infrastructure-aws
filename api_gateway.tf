//currently, we are creating the LB outside of TF context
//once we figure out a way to run our helm charts inside as part of TF
data "aws_lb" "prod" {
  name = var.eks_lb_name
}

resource "aws_api_gateway_rest_api" "main" {
  name        = "Miiingle.NET API"
  description = "The API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_vpc_link" "prod" {
  name        = format("%s Link", local.vpc_name)
  description = format("%s Link for API Gateway to EKS", local.vpc_name)
  target_arns = [data.aws_lb.prod.arn]

  tags = local.common_tags
}

