#!/bin/bash


# Packages
yum clean all
yum -y install epel-release
yum -y install ipset ipset-service wireshark zip ntp python2-pip strongswan openvpn easy-rsa iptables-services net-snmp net-tools quagga  sysstat traceroute telnet open-vm-tools policycoreutils-python bridge-utils libsemanage-python
pip install python-telegram-bot --upgrade
pip install configparser --upgrade

# Sysctl variables
cat >> /etc/sysctl.conf <<-END

net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.netfilter.nf_conntrack_acct = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

# Disables IP source routing
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# Disable ICMP Redirect Acceptance
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv4.conf.default.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Enable Log Spoofed Packets, Source Routed Packets, Redirect Packets
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# Don't relay bootp
net.ipv4.conf.all.bootp_relay = 0

# Don't proxy arp for anyone
net.ipv4.conf.all.proxy_arp = 0

# ICMP
net.ipv4.icmp_echo_ignore_all = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# Do not auto-configure IPv6
net.ipv6.conf.all.autoconf=0
net.ipv6.conf.all.accept_ra=0
net.ipv6.conf.default.autoconf=0
net.ipv6.conf.default.accept_ra=0
net.ipv6.conf.eth0.autoconf=0
net.ipv6.conf.eth0.accept_ra=0

# Increase the read-buffer space allocatable
net.ipv4.tcp_rmem = 8192 87380 16777216
net.ipv4.udp_rmem_min = 16384
net.core.rmem_default = 262144
net.core.rmem_max = 16777216

# Increase the write-buffer-space allocatable
net.ipv4.tcp_wmem = 8192 65536 16777216
net.ipv4.udp_wmem_min = 16384
net.core.wmem_default = 262144
net.core.wmem_max = 16777216

# Increase number of incoming connections
net.core.somaxconn = 32768

# Increase number of incoming connections backlog
net.core.netdev_max_backlog = 16384
net.core.dev_weight = 64

# Increase the maximum amount of option memory buffers
net.core.optmem_max = 65535

# Increase size of RPC datagram queue length
net.unix.max_dgram_qlen = 50



END


# services
systemctl disable avahi-daemon
systemctl disable firewalld
systemctl enable irqbalance
systemctl disable kdump
systemctl disable NetworkManager
systemctl disable postfix
systemctl enable ntpd
systemctl enable strongswan
systemctl enable openvpn@server
systemctl enable iptables
systemctl enable snmpd
systemctl enable zebra

# tuning

# Configs
cp config/iptables /etc/sysconfig/iptables
# SNMP


# SE LINUX
setsebool -P allow_zebra_write_config 1

cp /etc/sysconfig/grub /etc/sysconfig/grub.orig
awk '/GRUB_CMDLINE_LINUX/ {for(i = 1; i <= NF; i++) {if($i=="rhgb") {printf "net.ifnames=0 "; continue}; printf "%s ",$i;  }; printf "\n"; next} {print}' /etc/sysconfig/grub.orig > /etc/sysconfig/grub
grub2-mkconfig -o /boot/grub2/grub.cfg


# Cron backup of iptables daily
mv backups/iptables_save.sh /etc/cron.daily/
chmod +x /etc/cron.daily/iptables_save.sh
