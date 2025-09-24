############################
# Lambda (container image) + Alias for Blue/Green
############################
resource "aws_lambda_function" "svc" {
function_name = "${var.project_info.name}-svc"
    role = aws_iam_role.lambda_exec.arn
    package_type = "Image"
    image_uri = var.lambda.image_uri

    architectures = ["x86_64"]

    memory_size = var.lambda.memory_mb
    timeout = var.lambda.timeout_seconds

    environment {
        variables = {
        SECRET_NAME = aws_secretsmanager_secret.api_key.name
        }
    }
}

# Publish a numbered version on each apply (CI will typically run this after pushing a new image)
resource "aws_lambda_alias" "prod" {
    name = "alias-test"
    description = "Alias for blue/green"
    function_name = aws_lambda_function.svc.function_name
    function_version = aws_lambda_function.svc.version
}