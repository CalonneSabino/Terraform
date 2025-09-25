terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.9.0"
}

# Provider AWS 
provider "aws" {
  region = "us-east-2"
}

# Repositório ECR
resource "aws_ecr_repository" "pomodoro-terraform" {
  name = "pomodoro-terraform"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Security Group para EC2
resource "aws_security_group" "launch-wizard-5" {
  name        = "launch-wizard-5"
  description = "Liberar acesso HTTP e SSH"
  vpc_id      = "vpc-0dd592760b502e7d0" 

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
}

resource "aws_instance" "pomodoro-terraform" {
  ami           = "ami-0634f3c109dcdc659" 
  instance_type = "t3.micro"
  key_name      = "hello-teste-aws" 

  vpc_security_group_ids =  ["sg-0583a55e503b82036"]

  tags = {
    Name = "Pomodoro-terraform"
  }
}


output "ecr_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.pomodoro-terraform.repository_url
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.pomodoro.public_ip
}
