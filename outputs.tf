# API Gateway
output "apigatewayv2_api_api_endpoint" {
  description = "The URI of the API"
  value       = module.api_gateway.apigatewayv2_api_api_endpoint
}

output "dynamodb_table_name" {
  description = "The name of the DynamoDB Table"
  value       = aws_dynamodb_table.this.name
}
