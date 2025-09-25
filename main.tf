terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  region = "us-east-2"
}

#  VPC
resource "aws_vpc" "pomodoro" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "pomodoro-vpc"
  }
}

resource "aws_subnet" "pomodoro_public" {
  vpc_id                  = aws_vpc.pomodoro.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "pomodoro-subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "pomodoro" {
  vpc_id = aws_vpc.pomodoro.id

  tags = {
    Name = "pomodoro-igw"
  }
}


resource "aws_route_table" "pomodoro" {
  vpc_id = aws_vpc.pomodoro.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pomodoro.id
  }

  tags = {
    Name = "pomodoro-rt"
  }
}

resource "aws_route_table_association" "pomodoro" {
  subnet_id      = aws_subnet.pomodoro_public.id
  route_table_id = aws_route_table.pomodoro.id
}

# Security Group
resource "aws_security_group" "pomodoro" {
  name        = "pomodoro-sg"
  description = "Liberar acesso HTTP e SSH"
  vpc_id      = aws_vpc.pomodoro.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "pomodoro-sg"
  }
}

# Repositório ECR
resource "aws_ecr_repository" "pomodoro" {
  name = "pomodoro-terraform"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Instância EC2
resource "aws_instance" "pomodoro" {
  ami           = "ami-0634f3c109dcdc659"
  instance_type = "t3.micro"
  key_name      = "hello-teste-aws"

  subnet_id              = aws_subnet.pomodoro_public.id
  vpc_security_group_ids = [aws_security_group.pomodoro.id]

  tags = {
    Name = "Pomodoro-terraform"
  }
}

# Outputs
output "ecr_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.pomodoro.repository_url
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.pomodoro.public_ip
}
