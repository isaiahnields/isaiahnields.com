output "pdf_url" {
  description = "The public global CDN URL of your hosted PDF file"
  value       = "https://${aws_cloudfront_distribution.s3_distribution.domain_name}/${aws_s3_object.pdf_upload.key}"
}