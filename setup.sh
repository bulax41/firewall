#!/bin/bash

####################################################
#
# Define Global Variables
#
####################################################
MGMTIP="10.xxx.xxx.xxx"
PUBIP="xxx.xxx.xxx.xxx"
INTERNALIP="172.xxx.xxx.5"
LOCATION="ch2|ny4|ld4|fr2"

####################################################
#
# Define Functions for script
#
####################################################

#Ask whether to run script or not
function RUN_SCRIPT {
clear
echo
echo "This will set the hostname and IP addresses for eth0, eth1 and eth2. Then it will reinitialize the firewall"
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
}

#get information from user 
# PROMPT_FOR_IP PROMPT DEFAULT_IP ANSWER_VARIABLE_NAME
function PROMPT_FOR_IP {
  local PROMPT=$1
  local IP=$2
  local ANSWER=$3

  read -e -p "$PROMPT: [$IP]: " $ANSWER
  IP=`eval echo \\$\$ANSWER`
}

# call function to get requested info from user
function PROMPT_CONFIG {
  PROMPT_FOR_IP 'Management IP' $MGMTIP MGMTIP
  PROMPT_FOR_IP 'Public IP' $PUBIP PUBIP
  PROMPT_FOR_IP 'Internal IP' $INTERNALIP INTERNALIP
##*  PROMPT_FOR_IP 'Location' $LOCATION LOCATION
  FWNUM=`echo $PUBIP | cut -d "." -f 4`
##*  FWNAME="nfvi-$LOCATION-fw${FWNUM}.netfnds.com"
  FWNAME="fw${FWNUM}.netfnds.com"
  FWINAME="nfnm-fw${FWNUM}.management.netfnds.com"
}

#loop asking for info until user acknowledges info is correct
#PROMPT_FOR_ITEM PROMPT DEFAULT_ANSWER ANSWER_VARIABLE_NAME
function PROMPT_FOR_ITEM {
  local okay=n
  while [ $okay != "y" ]; do 
	echo
	read -e -p "$1: " -i "$2" $3
	echo "$1 = `eval echo \\$\$3`"
	read -e -p "Okay? (N|y): " okay
  done
}

#Print information and prompt user for acknowledgement
function PRINT_CONFIG {
  echo
  echo Configuration:
  echo "Firewall hostname: $FWNAME"
  echo "Management Name: $FWINAME"
  echo "Management IP: $MGMTIP"
  echo "Public IP: $PUBIP"
  echo "Internal IP: $INTERNALIP"

  read -e -p "Okay? (N|y): " proceed
  if [ $proceed != "y" ]; then
    RECONFIG
  fi
}

#Function to prompt user for requested information
function RECONFIG {
  PROMPT_FOR_ITEM Hostname $FWNAME FWNAME
  PROMPT_FOR_ITEM 'Management IP' $MGMTIP MGMTIP
  PROMPT_FOR_ITEM 'Public IP' $PUBIP PUBIP
  PROMPT_FOR_ITEM 'Internal IP' $INTERNALIP INTERNALIP
##*  PROMPT_FOR_ITEM 'Location' $LOCATION LOCATION

  PRINT_CONFIG
}

#Print Final configuration information prior to reinitializing the firewall
function FINAL_CONFIG {
  echo
  echo Configuration: 
  echo $FWNAME
  echo $FWINAME
  echo $MGMTIP
  echo $PUBIP
  echo $INTERNALIP
##*  echo $LOCATION
  echo
}

####################################################
#
# Begin the Setup Script
#
####################################################

#prompt for script run
RUN_SCRIPT

#prompt for relevant information
PROMPT_CONFIG

#print relevant information
PRINT_CONFIG

#print all information prior to reinitializing the firewall
FINAL_CONFIG

for i in 5 4 3 2 1; do
	echo -n "Initializing in ... $i"
	sleep 1
	echo -ne "\r"
done

##*if [ "x$LOCATION" = "xch2" ]; then
##*  STATICROUTE=10.70.70.1
##*elif [ "x$LOCATION" = "xny4" ]; then
##*  STATICROUTE=10.72.72.1
##*elif [ "x$LOCATION" = "xld4" ]; then
##*  STATICROUTE=10.74.74.1
##*elif [ "x$LOCATION" = "xfr2" ]; then
##*  STATICROUTE=10.71.71.1
##*else
##*fi

cat > /etc/hostname <<END
${FWNAME}
END

cat > /etc/hosts <<END
127.0.0.1		localhost.localdomain	localhost
${PUBIP}		${FWNAME}
END

for i in bgpd ospfd ripd zebra; do
	service quagga stop $i
done

cat > /etc/quagga/zebra.conf <<END
!
hostname ${FWNAME}
!
interface eth0
!
interface eth1
!
interface eth2
!
interface lo
 ip address 127.0.0.1/8
!
ip route 0.0.0.0/0 64.191.236.14 240
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
ip route 172.16.0.0/12 $STATICROUTE
!
END

for i in zebra ripd ospfd bgpd; do
	service quagga start $i
done

MGMTSUBNET=`echo $MGMTIP | cut -d "." -f 1,2,3`

vtysh<<EEND
conf term
interface eth0
ip address $MGMTIP/24
ipv6 nd suppress-ra
ip route 172.16.0.0/12 $MGMTSUBNET.1
end
copy run start
EEND



service iptables stop
cp -f /home/smc/config/iptables /etc/network/iptables_save
service iptables start

./mkfw-intf out eth1 nat $PUBIP/24
./mkfw-intf in eth2 nat $INTERNALIP/24
service iptables save

{
echo "tc qdisc add dev eth1 root handle 1: htb" 
echo "tc qdisc add dev eth2 root handle 1: htb"
echo
} > /home/smc/config/tc-config

./wshaper eth1 10000
./wshaper eth2 10000

echo
echo
echo "Firewall has been initialized"
echo 
echo "Rebooting..."
echo
echo
reboot
