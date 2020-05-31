//currently, we are creating the LB outside of TF context
//once we figure out a way to run our helm charts inside as part of TF
//this is a very unsuitable workaround, this will obviously break apart
//when we start creating multiple instances of the environment
data "aws_lb" "prod" {
  tags = {
    "kubernetes.io/service-name": "default/backend"
  }
}

resource "aws_api_gateway_rest_api" "main" {
  name        = "Miiingle.NET API"
  description = "The API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_vpc_link" "prod" {
  depends_on = [helm_release.backend]

  name        = format("%s Link", local.vpc_name)
  description = format("%s Link for API Gateway to EKS", local.vpc_name)
  target_arns = [data.aws_lb.prod.arn]

  tags = local.common_tags
}

resource "aws_api_gateway_method" "root_get" {
  authorization = "NONE"
  http_method = "GET"
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  rest_api_id = aws_api_gateway_rest_api.main.id
}

resource "aws_api_gateway_integration" "root_get_integration" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_rest_api.main.root_resource_id
  http_method = "GET"

  connection_type         = "VPC_LINK"
  connection_id           = aws_api_gateway_vpc_link.prod.id

  type                    = "HTTP"
  uri                     = "http://${data.aws_lb.prod.dns_name}/"
  integration_http_method = "GET"
}

resource "aws_api_gateway_deployment" "prod" {
  depends_on  = [aws_api_gateway_integration.root_get_integration]
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name  = "prod"
}


