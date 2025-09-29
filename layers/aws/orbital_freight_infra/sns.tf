resource "aws_sns_topic" "alerts" {
  name = "${var.project_info.name}-alerts"
}

# (opzionale) una subscription email per test
resource "aws_sns_topic_subscription" "alerts_email" {
  count     = var.alerts_email == null ? 0 : 1
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = var.alerts_email
}
