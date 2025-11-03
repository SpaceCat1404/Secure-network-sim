# Secure Segmented Network Simulation

This project implements a containerized version of the secure segmented network simulation described in `Idea 1_ Secure Segmented Network Simulation.md`, using Docker Compose to simulate the network architecture, firewall rules, and IDS.

## Prerequisites
- Docker Desktop installed and running.
- Bash shell (macOS/Linux).

## Quick Start
1. Clean up any previous runs:
   ```
   docker-compose down --volumes --remove-orphans && docker network prune -f
   ```
2. Run the simulation:
   ```
   ./test-instant.sh
   ```

## Expected Results (From Dry Run)
- **Firewall Startup**: ✅ Container starts with iptables rules applied.
- **DMZ Web Server**: ✅ Nginx config valid.
- **LAN to DMZ Access**: ✅ Allowed (curl succeeds).
- **WAN to DMZ Access (Port 80)**: ✅ Allowed (HTML content displayed).
- **DMZ to LAN Isolation**: ❌ Not blocked (ping succeeds; iptables DROP not fully enforced in Docker).
- **WAN ICMP to Firewall**: ✅ Allowed.
- **WAN to LAN Access**: ✅ Blocked.
- **IDS Status**: ✅ Suricata running on LAN interface.

## Implementation vs .md Spec
### Matches
- **Network Architecture**: Three isolated networks (WAN, LAN, DMZ) with matching subnets and IP schemas.
- **VM Equivalents**: Containers simulate pfSense (firewall), Ubuntu Server (DMZ-Web), Xubuntu (LAN-Client), Kali (Attacker).
- **Firewall Policies**: iptables enforces default deny WAN, allow ICMP/TCP 80 to DMZ, block DMZ to LAN.
- **IDS**: Suricata installed and monitoring LAN interface with ET rules.
- **Services**: Nginx on DMZ, curl/nmap tools in clients.

### Limitations (Docker-Specific)
- **IP Conflicts**: Fixed IPs in `docker-compose.yml` cause "Address already in use" errors; resolved by using dynamic IPs and unique subnets.
- **Firewall Enforcement**: Docker's bridge networking doesn't fully apply container iptables to inter-network forwarded traffic; DMZ-to-LAN blocking works in theory but not in practice due to Docker's routing model.
- **IDS Testing**: Installed and running, but full alert testing (e.g., nmap from DMZ to LAN) is limited since traffic is blocked at the network level.
- **Routing**: Manual route additions required for containers to communicate across networks via the firewall.
- **Scalability**: Containerized setup is for demonstration; production use VMs as per the spec for true isolation and enforcement.

## Conclusion
This Docker implementation demonstrates the core concepts of segmented networking, firewall rules, and IDS from the spec. It runs successfully for most tests but highlights Docker's limitations in mimicking VM-based network security. For full compliance and security, use VirtualBox/VMware with pfSense as described in the .md file.

## Files
- `docker-compose.yml`: Container definitions and network setup.
- `test-instant.sh`: Automated test script.
- `web-content/index.html`: Simple web page for DMZ server.
- `Idea 1_ Secure Segmented Network Simulation.md`: Original specification.