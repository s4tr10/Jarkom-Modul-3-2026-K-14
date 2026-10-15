#!/bin/bash

# ==============================================================
# Script Setup DB Slave (inumaki - 192.218.4.9) - Soal 13
# ==============================================================

# 1. Resolver untuk instalasi paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

# 2. Konfigurasi bind-address dan server-id = 2
CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
[ ! -f "$CONF" ] && CONF="/etc/mysql/my.cnf"

sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$CONF"
if grep -q "server-id" "$CONF"; then
    sed -i 's/^#server-id.*/server-id = 2/' "$CONF"
else
    sed -i '/\[mysqld\]/a server-id = 2' "$CONF"
fi

# 3. Buat direktori log dan socket dengan kepemilikan mysql
mkdir -p /var/log/mysql /run/mysqld
chown -R mysql:mysql /var/log/mysql /run/mysqld

# 4. Restart MariaDB
service mariadb restart || /etc/init.d/mariadb restart

# 4. Buat Database dan Struktur Tabel yang Sama
mariadb -e "
CREATE DATABASE IF NOT EXISTS db_shibuya_k14;
USE db_shibuya_k14;
CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(50) NOT NULL,
    endpoint VARCHAR(100) DEFAULT '/api',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
"

echo "=== Inumaki DB Slave Siap Dihubungkan ke Master ==="
echo "Jalankan perintah CHANGE MASTER TO dengan nilai File & Position dari yaga!"

