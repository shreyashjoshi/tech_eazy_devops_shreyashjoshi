# Public IP of EC2 instance
output "instance_public_ip_javaapp" {
  description = "Public IP of the JavaApp EC2 instance"
  value       = aws_instance.JavaApp_EC2.public_ip
}
