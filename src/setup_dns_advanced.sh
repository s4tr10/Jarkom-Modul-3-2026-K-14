#!/bin/bash

# ==============================================================
# Script Konfigurasi Soal 12 - DNS Master (utahime)
# CNAME www, Reverse DNS (PTR), dan Forwarder Internet
# ==============================================================

# 1. Perbarui Forward Zone dengan A record dan CNAME (/etc/bind/db.jujutsu.k14.com)
cat << 'EOF' > /etc/bind/db.jujutsu.k14.com
$TTL    604800
@       IN      SOA     ns1.jujutsu.k14.com. root.jujutsu.k14.com. (
                        2026101503      ; Serial (dinaikkan agar slave tersinkron)
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL
;
; Name Servers
@       IN      NS      ns1.jujutsu.k14.com.
@       IN      NS      ns2.jujutsu.k14.com.

; A Records
@       IN      A       192.218.1.4
ns1     IN      A       192.218.1.2
ns2     IN      A       192.218.1.3
utahime IN      A       192.218.1.2
shoko   IN      A       192.218.1.3
gojo    IN      A       192.218.1.4

; CNAME Record
www     IN      CNAME   jujutsu.k14.com.
EOF

# 2. Deklarasikan Zona Reverse DNS (/etc/bind/named.conf.local)
cat << 'EOF' > /etc/bind/named.conf.local
zone "jujutsu.k14.com" {
    type master;
    file "/etc/bind/db.jujutsu.k14.com";
    allow-transfer { 192.218.1.3; };
    also-notify { 192.218.1.3; };
};

zone "1.218.192.in-addr.arpa" {
    type master;
    file "/etc/bind/db.1.218.192";
    allow-transfer { 192.218.1.3; };
    also-notify { 192.218.1.3; };
};
EOF

# 3. Buat File Zona Reverse PTR (/etc/bind/db.1.218.192)
cat << 'EOF' > /etc/bind/db.1.218.192
$TTL    604800
@       IN      SOA     ns1.jujutsu.k14.com. root.jujutsu.k14.com. (
                        2026101501      ; Serial
                        604800          ; Refresh
                        86400           ; Retry
                        2419200         ; Expire
                        604800 )        ; Negative Cache TTL
;
@       IN      NS      ns1.jujutsu.k14.com.
@       IN      NS      ns2.jujutsu.k14.com.

; PTR Records (Reverse DNS untuk gojo 192.218.1.4)
4       IN      PTR     jujutsu.k14.com.
2       IN      PTR     ns1.jujutsu.k14.com.
3       IN      PTR     ns2.jujutsu.k14.com.
EOF

# 4. Konfigurasi DNS Forwarder (/etc/bind/named.conf.options)
cat << 'EOF' > /etc/bind/named.conf.options
options {
    directory "/var/cache/bind";

    forwarders {
        192.168.122.1;
    };

    allow-query { any; };
    dnssec-validation no;
    auth-nxdomain no;
    listen-on-v6 { any; };
};
EOF

# 5. Validasi Sintaks dan Muat Ulang Layanan named
named-checkconf
named-checkzone jujutsu.k14.com /etc/bind/db.jujutsu.k14.com
named-checkzone 1.218.192.in-addr.arpa /etc/bind/db.1.218.192
pkill named 2>/dev/null
/usr/sbin/named -u bind
echo "Konfigurasi DNS Soal 12 berhasil diterapkan!"

