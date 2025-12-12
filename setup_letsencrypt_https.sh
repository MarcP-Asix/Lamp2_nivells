#!/bin/bash

# Script: setup_letsencrypt_https.sh
# Objetivo: Automatizar la instalación y configuración de certificados SSL/TLS de Let's Encrypt en Apache
# Requisitos: sudo, Apache instalado, dominio apuntando al servidor

# --- Variables ---
DOMINIO=$1
EMAIL=$2

# --- Validaciones ---
if [ -z "$DOMINIO" ] || [ -z "$EMAIL" ]; then
  echo "Uso: $0 <dominio> <email>"
  exit 1
fi

# --- Actualizar paquetes ---
echo "[+] Actualizando paquetes..."
sudo apt update && sudo apt upgrade -y

# --- Instalar Certbot y módulo Apache ---
echo "[+] Instalando Certbot y módulo Apache..."
sudo apt install -y certbot python3-certbot-apache

# --- Solicitar certificado ---
echo "[+] Solicitando certificado SSL/TLS para $DOMINIO..."
sudo certbot --apache -d $DOMINIO -d www.$DOMINIO --non-interactive --agree-tos -m $EMAIL

# --- Verificar renovación automática ---
echo "[+] Verificando renovación automática..."
sudo systemctl enable certbot.timer
sudo systemctl start certbot.timer

# --- Reiniciar Apache ---
echo "[+] Reiniciando Apache..."
sudo systemctl reload apache2

echo "[✔] Configuración completada. El sitio $DOMINIO ya debería estar disponible con HTTPS."
