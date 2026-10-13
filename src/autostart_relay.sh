#!/bin/bash

# 1. Konfigurasi Interface Gateway Network 1 s.d. 4
ip link set eth1 up && ip addr flush dev eth1 && ip addr add 192.218.1.1/24 dev eth1
ip link set eth2 up && ip addr flush dev eth2 && ip addr add 192.218.2.1/24 dev eth2
ip link set eth3 up && ip addr flush dev eth3 && ip addr add 192.218.3.1/24 dev eth3
ip link set eth4 up && ip addr flush dev eth4 && ip addr add 192.218.4.1/24 dev eth4

# 2. Aktifkan IPv4 Forwarding dan Source NAT (Masquerade) ke WAN (eth0)
sysctl -w net.ipv4.ip_forward=1
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE 2>/dev/null

# 3. Jalankan Daemon DHCP Relay menuju Server tengen (192.218.4.10)
pkill dhcrelay 2>/dev/null
dhcrelay -4 -i eth2 -i eth3 -i eth4 192.218.4.10

echo "Routing dan DHCP Relay jichi aktif!"