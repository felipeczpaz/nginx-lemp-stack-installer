#!/usr/bin/env bash
set -euo pipefail

MYSQL_ROOT_PASSWORD="mysql_root_password"
YOUR_DOMAIN="your_domain.com"

sudo pacman -Syu --noconfirm
sudo pacman -S --noconfirm nginx mariadb php php-fpm

sudo rm -rf /var/lib/mysql
sudo rm -rf /var/log/mysql
sudo rm -rf /run/mysqld

# Create MariaDB/MySQL directories (data/log/socket runtime)
sudo mkdir -p /var/lib/mysql
sudo mkdir -p /var/log/mysql
sudo mkdir -p /run/mysqld

# Set ownership
sudo chown -R mysql:mysql /var/lib/mysql /var/log/mysql /run/mysqld

# Set permissions
sudo chmod 700 /var/lib/mysql
sudo chmod 755 /var/log/mysql
sudo chmod 755 /run/mysqld

sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql


sudo nginx -t

sudo systemctl enable --now mariadb
sudo systemctl enable --now mysql
sudo systemctl enable --now mysqld
sudo systemctl enable --now nginx

sudo systemctl restart mariadb
sudo systemctl restart mysql
sudo systemctl restart mysqld
sudo systemctl restart nginx

# --- MariaDB secure install (mysql_secure_installation equivalent) ---
SECURE_BIN="$(command -v mysql_secure_installation || true)"
if [ -z "$SECURE_BIN" ]; then
  echo "Error: mysql_secure_installation not found. Install/ensure MariaDB server utilities are present." >&2
  exit 1
fi

# Some MariaDB builds require the "current password" to be blank on fresh installs.
# This heredoc answers:
# - Set root password? y
# - New password
# - Re-enter new password
# - Remove anonymous users? y
# - Disallow root login remotely? y
# - Remove test database and access to it? y
# - Reload privilege tables? y

# Secure MySQL installation
sudo mysql_secure_installation <<EOF

y
$MYSQL_ROOT_PASSWORD
$MYSQL_ROOT_PASSWORD
y
y
y
y
EOF

sudo mkdir -p "/var/www/$YOUR_DOMAIN"
sudo chown -R "$USER:$USER" "/var/www/$YOUR_DOMAIN"

PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"

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

sudo systemctl enable --now php-fpm 2>/dev/null || true

if [ -z "$FASTCGI_PASS" ]; then
  FASTCGI_PASS="unix:/run/php/php-fpm.sock"
fi


CONF="/etc/nginx/nginx.conf"
LINE="include /etc/nginx/conf.d/*.conf;"

# Ensure nginx.conf exists
[[ -f "$CONF" ]] || { echo "Missing $CONF"; exit 1; }

# Backup
cp -a "$CONF" "${CONF}.bak.$(date +%F_%H%M%S)"

# If line doesn't exist, add it (after the first "http {" block start if possible, else append)
if ! grep -Fxq "$LINE" "$CONF"; then
  if grep -qE '^[[:space:]]*http[[:space:]]*\{' "$CONF"; then
    # insert after the first http { line
    awk -v line="$LINE" '
      { print }
      $0 ~ /^[[:space:]]*http[[:space:]]*\{/ && !done {
        print line
        done=1
      }
    ' "$CONF" > "${CONF}.tmp"
    mv "${CONF}.tmp" "$CONF"
  else
    echo "$LINE" >> "$CONF"
  fi
fi


sudo mkdir -p /etc/nginx/conf.d
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

sudo nginx -t
sudo systemctl restart nginx
sudo systemctl restart php-fpm 2>/dev/null || true

echo "Done. Site: http://$YOUR_DOMAIN"

