#!/bin/bash
clear
echo
echo "This will set the hostname and IP addresses for eth0, and eth1, then it will reinitialize the firewall"
echo
echo 
echo "All current configuration will be deleted"
echo
echo -n "Continue [N,y]: "
read DECISION

if [ "x$DECISION" != "xy" ]; then
	echo
	echo "Script cancelled. " 
	exit;
fi

echo

#FWNUM=XX
#echo -n "Firewall number: [$FWNUM]: "
#read FWNUM

PUBIP="xxx.xxx.xxx.xxx"
echo -n "Public IP: [$PUBIP]:"
read PUBIP

MGMTIP="10.xxx.xxx.xxx"
echo -n "Management IP: [$MGMTIP]:"
read MGMTIP

INTERNALIP="172.xxx.xxx.xxx"
echo -n "Internal IP: [$INTERNALIP]:"
read INTERNALIP

FWNUM=`cut -d "." -f 4`
FWNAME="fw${FWNUM}.netfnds.com"
FWINAME="nfnm-fw${FWNUM}.management.netfnds.com"
#PUBIP="64.191.236.${FWNUM}"
#INTERIP="172.16.11.${FWNUM}"

echo
echo Configuration:
echo "Firewall hostname: $FWNAME"
echo "Management Name: $FWINAME"
echo "Public IP: $PUBIP"
echo "Management IP: $MGMTIP"
echo "Internal IP: $INTERNALIP"
#echo "Interconect IP: $INTERIP" # deprecated EMG
echo -n "Okay? (N|y): "
read okay

if [ "x$okay" != "xy" ]; then
okay=no
while [ $okay != "y" ]; do 
	echo -n "hostname: [$FWNAME]: "
	read FWNAME
	echo "hostname=$FWNAME"
	echo -n "Okay? (N|y):"
	read okay
done

okay=no
while [ $okay != "y" ]; do
	echo -n "Public IP: [$PUBIP]: "
	read PUBIP
	echo "Public IP=$PUBIP"
	echo -n "Okay? (N|y):"
	read okay
done

okay=no
while [ $okay != "y" ]; do
	echo -n "Management IP: [$MGMTIP]: "
	read MGMTIP
	echo "Management IP=$MGMTIP"
	echo -n "Okay? (N|y):"
	read okay
done

okay=no
while [ $okay != "y" ]; do
	echo -n "Internal IP: [$INTERNALIP]: "
	read INTERNALIP
	echo "Internal IP=$INTERNALIP"
	echo -n "Okay? (N|y):"
	read okay
done

okay=no
###### The below is deprecated on firewall with only two interfaces. 
#while [ $okay != "y" ]; do
#	echo -n "Interconnect IP: [$INTERIP]: "
#	read INTERIP
#	echo "Internconnect IP=$INTERIP"
#	echo -n "Okay? (N|y):"
#	read okay
#done
fi

echo
echo Configuration: 
echo $FWNAME
echo $FWINAME
echo $PUBIP
echo $MGMTIP
echo $INTERNALIP
#echo $INTERIP # dprecateed EMG
echo

for i in 5 4 3 2 1; do
	echo -n "Initializing in ... $i"
	sleep 1
	echo -ne "\r"
done

cat > /etc/hostname <<END
${FWNAME}
END

cat > /etc/hosts <<END
127.0.0.1		localhost.localdomain	localhost
${PUBIP}		${FWNAME}
END

for i in bgpd ospfd ripd zebra; do
	service $i stop
done

cat > /etc/quagga/zebra.conf <<END
!
hostname ${FWNAME}
!
interface eth0
 ipv6 nd suppress-ra
!
interface eth1
 ipv6 nd suppress-ra
!
interface lo
 ip address 127.0.0.1/8
!
ip route 0.0.0.0/0 64.191.236.1 240
!
ipv6 forwarding
!
!
line vty
!
END

cat > /etc/quagga/ripd.conf <<END
!
hostname ${FWNAME}
!
interface eth0
 ip rip authentication mode text
 ip rip authentication string Rip@2007
!
router rip
 version 2
 network eth1
!
line vty
!
END

for i in zebra ripd ospfd bgpd; do
	service $i start
done

vtysh<<EEND
conf term
ip route 0.0.0.0/0 64.191.236.1 240
end
copy run start
EEND




service iptables stop
cp -f /root/scripts/config/iptables /etc/network/iptables_save
service iptables start


./mkfw-intf out eth1 nat $PUBIP/24
./mkfw-intf in eth2 nat $INTERNALIP/24
service iptables save

{
echo "tc qdisc add dev eth1 root handle 1: htb" 
echo "tc qdisc add dev eth2 root handle 1: htb"
echo
} > /root/scripts/config/tc-config

echo
echo
echo "Firewall has been initialized"
echo 
echo "Rebooting..."
echo
echo
reboot
