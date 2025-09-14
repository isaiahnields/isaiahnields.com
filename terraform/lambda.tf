# The filename points to a zip that will be created by the GitHub Action:
resource "aws_lambda_function" "front" {
  filename         = "../build/lambda.zip"   # relative to terraform/ directory
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_exec.arn
  handler          = "lambda_function.handler"
  runtime          = var.lambda_runtime
  source_code_hash = filebase64sha256("../build/lambda.zip")

  # Optional: set environment variables for the function
  environment {
    variables = {
      ENV = "prod"
    }
  }

  # Keep a small timeout for quick page responses
  timeout = 10
}