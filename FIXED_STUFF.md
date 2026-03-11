# Fixed Stuff — Full Changelog

Everything that was fixed during the entire conversation, from the first pass to the final audit.

---

## Pass 1 — Initial Cleanup (Wazuh Access + Non-Functional Containers)

### docker-compose.yml
- **Arkime + os01 commented out** — both containers were non-functional (user confirmed "Arkime aint working"). Commented out the `os01` OpenSearch node and the `arkime` service definitions, along with their `arkime_config` and `arkime_logs` volume declarations.
- **Header comments updated** — added Arkime to the "Dropped services" list, removed it from "Kept services".
- **Wazuh Dashboard depends_on fix** — added `wazuh.manager` to `wazuh.dashboard`'s `depends_on` so the dashboard waits for the manager to start before attempting to connect.

### verify-post-reboot.sh
- **Removed 14 non-existent service names** from the container check list (Shuffle, FleetDM, Caldera, CyberChef, OpenVAS, Wireshark, MITRE Navigator, etc.) — these were all already removed from docker-compose but the script still checked for them.
- **Expected container count** fixed from `30` to `16`.
- **Success threshold** raised from `25` to `12`.
- **Port test list** trimmed to only include ports of actual running services.
- **Access URLs** corrected (TheHive: `admin@thehive.local / secret` not `admin / cyberblue`, Portainer/Cortex: `setup required`, Wazuh: `https://` not `http://`, Velociraptor: `https://` not `http://`).
- **Removed `caldera-autostart`** from systemd service checks.

### force-start.sh
- **Removed references** to Arkime, Caldera, OpenVAS (services not in docker-compose).
- **Container count threshold** fixed from `25` to `12`.
- **Tool URL list** updated to match actual running services.
- **"30+ containers" text** corrected.

### fix-wazuh-services.sh (from initial commit)
- **Wazuh Dashboard health check** changed from `http://localhost:7001` to `https://localhost:7001` (Wazuh dashboard has SSL enabled and only responds to HTTPS).
- **Wazuh Dashboard URL** in output messages changed from `http://` to `https://`.

### suricata/logs/.gitkeep
- **Created missing directory** — the `evebox` container mounts `./suricata/logs:/var/log/suricata:ro` but the directory didn't exist in the repo, which could cause volume mount failures.

### README.md
- **"Our Cyberblue Services" section** rewritten to list only the actual services present in docker-compose.
- **"Removed from default" section** added, explaining what was filtered out and why.
- **Infrastructure services** listed (Wazuh Manager/Indexer, Elasticsearch, MISP support services, Suricata) so users know what's running without a UI.
- **Credentials** verified — all listed credentials are the actual defaults, no passwords were changed.

---

## Pass 2 — Final Audit (Ensuring Nothing Is Broken)

### fix-wazuh-services.sh — Container Name Typo (Critical Bug)
- **Lines 45, 46, 82, 165**: Fixed `wazuh-cert-genrator` → `wazuh-cert-generator` (missing 'e' in "generator"). The actual container is named `wazuh-cert-generator` in docker-compose.yml line 93. This typo caused the fix script to silently fail when trying to stop/remove/log the certificate generator container.
- **Line 178**: Changed "Should now show 15/15 services running" to "Should now show all services running" since the exact count depends on which optional services are enabled.

### cyberblue_install.sh — Arkime Setup (Dead Code)
- **Step 2.10 (lines 714–735)**: The Arkime initialization block tried to run `fix-arkime.sh`, create admin users in the arkime container, and run packet captures — but Arkime is commented out in docker-compose.yml. Replaced the entire block with a skip message explaining that Arkime is disabled and how to re-enable it.

---

## What Was NOT Changed (By Design)

### Passwords — All Defaults Preserved
No passwords were modified. All services use their original default credentials:
| Service | Username | Password |
|---------|----------|----------|
| Portal | admin | cyberblue123 |
| Wazuh | admin | SecretPassword |
| Velociraptor | admin | cyberblue |
| MISP | admin@admin.test | admin |
| TheHive | admin@thehive.local | secret |
| Cortex | — | setup required on first login |
| Portainer | — | setup required on first login |
| Arkime | admin | admin (disabled) |

### Scripts for Removed Services — Left In Place
The following scripts reference removed services but were intentionally left in the repo since they don't affect the running stack and could be useful if someone re-enables those services:
- `install_caldera.sh` — Caldera installer (Caldera removed from compose)
- `fix-fleet.sh` — FleetDM fixer (FleetDM removed from compose)
- `fix-arkime.sh` — Arkime fixer (Arkime commented out in compose)
- `generate-pcap-for-arkime.sh` — PCAP generator for Arkime
- `fleet/` directory — FleetDM agent configs
- `shuffle/` directory — Shuffle workflow templates

### Portal Tool References
The portal app (`portal/app_with_auth.py`, `portal/app.py`) still references removed services (CyberChef, FleetDM, Caldera, Wireshark, MITRE Navigator, Shuffle) in its tool configuration maps. These are harmless — the portal will simply show them as "offline" since their containers don't exist. No changes were made to the portal code.
