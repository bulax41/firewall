#!/bin/bash


# Packages
yum install epel-release
yum install wireshark ntp strongswan openvpn iptables-services net-snmp net-tools quagga  sysstat



# Sysctl variables
echo >> /etc/sysctl.conf <<-END

net.ipv4.ip_forward = 1
net.ipv4.conf.all.rp_filter = 0
net.ipv4.conf.default.rp_filter = 0
net.ipv4.conf.all.rp_filter = 0
net.netfilter.nf_conntrack_acct = 1
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1

END


# services


# tuning

# Configs
cp config/iptables /etc/sysconfig/iptables


# SE LINUX
setsebool -P allow_zebra_write_config 1
