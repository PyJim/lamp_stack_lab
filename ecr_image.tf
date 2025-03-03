resource "null_resource" "push_image" {
  provisioner "local-exec" {
    command = <<EOT
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.apache_php.repository_url}
      docker tag php-todo-app:latest ${aws_ecr_repository.apache_php.repository_url}:latest
      docker push ${aws_ecr_repository.apache_php.repository_url}:latest
    EOT
  }
}
