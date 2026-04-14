output "create_short_url_repository_url" {
  description = "ECR repository URL for create_short_url"
  value       = aws_ecr_repository.create_short_url.repository_url
}

output "redirect_repository_url" {
  description = "ECR repository URL for redirect"
  value       = aws_ecr_repository.redirect.repository_url
}
