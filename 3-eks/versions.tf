terraform {
  required_version = ">= 1.7"

  backend "s3" {
    bucket         = "vi-yanivzl-tfstate"
    key            = "state/eks.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "vi-yanivzl-tfstate-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.49"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.13"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.30"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }
  }
}