data "template_file" "api_specs" {
  template = file("open-api.yaml")
}

resource "aws_api_gateway_rest_api" "main" {
  name        = "Miiingle.NET API"
  description = "The API"
  body        = data.template_file.api_specs.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

//currently, we are creating the LB outside of TF context
//once we figure out a way to run our helm charts inside as part of TF
//this is a very unsuitable workaround, this will obviously break apart
//when we start creating multiple instances of the environment
data "aws_lb" "eks_internal" {
  depends_on = [helm_release.backend]

  tags = merge(
    {
      "kubernetes.io/service-name" : "default/backend"
    },
    local.common_tags
  )
}

resource "aws_api_gateway_vpc_link" "eks_internal" {
  name        = format("%s Link", local.vpc_name)
  description = format("%s Link for API Gateway to EKS", local.vpc_name)
  target_arns = [data.aws_lb.eks_internal.arn]

  tags = local.common_tags

  lifecycle {
    ignore_changes = [
      //this is a workaround. i have no clue why this list refreshes
      target_arns
    ]
  }
}

data "aws_api_gateway_resource" "registrations" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  path        = "/registrations"
}

resource "aws_api_gateway_integration" "registrations_get" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = data.aws_api_gateway_resource.registrations.id
  http_method = "GET"

  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.eks_internal.id

  type                    = "HTTP"
  uri                     = "http://${data.aws_lb.eks_internal.dns_name}/registrations"
  integration_http_method = "GET"
}

resource "aws_api_gateway_integration_response" "registrations_get" {
  rest_api_id = aws_api_gateway_integration.registrations_get.rest_api_id
  resource_id = aws_api_gateway_integration.registrations_get.resource_id
  http_method = "GET"
  status_code = "200"
}

resource "aws_api_gateway_deployment" "root_get_integration" {
  depends_on        = [aws_api_gateway_vpc_link.eks_internal, aws_api_gateway_integration.registrations_get]
  rest_api_id       = aws_api_gateway_rest_api.main.id
  stage_name        = "prod"
  stage_description = "The Prod API"
}


