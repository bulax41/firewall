#!/bin/bash
wan=101
trading=102
mgmt=100
ld5=74
dc3=73
ny4=71
ch2=70
fr2=72
ty3=75
hk1=76
sgx=77
domain="beeks.local"

HOSTNAME=""

if [ "x$1" != "x" ]
then
    HOSTNAME=$1
    LOCATION=$(echo $1 | awk -F "-" '{print $3}')
    FWNUM=$(echo $1 | cut -d "-" -f 1 | cut -c 3,4,5)
else
    echo
fi

# Packages
yum clean all
yum -y install epel-release
yum -y install ipset ipset-service wireshark zip ntp python2-pip strongswan openvpn easy-rsa iptables-services net-snmp net-tools quagga  sysstat traceroute telnet  policycoreutils-python bridge-utils libsemanage-python ipa-client nmap
pip install --upgrade pip
pip install python-telegram-bot --upgrade
pip install configparser --upgrade

# services
systemctl --now disable firewalld
systemctl --now enable irqbalance
systemctl --now disable kdump
systemctl --now disable NetworkManager
systemctl --now disable postfix
systemctl --now disable chronyd
systemctl --now enable ntpd
systemctl --now disable strongswan
systemctl --now disable openvpn@server
systemctl enable ipset
systemctl enable iptables
systemctl enable snmpd
systemctl enable zebra

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
net.core.dev_weight = 1024

# Increase the maximum amount of option memory buffers
net.core.optmem_max = 65535

# Increase size of RPC datagram queue length
net.unix.max_dgram_qlen = 50

END




# IPTables Initialize
cat > /etc/sysconfig/iptables <<-END
*mangle
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:OUTBOUND - [0:0]
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A POSTROUTING -o gre+ -j ACCEPT
-A POSTROUTING -o tun+ -j ACCEPT
COMMIT
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT DROP [0:0]
:DROPnLOG - [0:0]
:FORWARDnDROP - [0:0]
:INBOUNDnDROP - [0:0]
:OUTPUTnDROP - [0:0]
:INPUTnDROP - [0:0]
:OUTBOUNDnDROP - [0:0]
:INBOUND - [0:0]
:VPN_PEERS - [0:0]
:OUTBOUND - [0:0]
:INBOUND-DEFAULT - [0:0]
:OUTBOUND-DEFAULT - [0:0]
-A INPUT -m state --state RELATED -j ACCEPT
-A INPUT -m state --state ESTABLISHED -j ACCEPT
-A INPUT -m state --state INVALID -j DROP
-A INPUT -i lo -j ACCEPT
-A INPUT -p icmp -m limit --limit 10/s -j ACCEPT
-A INPUT -p udp -m udp --dport 1194 -m limit --limit 5/s -j ACCEPT
-A INPUT -p esp -j VPN_PEERS
-A INPUT -p 47 -j VPN_PEERS
-A INPUT -p udp -m udp --dport 500 -j VPN_PEERS
-A INPUT -p udp -m udp --dport 4500 -j VPN_PEERS
-A INPUT -j INPUTnDROP
-A INPUTnDROP -j DROP
-A VPN_PEERS -j DROP
-A FORWARD -j FORWARDnDROP
-A FORWARDnDROP -m limit --limit 5/s -j LOG --log-prefix "FORWARD DROP:  "
-A FORWARDnDROP -j DROP
-A OUTPUT -m state --state ESTABLISHED -j ACCEPT
-A OUTPUT -m state --state RELATED -j ACCEPT
-A OUTPUT -o lo -j ACCEPT
-A OUTPUT -p icmp -j ACCEPT
-A OUTPUT -o gre+ -j ACCEPT
-A OUTPUT -p udp -m udp --dport 53 -j ACCEPT
-A OUTPUT -p udp -m udp --dport 123 -j ACCEPT
-A OUTPUT -p tcp -m tcp --dport 80 -j ACCEPT
-A OUTPUT -p tcp -m tcp --dport 443 -j ACCEPT
-A OUTPUT -p udp -m udp --dport 500 -j VPN_PEERS
-A OUTPUT -p udp -m udp --dport 4500 -j VPN_PEERS
-A OUTPUT -p esp -j VPN_PEERS
-A OUTPUT -p 47 -j VPN_PEERS
-A OUTPUT -j OUTPUTnDROP
-A OUTPUTnDROP -m limit --limit 5/s -j LOG --log-prefix "OUTPUT DROP:  "
-A OUTPUTnDROP -j DROP
-A INBOUND -j INBOUNDnDROP
-A INBOUNDnDROP -j DROP
-A OUTBOUND -j OUTBOUNDnDROP
-A OUTBOUNDnDROP -j DROP
-A DROPnLOG -j DROP
-A OUTBOUND-DEFAULT -j OUTBOUNDnDROP
-A INBOUND-DEFAULT -j INBOUNDnDROP
COMMIT

END

# SE LINUX
setsebool -P allow_zebra_write_config 1

cp /etc/sysconfig/grub /etc/sysconfig/grub.orig
awk '/GRUB_CMDLINE_LINUX/ {for(i = 1; i <= NF; i++) {if($i=="rhgb") {printf "net.ifnames=0 "; continue}; printf "%s ",$i;  }; printf "\n"; next} {print}' /etc/sysconfig/grub.orig > /etc/sysconfig/grub
grub2-mkconfig -o /boot/grub2/grub.cfg


# Cron backup of iptables daily
mkdir /root/firewall/backups
cat > /etc/cron.daily/iptables_backup.sh <<-END
#!/bin/bash
iptables-save > /root/firewall/backups/iptables.\$(date +%Y%m%d)
ipset save > /root/firewall/backups/ipset.\$(date +%Y%m%d)
ip rule > /root/firewall/backups/rules.\$(date +%Y%m%d)
vtysh  vtysh -c "show run" > /root/firewall/backups/quagga.\$(date +%Y%m%d)
find /root/firewall/backups/ -mtime +30 -delete

END
chmod +x /etc/cron.daily/iptables_backup.sh

cat > /etc/cron.d/reboot <<-ENDCAT
0 7 * * 6 root /root/firewall/reboot.sh
END

cat > /etc/logrotate.conf <<-END
# rotate log files weekly
daily

# keep 4 weeks worth of backlogs
rotate 7

# create new (empty) log files after rotating old ones
create

# use date as a suffix of the rotated file
dateext

# uncomment this if you want your log files compressed
compress

# RPM packages drop log rotation information into this directory
include /etc/logrotate.d

# no packages own wtmp and btmp -- we'll rotate them here
/var/log/wtmp {
    monthly
    create 0664 root utmp
        minsize 1M
    rotate 1
}

/var/log/btmp {
    missingok
    monthly
    create 0600 root utmp
    rotate 1
}
END


if [ "x$HOSTNAME" != "x" ]
then

# iproute2 tables
cat >> /etc/iproute2/rt_tables <<-END
$mgmt mgmt
$wan wan
$trading trading
END

echo $HOSTNAME > /etc/hostname
cat > /etc/resolv.conf <<-END
search beeks.local
nameserver 10.$((LOCATION)).$((LOCATION)).254
END



fi
