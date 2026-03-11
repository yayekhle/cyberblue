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
- CyberChef: http://YOUR_IP:7004 (no auth)
- TheHive: http://YOUR_IP:7005 (admin@thehive.local/secret)
- Cortex: http://YOUR_IP:7006 (admin/cyberblue123)
- FleetDM: http://YOUR_IP:7007 (setup required)
- Arkime: http://YOUR_IP:7008 (admin/admin)
- Caldera: http://YOUR_IP:7009 (red:cyberblue, blue:cyberblue)
- EveBox: http://YOUR_IP:7015 (no auth)
- Wireshark: http://YOUR_IP:7011 (admin/cyberblue)
- MITRE Navigator: http://YOUR_IP:7013 (no auth)
- Portainer: https://YOUR_IP:9443 (admin/cyberblue123)


# Our Cyberblue Services && Portals 

Our own customized CyberBlue stack after filtering out unnecessary tools:

**Removed from default:**
- Shuffle (SOAR — TheHive+Cortex covers it)
- FleetDM (overlaps with Velociraptor)
- MITRE Navigator (use the online version)
- Caldera (red team tool, not a blue team daily driver)
- CyberChef (static app — use gchq.github.io/CyberChef)
- Wireshark (redundant with Arkime, also ran privileged)
- Arkime (not functional — commented out in docker-compose)

Portal: https://YOUR_IP:5443 (admin / cyberblue123)

Individual Tools:
- Velociraptor: https://YOUR_IP:7000 (admin/cyberblue)
- Wazuh: https://YOUR_IP:7001 (admin/SecretPassword)
- MISP: https://YOUR_IP:7003 (admin@admin.test/admin)
- TheHive: http://YOUR_IP:7005 (admin@thehive.local/secret)
- Cortex: http://YOUR_IP:7006 (setup required on first login)
- EveBox: http://YOUR_IP:7015 (no auth)
- Portainer: https://YOUR_IP:9443 (setup required on first login)

Infrastructure (no direct UI):
- Wazuh Manager (agent communication: ports 1514, 1515, 514/udp, API: 55000)
- Wazuh Indexer (OpenSearch: port 9200)
- Elasticsearch (Cortex backend: port 9210)
- MISP DB (MariaDB), MISP Redis, MISP Mail, MISP Modules
- Suricata (IDS — host network mode, feeds alerts to EveBox)

## Keep — Core Stack (non-negotiable)

| Tool | Why |
|------|-----|
| Wazuh | Your SIEM is the backbone — can't drop it |
| TheHive | Case management is essential for any serious SOC |
| Cortex | Tight TheHive integration, automates enrichment — keep it |
| MISP | Threat intel feeds everything else, critical |
| Arkime | Full packet capture is irreplaceable for deep investigations |
| Evebox/Suricata | IDS alerts are your early warning system |
| Velociraptor | Live forensics on endpoints, nothing else does this as well |

## Keep — High Value, Low Overhead

| Tool | Why |
|------|-----|
| CyberChef | Zero maintenance, analysts use it daily |
| Wireshark | As discussed — complements Arkime, keep it |
| Portainer | You need to manage your Docker stack somehow |

## Evaluate / Maybe Drop

| Tool | Reason to reconsider |
|------|---------------------|
| Shuffle | SOAR is only valuable if you have time to build playbooks. If your team is small or junior, it becomes shelfware. TheHive+Cortex already covers a lot of automation |
| FleetDM | Overlaps heavily with Velociraptor for endpoint visibility. Hard to justify running both unless you specifically need osquery's continuous telemetry model |
| MITRE Navigator | Useful for planning and reporting, but it's a reference tool, not operational. Bookmark the online version instead |
| Caldera | Red team simulation is valuable, but a SOC analyst doesn't run this day-to-day — this belongs to a red team or purple team exercise, not your daily SOC stack |
| CyberChef | Correct to drop it as a container. It's a static web app, you can just use gchq.github.io/CyberChef in your browser. Zero reason to run it locally |
| Wireshark | Also correct to drop. Runs with network_mode: host and privileged: true, which is a security risk on top of being redundant when you already have Arkime doing full packet capture |


## The Honest Lean Stack

Wazuh + TheHive + Cortex + MISP + Arkime + Evebox + Velociraptor + CyberChef

docker compose from 801 line to 660

# To Do List
- Simulate and attack 
- Change the index file of cyber blue to show the tools with our own style
