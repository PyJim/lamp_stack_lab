# Variables for database credentials (consider moving these to a secure location)
variable "db_username" {
  type    = string
  default = "jimmy"
  sensitive = true
}

variable "db_password" {
  type    = string
  default = "kodwoessel"
  sensitive = true
}

variable "db_name" {
  type    = string
  default = "todo_db"
  sensitive = true
  
}

variable "aws_region" {
  type    = string
  default = "eu-west-1"
  
}