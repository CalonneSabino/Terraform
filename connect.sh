#!/bin/bash

# Script para conectar à instância EC2
KEY_PATH="$HOME/.ssh/hello-teste-aws.pem"

# Ajustar permissões da chave SSH
echo "Ajustando permissões da chave SSH..."
chmod 775 "$KEY_PATH"

# Obter IP público da instância
echo "Obtendo IP público da instância..."
PUBLIC_IP=$(terraform output -raw ec2_public_ip)

if [ -z "$PUBLIC_IP" ]; then
    echo "Erro: Não foi possível obter o IP público. Execute 'terraform apply' primeiro."
    exit 1
fi

echo "IP público: $PUBLIC_IP"
echo "Conectando via SSH..."

# Conectar via SSH
ssh -i "$KEY_PATH" ubuntu@"$PUBLIC_IP"