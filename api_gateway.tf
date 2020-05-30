resource "aws_api_gateway_rest_api" "main" {
  name        = "Miiingle.NET API"
  description = "The API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}