import {
  to = aws_s3_bucket.pdf_bucket
  id = "isaiahnields.com"
}

import {
  to = aws_cloudfront_origin_access_control.oac
  id = "E1DDXL2P03HPQX"
}

import {
  to = aws_cloudfront_distribution.s3_distribution
  id = "E1ZHTV5XY3AP97"
}

import {
  to = aws_route53_record.cloudfront_alias
  id = "Z003292815IEA5D8Z77S0_isaiahnields.com_A"
}

# 1. Create a uniquely named S3 bucket
resource "aws_s3_bucket" "pdf_bucket" {
  bucket = "isaiahnields.com" # Must be globally unique
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
  name                              = "isaiahnields.com.s3.us-east-1.amazonaws.com-mfx8wpp4wgd"
  description                       = "CloudFront access control for private PDF S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


# 4. Attach a bucket policy allowing ONLY your CloudFront distribution to read from S3
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
          Service = "cloudfront.amazonaws.com"
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


# 5. Upload the PDF
resource "aws_s3_object" "pdf_upload" {
  bucket       = aws_s3_bucket.pdf_bucket.id
  key          = "Resume.pdf"                 # The name the file will have in S3
  source       = "Resume.pdf" # Local path in repo
  content_type = "application/pdf"            # Ensures it opens in browser instead of downloading
}

resource "aws_s3_object" "favicon_upload" {
  bucket       = aws_s3_bucket.pdf_bucket.id
  key          = "favicon.ico"
  source       = "favicon.ico"
  content_type = "image/vnd.microsoft.icon"
}


# 1. Fetch your existing Route 53 Hosted Zone
data "aws_route53_zone" "primary" {
  name         = "isaiahnields.com." # Change to your domain name (keep trailing dot)
  private_zone = false
}

# 2. Request a free public SSL/TLS Certificate
resource "aws_acm_certificate" "cert" {
  provider          = aws.us_east_1 # Enforces creation in us-east-1
  domain_name       = "isaiahnields.com" # Your target custom subdomain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# 3. Create the DNS Record required by AWS to validate you own the domain
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.primary.zone_id
}

# 4. Triggers the actual validation process
resource "aws_acm_certificate_validation" "cert" {
  provider                = aws.us_east_1
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# 5. Updated CloudFront Distribution
resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "CDN for public PDF hosting"
  default_root_object = "Resume.pdf"

  # ADD YOUR CUSTOM DOMAIN ALIAS HERE
  aliases = ["isaiahnields.com"]

  origin {
    domain_name              = aws_s3_bucket.pdf_bucket.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.pdf_bucket.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.pdf_bucket.id}"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # UPDATE VIEWER CERTIFICATE TO USE YOUR NEW ACM CERTIFICATE
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate_validation.cert.certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

resource "terraform_data" "always_invalidate" {
  input = timestamp() # Forces the resource to update on every run

  provisioner "local-exec" {
    command = "aws cloudfront create-invalidation --distribution-id ${aws_cloudfront_distribution.s3_distribution.id} --paths '/*'"
  }
}

# 6. Point your Custom Subdomain to CloudFront using a Route 53 A-Record
resource "aws_route53_record" "cloudfront_alias" {
  zone_id = data.aws_route53_zone.primary.zone_id
  name    = "isaiahnields.com"
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.s3_distribution.domain_name
    zone_id                = aws_cloudfront_distribution.s3_distribution.hosted_zone_id
    evaluate_target_health = false
  }
}


