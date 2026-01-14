#!/bin/bash

# --- CONFIGURACIÓN ---
WORDPRESS_DIR="/var/www/html"
DB_NAME="wordpress"
DB_USER="root"
# Genera una contraseña aleatoria de 16 caracteres para la base de datos
DB_PASSWORD=$(cat /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
WP_VERSION="latest"
TEMP_DOWNLOAD="/tmp/wordpress.tar.gz"

# Colores para la salida
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# --- FUNCIONES ---

# Función para verificar el éxito del último comando
check_success() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Éxito: $1${NC}"
    else
        echo -e "${RED}❌ Error: $1${NC}"
        exit 1
    fi
}

# 1. Función para descargar y descomprimir WordPress
download_wordpress() {
    echo "--- 1. Descargando y Descomprimiendo WordPress ---"
    
    # Descargar la última versión de WordPress
    wget -q "https://wordpress.org/${WP_VERSION}.tar.gz" -O ${TEMP_DOWNLOAD}
    check_success "Descarga de WordPress"
    
    # Eliminar contenido antiguo en el directorio objetivo
    sudo rm -rf ${WORDPRESS_DIR}/* ${WORDPRESS_DIR}/.* 2>/dev/null
    
    # Descomprimir en el directorio raíz
    sudo tar -xzf ${TEMP_DOWNLOAD} -C /tmp/
    sudo mv /tmp/wordpress/* ${WORDPRESS_DIR}/
    check_success "Descompresión y movimiento de archivos"
    
    # Limpiar el archivo temporal
    rm -f ${TEMP_DOWNLOAD}
}

# 2. Función para configurar la Base de Datos
setup_database() {
    echo -e "\n--- 2. Configurando Base de Datos MySQL/MariaDB ---"
    
    # Se requiere la herramienta 'mysql' para ejecutar comandos
    if ! command -v mysql &> /dev/null
    then
        echo -e "${RED}El cliente MySQL no está instalado. Por favor, instálalo e inténtalo de nuevo.${NC}"
        exit 1
    fi

    # Comandos SQL para crear la DB y el usuario
    SQL_COMMANDS="
    CREATE DATABASE IF NOT EXISTS wordpress DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;
    CREATE USER IF NOT EXISTS 'root'@'%' IDENTIFIED BY 'Jodopa2006';
    GRANT ALL PRIVILEGES ON wordpress.* TO 'root'@'%';
    FLUSH PRIVILEGES;
    "

    # Ejecutar comandos SQL. Se asume que el usuario puede usar 'sudo' para acceder a MySQL (o que tiene permisos de root para el socket)
    echo "$SQL_COMMANDS" | sudo mysql -u root
    check_success "Creación de la base de datos y el usuario"
    
    echo -e "${GREEN}Detalles de la Base de Datos:${NC}"
    echo "  Nombre de la DB: wordpress"
    echo "  Usuario de la DB: root"
    echo "  Contraseña (¡GUARDAR!): Jodopa2006"
}

# 3. Función para configurar el archivo wp-config.php
configure_wordpress() {
    echo -e "\n--- 3. Configurando WordPress (wp-config.php) ---"
    
    # Crear wp-config.php a partir de la plantilla
    sudo cp ${WORDPRESS_DIR}/wp-config-sample.php ${WORDPRESS_DIR}/wp-config.php
    check_success "Creación de wp-config.php"

    # Insertar detalles de la Base de Datos
    sudo sed -i "s/database_name_here/wordpress/g" ${WORDPRESS_DIR}/wp-config.php
    sudo sed -i "s/username_here/root/g" ${WORDPHRESS_DIR}/wp-config.php
    sudo sed -i "s/password_here/Jodopa2006/g" ${WORDPRESS_DIR}/wp-config.php
    check_success "Inserción de detalles de la DB"
    
    # Opcional: Insertar Claves de Seguridad Únicas de WordPress (Salts)
    SALT_KEYS=$(wget -qO - https://api.wordpress.org/secret-key/1.1/salt/)
    SALTED_CONFIG=$(awk "/put your unique phrase here/ {\$0=s} 1" s="${SALT_KEYS}" ${WORDPRESS_DIR}/wp-config.php)
    echo "${SALTED_CONFIG}" | sudo tee ${WORDPRESS_DIR}/wp-config.php > /dev/null
    check_success "Inserción de claves de seguridad (Salts)"
}

# 4. Función para configurar permisos
set_permissions() {
    echo -e "\n--- 4. Configurando Permisos de Archivos ---"
    
    # Determinar el usuario/grupo del servidor web (común: www-data en Debian/Ubuntu, apache en CentOS/RHEL)
    # Esto es una simplificación, comprueba tu sistema
    WEB_USER=$(ps aux | grep -E '[a]pache|[n]ginx|[h]ttpd' | grep -v root | head -n 1 | awk '{print $1}')
    if [ -z "$WEB_USER" ]; then
        WEB_USER="www-data" # Valor predeterminado para Debian/Ubuntu
        echo -e "${GREEN}INFO: No se pudo determinar el usuario del servidor web. Usando el valor predeterminado: ${WEB_USER}${NC}"
    fi

    # Establecer la propiedad del directorio de WordPress
    sudo chown -R ${WEB_USER}:${WEB_USER} ${WORDPRESS_DIR}
    check_success "Establecimiento de la propiedad (${WEB_USER}:${WEB_USER})"
    
    # Establecer permisos de archivos y directorios recomendados
    sudo find ${WORDPRESS_DIR} -type d -exec chmod 755 {} +
    sudo find ${WORDPRESS_DIR} -type f -exec chmod 644 {} +
    check_success "Establecimiento de permisos 755 (directorios) y 644 (archivos)"
    
    # Permisos adicionales para wp-content/uploads (si es necesario)
    # sudo chmod -R 775 ${WORDPRESS_DIR}/wp-content/uploads
}


# --- EJECUCIÓN DEL SCRIPT ---
echo "==============================================="
echo "🚀 INICIO DE LA INSTALACIÓN AUTOMÁTICA DE WORDPRESS"
echo "==============================================="

download_wordpress
setup_database
configure_wordpress
set_permissions

echo "==============================================="
echo -e "${GREEN}🎉 INSTALACIÓN DE WORDPRESS COMPLETADA${NC}"
echo "El sitio web está disponible en: http://[TU_DIRECCIÓN_IP_O_DOMINIO]/"
echo "--- PASO FINAL: Ejecuta la instalación a través del navegador ---"
echo "Ingresa la información de la DB mostrada arriba cuando te la solicite la página de instalación de WordPress."
echo "==============================================="
