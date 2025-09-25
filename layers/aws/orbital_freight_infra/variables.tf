############################
# Variables
############################

variable "project_info" {
description = "Project Info"
default = {}
}

variable "aws_region" {
description = "AWS region"
type = string
}

variable "lambda" {
description = "Lambda Info"
default = {}
}

variable "testvar" {
description = "test to check pipeline"
default = {}
}


variable "image_tag" {
description = "ECR image tag to deploy (must exist). Use 'latest' or a Git SHA."
type = string
default = "latest"
}
