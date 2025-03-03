resource "aws_ecr_repository" "apache_php" {
  name                 = "apache-php-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "apache-php-app"
  }
}
