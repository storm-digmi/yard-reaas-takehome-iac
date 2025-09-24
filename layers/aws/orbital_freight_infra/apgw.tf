############################
# API Gateway v2 (HTTP API) → Lambda alias
############################
resource "aws_apigatewayv2_api" "http" {
    name = "${var.project.name}-http"
    protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda_proxy" {
    api_id = aws_apigatewayv2_api.http.id
    integration_type = "AWS_PROXY"
    integration_method = "POST"
    payload_format_version = "2.0"
    integration_uri = aws_lambda_alias.prod.invoke_arn
}

# Route all (ANY /{proxy+}) to lambda
resource "aws_apigatewayv2_route" "proxy" {
    api_id = aws_apigatewayv2_api.http.id
    route_key = "$default"
    target = "integrations/${aws_apigatewayv2_integration.lambda_proxy.id}"
}

resource "aws_apigatewayv2_stage" "default" {
    api_id = aws_apigatewayv2_api.http.id
    name = "$default"
    auto_deploy = true
}

# Permission so API GW can invoke the Lambda alias
resource "aws_lambda_permission" "apigw_invoke" {
    statement_id = "AllowInvokeFromHttpApi"
    action = "lambda:InvokeFunction"
    function_name = aws_lambda_function.svc.function_name
    qualifier = aws_lambda_alias.prod.name
    principal = "apigateway.amazonaws.com"
    source_arn = "${aws_apigatewayv2_api.http.execution_arn}/*/*"
}