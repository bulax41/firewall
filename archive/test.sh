#!/bin/bash

LOGFILE=/var/log/fwchangelog 
log() {
   message="$@"
   echo "$(date +%c) $message">>$LOGFILE
   logger -t mkipsec-tunnel "$message"
}

NARGS=$(echo $@|wc -w)
if [ $NARGS -le 4 ]; then
   echo "Insufficient Args"
   echo
   echo "Usage: mkipsec-tunnel 'ClientID' 'NF Public IP' 'NF Subnet' 'Client IP' 'Client Subnet' [encrypt]"
   echo "Example: mkipsec-tunnel NFLLC 64.191.236.17 172.16.205.0/24 74.125.127.100 10.205.2.0/24 encrypt"
   echo 
   exit
fi

FILEPATH=/etc/ipsec.d
CLIENTID=$1
CONNNUM=$2
NFSUBNET=$3
CLIENTIP=$4
CLIENTSUBNET=$5
ENCRYPTION=$6

cat $FILEPATH/$CLIENTID.conf|grep $CLIENTID$CONNNUM
if [ $? -ne 0 ]; then
   echo "WARNING: The Connection $CLIENTID$CONNNUM does not exist"
   exit
else 
  ipsec auto --delete $CLIENTID$CONNNUM
  log ipsec auto --delete $CLIENTID$CONNNUM   
fi

ls $FILEPATH |grep $CLIENTID.conf > /dev/null 2>&1
if [ $? -ne 0 ]; then 
   echo "WARNING: The File $FILEPATH/$CLIENTID.conf does not exist"
   exit
else
   
fi

ls $FILEPATH |grep $CLIENTID.secrets > /dev/null 2>&1
if [ $? -ne 0 ]; then
   secrets >> $FILEPATH/$CLIENTID.secrets
   log "Added $NFPUBIP $CLIENTIP: $PASSWD"
else
   cat $FILEPATH/$CLIENTID.secrets|grep $CLIENTIP > /dev/null 2>&1
   if [ $? -ne 0 ]; then
      echo "WARNING: There is already a secret for $CLIENTIP"
      exit 
   else
      secrets >> $FILEPATH/$CLIENTID.secrets
      log "Added $NFPUBIP $CLIENTIP: $PASSWD"
   fi
fi

log ipsec auto --add $CLIENTID$NEWCONNINDEX
log ipsec auto --up $CLIENTID$NEWCONNINDEX

exit
