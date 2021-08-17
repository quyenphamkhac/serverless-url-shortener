provider "aws" {
  region                  = "ap-southeast-1"
  shared_credentials_file = "/Users/mac/.aws/credentials"
  profile                 = "skg"
}


locals {
  domain_name        = "ehr.sk-global.io"
  acm_domain_name    = "*.ehr.sk-global.io"
  api_v2_domain_name = "shrinkurl.ehr.sk-global.io"
  subdomain          = "shrinkurl"
}
###################
# ACM
###################
data "aws_acm_certificate" "this" {
  domain = local.acm_domain_name
  types  = ["AMAZON_ISSUED"]
}

data "aws_route53_zone" "this" {
  name = local.domain_name
}

###################
# Cloudwatch Logs
###################
resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.env_stage}-${var.service_name}"
  retention_in_days = 7

  tags = {
    "Name" = "${var.env_stage}-${var.service_name} logs"
    "App"  = var.app_name
  }
}

###################
# DynamoDB
###################
resource "aws_dynamodb_table" "this" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "Id"

  attribute {
    name = "Id"
    type = "S"
  }

  ttl {
    attribute_name = "TTL"
    enabled        = true
  }

  tags = {
    "Name"        = var.table_name
    "Environment" = var.env_stage
    "App"         = var.app_name
  }
}

###################
# HTTP API Gateway
###################
module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "${var.env_stage}-${var.service_name}-http-api"
  description   = "${var.env_stage} environment for ${var.service_name} HTTP API Gateway"
  protocol_type = "HTTP"

  cors_configuration = {
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"]
    allow_methods = ["*"]
    allow_origins = ["*"]
  }

  domain_name                 = local.api_v2_domain_name
  domain_name_certificate_arn = data.aws_acm_certificate.this.arn

  default_stage_access_log_destination_arn = aws_cloudwatch_log_group.this.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"

  default_route_settings = {
    detailed_metrics_enabled = true
    throttling_burst_limit   = 100
    throttling_rate_limit    = 100
  }

  integrations = {
    "POST /shrink_url" = {
      lambda_arn             = module.lambda_shortener.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }

    "GET /{key}" = {
      lambda_arn             = module.lambda_redirector.lambda_function_arn
      payload_format_version = "2.0"
      timeout_milliseconds   = 12000
    }
  }

  tags = {
    "Name" = "${var.env_stage}-${var.service_name}-http-api"
    "App"  = var.app_name
  }
}


###################
# Lambda Function
###################

module "lambda_redirector" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  function_name = "RedirectorLambda"
  description   = "Redirect lambda function with Terraform"
  handler       = "index.handler"
  runtime       = var.lambda_runtime
  memory_size   = var.memory_size
  source_path   = "./src/lambdas/redirector"

  publish = true

  allowed_triggers = {
    "APIGatewayAny" = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*"
    }
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = [aws_dynamodb_table.this.arn, "${aws_dynamodb_table.this.arn}/*"]
    }
  }

  environment_variables = {
    "TABLE_NAME"          = aws_dynamodb_table.this.name
    "SERVERLESS_PLATFORM" = "Terraform"
  }

  tags = {
    "Name" = "RedirectorLambda"
    "App"  = var.app_name
  }
}

module "lambda_shortener" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "~> 2.0"

  function_name = "ShortenerLambda"
  description   = "Shortener lambda function with Terraform"
  handler       = "index.handler"
  runtime       = var.lambda_runtime
  memory_size   = var.memory_size
  source_path   = "./src/lambdas/shortener"

  publish = true

  allowed_triggers = {
    "APIGatewayAny" = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*"
    }
  }

  attach_policy_statements = true
  policy_statements = {
    dynamodb = {
      effect    = "Allow",
      actions   = ["dynamodb:*"],
      resources = [aws_dynamodb_table.this.arn, "${aws_dynamodb_table.this.arn}/*"]
    }
  }

  environment_variables = {
    "TABLE_NAME"          = aws_dynamodb_table.this.name
    "SERVERLESS_PLATFORM" = "Terraform"
  }

  tags = {
    "Name" = "ShortenerLambda"
    "App"  = var.app_name
  }
}

##########
# Route53
##########
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.this.zone_id
  name    = local.subdomain
  type    = "A"
  alias {
    name                   = module.api_gateway.apigatewayv2_domain_name_configuration[0].target_domain_name
    zone_id                = module.api_gateway.apigatewayv2_domain_name_configuration[0].hosted_zone_id
    evaluate_target_health = false
  }
}
