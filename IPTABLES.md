''' Create a deterministic structure for iptables that doesn't have chains
  looping back and limiting number of rule checks when having thousands of
  Rules
'''


INBOUND: Traffic from untrusted network (Interet) to trusted or protected (internal) network-scripts
OUTBOUND: Traffic from protected network to untrust network.  Usually private to public with NAT.

FORWARDING Table:
Outgoing Interface -> Destination IP/Network -> Custom Policy -> Default Policy -> LOG -> DROP
