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