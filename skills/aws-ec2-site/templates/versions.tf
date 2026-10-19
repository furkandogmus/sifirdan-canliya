terraform {
  # use_lockfile (S3 native kilit) 1.10 ile geldi.
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      project    = var.project
      managed-by = "terraform"
    }
  }
}
