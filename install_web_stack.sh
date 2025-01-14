#!/bin/bash

# Define your root password
MYSQL_ROOT_PASSWORD="mysql_root_password"

# Define your domain
YOUR_DOMAIN="your_domain.com"

# Update package lists
sudo apt update

# Upgrade installed packages
sudo apt upgrade -y

# Perform distribution upgrade
sudo apt dist-upgrade -y

# Install Nginx, MySQL Server, PHP-FPM, and PHP MySQL extension
sudo apt install nginx mysql-server php-fpm php-mysql -y

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

# Create directory for your domain
sudo mkdir /var/www/$YOUR_DOMAIN

# Set ownership of the directory to the current user
sudo chown -R $USER:$USER /var/www/$YOUR_DOMAIN

# Determine PHP version
PHP_VERSION=$(php -v | head -n 1 | cut -d " " -f 2 | cut -f1-2 -d".")

# Set fastcgi_pass dynamically based on PHP version
FASTCGI_PASS="unix:/var/run/php/php${PHP_VERSION}-fpm.sock"

# Create Nginx server block configuration file
sudo bash -c "cat > /etc/nginx/sites-available/$YOUR_DOMAIN" <<EOF
server {
    listen 80;
    server_name $YOUR_DOMAIN www.$YOUR_DOMAIN;
    root /var/www/$YOUR_DOMAIN;

    index index.html index.php;

    location / {
        try_files $uri $uri/ /index.php?$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass $FASTCGI_PASS;
     }

    location ~ /\.ht {
        deny all;
    }
}
EOF

# Create a symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/$YOUR_DOMAIN /etc/nginx/sites-enabled/

# Check Nginx configuration
sudo nginx -t

# Restart Nginx
sudo systemctl restart nginx
