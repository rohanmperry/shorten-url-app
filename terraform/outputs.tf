output "create_short_url_repository_url" {
  description = "ECR repository URL for create_short_url"
  value       = aws_ecr_repository.create_short_url.repository_url
}

output "redirect_repository_url" {
  description = "ECR repository URL for redirect"
  value       = aws_ecr_repository.redirect.repository_url
}

output "frontend_bucket_name" {
  description = "S3 bucket name for frontend — used by CloudFront in shorten-url-infra"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_bucket_regional_domain" {
  description = "S3 regional domain name — used as CloudFront origin"
  value       = aws_s3_bucket.frontend.bucket_regional_domain_name
}
