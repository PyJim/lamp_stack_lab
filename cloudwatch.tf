resource "aws_cloudwatch_log_group" "ecs_nginx_log_group" {
  name              = "/ecs/nginx"
  retention_in_days = 30  # Adjust retention period as needed
}

resource "aws_cloudwatch_log_group" "ecs_apache_log_group" {
  name              = "/ecs/apache"
  retention_in_days = 30  # Adjust retention period as needed
}
