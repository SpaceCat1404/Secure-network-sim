#!/bin/bash
echo "🚀 Testing Network Security Lab..."

echo "1. Starting lab..."
docker-compose up -d
sleep 45

echo "Setting up routes..."
FIREWALL_LAN_IP=$(docker inspect firewall | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.key | endswith("_lan_net")) | .value.IPAddress')
FIREWALL_DMZ_IP=$(docker inspect firewall | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.key | endswith("_dmz_net")) | .value.IPAddress')
FIREWALL_WAN_IP=$(docker inspect firewall | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.key | endswith("_wan_net")) | .value.IPAddress')
docker exec attacker ip route add 10.100.1.0/24 via $FIREWALL_WAN_IP
docker exec attacker ip route add 10.100.2.0/24 via $FIREWALL_WAN_IP

echo "Firewall interfaces:"
docker exec firewall ip link show
echo "Firewall iptables FORWARD:"
docker exec firewall iptables -L FORWARD

echo "2. Testing DMZ web server..."
docker exec dmz-web nginx -t

echo "3. Testing LAN to DMZ access..."
if docker exec lan-client curl -s --connect-timeout 5 http://10.100.2.10 > /dev/null; then
    echo "✓ Allowed as expected"
else
    echo "❌ FAIL: LAN to DMZ blocked"
fi

echo "4. Testing WAN to DMZ access..."
docker exec attacker curl -s http://10.100.2.10 | head -n 3

echo "5. Testing DMZ to LAN isolation..."
docker exec dmz-web ping -c 2 -W 1 10.100.1.100 && echo "❌ FAIL" || echo "✓ Blocked correctly"

echo "6. Testing WAN ICMP to firewall..."
FIREWALL_LAN_IP=$(docker inspect firewall | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.key | endswith("_lan_net")) | .value.IPAddress')
FIREWALL_DMZ_IP=$(docker inspect firewall | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.key | endswith("_dmz_net")) | .value.IPAddress')
FIREWALL_WAN_IP=$(docker inspect firewall | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.key | endswith("_wan_net")) | .value.IPAddress')

echo "Firewall WAN IP: $FIREWALL_WAN_IP"
ATTACKER_WAN_IP=$(docker inspect attacker | jq -r '.[0].NetworkSettings.Networks | to_entries[] | select(.key | endswith("_wan_net")) | .value.IPAddress')
echo "Attacker WAN IP: $ATTACKER_WAN_IP"
docker exec attacker ping -c 2 -W 1 $FIREWALL_WAN_IP && echo "✓ ICMP allowed" || echo "❌ ICMP blocked"

echo "7. Testing WAN to LAN access..."
docker exec attacker curl -s --connect-timeout 5 http://10.100.1.100 || echo "✓ Blocked as expected"

echo "8. IDS Status..."
docker exec firewall ps aux | grep suricata | grep -v grep && echo "✓ Suricata running on LAN" || echo "❌ Suricata not running"

echo "✅ Lab is working!"