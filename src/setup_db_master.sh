#!/bin/bash

# ==============================================================
# Script Setup DB Master (yaga - 192.218.4.8) - Soal 13
# ==============================================================

# 1. Resolver untuk instalasi paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y mariadb-server

# 2. Konfigurasi bind-address, server-id, dan binary logging
CONF="/etc/mysql/mariadb.conf.d/50-server.cnf"
[ ! -f "$CONF" ] && CONF="/etc/mysql/my.cnf"

sed -i 's/^bind-address.*/bind-address = 0.0.0.0/' "$CONF"
if grep -q "server-id" "$CONF"; then
    sed -i 's/^#server-id.*/server-id = 1/' "$CONF"
else
    sed -i '/\[mysqld\]/a server-id = 1' "$CONF"
fi

if grep -q "log_bin" "$CONF"; then
    sed -i 's/^#log_bin.*/log_bin = \/var\/log\/mysql\/mysql-bin.log/' "$CONF"
else
    sed -i '/\[mysqld\]/a log_bin = /var/log/mysql/mysql-bin.log\nbinlog_do_db = db_shibuya_k14' "$CONF"
fi

# 3. Buat direktori log dan socket dengan kepemilikan mysql
mkdir -p /var/log/mysql /run/mysqld
chown -R mysql:mysql /var/log/mysql /run/mysqld

# 4. Restart MariaDB
service mariadb restart || /etc/init.d/mariadb restart

# 4. Inisialisasi Database, Tabel, User Replikasi, dan User Remote Network 4
mariadb -e "
CREATE DATABASE IF NOT EXISTS db_shibuya_k14;
USE db_shibuya_k14;
CREATE TABLE IF NOT EXISTS request_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    client_ip VARCHAR(50) NOT NULL,
    endpoint VARCHAR(100) DEFAULT '/api',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Replikasi untuk Slave inumaki
CREATE USER IF NOT EXISTS 'replica'@'%' IDENTIFIED BY 'replica123';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';

-- Hak Akses Remote untuk Seluruh Node di Network 4 (192.218.4.%)
CREATE USER IF NOT EXISTS 'app_user'@'192.218.4.%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON db_shibuya_k14.* TO 'app_user'@'192.218.4.%';
CREATE USER IF NOT EXISTS 'root'@'192.218.4.%' IDENTIFIED BY 'password123';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'192.218.4.%' WITH GRANT OPTION;

FLUSH PRIVILEGES;
"

echo "=== STATUS MASTER (Catat Nilai File & Position) ==="
mariadb -e "SHOW MASTER STATUS;"

