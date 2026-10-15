#!/bin/bash

# ==============================================================
# Script Setup API Worker (nanami, todo, kirara) - Soal 14
# IP Nanami: 192.218.4.5 | IP Todo: 192.218.4.6 | IP Kirara: 192.218.4.7
# ==============================================================

# 1. Resolver & Instalasi Nginx + PHP-FPM + Driver MySQL
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx php-fpm php-mysql

# 2. Jalankan PHP-FPM dan deteksi socket
service php*-fpm start || /etc/init.d/php*-fpm start
PHP_SOCK=$(ls /run/php/php*-fpm.sock 2>/dev/null | head -n 1)

# 3. Buat File API index.php yang mencatat log request ke database yaga
mkdir -p /var/www/html
cat << 'EOF' > /var/www/html/index.php
<?php
header('Content-Type: application/json');
$hostname = gethostname();

// Deteksi IP klien asli dari header proxy atau remote address
$client_ip = isset($_SERVER['HTTP_X_REAL_IP']) ? $_SERVER['HTTP_X_REAL_IP'] : 
             (isset($_SERVER['HTTP_X_FORWARDED_FOR']) ? explode(',', $_SERVER['HTTP_X_FORWARDED_FOR'])[0] : $_SERVER['REMOTE_ADDR']);

$endpoint = $_SERVER['REQUEST_URI'];

// Simpan request log ke DB Master yaga (192.218.4.8)
$db_status = "connected";
$conn = @new mysqli('192.218.4.8', 'app_user', 'password123', 'db_shibuya_k14');
if ($conn->connect_error) {
    $db_status = "error: " . $conn->connect_error;
} else {
    $stmt = $conn->prepare("INSERT INTO request_logs (client_ip, endpoint) VALUES (?, ?)");
    if ($stmt) {
        $stmt->bind_param("ss", $client_ip, $endpoint);
        $stmt->execute();
        $stmt->close();
    }
    $conn->close();
}

echo json_encode([
    'status' => 'success',
    'worker' => $hostname,
    'client_ip' => $client_ip,
    'endpoint' => $endpoint,
    'database' => $db_status,
    'message' => "Request processed by API worker $hostname"
], JSON_PRETTY_PRINT) . "\n";
?>
EOF
chown -R www-data:www-data /var/www/html

# 4. Konfigurasi Nginx Virtual Host (Hanya Izinkan geto 192.218.4.2)
cat << EOF > /etc/nginx/sites-available/default
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name jujutsu.k14.com www.jujutsu.k14.com _;

    root /var/www/html;
    index index.php index.html;

    # Batasi Akses: Hanya menerima trafik dari load balancer geto (192.218.4.2) & localhost
    allow 192.218.4.2;
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
echo "API Worker $(hostname) Berhasil Dikonfigurasi!"

