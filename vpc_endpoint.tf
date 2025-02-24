resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.eu-west-1.secretsmanager"
  vpc_endpoint_type = "Interface"
  subnet_ids   = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  security_group_ids = [aws_security_group.lambda_sg.id]

  private_dns_enabled = true
}
