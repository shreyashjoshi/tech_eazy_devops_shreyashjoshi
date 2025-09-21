# AMI ID, instance type, key pair, etc.

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}


variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}
variable "stage" {
  description = "Deployment stage ( dev, prod, test )"
  type        = string
  default     = "dev"
}
