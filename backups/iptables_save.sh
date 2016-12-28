#!/bin/bash
iptables-save > $PWD/backups/iptables.$(date +%Y%m%d)
find $PWD/backups/ -mtime +30d -delete
