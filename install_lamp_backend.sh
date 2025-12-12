#!/bin/bash
# install_lamp_backend.sh
# Script para automatizar la instalación de la pila LAMP en una máquina backend

# Salir si ocurre algún error
set -e

echo "=== Actualizando paquetes del sistema ==="
sudo apt update -y
sudo apt upgrade -y

echo "=== Instalando Apache ==="
sudo apt install apache2 -y
sudo systemctl enable apache2
sudo systemctl start apache2

echo "=== Instalando MariaDB (MySQL compatible) ==="
sudo apt install mariadb-server mariadb-client -y
sudo systemctl enable mariadb
sudo systemctl start mariadb

echo "=== Asegurando instalación de MariaDB ==="
sudo mysql_secure_installation <<EOF
y
rootpassword
rootpassword
y
y
y
y
EOF

echo "=== Instalando PHP y extensiones necesarias ==="
sudo apt install php libapache2-mod-php php-mysql php-cli php-curl php-xml php-gd -y

echo "=== Configurando Apache para usar PHP ==="
sudo systemctl restart apache2

echo "=== Configurando base de datos para el backend ==="
sudo mysql -u root -prootpassword <<MYSQL_SCRIPT
CREATE DATABASE backend_db;
CREATE USER 'backend_user'@'localhost' IDENTIFIED BY 'backend_pass';
GRANT ALL PRIVILEGES ON backend_db.* TO 'backend_user'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

echo "=== Creando archivo de prueba PHP ==="
echo "<?php phpinfo(); ?>" | sudo tee /var/www/html/info.php > /dev/null

echo "=== Instalación completada ==="
echo "Puedes verificar la instalación accediendo a http://localhost/info.php"
