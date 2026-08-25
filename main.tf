# 1. AWS Provider Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# 2. Virtual Private Cloud (VPC)
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "capstone_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "TKH-Capstone-VPC"
  }
}

# 3. Public Subnet
# tfsec:ignore:aws-ec2-no-public-ip-subnet
resource "aws_subnet" "capstone_subnet" {
  vpc_id                  = aws_vpc.capstone_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "TKH-Capstone-Subnet"
  }
}

# 4. Internet Gateway
resource "aws_internet_gateway" "capstone_igw" {
  vpc_id = aws_vpc.capstone_vpc.id

  tags = {
    Name = "TKH-Capstone-IGW"
  }
}

# 5. Route Table & Association
resource "aws_route_table" "capstone_rt" {
  vpc_id = aws_vpc.capstone_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.capstone_igw.id
  }

  tags = {
    Name = "TKH-Capstone-RouteTable"
  }
}

resource "aws_route_table_association" "capstone_rta" {
  subnet_id      = aws_subnet.capstone_subnet.id
  route_table_id = aws_route_table.capstone_rt.id
}

# 6. Latest Amazon Linux 2023 AMI Lookup
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# 7. Security Group (Firewall)
# tfsec:ignore:aws-ec2-no-public-ingress-sgr
# tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "capstone_sg" {
  name        = "TKH-Capstone-SG"
  description = "Allow HTTP globally and SSH from specific IP"
  vpc_id      = aws_vpc.capstone_vpc.id

  ingress {
    description = "Allow HTTP traffic from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH traffic from specific home IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["192.168.0.252/32"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "TKH-Capstone-SG"
  }
}

# 8. EC2 Web Server Instance
# tfsec:ignore:aws-ec2-enable-at-rest-encryption
# tfsec:ignore:aws-ec2-enforce-http-token-imds
resource "aws_instance" "capstone_web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.capstone_subnet.id
  vpc_security_group_ids = [aws_security_group.capstone_sg.id]

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  user_data = <<-EOF
              #!/bin/bash
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              EOF

  tags = {
    Name = "TKH-Capstone-WebServer"
  }
}