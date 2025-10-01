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

# VPC default
data "aws_vpc" "default" {
  default = true
}

# Subnets da VPC default
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Random suffix para o ECR
resource "random_id" "suffix" {
  byte_length = 4
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

# Security Group
resource "aws_security_group" "ssh_access" {
  name        = "ssh-access-${random_id.suffix.hex}"
  description = "Permite acesso SSH, HTTP e HTTPS"
  vpc_id      = data.aws_vpc.default.id
}

# Regras de Ingress
## SSH 
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["189.40.89.114/32"]
  security_group_id = aws_security_group.ssh_access.id
}

## HTTP - público
resource "aws_security_group_rule" "http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ssh_access.id
}

## HTTPS - público
resource "aws_security_group_rule" "https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ssh_access.id
}

# Regra de egress (permitir todo tráfego de saída)
resource "aws_security_group_rule" "all_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.ssh_access.id
}

# Instância EC2
resource "aws_instance" "meu_servidor" {
  ami           = "ami-0fb653ca2d3203ac1" # Ubuntu 22.04 LTS us-east-2
  instance_type = "t3.micro"
  key_name      = "hello-teste-aws"

  subnet_id                   = data.aws_subnets.default.ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.ssh_access.id]

  user_data = <<-EOF
    #!/bin/bash
    hostnamectl set-hostname Pomodoro-terraform
    echo "127.0.0.1 Pomodoro-terraform" >> /etc/hosts
  EOF

  provisioner "local-exec" {
    command = "chmod 400 ~/Downloads/hello-teste-aws.pem || true"

  }
}

# Outputs
output "ec2_public_ip" {
  description = "IP público da instância EC2"
  value       = aws_instance.meu_servidor.public_ip
}

output "ecr_url" {
  description = "URL do repositório ECR"
  value       = aws_ecr_repository.pomodoro.repository_url
}
