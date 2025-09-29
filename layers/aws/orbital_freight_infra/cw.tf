############################
# CloudWatch: Alarm for Lambda Errors + dashboard
############################
resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
    alarm_name = "${var.project_info.name}-lambda-errors"
    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods = 1
    metric_name = "Errors"
    namespace = "AWS/Lambda"
    period = 60
    statistic = "Sum"
    threshold = 1
    treat_missing_data = "notBreaching"

    dimensions = {
        FunctionName = aws_lambda_function.svc.function_name
        Resource = "${aws_lambda_function.svc.function_name}:${aws_lambda_alias.prod.name}"
    }
}

resource "aws_cloudwatch_dashboard" "main" {
    dashboard_name = "${var.project_info.name}-dashboard"
    dashboard_body = jsonencode({
        widgets = [
            {
                type = "metric",
                x = 0,
                y = 0,
                width = 12,
                height = 6,
                properties = {
                title = "Lambda Invocations / Errors (${aws_lambda_function.svc.function_name})",
                region = var.aws_region,
                metrics = [
                ["AWS/Lambda", "Invocations", "FunctionName", aws_lambda_function.svc.function_name, {"stat": "Sum"}],
                [".", "Errors", "FunctionName", aws_lambda_function.svc.function_name, {"stat": "Sum"}]
                ]}
            }
        ]
    })
}


resource "aws_cloudwatch_log_group" "lambda_lg" {
  name              = "/aws/lambda/${aws_lambda_function.svc.function_name}"
  retention_in_days = 14
}


resource "aws_cloudwatch_log_data_protection_policy" "mask_super_secret" {
  log_group_name = aws_cloudwatch_log_group.lambda_lg.name


  policy_document = jsonencode({
    Name        = "${var.project_info.name}-log-masking"
    Description = "Mask SUPER_SECRET_TOKEN value if it ever appears in logs"
    Version     = "2021-06-01"
    Statement   = [
      {
        Sid                  = "MaskExactSuperSecret"
        DataIdentifier       = []
        CustomDataIdentifier = [
          {
            Name  = "SuperSecretTokenExact"
            Regex = random_password.super_secret_token.result
          }
        ]
        Operation = { Deidentify = { MaskConfig = {} } }
      }
    ]
  })
}
