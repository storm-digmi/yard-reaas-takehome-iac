############################
# ECR — Repository to store Lambda container images
############################
resource "aws_ecr_repository" "podinfo" {
    name = "${var.project_info.name}-repo"
    image_tag_mutability = "MUTABLE"
    force_delete = true

    image_scanning_configuration {
        scan_on_push = true
    }
}

# Resolve the image by TAG and get its immutable DIGEST (fails if TAG not found)
# This makes Terraform wait until an image with var.image_tag exists.
data "aws_ecr_image" "selected" {
    repository_name = aws_ecr_repository.podinfo.name
    image_tag = var.image_tag
}