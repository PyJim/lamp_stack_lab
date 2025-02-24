resource "aws_security_group" "lambda_sg" {
  name        = "lambda-sg"
  description = "Security group for Lambda to access RDS"
  vpc_id      = aws_vpc.main.id  # Ensure this matches your VPC

  # Allow outbound traffic to the RDS security group
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.rds_sg.id]  # Reference your RDS SG
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  tags = {
    Name = "lambda-sg"
  }
}


resource "aws_security_group_rule" "lambda_sg_ingress" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.lambda_sg.id  # This is for the VPC Endpoint SG
  source_security_group_id = aws_security_group.lambda_sg.id  # Allow Lambda SG to talk to itself
}
