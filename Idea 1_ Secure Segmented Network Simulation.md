# **Technical Specification: Secure Segmented Network Simulation**

## **1\. Project Goal**

To build a secure, multi-segmented network within a virtual environment, controlled by a Next-Generation Firewall (NGFW). The implementation will enforce granular inter-segment security policies and use an IDS to monitor for threats.

## **2\. Core Technology Stack**

* **Hypervisor:** VirtualBox (or VMware Player/Workstation)  
* **NGFW / Router:** pfSense (or OPNsense)  
* **Internal Server (DMZ):** Ubuntu Server (or other lightweight Linux)  
* **Internal Client (LAN):** Xubuntu Desktop (or other lightweight Linux Desktop)  
* **Attacker/Test Machine:** Kali Linux (or any VM configured on the WAN network)  
* **IDS/IPS:** Suricata or Snort (as a package within pfSense)

## **3\. Network Architecture Specification**

### **3.1. Virtual Network Interfaces**

The hypervisor will be configured with three distinct virtual networks:

| Interface Name | pfSense Interface | Network Purpose | Virtual Switch Type |
| ----- | ----- | ----- | ----- |
| WAN | WAN | "Public Internet". Must be bridged or NAT'd to host. | e.g., VMnet8 (NAT) |
| LAN | LAN | "Internal Trusted Network". | e.g., VMnet10 (LAN\_Seg) |
| DMZ | OPT1 | "Demilitarized Zone". For public-facing servers. | e.g., VMnet11 (DMZ\_Seg) |

### **3.2. IP Addressing Schema**

| Interface | Subnet / IP | DHCP Server | Purpose |
| :---- | :---- | :---- | :---- |
| WAN | DHCP (from host) | N/A | Simulates ISP connection. |
| LAN | 10.10.10.1/24 | Enabled (Range: 10.10.10.100-200) | Trusted client network. |
| DMZ | 192.168.1.1/24 | Enabled (Range: 192.168.1.100-200) | Semi-trusted server network. |

### **3.3. Virtual Machine Deployment**

| VM Name | Network | OS | Purpose & Services |
| :---- | :---- | :---- | :---- |
| pfSense-FW | WAN, LAN, DMZ | pfSense | Core project firewall, router, IDS. |
| DMZ-Web | DMZ | Ubuntu Server | Hosts a simple web server (e.g., Nginx on port 80). |
| LAN-Client | LAN | Xubuntu Desktop | Simulates a trusted internal user's workstation. |
| Attacker | WAN | Kali Linux | Simulates an external threat. |

## **4\. Component Requirements & Configuration**

### **4.1. NGFW Policy (pfSense)**

The core of the project is the successful implementation of this firewall ruleset. Rules are processed top-down.

**WAN Interface Rules:**

* **Block** all unsolicited inbound traffic (default deny).  
* **Allow** ICMP (ping) for testing.  
* **Allow** TCP Port 80 traffic destined for DMZ-Web's IP (192.168.1.x). (This is the Port Forward rule).

**LAN Interface Rules:**

* **Allow** LAN Net to access any destination. (Trusted users can go anywhere).

**DMZ Interface Rules:**

* **Block** DMZ Net from accessing LAN Net. **(CRITICAL RULE: Prevents DMZ compromise from spreading to internal network).**  
* **Allow** DMZ Net to access any *except* LAN Net. (Allows servers to get updates from the internet).

### **4.2. Security Services Configuration**

* **IDS/IPS (Suricata/Snort):**  
  * Install the package on pfSense.  
  * Enable on the LAN interface.  
  * Enable the "ET Open Ruleset".  
  * Run a test (e.g., nmap \-sV from DMZ to LAN before the rule is active) and confirm an alert is generated.