//data "template_file" "api_specs" {
//  template = file("open-api.yaml")
//}

resource "aws_apigatewayv2_api" "main" {
  name          = "Miiingle.NET API"
  description   = "The API"
  protocol_type = "HTTP"
  tags          = local.common_tags
}

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

resource "aws_apigatewayv2_vpc_link" "eks_internal" {
  name               = format("%s Link", local.vpc_name)
  security_group_ids = [aws_default_security_group.default.id]
  subnet_ids         = aws_subnet.private.*.id

  tags = local.common_tags
}

resource "aws_apigatewayv2_route" "eks_internal" {
  depends_on = [helm_release.backend]

  api_id         = aws_apigatewayv2_api.main.id
  route_key      = "ANY /"
  operation_name = "Forward API Calls to EKS"
  target         = format("integrations/%s", aws_apigatewayv2_integration.eks_internal.id)
}

resource "aws_apigatewayv2_integration" "eks_internal" {
  depends_on = [helm_release.backend]

  api_id      = aws_apigatewayv2_api.main.id
  description = "Integrate to the main Backend"

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.eks_internal.id

  integration_type     = "HTTP_PROXY"
  integration_method   = "ANY"
  integration_uri      = data.aws_lb_listener.eks_internal.arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "prod"
  description = "Production API"
  auto_deploy = true

  //for reference:
  //https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-mapping-template-reference.html#context-variable-reference
  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_logs.arn
    format = jsonencode(
      {
        httpMethod     = "$context.httpMethod"
        stage          = "$context.stage"
        path           = "$context.path"
        ip             = "$context.identity.sourceIp"
        protocol       = "$context.protocol"
        requestId      = "$context.requestId"
        requestTime    = "$context.requestTime"
        responseLength = "$context.responseLength"
        status         = "$context.status"
      }
    )
  }

  default_route_settings {
    logging_level            = "OFF"
    data_trace_enabled       = false
    detailed_metrics_enabled = false
    throttling_burst_limit   = 100
    throttling_rate_limit    = 100
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_log_group" "api_logs" {
  name              = "API-Gateway-Execution-Logs_${aws_apigatewayv2_api.main.id}/prod"
  retention_in_days = 7
}