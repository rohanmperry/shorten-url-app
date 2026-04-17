resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend"

  tags = {
    Name        = "${var.project_name}-frontend"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  versioning_configuration {
    status = "Enabled"
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "frontend_bucket_policy" {
  statement {
    sid    = "AllowCloudFrontAccess"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.frontend.arn}/*"]
    # Give access only to CF distribution in our account.
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id
  policy = data.aws_iam_policy_document.frontend_bucket_policy.json
}

# Upload the index.html object, if it has changed.
#
resource "aws_s3_object" "frontend_index" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "index.html"
  source       = "${path.root}/../src/frontend/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.root}/../src/frontend/index.html")

  depends_on = [aws_s3_bucket.frontend]

  tags = {
    Name        = "${var.project_name}-frontend-index"
    Environment = var.environment
  }
}

# Upload the 404.html object, if it has changed.
#
resource "aws_s3_object" "frontend_404" {
  bucket       = aws_s3_bucket.frontend.id
  key          = "404.html"
  source       = "${path.root}/../src/frontend/404.html"
  content_type = "text/html"
  etag         = filemd5("${path.root}/../src/frontend/404.html")

  depends_on = [aws_s3_bucket.frontend]

  tags = {
    Name        = "${var.project_name}-frontend-404"
    Environment = var.environment
  }
}

data "terraform_remote_state" "infra" {
  backend = "s3"
  config = {
    bucket = "my-projects-tfstate"
    key    = "shorten-url/terraform.tfstate"
    region = "us-east-1"
  }
}

# Invalidate CF cache if files change
#
resource "null_resource" "cloudfront_invalidation" {
  triggers = {
    index_etag     = aws_s3_object.frontend_index.etag
    not_found_etag = aws_s3_object.frontend_404.etag
  }

  provisioner "local-exec" {
    command = <<EOT
      aws cloudfront create-invalidation \
        --distribution-id ${data.terraform_remote_state.infra.outputs.cloudfront_distribution_id} \
        --paths "/index.html" "/404.html"
    EOT
  }
}
