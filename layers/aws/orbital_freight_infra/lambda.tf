############################
# Lambda (container image) + Alias for Blue/Green
############################
resource "aws_lambda_function" "svc" {
    function_name = "${var.project_info.name}-svc"
    role = aws_iam_role.lambda_exec.arn
    package_type = "Image"
    image_uri = var.lambda.image_uri
    publish      = true  

    architectures = ["x86_64"]

    memory_size = var.lambda.memory_mb
    timeout = var.lambda.timeout_seconds

    environment {
        variables = {
            SUPER_SECRET_TOKEN_SECRET_ARN  = aws_secretsmanager_secret.super_token.arn
            SUPER_SECRET_TOKEN_SECRET_NAME = aws_secretsmanager_secret.super_token.name
        }
    }

    # Nice error message if the image does not exist yet
    lifecycle {
        precondition {
            condition = length(data.aws_ecr_image.selected.image_digest) > 0
            error_message = "ECR image with tag '${var.image_tag}' not found in ${aws_ecr_repository.podinfo.name}. Build & push first, then re-apply."
        }
        ignore_changes = [image_uri, qualified_arn, qualified_invoke_arn, version]
    }
}

# Publish a numbered version on each apply (CI will typically run this after pushing a new image)
resource "aws_lambda_alias" "prod" {
    name = "prod"
    description = "Alias for blue/green"
    function_name = aws_lambda_function.svc.function_name
    function_version = aws_lambda_function.svc.version

    lifecycle {
        ignore_changes = [function_version, routing_config]  # <— evita drift quando CodeDeploy sposta l’alias
   }
}