#!/bin/bash

# ==============================================================
# Script Setup Public Reverse Proxy (gojo - 192.218.1.4)
# Soal 16, 17, & 19:
#   - Path-Based Routing:
#       /     -> Frontend Workers (maki & panda) Round Robin
#       /api  -> Internal Load Balancer geto (192.218.4.2)
#   - Header Forwarding: X-Real-IP & X-Forwarded-For
#   - Proxy Caching: Cache frontend 10 menit + X-Cache-Status
#   - Rate Limiting: 10 request/detik per IP klien pada /api (HTTP 429)
# ==============================================================

# 1. Update & Instalasi Nginx
echo "nameserver 192.168.122.1" > /etc/resolv.conf
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y nginx

# 2. Siapkan Direktori Cache Nginx
mkdir -p /var/cache/nginx/web
chown -R www-data:www-data /var/cache/nginx

# 3. Konfigurasi Nginx di /etc/nginx/sites-available/default
cat << 'EOF' > /etc/nginx/sites-available/default
# Proxy Cache Zone untuk Frontend (Masa berlaku 10 menit)
proxy_cache_path /var/cache/nginx/web levels=1:2 keys_zone=web_cache:10m max_size=100m inactive=60m use_temp_path=off;

# Rate Limiting Zone untuk Endpoint API (10 r/s per IP klien)
limit_req_zone $binary_remote_addr zone=api_limit:10m rate=10r/s;
limit_req_status 429;

upstream frontend_cluster {
    server 192.218.4.3:80; # maki
    server 192.218.4.4:80; # panda
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name jujutsu.k14.com www.jujutsu.k14.com;

    # 1. Root (/) -> Diteruskan ke Frontend Cluster dengan Caching 10 Menit
    location / {
        proxy_pass http://frontend_cluster;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 3s;
        proxy_read_timeout 3s;

        # Konfigurasi Proxy Caching 10 Menit
        proxy_cache web_cache;
        proxy_cache_valid 200 302 10m;
        proxy_cache_valid 404 1m;
        proxy_cache_use_stale error timeout updating http_500 http_502 http_503 http_504;
        proxy_ignore_headers Cache-Control Expires Set-Cookie;
        proxy_hide_header Set-Cookie;

        # Header Status Caching (MISS / HIT)
        add_header X-Cache-Status $upstream_cache_status;
    }

    # 2. Path /api -> Diteruskan ke Internal Load Balancer geto dengan Rate Limiting 10 r/s
    location /api {
        limit_req zone=api_limit burst=10 nodelay;

        proxy_pass http://192.218.4.2/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 3s;
        proxy_read_timeout 3s;
    }
}
EOF

# 4. Uji Sintaks dan Restart Nginx
nginx -t
service nginx restart
echo "Public Reverse Proxy gojo Berhasil Dikonfigurasi dengan Caching dan Rate Limiting!"

