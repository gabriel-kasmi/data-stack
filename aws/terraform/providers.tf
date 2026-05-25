
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.83.0"
    }
  }

  backend "s3" {
    bucket = "my-terraform-state-bucket"
    key    = "state"
    region = "eu-west-1"
  }
}

provider "aws" {
  region = var.region
}
