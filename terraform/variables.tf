variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for namespacing"
  type        = string
  default     = "shorten-url"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
