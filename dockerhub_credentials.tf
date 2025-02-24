resource "aws_secretsmanager_secret" "docker_hub_credentials" {
  name        = "docker-hub-credentials"
  description = "Docker Hub credentials for ECS tasks"
}

resource "aws_secretsmanager_secret_version" "docker_hub_credentials_version" {
  secret_id     = aws_secretsmanager_secret.docker_hub_credentials.id
  secret_string = jsonencode({
    username = "",
    password = ""
  })
}
