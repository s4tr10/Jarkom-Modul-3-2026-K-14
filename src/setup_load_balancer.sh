#!/bin/bash

# ==============================================================
# Script Setup Internal Load Balancer (geto - 192.218.4.2) - Soal 15
# Upstream api_cluster (Weighted Round Robin 3:1: nanami & todo)
# ==============================================================

# 1. Resolver & Install Nginx
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

# 2. Konfigurasi Upstream Weighted Round Robin di /etc/nginx/sites-available/default
cat << 'EOF' > /etc/nginx/sites-available/default
upstream api_cluster {
    server 192.218.4.5:80 weight=3 max_fails=2 fail_timeout=5s; # nanami (worker utama)
    server 192.218.4.6:80 weight=1 max_fails=2 fail_timeout=5s; # todo (worker utama)
    server 192.218.4.7:80 backup;                                # kirara (worker cadangan/backup)
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Soal 17: Hanya percaya proxy terpercaya gojo (192.218.1.4)
    set_real_ip_from 192.218.1.4;
    real_ip_header X-Forwarded-For;
    real_ip_recursive on;

    location / {
        proxy_pass http://api_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 2s;
        proxy_read_timeout 2s;
        proxy_next_upstream error timeout invalid_header http_500 http_502 http_503;
    }
}
EOF

# 3. Uji Sintaks dan Restart Nginx
nginx -t
service nginx restart
echo "Internal Load Balancer geto (Weighted Round Robin 3:1) Berhasil Dikonfigurasi!"

