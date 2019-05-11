#!/bin/bash

if [ ! -e $1 ] 
then
        echo "File $1 not found"
        exit
fi
DIR=$(basename $1 .tgz)


tar zxf $1
for i in $(ls $DIR)
do
        ./rmfw-ip $i
        iptables-restore -n < $DIR/$i
        iptables -I INBOUND -d $i -j INBOUND-$i
        iptables -I OUTBOUND -s $i -j OUTBOUND-$i
done
rm -rf $DIR
