terraform {
  required_version = ">= 1.7"

  backend "s3" {
    bucket         = "vi-yanivzl-tfstate"
    key            = "state/setup.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "vi-yanivzl-tfstate-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}