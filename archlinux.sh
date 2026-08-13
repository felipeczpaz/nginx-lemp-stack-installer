#!/bin/bash
set -e

# Define your MySQL root password (CHANGE THIS)
MYSQL_ROOT_PASSWORD="mysql_root_password"

# Define your domain (CHANGE THIS)
YOUR_DOMAIN="your_domain.com"

# Update package database and upgrade
sudo pacman -Syu --noconfirm

# Install Nginx, MySQL, PHP-FPM, and PHP MySQL extension
# (On Arch, the MySQL package is usually community "mariadb" unless you specifically want MySQL.)
# We'll use MariaDB for compatibility.
sudo pacman -S --noconfirm nginx mariadb php php-fpm php-mysql

# Enable and start services
sudo systemctl enable --now nginx
sudo systemctl enable --now mariadb

# Secure MariaDB installation (mysql_secure_installation equivalent)
# On Arch, the command typically exists with the server package.
# If it isn't present for some reason, the script will fail here.
sudo mysql_secure_installation <<EOF

y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
y
y
y
y
EOF

# Create directory for your domain
sudo mkdir -p "/var/www/$YOUR_DOMAIN"

# Set ownership of the directory to current user
sudo chown -R "$USER:$USER" "/var/www/$YOUR_DOMAIN"

# Determine PHP major.minor (e.g., 8.2)
PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"

# Determine PHP-FPM socket path on Arch.
# Default socket commonly:
# /run/php/php-fpm.sock or /run/php/php${VERSION}-fpm.sock depending on packaging/config.
# We'll check a few likely locations.
SOCK_CANDIDATES=(
  "/run/php/php${PHP_VERSION}-fpm.sock"
  "/var/run/php/php${PHP_VERSION}-fpm.sock"
  "/run/php/php-fpm.sock"
  "/var/run/php/php-fpm.sock"
)

FASTCGI_PASS=""
for s in "${SOCK_CANDIDATES[@]}"; do
  if [ -S "$s" ]; then
    FASTCGI_PASS="unix:$s"
    break
  fi
done

# Start PHP-FPM and re-check if socket not found yet
sudo systemctl enable --now php-fpm 2>/dev/null || true

if [ -z "$FASTCGI_PASS" ]; then
  # As a fallback, use the common Arch default name.
  FASTCGI_PASS="unix:/run/php/php-fpm.sock"
fi

# Create Nginx config
# Arch nginx uses /etc/nginx/nginx.conf and often includes conf.d/*.conf.
# We'll keep it simple: create a dedicated file in conf.d.
sudo bash -c "cat > /etc/nginx/conf.d/$YOUR_DOMAIN.conf" <<EOF
server {
    listen 80;
    server_name $YOUR_DOMAIN www.$YOUR_DOMAIN;

    root /var/www/$YOUR_DOMAIN;
    index index.html index.php;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_index index.php;
        fastcgi_pass $FASTCGI_PASS;
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Validate and restart
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl restart php-fpm 2>/dev/null || true

echo "Done. Site: http://$YOUR_DOMAIN"

