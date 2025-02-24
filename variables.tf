# Variables for database credentials (consider moving these to a secure location)
variable "db_username" {
  type    = string
  default = ""
}

variable "db_password" {
  type    = string
  default = ""
}

variable "db_name" {
  type    = string
  default = ""
  
}

variable "aws_region" {
  type    = string
  default = ""
  
}