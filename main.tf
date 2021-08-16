provider "aws" {
  region                  = "ap-southeast-1"
  shared_credentials_file = "/Users/mac/.aws/credentials"
  profile                 = "skg"
}


module "lambda_redirector" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  function_name = "RedirectorLambda"
  description   = "Redirect lambda function with Terraform"
  handler       = "index.handler"
  runtime       = var.lambda_runtime
  source_path   = "./src/lambdas/redirector"

  environment_variables = {
    "SERVERLESS_PLATFORM" = "Terraform"
  }

  tags = {
    "Name" = "RedirectorLambda"
    "App"  = "Serverless Url Shortener"
  }
}

module "lambda_shortener" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  function_name = "ShortenerLambda"
  description   = "Shortener lambda function with Terraform"
  handler       = "index.handler"
  runtime       = var.lambda_runtime
  source_path   = "./src/lambdas/shortener"

  environment_variables = {
    "SERVERLESS_PLATFORM" = "Terraform"
  }

  tags = {
    "Name" = "ShortenerLambda"
    "App"  = "Serverless Url Shortener"
  }
}
