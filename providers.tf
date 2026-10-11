terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" # Replace with your preferred AWS region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}