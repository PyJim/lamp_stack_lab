resource "aws_lambda_function" "db_init_lambda" {
  function_name = "db_init_lambda"
  role          = aws_iam_role.lambda_execution.arn
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  filename      = "./lambda/lambda_function.zip"
  timeout       = 30

  vpc_config {
    subnet_ids         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }

  environment {
    variables = {
      DB_HOST     = aws_db_instance.mysql.endpoint
      DB_SECRET   = aws_secretsmanager_secret.rds_proxy_secret.arn
      DB_NAME     = "todo_db"
    }
  }
}


resource "null_resource" "invoke_lambda" {
  depends_on = [aws_lambda_function.db_init_lambda]

  provisioner "local-exec" {
    command = <<EOT
      aws lambda invoke \
        --function-name ${aws_lambda_function.db_init_lambda.function_name} \
        --region ${var.aws_region} \
        output.json
    EOT
  }
}
