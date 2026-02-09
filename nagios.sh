#!/bin/bash

# Script de instalación interactiva de Nagios Core
# Ejecutar con privilegios de root (sudo)

set -e # Detener si hay errores

# --- PARTE INTERACTIVA: CONTRASEÑA ---
echo "-------------------------------------------------------"
echo " CONFIGURACIÓN DE ACCESO A NAGIOS"
echo "-------------------------------------------------------"
# Pedir contraseña de forma segura (sin mostrar caracteres)
read -sp "Define la contraseña para el usuario 'nagiosadmin': " NAGIOS_PW
echo ""
read -sp "Confirma la contraseña: " NAGIOS_PW2
echo ""

if [ "$NAGIOS_PW" != "$NAGIOS_PW2" ]; then
    echo "Error: Las contraseñas no coinciden. Abortando."
    exit 1
fi
echo "Contraseña guardada correctamente."
echo "-------------------------------------------------------"

echo "--- 1. Instalando dependencias ---"
sudo apt-get update
sudo apt-get install -y autoconf gcc libc6 make wget unzip apache2 php libapache2-mod-php \
libgd-dev ufw autoconf gcc libc6 libmcrypt-dev make libssl-dev wget bc gawk dc \
build-essential snmp libnet-snmp-perl gettext iputils-ping monitoring-plugins-contrib nagios-nrpe-plugin

echo "--- 2. Descargando Nagios Core ---"
cd /tmp
# Tu comando wget original (sin cambios)
wget -O nagioscore.tar.gz $(wget -q -O - https://api.github.com/repos/NagiosEnterprises/nagioscore/releases/latest | grep '"browser_download_url":' | grep -o 'https://[^"]*')

tar -xzf nagioscore.tar.gz
cd nagios-4* # Entra en la carpeta extraída

echo "--- 3. Compilando e instalando Nagios Core ---"
sudo ./configure --with-httpd-conf=/etc/apache2/sites-enabled
sudo make all
sudo make install-groups-users
sudo usermod -a -G nagios www-data
sudo make install
sudo make install-daemoninit
sudo make install-commandmode
sudo make install-config
sudo make install-webconf

echo "--- 4. Configurando Apache y Módulos ---"
sudo a2enmod rewrite
sudo a2enmod cgi

# Configuración de contraseña usando la variable interactiva
echo "$NAGIOS_PW" | sudo htpasswd -c -i /usr/local/nagios/etc/htpasswd.users nagiosadmin

sudo systemctl restart apache2.service
sudo systemctl start nagios.service

echo "--- 5. Instalando Nagios Plugins ---"
cd /tmp
wget https://github.com/nagios-plugins/nagios-plugins/archive/master.tar.gz
tar zxf master.tar.gz
cd nagios-plugins-master/

# Preparar e instalar plugins
sudo ./tools/setup
sudo ./configure
sudo make
sudo make install

echo "--- 6. Verificación final ---"
sudo /usr/local/nagios/bin/nagios -v /usr/local/nagios/etc/nagios.cfg
sudo systemctl restart nagios

echo "-------------------------------------------------------"
echo " ¡PROCESO FINALIZADO!"
echo " URL: http://$(hostname -I | awk '{print $1}')/nagios"
echo " Usuario: nagiosadmin"
echo " Contraseña: (la que definiste al principio)"
echo "-------------------------------------------------------"