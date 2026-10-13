#!/bin/bash

# 1. DNS Sementara untuk instalasi paket
echo "nameserver 192.168.122.1" > /etc/resolv.conf
echo "nameserver 8.8.8.8" >> /etc/resolv.conf

# 2. Instalasi Paket ISC DHCP Server
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-server

# 3. Tetapkan listening interface pada eth0
echo 'INTERFACESv4="eth0"' > /etc/default/isc-dhcp-server

# 4. Tulis File Konfigurasi dhcpd.conf
cat << 'EOC' > /etc/dhcp/dhcpd.conf
# =============================================================
# PARAMETER GLOBAL (Soal 2 & Soal 7)
# =============================================================
default-lease-time 600;
max-lease-time 7200;
authoritative;

option domain-name-servers 192.218.1.2, 192.218.1.3;
option domain-name "k14.com";
option domain-search "k14.com";

# =============================================================
# CLASS DIVISI A (Soal 4)
# =============================================================
class "pool1-clients" {
    match hardware;
}
subclass "pool1-clients" 1:02:42:6c:43:66:00; # itadori
subclass "pool1-clients" 1:02:42:0e:6c:c7:00; # fushiguro

class "pool2-clients" {
    match hardware;
}
subclass "pool2-clients" 1:02:42:cb:7a:f8:00; # zenin
subclass "pool2-clients" 1:02:42:1d:9e:34:00; # okkotsu

# =============================================================
# CLASS DIVISI B (Soal 5)
# =============================================================
class "short-lease-clients" {
    match hardware;
}
subclass "short-lease-clients" 1:02:42:7a:76:5b:00; # ino
subclass "short-lease-clients" 1:02:42:5f:4d:2a:00; # kusakabe

class "long-lease-clients" {
    match hardware;
}
subclass "long-lease-clients" 1:02:42:c9:60:89:00; # miwa

# =============================================================
# NETWORK 4: Subnet Data Center (Soal 2 - No Dynamic Pool)
# =============================================================
subnet 192.218.4.0 netmask 255.255.255.0 {
}

# =============================================================
# NETWORK 2: Divisi A (Soal 4 - Dual Pool & Isolasi .36-.69)
# =============================================================
subnet 192.218.2.0 netmask 255.255.255.0 {
    option routers 192.218.2.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.218.2.255;

    pool {
        allow members of "pool1-clients";
        range 192.218.2.10 192.218.2.35;
    }

    pool {
        allow members of "pool2-clients";
        range 192.218.2.70 192.218.2.95;
    }
}

# =============================================================
# NETWORK 3: Divisi B (Soal 5 Short/Long Lease & Soal 6 Fixed IP)
# =============================================================
subnet 192.218.3.0 netmask 255.255.255.0 {
    option routers 192.218.3.1;
    option subnet-mask 255.255.255.0;
    option broadcast-address 192.218.3.255;

    # Short Lease: 30 menit (1800 detik)
    pool {
        allow members of "short-lease-clients";
        range 192.218.3.10 192.218.3.89;
        default-lease-time 1800;
        max-lease-time 1800;
    }

    # Long Lease: 12 jam (43200 detik)
    pool {
        allow members of "long-lease-clients";
        range 192.218.3.100 192.218.3.199;
        default-lease-time 43200;
        max-lease-time 43200;
    }

    # VIP Static Lease: kugisaki (Soal 6)
    host kugisaki {
        hardware ethernet 02:42:61:52:58:00;
        fixed-address 192.218.3.99;
    }
}
EOC

# 5. Uji Sintaks dan Jalankan Service
dhcpd -t -cf /etc/dhcp/dhcpd.conf
pkill dhcpd 2>/dev/null
service isc-dhcp-server restart || dhcpd -4 -cf /etc/dhcp/dhcpd.conf

echo "Setup DHCP Server tengen selesai dan aktif!"