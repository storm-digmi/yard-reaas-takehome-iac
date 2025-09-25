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