# Un valore dummy generato
resource "random_password" "super_secret_token" {
  length  = 32
  special = false
}

# Il Secret (contenitore)
resource "aws_secretsmanager_secret" "super_token" {
  name        = "${var.project_info.name}-SUPER_SECRET_TOKEN"
  description = "Dummy token for Orbital Freight demo"
  recovery_window_in_days = 7
}

# La prima versione del secret (il valore)
resource "aws_secretsmanager_secret_version" "super_token_v1" {
  secret_id     = aws_secretsmanager_secret.super_token.id
  secret_string = random_password.super_secret_token.result
}
