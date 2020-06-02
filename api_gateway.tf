//data "template_file" "api_specs" {
//  template = file("open-api.yaml")
//}

resource "aws_apigatewayv2_api" "main" {
  name          = "Miiingle.NET API"
  description   = "The API"
  protocol_type = "HTTP"
  tags          = local.common_tags
}

//resource "aws_api_gateway_rest_api" "main" {
//  name        = "Miiingle.NET API"
//  description = "The API"
//  body        = data.template_file.api_specs.rendered
//
//  endpoint_configuration {
//    types = ["REGIONAL"]
//  }
//}

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

data "aws_lb_listener" "eks_internal" {
  load_balancer_arn = data.aws_lb.eks_internal.arn
  port              = 80
}

//sometime this resource gets problematic, this happens when aws_lb.eks_internal is not yet ready
//TODO: create this resource only after aws_lb is ready to serve
//resource "aws_api_gateway_vpc_link" "eks_internal" {
//  name        = format("%s Link", local.vpc_name)
//  description = format("%s Link for API Gateway to EKS", local.vpc_name)
//  target_arns = [data.aws_lb.eks_internal.arn]
//
//  tags = local.common_tags
//
//  lifecycle {
//    ignore_changes = [
//      //this is a workaround. i have no clue why this list refreshes
//      target_arns
//    ]
//  }
//}
resource "aws_apigatewayv2_vpc_link" "eks_internal" {
  name               = format("%s Link", local.vpc_name)
  security_group_ids = [aws_default_security_group.default.id]
  subnet_ids         = aws_subnet.private.*.id

  tags = local.common_tags
}

//data "aws_api_gateway_resource" "registrations" {
//  rest_api_id = aws_api_gateway_rest_api.main.id
//  path        = "/registrations"
//}
resource "aws_apigatewayv2_route" "registrations_get" {
  depends_on = [helm_release.backend]

  api_id         = aws_apigatewayv2_api.main.id
  route_key      = "GET /registrations"
  operation_name = "List of Registrations"
}

//resource "aws_api_gateway_integration" "registrations_get" {
//  rest_api_id = aws_api_gateway_rest_api.main.id
//  resource_id = data.aws_api_gateway_resource.registrations.id
//  http_method = "GET"
//
//  connection_type = "VPC_LINK"
//  connection_id   = aws_api_gateway_vpc_link.eks_internal.id
//
//  type                    = "HTTP"
//  uri                     = "http://${data.aws_lb.eks_internal.dns_name}/registrations"
//  integration_http_method = "GET"
//}
resource "aws_apigatewayv2_integration" "registrations_get" {
  depends_on = [helm_release.backend]

  api_id      = aws_apigatewayv2_api.main.id
  description = "List all the registration"

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.eks_internal.id

  integration_type   = "HTTP_PROXY"
  integration_method = "GET"
  integration_uri    = data.aws_lb_listener.eks_internal.arn
  //  integration_uri    = "http://${data.aws_lb.eks_internal.dns_name}/registrations"
}

//resource "aws_api_gateway_integration_response" "registrations_get" {
//  rest_api_id = aws_api_gateway_integration.registrations_get.rest_api_id
//  resource_id = aws_api_gateway_integration.registrations_get.resource_id
//  http_method = "GET"
//  status_code = "200"
//}

//resource "aws_api_gateway_deployment" "main" {
//  depends_on        = [aws_api_gateway_integration.registrations_get]
//  rest_api_id       = aws_api_gateway_rest_api.main.id
//  stage_name        = "prod"
//  stage_description = "The Prod API"
//
//  lifecycle {
//    create_before_destroy = true
//  }
//}

//resource "aws_api_gateway_stage" "prod" {
//  deployment_id = aws_api_gateway_deployment.main.id
//  rest_api_id = aws_api_gateway_deployment.main.rest_api_id
//  stage_name = "prod"
//}