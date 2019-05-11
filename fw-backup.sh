#!/bin/bash

DIR="save.$(date '+%y%m%d.%H%M%S')"
mkdir $DIR

for i in $(iptables -L INBOUND -n | awk '{ if(match($1,/INBOUND-(.*)/,m)) print m[1]}' )
do
        echo "*filter" > $DIR/$i
        iptables -S INBOUND-$i >> $DIR/$i
        iptables -S OUTBOUND-$i >> $DIR/$i
        echo "COMMIT" >> $DIR/$i
done

tar zcf $DIR.tgz $DIR
rm -rf $DIR

