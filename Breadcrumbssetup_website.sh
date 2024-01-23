#!/bin/bash

read_user_input() {
    read -p "$1: " input
    echo "$input"
}

domain=$(read_user_input "Geben Sie Ihre Domain ein")
admin_email=$(read_user_input "Geben Sie die E-Mail-Adresse des Administrators ein")
website_path=$(read_user_input "Geben Sie den Pfad zu Ihren Website-Dateien ein")

# System-Updates durchführen
echo "Führe System-Updates durch..."
sudo apt update
sudo apt upgrade -y
echo "System-Updates abgeschlossen."

# Apache2 installieren und starten
echo "Installiere und starte Apache2..."
sudo apt install apache2 -y
sudo systemctl start apache2
sudo systemctl enable apache2
echo "Apache2 erfolgreich installiert und gestartet."

# Certbot installieren, wenn gewünscht
install_certbot=$(read_user_input "Möchten Sie Certbot für automatische SSL-Zertifikate installieren? (y/n)")
if [ "$install_certbot" = "y" ]; then
    echo "Installiere Certbot..."
    sudo apt install certbot python3-certbot-apache -y
    echo "Certbot erfolgreich installiert."
fi

# Website-Dateien kopieren
echo "Kopiere Website-Dateien..."
sudo mkdir -p /var/www/html/$domain
sudo cp -r $website_path/* /var/www/html/$domain
echo "Website-Dateien erfolgreich kopiert."

# Apache-Konfigurationsdatei erstellen
echo "Erstelle Apache-Konfigurationsdatei..."
sudo tee /etc/apache2/sites-available/$domain.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin $admin_email
    ServerName $domain
    DocumentRoot /var/www/html/$domain

    <Directory /var/www/html/$domain>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$domain_error.log
    CustomLog \${APACHE_LOG_DIR}/$domain_access.log combined
</VirtualHost>
EOF
echo "Apache-Konfigurationsdatei erfolgreich erstellt."

# Apache-Site aktivieren und neu starten
echo "Aktiviere Apache-Site und starte Apache neu..."
sudo a2ensite $domain.conf
sudo systemctl restart apache2
echo "Apache erfolgreich neu gestartet."

# SSL-Zertifikat einrichten, wenn Certbot installiert ist
if [ "$install_certbot" = "y" ]; then
    echo "Richte SSL-Zertifikat ein..."
    sudo certbot --apache -d $domain
    echo "SSL-Zertifikat erfolgreich eingerichtet."
fi

echo "Der Apache-Webserver wurde erfolgreich installiert und konfiguriert."
echo "Bitte führen Sie die weiteren Anpassungen entsprechend Ihren Anforderungen durch."
echo "Laden Sie nun Ihren Code in das Verzeichnis /var/www/html/$domain hoch."

echo "Credit: Rami from ogdev"
echo "Support: "https://discord.gg/AvTchZMST8"
