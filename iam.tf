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

# resource "aws_iam_role_policy_attachment" "rds_db_proxy_access" {
#   role       = aws_iam_role.rds_db_proxy.name
#   policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSProxyServiceRolePolicy"
# }

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
          "arn:aws:logs:eu-west-1:529088286633:log-group:/ecs/nginx:*",
          "arn:aws:logs:eu-west-1:529088286633:log-group:/ecs/apache:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_logging" {
  policy_arn = aws_iam_policy.ecs_logging_policy.arn
  role       = "ecsTaskExecutionRole" # Replace with your actual ECS execution role
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

resource "aws_iam_role_policy_attachment" "ecs_secrets_attachment" {
  policy_arn = aws_iam_policy.ecs_secrets_policy.arn
  role       = "ecsTaskExecutionRole" # Ensure this matches your actual ECS execution role
}



# IAM Role for lambda function to connect to RDS

# Lambda IAM Role
resource "aws_iam_role" "lambda_execution" {
  name = "lambda-mysql-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

# IAM Policy for Lambda to Access RDS Proxy and Secrets Manager
resource "aws_iam_policy" "lambda_rds_access" {
  name = "lambda-mysql-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = aws_secretsmanager_secret.rds_proxy_secret.arn
      },
      {
        # Allow Lambda to decrypt secrets if using AWS-managed KMS key
        Effect   = "Allow",
        Action   = ["kms:Decrypt"],
        Resource = "arn:aws:kms:eu-west-1:529088286633:key/*"
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "rds-db:connect"
        ],
        Resource = aws_db_proxy.rds_proxy.arn
      },
      {
        Effect   = "Allow",
        Action   = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface",
          "ec2:AttachNetworkInterface",
        ],
        Resource = "*"
      },
      {
        # Allow Lambda to resolve DNS (needed for RDS Proxy in private subnet)
        Effect   = "Allow",
        Action   = ["route53:Resolve"],
        Resource = "*"
      }
    ]
  })
}

# Attach policy to Lambda Role
resource "aws_iam_role_policy_attachment" "lambda_rds_attach" {
  role       = aws_iam_role.lambda_execution.name
  policy_arn = aws_iam_policy.lambda_rds_access.arn
}