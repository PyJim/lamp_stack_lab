# ECS Task Execution Role
resource "aws_iam_role" "ecs_task_execution" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "ecs-tasks.amazonaws.com" },
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_policy" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# RDS DB Proxy IAM Role
resource "aws_iam_role" "rds_db_proxy" {
  name = "rds-db-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Principal = { Service = "rds.amazonaws.com" },
      Effect    = "Allow"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "rds_db_proxy_access" {
  role       = aws_iam_role.rds_db_proxy.name
  policy_arn = aws_iam_policy.rds_proxy_policy.arn
}

resource "aws_iam_policy" "rds_proxy_policy" {
  name        = "RDSProxyCustomPolicy"
  description = "Custom IAM Policy for RDS Proxy"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "rds:CreateDBProxy",
          "rds:DescribeDBProxies",
          "rds:DeleteDBProxy",
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
          "iam:PassRole"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "rds_proxy_attachment" {
  role       = aws_iam_role.rds_db_proxy.name
  policy_arn = aws_iam_policy.rds_proxy_policy.arn
}



resource "aws_iam_policy" "ecs_logging_policy" {
  name        = "ecs-cloudwatch-logs-policy"
  description = "Allows ECS tasks to write logs to CloudWatch"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          "${aws_cloudwatch_log_group.ecs_apache_log_group.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_logging" {
  policy_arn = aws_iam_policy.ecs_logging_policy.arn
  role       = aws_iam_role.ecs_task_execution.name
}


resource "aws_iam_policy" "ecs_secrets_policy" {
  name        = "ecs-secrets-access-policy"
  description = "Allows ECS tasks to retrieve secrets from AWS Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.rds_proxy_secret.arn
      }
    ]
  })
}
