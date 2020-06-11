resource "aws_cognito_user_pool" "main" {
  name = "prod_users"
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "client-web"
  user_pool_id = aws_cognito_user_pool.main.id
}

resource "aws_cognito_resource_server" "resource" {
  identifier   = "https://api.miiingle.net"
  name         = "backend"
  user_pool_id = aws_cognito_user_pool.main.id

  scope {
    scope_description = "Backend Access"
    scope_name        = "backend"
  }
}