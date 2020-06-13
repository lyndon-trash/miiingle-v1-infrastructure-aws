data "aws_route53_zone" "zone" {
  name         = var.domain_base
  private_zone = false
}

resource "aws_acm_certificate" "api" {
  domain_name       = "api.${var.domain_base}"
  validation_method = "DNS"

  tags = merge(
    {
      Name = "Cert api.${var.domain_base}"
    },
    local.common_tags
  )
}

resource "aws_route53_record" "cert_validation_api" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = aws_acm_certificate.api.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.api.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.api.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_apigatewayv2_domain_name" "api" {
  domain_name = aws_acm_certificate.api.domain_name

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.api.arn
    endpoint_type   = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "api" {
  domain_name = aws_apigatewayv2_domain_name.api.id
  api_id      = aws_apigatewayv2_api.main.id
  stage       = aws_apigatewayv2_stage.prod.id
}

resource "aws_route53_record" "api_dns_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "api"
  type    = "CNAME"
  records = aws_apigatewayv2_domain_name.api.domain_name_configuration.*.target_domain_name
  ttl     = 60
}

resource "aws_acm_certificate" "web_app" {
  domain_name       = "app.${var.domain_base}"
  validation_method = "DNS"

  tags = merge(
    {
      Name = "Cert app.${var.domain_base}"
    },
    local.common_tags
  )
}

resource "aws_route53_record" "cert_validation_web_app" {
  zone_id = data.aws_route53_zone.zone.zone_id
  type    = aws_acm_certificate.web_app.domain_validation_options.0.resource_record_type
  name    = aws_acm_certificate.web_app.domain_validation_options.0.resource_record_name
  records = [aws_acm_certificate.web_app.domain_validation_options.0.resource_record_value]
  ttl     = 60
}

resource "aws_route53_record" "web_app_dns_record" {
  zone_id = data.aws_route53_zone.zone.zone_id
  name    = "app"
  type    = "CNAME"
  records = [aws_cloudfront_distribution.frontend_webapp_distribution.domain_name]
  ttl     = 60
}