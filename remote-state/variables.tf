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