# The Default Cyberblue Setup

## Container Overview

- Here's the full picture of all 15 containers organized by category (the default one of Cyberblue):

| Tool | Category | What it does |
|------|----------|--------------|
| Velociraptor | DFIR | Live forensics & threat hunting |
| Wazuh Dashboard | SIEM | Log analysis & alerting |
| Shuffle | SOAR | Security automation/orchestration |
| TheHive | SOAR | Incident response & case management |
| Cortex | SOAR | Automated threat analysis (TheHive addon) |
| MISP | Threat Intel | Threat intel sharing platform |
| MITRE Navigator | Threat Intel | ATT&CK framework navigator |
| CyberChef | Utility | Data encode/decode/forensics swiss knife |
| FleetDM | Endpoint Mgmt | Osquery-based endpoint visibility |
| Arkime | Network Analysis | Full packet capture & search |
| Wireshark | Network Analysis | Packet analysis |
| Evebox | Intrusion Detection | Suricata IDS alert manager |
| Caldera | Attack Simulation | Adversary emulation (red team) |
| Portainer | Management | Docker container manager |
| CyberChef | Utility | (duplicate shown in UI) |

## `Default` Cyberblue Services && Portals 

Portal: https://YOUR_IP:5443 (no auth required)

Individual Tools:
- Velociraptor: https://YOUR_IP:7000 (admin/cyberblue)
- Wazuh: https://YOUR_IP:7001 (admin/SecretPassword)
- Shuffle: https://YOUR_IP:7002 (admin/password)
- MISP: https://YOUR_IP:7003 (admin@admin.test/admin)
- CyberChef: http://YOUR_IP:7004 (no auth) `TO DELETE`
- TheHive: http://YOUR_IP:7005 (admin@thehive.local/secret)
- Cortex: http://YOUR_IP:7006 (admin/cyberblue123)
- FleetDM: http://YOUR_IP:7007 (setup required)
- Arkime: http://YOUR_IP:7008 (admin/admin)
- Caldera: http://YOUR_IP:7009 (red:cyberblue, blue:cyberblue)
- EveBox: http://YOUR_IP:7015 (no auth)
- Wireshark: http://YOUR_IP:7011 (admin/cyberblue) `TO DELETE`
- MITRE Navigator: http://YOUR_IP:7013 (no auth)
- Portainer: https://YOUR_IP:9443 (admin/cyberblue123)


# Our Cyberblue Services && Portals 

- Our own Customized Cyberblue Services & Portals (after filtering out unnecessary tools and building it on our own style):

Portal: https://YOUR_IP:5443 (no auth required)

Individual Tools:
- Velociraptor: https://YOUR_IP:7000 (admin/cyberblue)
- Wazuh: https://YOUR_IP:7001 (admin/SecretPassword)
- Shuffle: https://YOUR_IP:7002 (admin/password)
- MISP: https://YOUR_IP:7003 (admin@admin.test/admin)
- CyberChef: http://YOUR_IP:7004 (no auth) `TO DELETE`
- TheHive: http://YOUR_IP:7005 (admin@thehive.local/secret)
- Cortex: http://YOUR_IP:7006 (admin/cyberblue123)
- FleetDM: http://YOUR_IP:7007 (setup required)
- Caldera: http://YOUR_IP:7009 (red:cyberblue, blue:cyberblue)
- EveBox: http://YOUR_IP:7015 (no auth)
- MITRE Navigator: http://YOUR_IP:7013 (no auth)
- Portainer: https://YOUR_IP:9443 (admin/cyberblue123)

(Arkime and wireshark aint working, )

# To Do List
- Filter more tools (remove unnecessary ones)
- Simulate and attack 
- Change the index file of cyber blue to show the tools with out own style