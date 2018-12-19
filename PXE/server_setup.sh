#!/bin/bash

PREFIX=$1
if [ "x$PREFIX" == "x" ]
then
  echo "Site prefix needed.  i.e. 10.X.X"
  exit
fi

yum -y install syslinux dhcp tftp-server vsftpd xinetd
cp -r /usr/share/syslinux/* /var/lib/tftpboot
mkdir /var/lib/tftpboot/pxelinux.cfg 2> /dev/null
cat > /etc/dhcp/dhcpd.conf << END
default-lease-time 604800;
max-lease-time 18144000;
authoritative;
option classless-routes code 121 = array of unsigned integer 8;
option classless-routes-win code 249 = array of unsigned integer 8;
option domain-name "beeks.local";
option domain-name-servers $PREFIX.254;

subnet  $PREFIX.0 netmask 255.255.255.0 {
        range $PREFIX.200 $PREFIX.249;
        option routers $PREFIX.1;
        next-server $PREFIX.254;
        filename "pxelinux.0";
}

END

cat > /var/lib/tftpboot/pxelinux.cfg/default <<END
default menu.c32
prompt 0
timeout 300
ONTIMEOUT local

menu title ########## PXE Boot Menu ##########

label 1
menu label ^1)  CentOS 7 x64
kernel centos7/vmlinuz
append initrd=centos7/initrd.img method=ftp://$PREFIX.254/pub ks=ftp://$PREFIX.254/pub/centos7.cfg devfs=nomount

label 2
menu label ^2) Firewall
kernel centos7/vmlinuz
append initrd=centos7/initrd.img method=ftp://$PREFIX.254/pub ks=ftp://$PREFIX.254/pub/firewall.cfg devfs=nomount

END

cat > /var/ftp/pub/centos7.cfg << END
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --disabled
# Install OS instead of upgrade
install
# Use FTP installation media
url --url="ftp://$PREFIX.254/pub/"
# Root password
rootpw --plaintext VDIware123
# System authorization information
auth useshadow passalgo=sha512
# Use graphical install
graphical
firstboot disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux enable
# Installation logging level
logging level=info
# System timezone
timezone America/Chicago
# System bootloader configuration
bootloader location=mbr
clearpart --all --initlabel
autopart --type lvm --fstype xfs --nohome
%packages
@^minimal
@core
%end
%addon com_redhat_kdump --disable --reserve-mb='auto'
%end
END

cat > /var/ftp/pub/firewall.cfg << END
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --disabled
# Install OS instead of upgrade
install
# Use FTP installation media
url --url="ftp://$PREFIX.254/pub/"
# Root password
rootpw --plaintext VDIware123
# System authorization information
auth useshadow passalgo=sha512
# Use graphical install
graphical
firstboot disable
# System keyboard
keyboard us
# System language
lang en_US
# SELinux configuration
selinux enable
# Installation logging level
logging level=info
# System timezone
timezone America/Chicago
# System bootloader configuration
bootloader location=mbr
clearpart --all --initlabel
autopart --type lvm --fstype xfs --nohome
%packages
@^minimal
@core
%end
%post --log=/root/post.log
yum -y install epel-release
yum -y install ipset ipset-service wireshark zip ntp python2-pip strongswan openvpn easy-rsa iptables-services net-snmp net-tools quagga  sysstat traceroute telnet  policycoreutils-python bridge-utils libsemanage-python ipa-client nmap wget
pip install --upgrade pip
pip install python-telegram-bot --upgrade
pip install configparser --upgrade
wget ftp://$PREFIX.254/pub/VMwareTools-10.2.5-8068406.tar.gz
tar zxf VMwareTools.tar.gz
cd vmware-tools-distrib
./vmware-install.pl -d -f
%end

%addon com_redhat_kdump --disable --reserve-mb='auto'
%end
END

wget http://mirror.team-cymru.com/CentOS/7.6.1810/isos/x86_64/CentOS-7-x86_64-Minimal-1810.iso
mount -o loop CentOS-7-x86_64-Minimal-1810.iso /media/
mkdir /var/lib/tftpboot/centos7 2> /dev/null
cp /media/images/pxeboot/vmlinuz  /var/lib/tftpboot/centos7/
cp /media/images/pxeboot/initrd.img  /var/lib/tftpboot/centos7/
cp -r /media/*  /var/ftp/pub/
chmod -R 755 /var/ftp/pub
umount /media
systemctl --now enable xinetd
systemctl --now enable tftp-server
systemctl --now enable dhcpd
systemctl --now enable vsftpd
