#!/bin/sh

echo "=== 1. Melepaskan Lease Lama & Meminta IP Baru ==="
killall udhcpc 2>/dev/null
ip addr flush dev eth0
udhcpc -i eth0

echo -e "\n=== 2. Alamat IP Antarmuka eth0 ==="
ip a show dev eth0

echo -e "\n=== 3. Tabel Routing (Default Gateway) ==="
ip route

echo -e "\n=== 4. Konfigurasi DNS Resolver (/etc/resolv.conf) ==="
cat /etc/resolv.conf

echo -e "\n=== 5. Uji Konektivitas Gateway ==="
GW=$(ip route | grep default | awk '{print $3}')
if [ -n "$GW" ]; then
    ping -c 2 "$GW"
else
    echo "Default gateway tidak ditemukan!"
fi