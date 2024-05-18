################################################################################
# General
################################################################################

variable "name" {
  description = "The name of environment infrastructure, this name is used for vpc and eks cluster."
  type        = string
  default     = "vi-yanivzl"
}

variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment of the deployment - just for tags"
  type        = string
  default     = "Development"
}

################################################################################
# VPC
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}



################################################################################
# DocumentDB
################################################################################

variable "docdb_cluster_size" {
  description = "Number of DB instances to create in the cluster"
  type        = number
  default     = 1
}

variable "docdb_master_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "Vi_admin"
}

variable "docdb_master_password" {
  description = "Password for the master DB user."
  type        = string
  default     = "Vi_123456"
}

################################################################################
# Cluster
################################################################################

variable "eks_cluster_version" {
  description = "The Version of Kubernetes to deploy"
  type        = string
  default     = "1.29"
}

# Intial node group configuration

variable "eks_intial_node_group_name" {
  description = "node groups name"
  type        = string
  default     = "managed-node-group"
}

variable "eks_intial_node_group_min_size" {
  description = "Min size of the initial node group"
  type        = number
  default     = 1
}

variable "eks_intial_node_group_max_size" {
  description = "Max size of the initial node group"
  type        = number
  default     = 4
}

variable "eks_intial_node_group_desired_size" {
  description = "Desired size of the initial node group"
  type        = number
  default     = 2
}
