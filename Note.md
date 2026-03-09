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

## The Honest Lean Stack

Wazuh + TheHive + Cortex + MISP + Arkime + Evebox + Velociraptor + CyberChef