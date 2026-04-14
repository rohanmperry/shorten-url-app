terraform {
  required_version = "~> 1.14"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "my-projects-tfstate"
    key          = "shorten-url-app/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
  }
}
