#!/bin/bash

# Script de instalación automática de ownCloud
# Basado en PHP 7.4 (Requerido por versiones estables de ownCloud)

set -e

# --- CONFIGURACIÓN DE VARIABLES ---
DB_NAME="owncloud"
DB_USER="dbadmin"
DB_PASS="12345"
ROOT_DB_PASS="" # Déjala vacía si no tienes contraseña de root

echo "--- 1. Agregando repositorio PHP y actualizando ---"
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository -y ppa:ondrej/php
sudo apt update

echo "--- 2. Instalando Apache, MariaDB y PHP 7.4 ---"
sudo apt install -y apache2 mariadb-server redis-server bzip2 \
php7.4-{zip,xml,intl,mbstring,gd,curl,mysql,bz2,cli,apcu,redis} libapache2-mod-php7.4

# Forzar PHP 7.4 como predeterminado
sudo update-alternatives --set php /usr/bin/php7.4

echo "--- 3. Configurando Base de Datos ---"
sudo mysql -u root <<EOF
CREATE DATABASE IF NOT EXISTS $DB_NAME;
CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
EOF

echo "--- 4. Descargando y extrayendo ownCloud ---"
cd /tmp
wget https://download.owncloud.com/server/stable/owncloud-complete-latest.tar.bz2
tar -xjvf owncloud-complete-latest.tar.bz2
sudo mv owncloud /var/www/

echo "--- 5. Configurando Apache ---"
sudo cat <<EOF | sudo tee /etc/apache2/sites-available/owncloud.conf
<VirtualHost *:80>
    Alias /owncloud "/var/www/owncloud/"
    DirectoryIndex index.php
    <Directory /var/www/owncloud/>
        Options +FollowSymlinks
        AllowOverride All
        <IfModule mod_dav.c>
            Dav off
        </IfModule>
        SetEnv HOME /var/www/owncloud
        SetEnv HTTP_HOME /var/www/owncloud
    </Directory>
</VirtualHost>
EOF

sudo a2ensite owncloud.conf
sudo a2enmod headers env dir mime unique_id rewrite

echo "--- 6. Ajustando permisos ---"
sudo chown -R www-data:www-data /var/www/owncloud/
sudo find /var/www/owncloud/ -type d -exec chmod 750 {} \;
sudo find /var/www/owncloud/ -type f -exec chmod 640 {} \;

echo "--- 7. Reiniciando servicios ---"
sudo systemctl restart apache2
sudo systemctl restart mariadb

echo "-------------------------------------------------------"
echo " ¡Instalación completada!"
echo " Acceso: http://tu_ip/owncloud"
echo " DB Name: $DB_NAME"
echo " DB User: $DB_USER"
echo " DB Pass: $DB_PASS"
echo "-------------------------------------------------------"
