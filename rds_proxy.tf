resource "aws_db_proxy" "rds_proxy" {
  name                   = "rds-proxy"
  engine_family          = "MYSQL"
  idle_client_timeout    = 1800
  require_tls            = false
  role_arn               = aws_iam_role.rds_db_proxy.arn  # Use the fixed IAM role
  vpc_subnet_ids         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  auth {
    auth_scheme = "SECRETS"
    description = "RDS proxy authentication"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.rds_proxy_secret.arn
  }
}


# Register the RDS instance as a target of the proxy
resource "aws_db_proxy_target" "rds_proxy_target" {
    db_proxy_name          = aws_db_proxy.rds_proxy.name
    db_instance_identifier = aws_db_instance.mysql.identifier
    target_group_name      = "default"
}

