provider "aws" {
  region = var.aws_region   
  
}
data "aws_ami" "ubuntu" {
  most_recent = true

  # owner id for Ubuntu images
  owners = ["amazon"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}
# resource "aws_key_pair" "mykey" {
#   key_name   = "my-keypair"
#   public_key = file("C:\\Users\\\\.ssh\\id_rsa.pub")
# }
resource "aws_instance" "JavaApp_EC2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  # Attach to the default subnet created below
  subnet_id = aws_subnet.public.id
# key_name = aws_key_pair.mykey.key_name
  # Attach the security group allowing SSH and HTTP
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  # Use the user_data script to bootstrap the instance
  #user_data = file("${path.module}/../scripts/user_data.sh")
  user_data = templatefile("${path.module}/../scripts/user_data.sh", {
    stage = var.stage
  })

  tags = {
    Name = "JavaApp_EC2"
  }
}

# --- Networking resources: VPC, subnet, IGW, route table ---
resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true

}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Security group to allow SSH (22) and HTTP (80)
resource "aws_security_group" "instance_sg" {
  name        = "Allow__HTTP"
  description = "Allow HTTP"
  vpc_id      = aws_vpc.main_vpc.id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
