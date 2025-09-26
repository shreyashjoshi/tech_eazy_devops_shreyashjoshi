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
  iam_instance_profile = [aws_iam_instance_profile.ec2-instance-profile.name,aws_iam_instance_profile.ec2_profile_ssm.name]

  # Use the user_data script to bootstrap the instance
  #user_data = file("${path.module}/../scripts/user_data.sh")
  user_data = templatefile("${path.module}/../scripts/user_data.sh", {
    stage = var.stage
  })

  tags = {
    Name = "JavaApp_EC2"
  }
  depends_on = [module.s3_bucket,]
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

resource "random_id" "bucket_suffix" {
  byte_length = 4
 }

module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "app-config-${random_id.bucket_suffix.hex}"
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = true
  }

}


#Read only access to specific S3 bucket
module "iam_policy_readonly" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "S3ReadOnlyPolicy_Access_tf"
  path        = "/"
  description = "Read Only Access to specific S3 bucket"

  policy = <<-EOF
  {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowListBucket",
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${module.s3_bucket.s3_bucket_id}"
      ]
    },
    {
      "Sid": "AllowReadObjects",
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetObjectAcl"
      ],
      "Resource": [
        "arn:aws:s3:::${module.s3_bucket.s3_bucket_id}/*"
      ]
    }
  ]
}
  EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# create and upload to bucket but no read or write down
module "iam_policy_action" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-policy"

  name        = "S3CreateAndUploadPolicy_Access_tf"
  path        = "/"
  description = "My example policy"

  policy = <<-EOF
    {
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowBucketCreation",
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AllowPutObjectOnly",
      "Effect": "Allow",
      "Action": [
        "s3:PutObject"
      ],
      "Resource": "arn:aws:s3:::*/*"
    }
  ]
}
  EOF

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

module "iam_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role"

  name = "example-ec2-role"

  trust_policy_permissions = {
    TrustEC2 = {
      principals = [{
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }]
    }
  }

  policies = {
    custom                     = module.iam_policy_action.arn
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_iam_instance_profile" "example" {
  name = "ec2-instance-profile"
  role = module.iam_role.instance_profile_iam_instance_profile_name
}

resource "aws_ssm_parameter" "s3_bucket_name" {
  name  = "S3BucketName"
  type  = "String"
  value = module.s3_bucket.s3_bucket_id
  depends_on = [module.s3_bucket]
}
provider "aws" {
  region = "us-east-1"  # Change as needed
}

# 1. Create IAM Policy allowing read access to Parameter Store
resource "aws_iam_policy" "ssm_parameter_read" {
  name        = "SSMParameterReadPolicy"
  description = "Allows reading parameters from SSM Parameter Store"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath"
        ],
        Resource = "*"
      }
    ]
  })
}
resource "aws_iam_role" "ec2_ssm_role" {
  name = "EC2SSMParameterReadRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ec2_ssm_role.name
  policy_arn = aws_iam_policy.ssm_parameter_read.arn
}
resource "aws_iam_instance_profile" "ec2_profile_ssm" {
  name = "EC2SSMInstanceProfile"
  role = aws_iam_role.ec2_ssm_role.name
}

resource "aws_s3_bucket_lifecycle_configuration" "log_lifecycle" {
  bucket = module.s3_bucket.s3_bucket_id

  rule {
    id     = "DeleteLogsAfter7Days"
    status = "Enabled"

    expiration {
      days = 7  # Delete after 7 days
    }
  }
}