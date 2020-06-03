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
}

resource "aws_apigatewayv2_integration" "eks_internal" {
  depends_on = [helm_release.backend]

  api_id      = aws_apigatewayv2_api.main.id
  description = "Integrate to the main Backend"

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.eks_internal.id

  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = data.aws_lb_listener.eks_internal.arn
}