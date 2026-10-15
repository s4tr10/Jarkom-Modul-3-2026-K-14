#!/bin/bash

# ==============================================================
# Script Setup Frontend Worker (maki & panda) - Soal 14
# IP Maki: 192.218.4.3 | IP Panda: 192.218.4.4
# ==============================================================

# 1. Resolver & Instalasi Nginx + PHP-FPM
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php-fpm

# 2. Jalankan PHP-FPM dan deteksi socket
service php*-fpm start || /etc/init.d/php*-fpm start
PHP_SOCK=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -n 1)

# 3. Buat File Frontend index.php
mkdir -p /var/www/html
cat << 'EOF' > /var/www/html/index.php
<?php
header('Content-Type: text/plain');
echo "Frontend Server: " . gethostname() . "\n";
?>
EOF
chown -R www-data:www-data /var/www/html

# 4. Konfigurasi Nginx Virtual Host (Hanya Izinkan gojo 192.218.1.4)
cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name jujutsu.k14.com www.jujutsu.k14.com _;

    root /var/www/html;
    index index.php index.html;

    # Batasi Akses: Hanya menerima trafik dari proxy gojo (192.218.1.4) & localhost
    allow 192.218.1.4;
    allow 127.0.0.1;
    deny all;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_SOCK;
    }
}
EOF

# 5. Uji Sintaks dan Restart Layanan
nginx -t
service php*-fpm restart
service nginx restart
echo "Frontend Worker $(hostname) Berhasil Dikonfigurasi!"

