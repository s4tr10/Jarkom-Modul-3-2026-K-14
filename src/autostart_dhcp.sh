#!/bin/bash
ip addr flush dev eth0 2>/dev/null
ip addr add 192.218.4.10/24 dev eth0
ip link set eth0 up
ip route replace default via 192.218.4.1 dev eth0

pkill dhcpd 2>/dev/null
service isc-dhcp-server start || dhcpd -4 -cf /etc/dhcp/dhcpd.conf