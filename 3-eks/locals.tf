locals {
  num_of_subnets = min(length(data.aws_availability_zones.available.names), 2)
  azs            = slice(data.aws_availability_zones.available.names, 0, local.num_of_subnets)

  tags = {
    Environment = var.environment
  }

  eks_auth_users = toset([
    "arn:aws:iam::851725552187:user/yanivzlotnik1@gmail.com",
  ])
}