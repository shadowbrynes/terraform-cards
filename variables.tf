variable "aws_region_primary" {
  type    = string
  default = "us-east-1"
}

variable "aws_region_secondary" {
  type    = string
  default = "us-east-2"
}

variable "aws_region_tertiary" {
  type    = string
  default = "eu-west-1"
}

variable "ami_primary" {
  type        = string
  description = "Active AMI for us-east-1"
  default     = "ami-033ea4ff4a9c726dc"
}

variable "ami_ohio" {
  type        = string
  description = "Active AMI for us-east-2"
  default     = "ami-0ee52710c51e09069"
}

variable "ami_ireland" {
  type        = string
  description = "Active AMI for eu-west-1"
  default     = "ami-004a99a2ac96ef6aa"
}

variable "app_port" {
  type    = number
  default = 8085
}

variable "private_key_path" {
  type    = string
  default = "./umoh2.pem"
}

variable "jar_source_path" {
  type    = string
  default = "./account-0.0.1-SNAPSHOT.jar"
}
