############################
# CodeDeploy — App + Deployment Group (for Lambda)
# NOTE: The Deployment Group doesn't need to reference the function; the function & alias
# are specified at deployment time via the AppSpec. We do wire in alarms + rollback here.
############################
resource "aws_codedeploy_app" "lambda_app" {
    name = "${var.project_info.name}-cd-app"
    compute_platform = "Lambda"
}

resource "aws_codedeploy_deployment_group" "lambda_dg" {
    app_name = aws_codedeploy_app.lambda_app.name
    deployment_group_name = "${var.project_info.name}-cd-dg"
    service_role_arn = aws_iam_role.codedeploy_service.arn

    # Required for Lambda: BLUE_GREEN + WITH_TRAFFIC_CONTROL
    deployment_style {
        deployment_type = "BLUE_GREEN"
        deployment_option = "WITH_TRAFFIC_CONTROL"
    }

    # Canary 10% for 5 minutes (built-in)
    deployment_config_name = "CodeDeployDefault.LambdaCanary10Percent2Minutes"

    alarm_configuration {
        alarms = [aws_cloudwatch_metric_alarm.lambda_errors.alarm_name]
        enabled = true
    }

    auto_rollback_configuration {
        enabled = true
        events = ["DEPLOYMENT_FAILURE", "DEPLOYMENT_STOP_ON_ALARM"]
    }
}