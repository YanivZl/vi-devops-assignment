################################################################################
# General
################################################################################

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "organization" {
  description = "The name of environment infrastructure, this name is used for vpc, DocDB and eks cluster."
  type        = string
  default     = "vi"
}

variable "name" {
  description = "The name of environment infrastructure, this name is used for vpc, DocDB and eks cluster."
  type        = string
  default     = "yanivzl"
}

################################################################################
# ECR
################################################################################

variable "ecr_repositories" {
  description = "The suffixes of the name of ECR repositories. Will loop over this list and create repositories"
  type        = set(string)
  default = [
    "service1",
    "service2"
  ]
}

################################################################################
# IAM OIDC for Github Actions 
################################################################################

variable "github_organization_name" {
  description = "The name of the github account to provide permissions to AWS IAM using OIDC"
  type        = string
  default     = "YanivZl"
}