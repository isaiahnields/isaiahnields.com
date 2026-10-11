import {
  to = aws_s3_bucket.pdf_bucket
  id = "isaiahnields.com"
}

# 1. Create a uniquely named S3 bucket
resource "aws_s3_bucket" "pdf_bucket" {
  bucket = "isaiahnields.com" # Must be globally unique
}

output "bucket_name" {
  value       = aws_s3_bucket.pdf_bucket.id
  description = "The name of the S3 bucket."
}


# 2. Keep public access strictly blocked at the S3 level
resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket = aws_s3_bucket.pdf_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# 3. Create an Origin Access Control (OAC) to let CloudFront talk to S3
resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-pdf-oac"
  description                       = "CloudFront access control for private PDF S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# 4. Create the CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for public PDF hosting"
  default_root_object = "Resume.pdf" # Optional: typing the base domain opens the PDF directly

  # Point CloudFront to your S3 bucket
  origin {
    domain_name              = aws_s3_bucket.pdf_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.pdf_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  # Configure how files are served and cached
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.pdf_bucket.id}"
    viewer_protocol_policy = "redirect-to-https" # Enforces security

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600     # Caches the PDF for 1 hour
    max_ttl     = 86400
  }

  # Optimize distribution locations (PriceClass_100 uses NA and Europe networks only, keeping costs low)
  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none" # Accessible globally
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

# 5. Attach a bucket policy allowing ONLY your CloudFront distribution to read from S3
resource "aws_s3_bucket_policy" "allow_cloudfront" {
  depends_on = [aws_s3_bucket_public_access_block.block_public]
  bucket     = aws_s3_bucket.pdf_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "://amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.pdf_bucket.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}


# 6. Upload the PDF
resource "aws_s3_object" "pdf_upload" {
  bucket       = aws_s3_bucket.pdf_bucket.id
  key          = "Resume.pdf"                 # The name the file will have in S3
  source       = "${path.module}/Resume.pdf" # Local path in repo
  content_type = "application/pdf"            # Ensures it opens in browser instead of downloading
}
