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

resource "aws_cloudwatch_metric_alarm" "api_5xx" {
  alarm_name          = "${var.project_info.name}-apigw-5xx"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "5xx"
  namespace           = "AWS/ApiGateway"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = aws_apigatewayv2_api.http.id
    Stage = aws_apigatewayv2_stage.default.name
  }

  alarm_actions = [aws_sns_topic.alerts.arn]
  ok_actions    = [aws_sns_topic.alerts.arn]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "${var.project_info.name}-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      # Requests & errors (API Gateway)
      {
        "type": "metric", "x": 0, "y": 0, "width": 12, "height": 6,
        "properties": {
          "title": "API Requests & 4xx/5xx (${aws_apigatewayv2_api.http.id}/${aws_apigatewayv2_stage.default.name})",
          "region": var.aws_region,
          "metrics": [
            ["AWS/ApiGateway", "Count", "ApiId", aws_apigatewayv2_api.http.id, "Stage", aws_apigatewayv2_stage.default.name, {"stat":"Sum","label":"Requests"}],
            [".", "4xx",   ".", ".", ".", ".", {"stat":"Sum","label":"4xx"}],
            [".", "5xx",   ".", ".", ".", ".", {"stat":"Sum","label":"5xx"}]
          ],
          "view": "timeSeries",
          "stacked": false
        }
      },

      # P95 Latency (API Gateway)
      {
        "type": "metric", "x": 0, "y": 6, "width": 12, "height": 6,
        "properties": {
          "title": "API Latency P95",
          "region": var.aws_region,
          "metrics": [
            ["AWS/ApiGateway", "Latency", "ApiId", aws_apigatewayv2_api.http.id, "Stage", aws_apigatewayv2_stage.default.name, {"stat":"p95","label":"Latency p95 (ms)"}]
          ],
          "view": "timeSeries"
        }
      },

      # Lambda Duration P95
      {
        "type":"metric", "x": 0, "y": 12, "width": 12, "height": 6,
        "properties": {
          "title":"Lambda Duration P95 (${aws_lambda_function.svc.function_name})",
          "region": var.aws_region,
          "metrics": [
            ["AWS/Lambda","Duration","FunctionName", aws_lambda_function.svc.function_name, {"stat":"p95","label":"Duration p95 (ms)"}]
          ],
          "view":"timeSeries"
        }
      },

      # Alarm state (API 5xx)
      {
        "type":"alarm", "x": 0, "y": 18, "width": 12, "height": 4,
        "properties": { "alarms": [ aws_cloudwatch_metric_alarm.api_5xx.arn ] }
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
        Sid            = "audit-policy"
        DataIdentifier = ["SuperSecretTokenExact"]
        Operation      = { Audit = { FindingsDestination = {} } }
      },
      
      {
        Sid            = "redact-policy"
        DataIdentifier = ["SuperSecretTokenExact"]
        Operation      = { Deidentify = { MaskConfig = {} } }
      }
    ]
    Configuration = {
      CustomDataIdentifier = [
        {
          Name  = "SuperSecretTokenExact"
          
          Regex = random_password.super_secret_token.result
        }
      ]
    }
  })
}

