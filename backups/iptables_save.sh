#!/bin/bash
iptables-save > /root/firewall/backups/iptables.$(date +%Y%m%d)
find /root/firewall/backups/ -mtime +30 -delete
