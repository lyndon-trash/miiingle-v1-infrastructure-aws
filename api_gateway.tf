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

resource "aws_api_gateway_stage" "prod" {
  stage_name    = "prod"
  rest_api_id   = aws_api_gateway_rest_api.main.id
  deployment_id = aws_api_gateway_deployment.prod.id
}

resource "aws_api_gateway_deployment" "prod" {
  depends_on  = [aws_api_gateway_integration.registrations_get_integration]
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = "prod"
}

resource "aws_api_gateway_resource" "registrations" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "registrations"
}

resource "aws_api_gateway_method" "registrations_get" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.registrations.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "registrations_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.registrations.id
  http_method = aws_api_gateway_method.registrations_get.http_method

  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.prod.id

  type                    = "HTTP"
  uri                     = "http://${data.aws_lb.prod.dns_name}/registrations"
  integration_http_method = "GET"
}
