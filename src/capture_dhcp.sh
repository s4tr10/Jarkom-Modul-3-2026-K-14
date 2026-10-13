#!/bin/bash

which tcpdump >/dev/null 2>&1 || (apt-get update && apt-get install -y tcpdump)

echo "=========================================================="
echo " Menunggu Paket DHCP Handshake (Discover, Offer, Req, ACK)"
echo " Segera jalankan permintaan IP baru pada node client!     "
echo "=========================================================="

tcpdump -i eth0 -nvvv -c 8 'udp and (port 67 or port 68)'