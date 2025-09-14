variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-west-2"
}

variable "lambda_function_name" {
  description = "isaiahnields.com frontend lambda function"
  type        = string
  default     = "isaiahnields-com-frontend"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

# If you own isaiahnields.com and want to create Route53 records:
variable "hosted_zone_id" {
  description = "Optional Route53 hosted zone ID for isaiahnields.com"
  type        = string
  default     = "Z003292815IEA5D8Z77S0"
}

variable "domain_name" {
  description = "Optional base domain to create record for (e.g. isaiahnields.com)"
  type        = string
  default     = "isaiahnields.com"
}