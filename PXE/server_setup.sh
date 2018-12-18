#!/bin/bash

PREFIX=10.70.70

yum install syslinux dhcp tftp-server vsftpd xinetd
cp -r /usr/share/syslinux/* /var/lib/tftpboot
mkdir /var/lib/tftpboot/pxelinux.cfg
cat > /etc/dhcp/dhcpd.conf << END
default-lease-time 604800;
max-lease-time 18144000;
authoritative;
option classless-routes code 121 = array of unsigned integer 8;
option classless-routes-win code 249 = array of unsigned integer 8;
option domain-name "beeks.local";
option domain-name-servers 10.70.70.254;

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
menu label ^1) Install CentOS 7 x64 with Local Repo
kernel centos7/vmlinuz
append initrd=centos7/initrd.img method=ftp://10.70.70.254/pub ks=ftp://10.70.70.254/pub/centos7.cfg devfs=nomount

label 2
menu label ^2) Install CentOS 7 x64 with http://mirror.centos.org Repo
kernel centos7/vmlinuz
append initrd=centos7/initrd.img method=http://mirror.centos.org/centos/7/os/x86_64/ devfs=nomount ip=dhcp

END

cat > /var/ftp/pub/centos7.cfg << END
#platform=x86, AMD64, or Intel EM64T
#version=DEVEL
# Firewall configuration
firewall --disabled
# Install OS instead of upgrade
install
# Use FTP installation media
url --url="ftp://10.70.70.254/pub/"
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

wget http://mirror.team-cymru.com/CentOS/7.6.1810/isos/x86_64/CentOS-7-x86_64-Minimal-1810.iso
mount -o loop CentOS-7-x86_64-Minimal-1810.iso /media/
mkdir /var/lib/tftpboot/centos7
cp /media/images/pxeboot/vmlinuz  /var/lib/tftpboot/centos7/
cp /media/images/pxeboot/initrd.img  /var/lib/tftpboot/centos7/
cp -r /media/*  /var/ftp/pub/
chmod -R 755 /var/ftp/pub
umount /media
systemctl --now enable xinetd
systemctl --now enable tftp-server
systemctl --now enable dhcpd
systemctl --now enable vsftpd
