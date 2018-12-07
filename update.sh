#!/bin/bash

HOSTNAME=$1
if [ "x$HOSTNAME" == "x" ];
then
  echo update.sh hostname
  echo
  echo example: update.sh fw50-customer-ny4
fi


### Backups
mkdir -p /root/firewall/backups > /dev/null 2>&1
cat > /etc/cron.daily/iptables_backup.sh <<-END
#!/bin/bash
iptables-save > /root/firewall/backups/iptables.\$(date +%Y%m%d)
ipset save > /root/firewall/backups/ipset.\$(date +%Y%m%d)
ip rule > /root/firewall/backups/rules.\$(date +%Y%m%d)
vtysh -c "show run" > /root/firewall/backups/quagga.\$(date +%Y%m%d)
find /root/firewall/backups/ -mtime +30 -delete

END
chmod +x /etc/cron.daily/iptables_backup.sh

hostname $HOSTNAME.beeks.local
echo $HOSTNAME.beeks.local  > /etc/hostname
cat > /etc/resolv.conf <<-END
search beeks.local
nameserver 10.72.72.254
END

timedatectl set-timezone America/New_York


for i in $(netstat -i |  awk '/BMRU/ {print $1}')
do
  mv /etc/sysconfig/network-scripts/ifcfg-$i /etc/sysconfig/network-scripts/ifcfg-$i.save
cat > /etc/sysconfig/network-scripts/ifcfg-$i <<-ENDCAT
  TYPE=Ethernet
  BOOTPROTO=none
  DEVICE=$i
  ONBOOT=yes
  ETHTOOL_OPTS=" -G $i rx 4096; -G $i tx 4096"
ENDCAT

done


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



cat > /etc/cron.d/reboot <<-ENDCAT
0 7 * * 6 root /root/firewall/reboot.sh
ENDCAT



for i in pete petel shaun lee tony jade calum carson ross eric stuart oxidized calumh max
do
  userdel $i > /dev/null 2>&1
done

for i in $(iptables -L FORWARD -nv | awk '/INBOUND/ {print $7}')
do
  iptables -t mangle -N OUTBOUND
  iptables -t mangle -A PREROUTING -i $i -j OUTBOUND
done

for i in IN OUT
do
  iptables -N $(echo $i)BOUND-DEFAULT > /dev/null 2>&1
  if [ $? -eq 0 ]; then
    iptables -A $(echo $i)BOUND-DEFAULT -j DROPnLOG
  fi
done

awk '/^#PermitRootLogin/ {print "PermitRootLogin no"}' /etc/ssh/sshd_config > /tmp/sshd_config
mv -f /tmp/sshd_config /etc/ssh/sshd_config

mv /usr/lib/systemd/system/getty@.service /usr/lib/systemd/system/getty\@.service.old
awk '/^ExecStart/ {print "ExecStart=-/bin/agetty --autologin root --noclear %I $TERM"}' /usr/lib/systemd/system/getty\@.service.old > /usr/lib/systemd/system/getty\@.service

yum remove open-vm-tools 

yum -y upgrade
yum install ipa-client ipset ipset-service
systemctl enable ipset

ipa-client-install —-mkdirhome -p firewall -w firewall
