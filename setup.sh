#!/bin/bash


# Packages
yum clean all
yum -y install epel-release
yum -y install wireshark zip ntp python2-pip strongswan openvpn easy-rsa iptables-services net-snmp net-tools quagga  sysstat traceroute telnet open-vm-tools policycoreutils-python
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
awk '/GRUB_CMDLINE_LINUX/ {for(i = 1; i <= NF; i++) {if($i=="rhgb") continue; printf "%s ",$i }; printf "\n"; next} {print}' /etc/sysconfig/grub.orig > /etc/sysconfig/grub
grub2-mkconfig -o /boot/grub2/grub.cfg


# Cron backup of iptables daily
mv backups/iptables_save.sh /etc/cron.daily/
