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

# 2. Disable block public access settings so the PDF can be viewed publicly
resource "aws_s3_bucket_public_access_block" "allow_public" {
  bucket = aws_s3_bucket.pdf_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 3. Apply a bucket policy to allow anyone to read objects inside it
resource "aws_s3_bucket_policy" "public_read_policy" {
  depends_on = [aws_s3_bucket_public_access_block.allow_public]
  bucket     = aws_s3_bucket.pdf_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.pdf_bucket.arn}/*"
      }
    ]
  })
}

# 4. Upload the PDF file from your Git repository to the S3 bucket
resource "aws_s3_object" "pdf_upload" {
  bucket       = aws_s3_bucket.pdf_bucket.id
  key          = "Resume.pdf"                 # The name the file will have in S3
  source       = "${path.module}/Resume.pdf" # Local path in repo
  content_type = "application/pdf"            # Ensures it opens in browser instead of downloading
}
