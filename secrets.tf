# Create the Secrets Manager secret for RDS Proxy authentication
resource "aws_secretsmanager_secret" "rds_proxy_secret" {
  name        = "rds-proxy-secret"
  description = "Secret for RDS proxy authentication"
}

# Create a secret version with the DB credentials
resource "aws_secretsmanager_secret_version" "rds_proxy_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_proxy_secret.id
  secret_string = jsonencode({
    username = var.db_username,
    password = var.db_password,
    db_name  = var.db_name
  })
}
