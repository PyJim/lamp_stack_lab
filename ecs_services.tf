# Security Group for Nginx tasks (they receive traffic from the ALB)
resource "aws_security_group" "ecs_nginx_sg" {
  name        = "ecs-nginx-sg"
  description = "Allow traffic from ALB"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Apache+PHP tasks (allow traffic from Nginx)
resource "aws_security_group" "ecs_apache_sg" {
  name        = "ecs-apache-sg"
  description = "Allow traffic from the reverse proxy"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_nginx_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#########################
# ECS Task Definitions
#########################

# Nginx (Reverse Proxy) Task Definition
resource "aws_ecs_task_definition" "nginx" {
  family                   = "nginx-reverse-proxy"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name         = "nginx"
      image        = "529088286633.dkr.ecr.eu-west-1.amazonaws.com/nginx-proxy:latest"
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/nginx",
          "awslogs-region"        = "eu-west-1",
          "awslogs-stream-prefix" = "nginx"
        }
      }
    }
  ])
}

# Apache+PHP Task Definition
resource "aws_ecs_task_definition" "apache" {
  family                   = "apache-php-app"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "apache-php"
      image = "529088286633.dkr.ecr.eu-west-1.amazonaws.com/apache-php-app:latest"
      portMappings = [{
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }]
      environment = [
        {
          name  = "DB_HOST"
          value = aws_db_proxy.rds_proxy.endpoint
        },
        {
        name  = "DB_CREDENTIALS"
        value = jsonencode({
          db_name  = "todo_db"
          password = "kodwoessel"
          username = "jimmy"
        })
      }
      ]
      # secrets = [
      #   { name = "DB_CREDENTIALS", valueFrom = aws_secretsmanager_secret.rds_proxy_secret.arn }
      # ]
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = "/ecs/apache",
          "awslogs-region"        = "eu-west-1",
          "awslogs-stream-prefix" = "apache"
        }
      }
    }
  ])
}

#########################
# ECS Services
#########################

# ECS Service for Nginx (reverse proxy)
resource "aws_ecs_service" "nginx" {
  name            = "nginx-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups = [aws_security_group.ecs_nginx_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.http]
}

# ECS Service for Apache+PHP
resource "aws_ecs_service" "apache" {
  name            = "apache-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.apache.arn
  desired_count   = 2
  launch_type     = "FARGATE"
  platform_version = "LATEST"

  network_configuration {
    subnets         = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups = [aws_security_group.ecs_apache_sg.id]
    assign_public_ip = false
  }
  service_registries {
    registry_arn = aws_service_discovery_service.apache.arn
  }

  # This service runs behind the reverse proxy.
  # Ensure that your nginx configuration (inside the container) points to these tasks.
}
