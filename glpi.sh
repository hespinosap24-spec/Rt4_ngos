#!/bin/bash

# Script de instalación automática de GLPI 10.0.19
# Ejecutar con privilegios de root (sudo)

set -e # Detener el script si ocurre un error

echo "--- 1. Actualizando sistema e instalando dependencias ---"
apt update
apt install -y apache2 mariadb-server php php-{apcu,cli,common,curl,gd,imap,ldap,mysql,xmlrpc,xml,mbstring,bcmath,intl,zip,redis,bz2,soap,cas} libapache2-mod-php

echo "--- 2. Configuración de Base de Datos ---"
# Nota: mysql_secure_installation es interactivo. 
# Deberás configurar la contraseña de root manualmente cuando se te pida.
mysql_secure_installation

echo "Cargando zonas horarias en MariaDB..."
mysql_tzinfo_to_sql /usr/share/zoneinfo | mysql mysql

echo "--- 3. Descargando y extrayendo GLPI 10.0.19 ---"
cd /var/www/html
wget https://github.com/glpi-project/glpi/releases/download/10.0.19/glpi-10.0.19.tgz
tar -xvzf glpi-10.0.19.tgz
rm glpi-10.0.19.tgz # Limpiar el comprimido

echo "--- 4. Configurando rutas personalizadas (Hardening) ---"

# Crear directorios necesarios
mkdir -p /etc/glpi
mkdir -p /var/lib/glpi
mkdir -p /var/log/glpi

# Crear archivo downstream.php
cat <<EOF > /var/www/html/glpi/inc/downstream.php
<?php
define('GLPI_CONFIG_DIR', '/etc/glpi/');
if (file_exists(GLPI_CONFIG_DIR . '/local_define.php')) {
    require_once GLPI_CONFIG_DIR . '/local_define.php';
}
EOF

# Mover directorios originales a sus nuevas ubicaciones
mv /var/www/html/glpi/config/ /etc/glpi/
mv /var/www/html/glpi/files/ /var/lib/glpi/
# Nota: El log se mueve de forma específica
mv /var/lib/glpi/_log /var/log/glpi || true

# Crear archivo local_define.php
cat <<EOF > /etc/glpi/local_define.php
<?php
define('GLPI_VAR_DIR', '/var/lib/glpi');
define('GLPI_DOC_DIR', GLPI_VAR_DIR);
define('GLPI_CACHE_DIR', GLPI_VAR_DIR . '/_cache');
define('GLPI_CRON_DIR', GLPI_VAR_DIR . '/_cron');
define('GLPI_GRAPH_DIR', GLPI_VAR_DIR . '/_graphs');
define('GLPI_LOCAL_I18N_DIR', GLPI_VAR_DIR . '/_locales');
define('GLPI_LOCK_DIR', GLPI_VAR_DIR . '/_lock');
define('GLPI_PICTURE_DIR', GLPI_VAR_DIR . '/_pictures');
define('GLPI_PLUGIN_DOC_DIR', GLPI_VAR_DIR . '/_plugins');
define('GLPI_RSS_DIR', GLPI_VAR_DIR . '/_rss');
define('GLPI_SESSION_DIR', GLPI_VAR_DIR . '/_sessions');
define('GLPI_TMP_DIR', GLPI_VAR_DIR . '/_tmp');
define('GLPI_UPLOAD_DIR', GLPI_VAR_DIR . '/_uploads');
define('GLPI_INVENTORY_DIR', GLPI_VAR_DIR . '/_inventories');
define('GLPI_THEMES_DIR', GLPI_VAR_DIR . '/_themes');
define('GLPI_LOG_DIR', '/var/log/glpi');
EOF

echo "--- 5. Ajustando permisos y seguridad ---"

# Asignar propietario
chown www-data:www-data /var/www/html/glpi/ -R
chown www-data:www-data /etc/glpi -R
chown www-data:www-data /var/lib/glpi -R
chown www-data:www-data /var/log/glpi -R
chown www-data:www-data /var/www/html/glpi/marketplace -Rf

# Permisos de archivos (644) y directorios (755)
find /var/www/html/glpi/ -type f -exec chmod 0644 {} \;
find /var/www/html/glpi/ -type d -exec chmod 0755 {} \;
find /etc/glpi -type f -exec chmod 0644 {} \;
find /etc/glpi -type d -exec chmod 0755 {} \;
find /var/lib/glpi -type f -exec chmod 0644 {} \;
find /var/lib/glpi -type d -exec chmod 0755 {} \;
find /var/log/glpi -type f -exec chmod 0644 {} \;
find /var/log/glpi -type d -exec chmod 0755 {} \;

echo "--- Instalación finalizada ---"
echo "Recuerda configurar el VirtualHost de Apache para apuntar a /var/www/html/glpi/public"
