resource "aws_cognito_user_pool" "main" {
  name = "prod_users"
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "client-web"
  user_pool_id = aws_cognito_user_pool.main.id
}