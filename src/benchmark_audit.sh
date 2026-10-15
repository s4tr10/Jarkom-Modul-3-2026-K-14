#!/bin/sh

# ==============================================================
# Script Benchmark dan Pengujian Kapasitas (kusakabe) - Soal 20
# Dilakukan dari node klien Network 3 (kusakabe - alpinet)
# ==============================================================

# 1. Pastikan apache2-utils terpasang di Alpine Linux
echo "Memeriksa dan memasang apache2-utils..."
apk update
apk add apache2-utils curl

echo "=== 1. Pengujian Proxy Caching & Rate Limiting (Curl Sederhana) ==="
echo "--- Akses Halaman Web Utama Root (/) ---"
curl -i http://jujutsu.k14.com/
sleep 1
curl -i http://jujutsu.k14.com/

echo ""
echo "--- Uji Coba Bursts pada Endpoint /api ---"
for i in $(seq 1 15); do
    code=$(curl -s -o /dev/null -w "%{http_code}" http://jujutsu.k14.com/api)
    echo "Request $i: HTTP Status $code"
done

echo ""
echo "=== 2. Apache Benchmark Baseline Frontend Cluster (/): 600 Request, Concurrency 30 ==="
ab -n 600 -c 30 http://jujutsu.k14.com/

echo ""
echo "=== 3. Apache Benchmark Endpoint /api dengan Rate Limiting Aktif ==="
ab -n 600 -c 30 http://jujutsu.k14.com/api

echo "Audit Kapasitas dan Pengujian Selesai!"

