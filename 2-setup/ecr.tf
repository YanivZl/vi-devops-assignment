resource "aws_ecr_repository" "my_ecr_repository" {
  for_each = var.ecr_repositories

  name = "${var.organization}-${var.name}-${each.value}"

  image_tag_mutability = "IMMUTABLE"
}