resource "aws_cognito_user_pool" "main" {
  name = "prod_users"
}

resource "aws_cognito_user_pool_domain" "main" {
  depends_on      = [aws_route53_record.apex]
  user_pool_id    = aws_cognito_user_pool.main.id
  domain          = aws_acm_certificate.cognito_domain.domain_name
  certificate_arn = aws_acm_certificate.cognito_domain.arn
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "client-web"
  user_pool_id = aws_cognito_user_pool.main.id

  prevent_user_existence_errors = "LEGACY"
  read_attributes               = []
  refresh_token_validity        = 30

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]

  supported_identity_providers = ["COGNITO"]

  allowed_oauth_scopes = [
    "aws.cognito.signin.user.admin",
    "email",
    "https://api.${var.domain_base}/backend",
    "openid",
    "phone",
    "profile",
  ]

  explicit_auth_flows = [
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]

  logout_urls   = ["https://app.${var.domain_base}/logout", "https://localhost:4200/logout"]
  callback_urls = ["https://app.${var.domain_base}/auth", "https://localhost:4200/auth"]
}

resource "aws_cognito_resource_server" "resource" {
  identifier   = "https://api.${var.domain_base}"
  name         = "backend"
  user_pool_id = aws_cognito_user_pool.main.id

  scope {
    scope_description = "Backend Access"
    scope_name        = "backend"
  }
}