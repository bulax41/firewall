#!/bin/bash


# Packages
yum clean all
yum -y install epel-release
yum -y install wireshark ntp strongswan openvpn iptables-services net-snmp net-tools quagga  sysstat traceroute telnet open-vm-tools

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
systemctl disable avahi-daemon
systemctl disable firewalld
systemctl disable irqbalance
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

echo >> /etc/default/grub <<-END
GRUB_TIMEOUT=5
GRUB_DISTRIBUTOR="$(sed 's, release .*$,,g' /etc/system-release)"
GRUB_DEFAULT=saved
GRUB_DISABLE_SUBMENU=true
GRUB_TERMINAL_OUTPUT="console"
GRUB_CMDLINE_LINUX="rd.lvm.lv=centos/swap vconsole.font=latarcyrheb-sun16 rd.lvm.lv=centos/root crashkernel=auto  vconsole.keymap=us rhgb net.ifnames=0"
GRUB_DISABLE_RECOVERY="true"
END
grub2-mkconfig -o /boot/grub2/grub.cfg
