data "aws_caller_identity" "current" {}

#### lambda ####
data "aws_iam_policy_document" "lambda_assume" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
        type = "Service"
        identifiers = ["lambda.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "lambda_exec" {
    name = "${var.project_info.name}-lambda-exec"
    assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

# Basic logs
resource "aws_iam_role_policy_attachment" "lambda_basic" {
    role = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}


#### code deploy ####
data "aws_iam_policy_document" "codedeploy_assume" {
    statement {
        actions = ["sts:AssumeRole"]
        principals {
            type = "Service"
            identifiers = ["codedeploy.amazonaws.com"]
        }
    }
}

resource "aws_iam_role" "codedeploy_service" {
    name = "${var.project_info.name}-codedeploy-role"
    assume_role_policy = data.aws_iam_policy_document.codedeploy_assume.json
}

resource "aws_iam_role_policy_attachment" "codedeploy_managed" {
    role = aws_iam_role.codedeploy_service.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRoleForLambda"
}


#### secrets manager ####
data "aws_iam_policy_document" "lambda_secrets_read" {
  statement {
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret"
    ]
    resources = [aws_secretsmanager_secret.super_token.arn]
  }
}

resource "aws_iam_policy" "lambda_secrets_read" {
  name   = "${var.project_info.name}-lambda-secrets-read"
  policy = data.aws_iam_policy_document.lambda_secrets_read.json
}

resource "aws_iam_role_policy_attachment" "lambda_attach_secrets_read" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_secrets_read.arn
}

