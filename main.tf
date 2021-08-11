provider "aws" {
  region = "ap-southeast-1"
  shared_credentials_file = "/Users/mac/.aws/credentials"
  profile = "skg"
}

resource "aws_apigatewayv2_api" "shortener" {
  name = "shortener-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "stage" {
  id = aws_apigatewayv2_api.shortener.id
  name = "dev"
}