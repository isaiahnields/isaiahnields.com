output "lambda_function_name" {
  value = aws_lambda_function.front.function_name
}

output "api_endpoint" {
  value = aws_apigatewayv2_api.http.api_endpoint
  description = "Invoke this URL to reach the site (e.g. https://{id}.execute-api.{region}.amazonaws.com)"
}
