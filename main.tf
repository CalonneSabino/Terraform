terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }

  required_version = ">= 1.9.0"
}

provider "aws" {
  region = "us-east-2"
}

# Usando a VPC padrao pra nao ter problemas de permissao
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Repositório ECR
resource "aws_ecr_repository" "pomodoro" {
  name = "pomodoro-app-${random_id.suffix.hex}"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }
}

# Random suffix to avoid naming conflicts
resource "random_id" "suffix" {
  byte_length = 4
}

# Instância EC2 com defalt VPC
resource "aws_instance" "meu_servidor" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.micro"
  key_name      = "hello-teste-aws"

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true

  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname Pomodoro-terraform
    echo "127.0.0.1 Pomodoro-terraform" >> /etc/hosts
  EOF

  # Use default security group to avoid permission issues
}

# Outputs
output "ecr_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.pomodoro.repository_url
}

output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.meu_servidor.public_ip
}
