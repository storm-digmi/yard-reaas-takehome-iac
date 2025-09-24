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
description = "test to check pipe"
default = {}
}