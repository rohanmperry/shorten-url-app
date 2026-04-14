provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "create_short_url" {
  name                 = "${var.project_name}/create-short-url"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}/create-short-url"
    Environment = var.environment
  }
}

resource "aws_ecr_repository" "redirect" {
  name                 = "${var.project_name}/redirect"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}/redirect"
    Environment = var.environment
  }
}

resource "aws_ecr_lifecycle_policy" "create_short_url" {
  repository = aws_ecr_repository.create_short_url.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 3 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
      action = { type = "expire" }
    }]
  })
}

resource "aws_ecr_lifecycle_policy" "redirect" {
  repository = aws_ecr_repository.redirect.name
  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 3 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
      action = { type = "expire" }
    }]
  })
}
