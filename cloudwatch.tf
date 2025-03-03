resource "aws_cloudwatch_log_group" "ecs_apache_log_group" {
  name              = "/ecs/apache"
  retention_in_days = 30  # Adjust retention period as needed
}
