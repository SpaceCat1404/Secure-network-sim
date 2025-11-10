#!/bin/sh
set -e

# Wait for Docker networks to attach (max ~30s)
count=0
while [ $count -lt 30 ]; do
  IFACES=$(ls /sys/class/net | grep -v lo || true)
  if [ "$(echo "$IFACES" | wc -w)" -ge 2 ]; then
    break
  fi
  count=$((count+1))
  sleep 1
done

echo "Interfaces found: $IFACES"

# Enable IPv4 forwarding
sysctl -w net.ipv4.ip_forward=1 || true

# Flush previous rules
iptables -F
iptables -t nat -F
iptables -X

# Default DROP policy with established/related accepted
iptables -P FORWARD DROP
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i lo -j ACCEPT

# Subnet variables (must match compose)
LAN_NET="10.100.1.0/24"
DMZ_NET="10.100.2.0/24"
WAN_NET="10.100.0.0/24"
DMZ_WEB_IP="10.100.2.10"

# Allow LAN -> DMZ only HTTP to dmz-web
iptables -A FORWARD -s ${LAN_NET} -d ${DMZ_WEB_IP}/32 -p tcp --dport 80 -m conntrack --ctstate NEW -j ACCEPT

# Allow LAN -> WAN: ICMP + DNS + HTTP for demo
iptables -A FORWARD -s ${LAN_NET} -d ${WAN_NET} -p icmp -j ACCEPT
iptables -A FORWARD -s ${LAN_NET} -d ${WAN_NET} -p udp --dport 53 -j ACCEPT
iptables -A FORWARD -s ${LAN_NET} -d ${WAN_NET} -p tcp --dport 80 -j ACCEPT

# Drop remainder of LAN-originating traffic
iptables -A FORWARD -s ${LAN_NET} -j DROP

# Allow DMZ -> WAN (for package fetches if needed)
iptables -A FORWARD -s ${DMZ_NET} -d ${WAN_NET} -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

echo "iptables rules:"
iptables -L -v -n

# Build suricata interface list from non-loopback interfaces
SURICATA_IFS=""
for i in $IFACES; do
  SURICATA_IFS="${SURICATA_IFS} -i ${i}"
done

echo "Starting suricata on interfaces: $SURICATA_IFS"
suricata-update || true
suricata -c /etc/suricata/suricata.yaml ${SURICATA_IFS} -v &

# Tail logs so docker logs show them
tail -F /var/log/suricata/* /dev/null
