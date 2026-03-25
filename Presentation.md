# 🛡️ Building a Security Operations Center (SOC) Lab
## A Comprehensive Guide to Enterprise Security Monitoring

---

## 📑 Table of Contents

### **Part 1: Understanding SOC Fundamentals**
- [1. What is a SOC Lab?](#what-is-a-soc-lab)
- [2. Why Build One?](#why-build-a-soc-lab)
- [3. Docker & Containers: The Foundation](#-docker--containers-the-foundation)

### **Part 2: Security Operations Workflow**
- [4. The Security Workflow](#the-security-workflow)
- [5. Core Components](#core-components)
- [6. Our Stack Architecture](#our-stack-architecture)

### **Part 3: Tools in Detail**
- [7. Key Tools Explained](#key-tools-explained)
- [8. Tool Interaction Examples](#the-data-flow-a-real-incident-example)

### **Part 4: Infrastructure & Automation**
- [9. The Scripting Orchestra](#-the-scripting-orchestra-automation-behind-the-scenes)
- [10. Script Layers (Setup, Fix, Tool-Specific)](#layer-1-setup--prerequisites-one-time-installation)
- [11. Deployment Timeline](#the-complete-deployment-timeline)

### **Part 5: Learning & Application**
- [12. Discussion Points](#discussion-points)
- [13. Next Steps for Students](#next-steps-what-students-can-do)
- [14. Key Takeaways](#key-takeaways-for-students)

---

## What is a SOC Lab?

A **Security Operations Center (SOC) Lab** is a simulated enterprise security environment that mimics real-world security operations. It provides:

- 🎯 **Controlled Testing Environment** - Practice without risking production systems
- 🔍 **Integrated Security Tools** - Multiple complementary systems working together
- 📊 **Complete Incident Workflow** - Detection → Analysis → Response → Resolution
- 👥 **Team Collaboration** - Different roles working together (analysts, incident responders, threat hunters)

### Real-World Analogy
```
A SOC Lab is like a flight simulator:
- Pilots practice emergency scenarios safely
- Real aircraft stay protected
- They learn procedures without crashing planes

A SOC Lab is similar:
- Security analysts practice incident response safely
- Production systems stay protected
- They learn detection and response workflows without affecting real infrastructure
```

---

## Why Build a SOC Lab?

### 1. **Hands-on Experience** 🖥️
Gain practical skills with industry-standard security tools that real companies use every day.

### 2. **Skill Development** 📚
Master critical competencies:
- **Threat Hunting** - Proactively search for suspicious activity
- **Incident Response** - Respond quickly to detected threats
- **Log Analysis** - Extract meaningful insights from massive datasets
- **Forensics** - Investigate what happened after an incident

### 3. **Tool Familiarity** 🛠️
Learn tools used by Fortune 500 companies, government agencies, and security firms.

### 4. **Realistic Scenarios** 🎬
Simulate actual attack chains and practice responding under pressure.

### 5. **Collaboration Skills** 👥
Experience how security teams work together in real operations centers.

---

# 🐳 Docker & Containers: The Foundation

## What is Docker?

**Docker** is containerization technology — think of it as a **lightweight virtual machine** that packages an entire application with all its dependencies into a single, portable unit called a **container**.

### Regular Virtual Machine vs Docker Container

```
┌─────────────────────────────────────┐
│   TRADITIONAL VM APPROACH           │
├─────────────────────────────────────┤
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Ubuntu OS (4 GB)            │  │
│  │  ├─ Kernel                   │  │
│  │  ├─ System libraries         │  │
│  │  ├─ Package manager          │  │
│  │  └─ Thousands of packages    │  │
│  └──────────────────────────────┘  │
│           ↓                          │
│  ┌──────────────────────────────┐  │
│  │  Your Application            │  │
│  │  (e.g., Wazuh Dashboard)     │  │
│  │  + Dependencies              │  │
│  └──────────────────────────────┘  │
│                                     │
│  Total Size: ~8-10 GB               │
│  Startup Time: 30-60 seconds        │
│  Overhead: High                     │
└─────────────────────────────────────┘
```

```
┌─────────────────────────────────────┐
│   DOCKER CONTAINER APPROACH         │
├─────────────────────────────────────┤
│                                     │
│  Host OS: Ubuntu (shared)           │
│  (Only ONE copy of kernel)          │
│           ↓                          │
│  ┌──────────────────────────────┐  │
│  │ Docker Container (Wazuh)     │  │
│  │ ├─ Only app + dependencies   │  │
│  │ ├─ Minimal libraries         │  │
│  │ └─ NO full OS                │  │
│  │  Size: 200-500 MB            │  │
│  └──────────────────────────────┘  │
│           ↓                          │
│  ┌──────────────────────────────┐  │
│  │ Docker Container (MISP)      │  │
│  │  Size: 300-600 MB            │  │
│  └──────────────────────────────┘  │
│           ↓                          │
│  ┌──────────────────────────────┐  │
│  │ Docker Container (Velociraptor)
│  │  Size: 100-200 MB            │  │
│  └──────────────────────────────┘  │
│                                     │
│  Total Size: ~1-2 GB (all 3)        │
│  Startup Time: 2-5 seconds each     │
│  Overhead: Minimal                  │
└─────────────────────────────────────┘
```

## What is a Container?

A **container** is an isolated, lightweight environment that includes:

✅ **Your Application** - Wazuh, MISP, Velociraptor, etc.
✅ **Dependencies** - Only the libraries your app needs
✅ **Runtime** - Python, Node.js, Java, etc.
✅ **Configuration** - Settings specific to that service
❌ **NO Full OS** - Containers share the host OS kernel

### The Container Isolation

```
Host System: Ubuntu Linux
         │
         ├─ Shared Kernel
         ├─ Shared Hardware
         └─ Shared OS Libraries

         │
    ┌────┴────┬─────────┬──────────┐
    ↓         ↓         ↓          ↓
┌────────┐ ┌─────┐ ┌──────┐ ┌─────────┐
│Wazuh   │ │MISP │ │Arkime│ │Veloci   │
│        │ │     │ │      │ │raptor   │
│Process │ │Proc │ │Proc  │ │Proc     │
│Network │ │Net  │ │Net   │ │Net      │
│Storage │ │Stor │ │Stor  │ │Stor     │
│        │ │     │ │      │ │         │
│ISOLATED│ │ISO- │ │ISO-  │ │ISOLATED │
│FILESYSTEM
│        │ │     │ │      │ │         │
└────────┘ └─────┘ └──────┘ └─────────┘

Key: Each container has its own:
  • Filesystem (/etc, /var, /home)
  • Process space (separate PIDs)
  • Network namespace (separate network interfaces, ports)
  • But shares: Kernel, CPU, RAM (efficiently)
```

---

## Why We Use Docker for This SOC Lab

### **Problem 1: Installation Nightmare**
```
Without Docker:
  1. Install Ubuntu 20.04
  2. Install Wazuh (requires Python 3, Node.js, Elasticsearch)
  3. Install MISP (requires Apache, PHP, MySQL)
  4. Install Velociraptor (requires Go runtime)
  5. Install Arkime (requires Node.js, Elasticsearch)
  6. Install TheHive (requires Scala, Java)
  7. Configure networking between all tools
  8. Fix port conflicts
  9. Debug SSL certificates
  10. Troubleshoot dependency conflicts
  Result: 6-8 hours, fragile, breaks with each update

With Docker:
  1. docker compose up -d
  Result: 5 minutes, reproducible, can tear down and rebuild anytime
```

### **Problem 2: Dependency Hell**
```
Scenario: You need Python 3.8 for one tool, Python 3.11 for another

Without Docker:
  ❌ Can't have both versions installed
  ❌ One tool breaks when you upgrade
  ❌ Virtual envs are fragile
  ❌ System packages conflict

With Docker:
  ✅ Each container has its own Python
  ✅ Container 1: Python 3.8
  ✅ Container 2: Python 3.11
  ✅ Both run simultaneously without conflict
```

### **Problem 3: Portability**
```
Your Development:
  Ubuntu 22.04 on laptop
  Docker: WORKS ✅

Your School Lab (Windows):
  Windows 10 + WSL2
  Docker: WORKS ✅

AWS Deployment:
  Ubuntu 20.04 on AWS EC2
  Docker: WORKS ✅

Azure VM:
  Ubuntu 22.04 on Azure
  Docker: WORKS ✅

Same docker-compose.yml
Same containers
Same results everywhere!
```

### **Problem 4: Quick Teardown & Rebuild**
```
Without Docker:
  "We need to reset to clean state"
  → Uninstall 7 tools
  → Purge all configs
  → Remove all databases
  → Reinstall from scratch
  Time: 3-4 hours

With Docker:
  docker compose down -v
  (volume flag removes all data)
  docker compose up -d
  (rebuild fresh copy)
  Time: 5 minutes
```

---

## How Docker Solves Our Project Needs

### **1. Multiple Tools, One Machine**

Without Docker, you'd need:
- 7 separate servers (expensive!)
- Or 7 massive VMs (slow, resource-hungry)

With Docker:
- One machine runs all 7 as lightweight containers
- Containers boot in seconds
- Can run on laptop, EC2 instance, or physical server
- Each tool still has complete isolation

### **2. Configuration as Code**

`docker-compose.yml` describes the entire deployment:
```yaml
services:
  wazuh.manager:
    image: custom-wazuh-manager
    environment:
      - INDEXER_URL=https://wazuh.indexer:9200
      - FILEBEAT_SSL_VERIFICATION_MODE=full
    ports:
      - "7001:443"
    volumes:
      - ./wazuh/config:/var/ossec/etc
```

**Benefits:**
✅ Version control your entire infrastructure
✅ Reproducible deployments
✅ Easy to modify, easy to revert
✅ Documentation built-in

### **3. Networking Between Tools**

Containers communicate through a **Docker network**:

```
┌────────────────────────────────────────┐
│     Docker Internal Network             │
├────────────────────────────────────────┤
│                                        │
│  Wazuh Manager                         │
│  (internal hostname: wazuh.manager)    │
│         │                              │
│         ├─ talks to ──→ Indexer        │
│         ├─ talks to ──→ Filebeat       │
│         └─ talks to ──→ Dashboard      │
│                                        │
│  MISP                                  │
│  (internal hostname: misp)             │
│         │                              │
│         ├─ talks to ──→ Redis          │
│         ├─ talks to ──→ Database       │
│         └─ talks to ──→ Mail service   │
│                                        │
│  Velociraptor                          │
│  (internal hostname: velociraptor)     │
│         │                              │
│         └─ talks to ──→ External agents│
│                                        │
└────────────────────────────────────────┘

Benefit: Tools find each other by name
No hardcoded IPs or localhost hacks needed!
```

### **4. Data Persistence**

Containers are **ephemeral** (temporary), but we need data to survive container restarts:

```
By default:
  Container starts with fresh state
  Container stops → all data deleted
  Bad for a SOC lab!

Solution: Docker Volumes
  Bind-mount to host directories

  Container process              Host Directory
  /var/ossec/data ──────→ ./wazuh/data/
  /var/lib/misp ─────────→ ./misp/configs/
  /var/log ──────────────→ ./logs/

Result:
  Container stops → data persists
  New container starts → sees all old data
  Perfect for testing!
```

### **5. Security Isolation**

Each container runs as separate process with limited permissions:

```
Without Docker:
  All tools run as separate system users
  One compromise → might affect others
  Shared OS means shared vulnerability surface

With Docker:
  Each tool in its own sandbox
  Limited network access
  Limited filesystem access
  Can set resource limits (CPU, RAM)
  Container escape is very difficult

This is why enterprises use containers!
```

---

## Docker Architecture in Our Project

```
┌─────────────────────────────────────────────────────┐
│              Your Host Machine                       │
│  (Ubuntu 20.04 / 22.04, AWS, Azure, VMware, etc.)  │
├─────────────────────────────────────────────────────┤
│                                                     │
│  Host OS: Ubuntu                                   │
│  ├─ Linux Kernel (shared by all containers)       │
│  └─ Docker Daemon (manages containers)             │
│                                                     │
│  ┌─────────────────────────────────────────────┐  │
│  │         Docker Container Runtime             │  │
│  │  (Namespaces + Cgroups = Isolation)         │  │
│  ├─────────────────────────────────────────────┤  │
│  │                                             │  │
│  │  ┌────────┐  ┌────────┐  ┌────────┐       │  │
│  │  │ Wazuh  │  │ MISP   │  │Veloci  │       │  │
│  │  │Manager │  │        │  │raptor  │  ...  │  │
│  │  └────────┘  └────────┘  └────────┘       │  │
│  │  Mount:      Mount:      Mount:           │  │
│  │  ./wazuh/    ./misp/     ./veloci/        │  │
│  │                                             │  │
│  │  Internal Docker Network (172.17.0.0/16)  │  │
│  │  All containers can talk to each other     │  │
│  │                                             │  │
│  └─────────────────────────────────────────────┘  │
│                                                     │
│  Exposed to Host/External:                        │
│  ├─ :5443  → Portal                             │
│  ├─ :7000  → Velociraptor                       │
│  ├─ :7001  → Wazuh Dashboard                    │
│  ├─ :7003  → MISP                              │
│  └─ :7005+ → Other tools                       │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Key Docker Concepts Used in Our Project

### **1. Docker Image** 🖼️
```
What: A blueprint or snapshot of an application with everything it needs

Think of it like: A recipe for a dish
  - Lists all ingredients (dependencies)
  - Lists all steps (configuration)
  - Frozen in time (doesn't change)

Example from our project:
  Image: wazuh/wazuh-manager:latest
  Contains:
    • Ubuntu Linux base OS
    • Wazuh software + binaries
    • Python 3.9
    • Required libraries
    • Configuration files
    • Startup scripts

Size: Typically 200MB - 2GB per image
```

### **2. Container** 📦
```
What: A running instance created FROM an image

Think of it like: Cooking the dish from the recipe
  - Image is the recipe
  - Container is the actual cooked meal
  - Multiple meals from one recipe
  - Each meal is isolated and independent

Example in our project:
  From image: wazuh/wazuh-manager:latest
  Run container: wazuh-manager (the actual running service)

Properties:
  ✅ Isolated filesystem
  ✅ Independent processes
  ✅ Separate network namespace
  ✅ Can be stopped/started/deleted without affecting the image
  ✅ Can run multiple containers from same image simultaneously
```

### **3. Docker .env File** 🔐
```
What: Environment variables file that configures your deployment

Purpose: Customize WITHOUT editing docker-compose.yml

Example: .env file in project root
──────────────────────────────────────
HOST_IP=192.168.1.100
MISP_BASE_URL=https://192.168.1.100:7003
OS_VERSION=2.18.0
ARKIME_PORT=8005
PCAP_DIR=./arkime/pcaps
SECRET_PASSWORD=SecretPassword
──────────────────────────────────────

How it's used in docker-compose.yml:
  environment:
    - MISP_BASE_URL=${MISP_BASE_URL}  ← Gets value from .env
    - OS_VERSION=${OS_VERSION:-2.18.0}  ← Uses .env, or defaults to 2.18.0

Benefits:
  ✅ Different deployments = different .env values
  ✅ Keep secrets out of git (add .env to .gitignore)
  ✅ One docker-compose.yml works everywhere
  ✅ Easy to modify without touching YAML
```

### **4. Example .env File** 📝
```
Our project's .env should contain:

# Network Configuration
HOST_IP=YOUR_IP_ADDRESS                    # Auto-detected by cyberblue_init.sh
INTERFACE=eth0                             # Network interface

# MISP Configuration
MISP_BASE_URL=https://YOUR_IP:7003         # Threat intel platform
MISP_AUTH_KEY=misp_api_key_here            # API authentication

# Wazuh Configuration
WAZUH_CERT_COMMON_NAME=wazuh.indexer      # Certificate subject
WAZUH_INDEXER_USERNAME=admin              # Default username
WAZUH_INDEXER_PASSWORD=SecretPassword     # Default password

# OpenSearch / Elasticsearch
OS_VERSION=2.18.0                          # Version to use

# Arkime Configuration
ARKIME_PORT=8005                           # Port for packet capture UI
PCAP_DIR=./arkime/pcaps                   # Where to store packet captures

# Database Configuration
MYSQL_ROOT_PASSWORD=mysql_root_pass       # MySQL admin password
MYSQL_DATABASE=misp                        # Database name

# Logging
LOG_LEVEL=info                             # Verbosity level
DEBUG=false                                # Enable debug mode

Example real deployment:
────────────────────────
HOST_IP=192.168.1.100
MISP_BASE_URL=https://192.168.1.100:7003
WAZUH_INDEXER_PASSWORD=MySecurePass123
OS_VERSION=2.18.0
ARKIME_PORT=8005
PCAP_DIR=/data/pcaps
```

### **5. Docker Image vs Container (Side by Side)** 🔄
```
┌────────────────────────────────────────┐
│          DOCKER IMAGE                  │
├────────────────────────────────────────┤
│ • Read-only blueprint                  │
│ • Stored on disk                       │
│ • Shared across containers             │
│ • Example: ubuntu:22.04                │
│ • Size: 150MB-2GB                      │
│ • Command: docker build, docker pull   │
│ • Status: Not running                  │
│ • Lifecycle: Persistent                │
└────────────────────────────────────────┘
              ↓
       (instantiate from image)
              ↓
┌────────────────────────────────────────┐
│        DOCKER CONTAINER                │
├────────────────────────────────────────┤
│ • Running instance of image            │
│ • Unique filesystem per container      │
│ • Independent from other containers    │
│ • Example: running_ubuntu_001          │
│ • Memory: RAM usage at runtime         │
│ • Command: docker run, docker start    │
│ • Status: Running or Stopped           │
│ • Lifecycle: Can be deleted             │
└────────────────────────────────────────┘
```

### **6. Relationship Example in Our Project** 🏗️
```
Images (blueprints):
  wazuh/wazuh-manager:latest          [image]
  coolacid/misp-docker:latest         [image]
  opensearchproject/opensearch:2.18   [image]
         ↓
    docker compose up -d
         ↓
Containers (running instances):
  wazuh-manager (PID 1234)            [container]
  misp (PID 1235)                     [container]
  os01 (PID 1236)                     [container]

Configuration files (.env):
  HOST_IP=192.168.1.100
  MISP_BASE_URL=https://192.168.1.100:7003
  ↓
Applied to each container at startup
↓
Each container sees environment variables
Each container mounts configured volumes
Each container connects to configured network
```

| Concept | What It Means | Why We Use It |
|---------|--------------|---------------|
| **Image** | Frozen blueprint of a container | Pre-built with all dependencies |
| **Container** | Running instance of an image | Each tool runs in isolation |
| **.env File** | Environment variables for configuration | Customize without editing YAML |
| **example.env** | Template showing what variables are needed | Documentation + starting point |
| **Volume** | Persistent storage | Data survives container restart |
| **Network** | Internal communication | Tools talk to each other |
| **Ports** | External access | Map internal ports to host |
| **docker-compose** | Multi-container orchestration | Define entire stack in YAML |
| **Entrypoint** | Container startup script | Automatic initialization |

---

## The Container Startup Process

```
TIME     EVENT                           WHAT HAPPENS
─────────────────────────────────────────────────────
T=0      docker compose up -d            You run the command
         │
T=0.1    Docker reads events             Reads docker-compose.yml
         │
T=0.5    Creates containers              Allocates resources
         │                               Creates filesystems
         │                               Sets up networking
         │
T=1      Runs entrypoint.sh              Each container starts
         │                               Initialization scripts run
         │                               Services boot up
         │
T=5-10   Services accept connections     Wazuh ready
         │                               MISP ready
         │                               Velociraptor ready
         │
T=10+    Your SOC lab is ready!          Access via URLs
```

---

## Why Containers are Perfect for Education

1. **Easy to Deploy** - One `docker-compose up` command
2. **Easy to Reset** - Delete volumes, rebuild fresh
3. **No System Pollution** - Uninstall = just remove containers
4. **Resource Efficient** - Can run multiple labs on one machine
5. **Real-World** - Same tech enterprises use
6. **Portable** - Works everywhere (WSL2, AWS, Azure, bare metal)
7. **Version Control** - docker-compose.yml in git
8. **Layered Learning** - Learn containers + security simultaneously

---

## Understanding docker-compose.yml (Our Infrastructure as Code)

This file describes:
- **What services** to run
- **How to configure** them
- **How they connect**
- **What data persists**
- **What ports** are exposed

Example (simplified):
```yaml
version: '3.8'

services:
  # MISP - Threat Intelligence Platform
  misp:
    image: coolacid/misp-docker:latest     # Which image to use
    environment:
      - MISP_BASEURL=https://IP:7003       # Configuration
      - SECURITYSALT=random                # Secrets
    ports:
      - "7003:443"                         # External → Internal
    volumes:
      - ./misp/configs:/var/www/MISP/app/Config    # Data persistence
    depends_on:
      - redis                              # Dependencies

  # Wazuh - SIEM
  wazuh.manager:
    image: custom-wazuh-manager:latest
    environment:
      - INDEXER_URL=https://wazuh.indexer:9200
    ports:
      - "7001:443"
    volumes:
      - ./wazuh/data:/var/ossec/data
    depends_on:
      - wazuh.indexer                      # Must start indexer first!

  # Wazuh Indexer (Database)
  wazuh.indexer:
    image: custom-wazuh-indexer:latest
    environment:
      - OPENSEARCH_JAVA_OPTS=-Xms512m -Xmx512m
    volumes:
      - ./wazuh/indexer:/var/lib/opensearch
```

**Why This Approach:**
- Entire infrastructure described in one file
- Version control your deployment
- Anyone can reproduce it
- Changes are documented
- Easy to modify and test

---

## Summary: Docker Makes This All Possible

```
Without Docker:          With Docker:
─────────────────────    ─────────────────
Manual installation      Automated deployment
8+ hours setup           5 minutes setup
Fragile                  Reproducible
Works on MY machine      Works everywhere
Hard to debug            Transparent layers
Uninstall nightmare      Delete & rebuild
Not scalable             Deploy 100 labs
Production != Lab        Same tech as production

CONTAINERS = The future of infrastructure!
```

---

Here's what happens when a threat is detected:

```
┌─────────────────────────────────────────────────────────────────┐
│                    INCIDENT RESPONSE WORKFLOW                    │
└─────────────────────────────────────────────────────────────────┘

STEP 1: DETECTION
 ├─ Network sensors detect suspicious traffic
 ├─ Endpoint agents report unusual processes
 └─ Logs trigger automated alerts
         ↓
              [DETECTION TOOLS: Suricata IDS, Wazuh, Velociraptor]

STEP 2: ANALYSIS & INVESTIGATION
 ├─ Analyst collects evidence
 ├─ Enriches with threat intelligence
 └─ Correlates across multiple data sources
         ↓
              [ANALYSIS TOOLS: Wazuh SIEM, Arkime, TheHive, MISP]

STEP 3: RESPONSE
 ├─ Isolate affected systems
 ├─ Block malicious IPs/domains
 └─ Document findings
         ↓
              [RESPONSE TOOLS: TheHive (case management), Cortex]

STEP 4: REMEDIATION
 ├─ Remove malware
 ├─ Patch vulnerabilities
 └─ Restore systems
         ↓

STEP 5: LESSONS LEARNED
 ├─ Update detection rules
 ├─ Share intelligence
 └─ Improve processes
         ↓
              [SHARING: MISP (Threat Intel Platform)]
```

---

## Core Components

### The Four Pillars of a SOC

```
                    ┌─────────────────┐
                    │  SIEM (Wazuh)   │  🔍 See everything
                    │ Central logging │
                    │ & correlation   │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              ↓              ↓              ↓
          ┌──────┐      ┌──────┐      ┌──────┐
          │ DFIR │      │ SOAR │      │ TI   │
          │ Threat→     │Case  │      │Threat│
          │Hunting      │Mgmt  │      │Intel│
          └──────┘      └──────┘      └──────┘
          Velociraptor  TheHive       MISP
                        +Cortex
```

---

## Our Stack Architecture

### The Lean, Optimized Setup

We built a **focused** SOC lab by removing redundancies:

```
┌─────────────────────────────────────────────────────────────────┐
│                    OUR OPTIMIZED SOC STACK                       │
└─────────────────────────────────────────────────────────────────┘

    ┌──────────────────────────────────────────────────────┐
    │         CENTRAL DASHBOARD & MANAGEMENT                │
    │              Portal (5443) - Web UI                   │
    └──────────────────────────────────────────────────────┘
                          │
              ┌───────────┼───────────┐
              ↓           ↓           ↓

    ┌─────────────────────────────────────────────────────┐
    │  VISIBILITY (Log from everywhere)                    │
    │  ┌─ Wazuh: Collects logs from endpoints & networks   │
    │  └─ Suricata IDS: Network-based detection             │
    └─────────────────────────────────────────────────────┘
              ↓

    ┌─────────────────────────────────────────────────────┐
    │  INTELLIGENCE (Context about threats)                │
    │  ┌─ MISP: Share and track threat indicators           │
    │  └─ Cortex: Automated threat analysis                 │
    └─────────────────────────────────────────────────────┘
              ↓

    ┌─────────────────────────────────────────────────────┐
    │  INVESTIGATION (Deep dive into events)               │
    │  ┌─ Velociraptor: Endpoint forensics                  │
    │  ├─ Arkime: Full packet capture & search              │
    │  └─ EveBox: IDS alert interface                       │
    └─────────────────────────────────────────────────────┘
              ↓

    ┌─────────────────────────────────────────────────────┐
    │  RESPONSE (Take action)                              │
    │  └─ TheHive: Case management & collaboration           │
    └─────────────────────────────────────────────────────┘
```

### What We Removed & Why

| Tool | Removed? | Reason |
|------|----------|--------|
| **Shuffle** | ✅ Yes | SOAR complexity not needed - TheHive+Cortex sufficient |
| **FleetDM** | ✅ Yes | Overlaps with Velociraptor for endpoint visibility |
| **CyberChef** | ✅ Yes | Static app - use online version (gchq.github.io/CyberChef) |
| **Wireshark** | ✅ Yes | Redundant with Arkime + security risk (runs privileged) |
| **MITRE Navigator** | ✅ Yes | Reference tool - bookmark online version |
| **Caldera** | ✅ Yes | Red team tool - not for daily SOC operations |
| **Arkime** | ✅ KEPT | Full packet capture tool (active in docker-compose.yml) |

---

## Key Tools Explained

### 1. **Wazuh** (SIEM - The Foundation)
```
What: Security Information & Event Management
Port: 7001
Role: Central logging and alerting
Analogy: The "nervous system" of your SOC

┌──────────────────────────────────────────┐
│ Wazuh Agent (on every machine)            │
│ ├─ Collects logs                          │
│ ├─ Monitors file changes                  │
│ └─ Detects suspicious behavior            │
└──────────────┬───────────────────────────┘
               │ (sends data)
               ↓
┌──────────────────────────────────────────┐
│ Wazuh Manager (central server)            │
│ ├─ Correlates events                      │
│ ├─ Applies detection rules                │
│ └─ Generates alerts                       │
└──────────────────────────────────────────┘
```
**In Practice:** An employee downloads a malicious file → Wazuh agent sees it → Alerts the manager → Analyst is notified

---

### 2. **Velociraptor** (DFIR - Endpoint Forensics)
```
What: Digital Forensics & Incident Response
Port: 7000
Role: Live investigation on endpoints
Analogy: Remote crime scene investigator

When needed:
├─ A malware infection is suspected
├─ You need to search all computers for a suspicious file
├─ You want to capture RAM from an infected machine
└─ You need to find evidence of data exfiltration

Key capability: Query hundreds of endpoints simultaneously
```

**Real Example:**
- Wazuh detects suspicious PowerShell activity on 15 machines
- Velociraptor instantly queries all 15 to find the source
- Evidence collected centrally in seconds

---

### 3. **TheHive** (Case Management)
```
What: Incident Response Platform
Port: 7005
Role: Coordinate incident response

Timeline:
├─ Analyst receives alert
├─ Creates case in TheHive
├─ Assigns tasks to team members
├─ Adds evidence and findings
├─ Documents timeline of events
└─ Tracks resolution status
```

**Team Collaboration:**
```
Senior Analyst: "Looking at this alert, appears to be malware"
  ├─ Junior Analyst: "I'll run Velociraptor scan"
  │  └─ (adds findings to case)
  ├─ Network Engineer: "I'll block the C2 domain"
  │  └─ (documents action in case)
  └─ Manager: "Approved incident severity = CRITICAL"
     └─ (follows up in case)
```

---

### 4. **MISP** (Threat Intelligence Sharing)
```
What: Malware Information Sharing Platform
Port: 7003
Role: Share and receive threat indicators

Benefits:
├─ Share indicators (IPs, domains, file hashes)
├─ Receive threat feeds from partners
├─ Track threat actors
└─ Improve detection rules across organizations

Real-world: If you discover a malware campaign,
you share indicators → other organizations detect it too
```

---

### 5. **Cortex** (Threat Analysis)
```
What: Automated Threat Analysis Engine
Port: 7006
Role: Enrich alerts with external intelligence

Process:
1. An alert triggers in Wazuh
2. Cortex automatically:
   ├─ Checks the IP on VirusTotal
   ├─ Looks up the domain reputation
   ├─ Checks if hash is known malware
   └─ Cross-references with MISP feeds
3. Adds findings to TheHive case

Result: Human analysts save hours on research
```

---

### 6. **Arkime** (Network Analysis)
```
What: Full Packet Capture & Search
Port: 7008
Role: Deep network investigation

Capability:
├─ Records EVERY packet on the network
├─ Search by IP, domain, protocol, payload
└─ Extract files transmitted on the network

Use Case:
A user clicks a suspicious link → You want to see
exactly what was transmitted → Arkime has the full record
```

---

### 7. **EveBox** (IDS Alert Manager)
```
What: Suricata IDS Alert Interface
Port: 7015
Role: View network-based detections

Source: Suricata IDS
├─ Monitors network traffic in real-time
├─ Triggers alerts on suspicious patterns
└─ (e.g., SQL injection attempts, port scans, malware C2 traffic)

EveBox interface makes alerts easier to browse and correlate
```

---

## Discussion Points for Students

### 🎯 "This is What Enterprise Security Actually Looks Like"

**Why this matters:**
- Most students learn security theory in isolation
- Real enterprises use integrated toolchains
- This SOC lab shows the practical reality
- You'll see how tools complement each other, not replace each other

**Example:** Finding a mystery IP address
```
Step 1: Wazuh detects unusual outbound connection → "What IP is that?"
Step 2: EveBox shows Suricata triggered on that IP → "Known malware!"
Step 3: MISP database confirms it's a known C2 server
Step 4: Arkime provides packet dump of the communication
Step 5: Velociraptor finds which process initiated it
Step 6: TheHive documents entire investigation
```

---

### 🔧 "Each Tool Solves a Specific Problem"

**Central Principle:** No single tool does everything well

| Problem | Tool | Why |
|---------|------|-----|
| "Where are my logs?" | Wazuh SIEM | Built for centralization & correlation |
| "What happened on this machine?" | Velociraptor | Live forensics, not just logs |
| "What did the network see?" | Arkime + Suricata | Network visibility |
| "Is this threat known?" | MISP + Cortex | Intelligence enrichment |
| "How do we manage this incident?" | TheHive | Case workflow, collaboration |

---

### 🔒 "You Can Practice Incident Response Without Risking Production"

**Why this is critical:**
- Real incidents are high-stress
- Making mistakes requires practice
- You can't practice phishing response on production email system
- This SOC lab lets you simulate realistically:
  - Malware infections
  - Network attacks
  - Insider threats
  - Data exfiltration

---

### 🏢 "Industry-Standard Tools Used by Real Security Teams"

These aren't academic toys:

**Wazuh:** Used by organizations worldwide for SIEM
**Velociraptor:** Deployed in enterprise environments
**TheHive:** Standard incident response platform
**MISP:** Used by government agencies, financial institutions
**Cortex:** Integrated with major security ecosystems
**Suricata:** Open-source IDS powering enterprise networks

**Bonus:** Learning these tools = Job-ready skills

---

## The Data Flow: A Real Incident Example

```
SCENARIO: Malware detected on employee machine

┌──────────────────────────────────────────────────┐
│ Employee's Computer (has Wazuh agent)            │
│ · Suspicious executable detected                 │
│ · Hash: a1b2c3d4e5f6...                          │
└────────────────────────┬─────────────────────────┘
                         │ sends log
                         ↓
        ┌────────────────────────────────┐
        │        WAZUH MANAGER            │
        │ · Rule match: "Suspicious EXE" │
        │ · Severity: HIGH                │
        └────────────┬───────────────────┘
                     │ triggers alert
         ┌───────────┼───────────┐
         ↓           ↓           ↓
    ┌────────┐  ┌───────┐  ┌────────┐
    │ Cortex │  │TheHive│  │Analyst │
    │auto-   │  │creates│  │notified│
    │enriches│  │case   │  │(email) │
    └────────┘  └───────┘  └────────┘
         │           │           │
         └─────┬─────┴─────┬─────┘
               │           │
               ↓           ↓
        ┌──────────────────────────────┐
        │  VirusTotal Check (done      │
        │  automatically by Cortex)    │
        │  · File: KNOWN MALWARE ⚠️    │
        │  · Family: Trojan.GenericXYZ │
        │  · Detection: 32/70          │
        └──────────────────────────────┘
               │ (findings added to case)
               ↓
        ┌──────────────────────────────┐
        │   ANALYST ACTIONS            │
        │ 1. Run Velociraptor scan     │
        │    → Find 3 more infected    │
        │      machines                │
        │ 2. Check Arkime              │
        │    → See C2 communication    │
        │ 3. Update TheHive case       │
        │ 4. Share hash to MISP        │
        │ 5. Block C2 server           │
        └──────────────────────────────┘
```

---

## Key Takeaways for Students

✅ A SOC Lab is a **sandbox for security learning**
✅ Real security uses **multiple complementary tools**
✅ The workflow is: **Detect → Analyze → Respond → Learn**
✅ Every tool has a **specific purpose**
✅ Security is a **team sport** requiring collaboration
✅ These tools are **used in real enterprises** - learning them matters

---

## Next Steps: What Students Can Do

1. **Deploy the lab** on your own machine or cloud instance
2. **Practice scenarios:**
   - Simulate malware infection
   - Practice incident response workflow
   - Run threat hunts across all systems
3. **Integrate with learning:**
   - Combine with TryHackMe/HackTheBox attacks
   - Detect attacks you're running
   - Practice response procedures
4. **Explore each tool:**
   - Read Wazuh detection rules
   - Write Velociraptor queries
   - Create TheHive playbooks
   - Share threat intel through MISP

---

## Architecture Diagram Summary

```
                    🌐 INTERNET
                        │
                        ↓
            ┌───────────────────────┐
            │  Suricata IDS         │  ← Network threats
            │  (Host Network Mode)  │
            └──────────┬────────────┘
                       │
         ┌─────────────┼─────────────┐
         │             │             │
         ↓             ↓             ↓
    ┌─────────┐   ┌─────────┐   ┌─────────┐
    │  WAZUH  │   │ARKIME   │   │EVEBOX   │
    │  (7001) │   │(7008)   │   │(7015)   │
    └────┬────┘   └─────────┘   └─────────┘
         │
         ├─────────────┬─────────────┬─────────────┐
         ↓             ↓             ↓             ↓
    ┌─────────┐   ┌──────────┐ ┌──────────┐ ┌─────────┐
    │VELOCI   │   │THE HIVE  │ │CORTEX    │ │MISP     │
    │(7000)   │   │(7005)    │ │(7006)    │ │(7003)   │
    └─────────┘   └──────────┘ └──────────┘ └─────────┘
         │             │            │           │
         └─────────────┴────────────┴───────────┘
                       ↓
            ┌──────────────────────┐
            │  Web Portal (5443)   │
            │  Central Dashboard   │
            └──────────────────────┘
```

---

# 🎼 The Scripting Orchestra: Automation Behind the Scenes

Behind every smooth SOC Lab deployment is a **coordinated symphony of shell scripts** (`.sh` files). These scripts automate everything from installation to troubleshooting. Let's understand this automation framework:

## The Big Picture: Script Layers

```
┌─────────────────────────────────────────────────┐
│        ORCHESTRATION LAYER (Main Scripts)       │
│  cyberblue_init.sh                              │
│  cyberblue_install.sh                           │
│  force-start.sh                                 │
└────────────────────┬────────────────────────────┘
                     │
      ┌──────────────┼──────────────┐
      ↓              ↓              ↓
┌────────────┐ ┌───────────┐ ┌─────────────┐
│ SETUP      │ │ FIX       │ │ TOOL-SPECIFIC
│ LAYER      │ │ & REPAIR  │ │ SCRIPTS
│            │ │ LAYER     │ │
│• prereqs   │ │• wazuh    │ │• misp
│• docker    │ │• arkime   │ │• velociraptor
│• system    │ │• fleet    │ │• arkime
│ config    │ │• docker   │ │• portal
└────────────┘ └───────────┘ └─────────────┘
```

## Layer 1: Setup & Prerequisites (One-Time Installation)

### **1. install-prerequisites.sh** (The Foundation Builder)
```bash
Function: Install Docker, Docker Compose, and system optimizations
Runs: FIRST (before anything else)
Time: ~5-10 minutes
What it does:
  ✅ Updates system packages
  ✅ Installs Docker CE and Docker Compose
  ✅ Configures Docker daemon
  ✅ Sets system limits (vm.max_map_count=262144 for OpenSearch)
  ✅ Applies iptables networking rules
  ✅ Creates Docker group permissions
  ✅ Tests Docker access
```

**Why this matters:**
- Docker and networking must be perfect before anything runs
- System kernel parameters must be tuned for Elasticsearch/OpenSearch
- Without this, your SOC lab will fail on startup

### **2. cyberblue_init.sh** (The Smart Initializer)
```bash
Function: One-shot initialization for a fresh CyberBlue deployment
Runs: SECOND (after prerequisites installed)
Time: ~2 minutes
What it does:
  ✅ Auto-detects your HOST_IP address
  ✅ Updates .env file with real IP (not localhost!)
  ✅ Sets MISP_BASE_URL correctly
  ✅ Creates all required bind-mount directories
  ✅ Sets directory permissions
  ✅ Makes all scripts executable
  ✅ Persists vm.max_map_count across reboots
```

**Example Flow:**
```
Your machine has IP: 192.168.1.100

cyberblue_init.sh detects this:
  1. Tries multiple detection methods (robust!)
  2. Finds: 192.168.1.100
  3. Writes to .env:  HOST_IP=192.168.1.100
  4. Updates MISP:  MISP_BASE_URL=https://192.168.1.100:7003
  5. Creates directories: /arkime/pcaps, /misp/configs, etc.

Result: docker compose up -d will work correctly!
```

### **3. install_docker.sh** (Simple Docker Installer)
```bash
Function: Quick Docker installation (simplified version)
Runs: OPTIONAL/Alternative to install-prerequisites.sh
Time: ~5 minutes
What it does:
  ✅ Adds Docker GPG key
  ✅ Adds Docker repository
  ✅ Installs Docker packages
  ✅ Sets up user permissions
```

---

## Layer 2: Troubleshooting & Repair Scripts

These scripts FIX Things When They Break:

### **4. fix-wazuh-services.sh** (The Wazuh Doctor) 🏥
```bash
Function: Complete Wazuh SSL certificates & service fix
Runs: When Wazuh won't start or shows certificate errors
Time: ~3-4 minutes per run
What it does:
  ✅ STEP 1: Stops all Wazuh containers
  ✅ STEP 2: Deletes SSL certs completely (starts fresh)
  ✅ STEP 3: Clears Docker volumes
  ✅ STEP 4: Regenerates fresh SSL certificates
  ✅ STEP 5: Fixes certificate permissions
  ✅ STEP 6: Starts Wazuh services in CORRECT ORDER:
            1. Indexer first (waits 45s for startup)
            2. Manager (waits 30s)
            3. Dashboard (waits 45s)
  ✅ STEP 7: Verifies all 3 services are running
```

**Why This Script Exists:**
- Wazuh has complex SSL certificate requirements
- Order of startup matters (indexer MUST start first)
- Certificate permissions can get corrupted
- Much faster to run this than debug manually!

**Order Matters Diagram:**
```
❌ WRONG ORDER:           ✅ CORRECT ORDER:
   Manager starts         Indexer starts
   ↓ (fails, no indexer)  ↓ (success)
   Indexer starts         Wait 45s for indexer health
   ↓ (conflict!)          ↓
   Dashboard crashes      Manager starts
                         ↓ (success, indexer ready)
                         Wait 30s
                         ↓
                         Dashboard starts
                         ↓ (success!)
```

### **5. fix-docker-external-access.sh** (The Network Fixer) 🌐
```bash
Function: Fix Docker container access from external networks
Runs: When you can't reach services from outside your machine
Time: ~2 minutes
What it does:
  ✅ Detects your primary network interface (eth0, ens5, etc.)
  ✅ Finds Docker bridges (br-xxxxx)
  ✅ Backs up current iptables rules (safety first!)
  ✅ Adds iptables FORWARD rules for Docker
  ✅ Sets FORWARD policy to ACCEPT
  ✅ Opens common SOC tool ports (7001, 7003, 7005, etc.)
  ✅ Makes rules persistent across reboots
  ✅ Creates systemd service for automatic rule application
  ✅ Tests connectivity to verify it works
```

**Real-World Problem This Solves:**
```
You deploy on AWS EC2 or Azure VM:
  • Firewall drops packets at iptables level
  • Docker containers won't reach the network
  • You can't access MISP from your browser

This script fixes it by:
  1. Allowing traffic FROM external → Docker bridge
  2. Allowing traffic FROM Docker bridge → external
  3. Making it persistent
  4. Creating autorun service
```

### **6. force-start.sh** (The Emergency Restart) 🚨
```bash
Function: Complete Docker restart when things are stuck
Runs: When containers hang or don't respond
Time: ~3-5 minutes
What it does:
  ✅ Restarts Docker daemon completely
  ✅ Waits for Docker to be ready (with timeout)
  ✅ Brings up ALL containers with docker compose up -d
  ✅ Waits 30s for services to stabilize
  ✅ Verifies containers are running
  ✅ Shows you all service URLs for access
```

**When to Use:**
```
Problem 1: "Container not responding"
  → Solution: ./force-start.sh

Problem 2: "Docker networking is broken"
  → Solution: ./force-start.sh

Problem 3: "After system reboot, containers won't start"
  → Solution: ./force-start.sh
```

---

## Layer 3: Tool-Specific Configuration Scripts

These scripts configure individual tools:

### **MISP Configuration Scripts**
```bash
misp/configure-threat-feeds.sh
  ✅ Sets up MISP threat intelligence feeds
  ✅ Adds ATT&CK framework data
  ✅ Configures automated feed updates

misp/configure-threat-more-feeds.sh
  ✅ Additional threat feed sources
  ✅ IoC (Indicator of Compromise) databases

misp/update-feeds.sh
  ✅ Updates all threat feeds on-demand
  ✅ (Usually runs on a schedule)
```

### **Velociraptor Agent Scripts**
```bash
velociraptor/agents/download-binaries.sh
  ✅ Downloads Velociraptor agent binaries
  ✅ Prepares for deployment to endpoints
```

### **Wazuh Agent Scripts**
```bash
wazuh/agents/download-packages.sh
  ✅ Downloads Wazuh agent installers
  ✅ Supports multiple OS (Windows, Linux, macOS)
```

### **Fleet Agent Scripts**
```bash
fleet/agents/download-packages.sh
  ✅ Downloads Osquery binaries
  ✅ For endpoint visibility

fleet/configure-fleet-secret.sh
  ✅ Sets up Fleet enrollment tokens
  ✅ Agents use this to register with Fleet
```

### **Arkime & Network Scripts**
```bash
arkime/scripts/arkime-parse-pcap-folder.sh
  ✅ Processes PCAP files for packet analysis
  ✅ Imports packet captures into Arkime

generate-pcap-for-arkime.sh
  ✅ Creates test PCAP files for Arkime
  ✅ Useful for testing without live traffic

scripts/start-suricata.sh
  ✅ Starts Suricata IDS with proper config
```

### **Portal & Management**
```bash
portal/start_portal.sh
  ✅ Starts the CyberBlue web portal
  ✅ Main entry point for all users (https://IP:5443)

scripts/detect-interface.sh
  ✅ Auto-detects network interface
  ✅ Used by other scripts for networking
```

---

## The Docker Build Infrastructure

### **Build Scripts** (Creating Custom Images)
```bash
wazuh/build-docker-images/build-images.sh
  ✅ Builds custom Wazuh Docker images
  ✅ Includes all security configurations
  ✅ Adds custom entrypoint scripts

Entrypoint Scripts (inside containers):
  wazuh-manager/config/entrypoint.sh
  wazuh-indexer/config/entrypoint.sh
  wazuh-dashboard/config/entrypoint.sh
  misp/core/files/entrypoint.sh
  velociraptor/entrypoint.sh

Why multiple entrypoints?
  ✅ Each service has unique startup requirements
  ✅ Certificate setup, configuration, health checks
  ✅ Container-specific logging
```

---

## The Complete Deployment Timeline

```
TIME    SCRIPT                           ACTION
────────────────────────────────────────────────────────────────
T=0     install-prerequisites.sh         Install Docker & system setup
        (takes ~10 minutes)

T=10min cyberblue_init.sh               Detect IP, create directories
        (takes ~2 minutes)

T=12min docker compose up -d            Deploy containers
        (takes ~5 minutes for all to start)

T=17min [Container startup]
        • Wazuh cert-generator runs first
        • Wazuh indexer starts
        • Wazuh manager starts
        • Wazuh dashboard starts
        • All other tools start

T=20+   All services available!
        Portal: https://YOUR_IP:5443
        Wazuh: https://YOUR_IP:7001
        Etc.
```

---

## How Scripts Handle Errors (Resilience)

### **Error Handling Pattern**
```bash
# Safe pattern used in all scripts:
set -euo pipefail

# Meaning:
# -e: Exit if ANY command fails
# -u: Error if undefined variable used
# -o pipefail: Failed commands in pipes cause failure

# Special handling for optional steps:
optional_command || true
# This means: run the command, BUT don't fail if it doesn't work
```

### **Health Checks Built Into Scripts**
```bash
# Instead of just starting services:
docker-compose up -d

# Scripts actually check:
1. Is the service running?
   → sudo docker ps | grep service-name

2. Is the service responding?
   → curl -s -k https://localhost:PORT

3. Are the network ports open?
   → netstat -tulpn | grep PORT

4. Do required files exist?
   → [ -f /path/to/config ] || error "missing file"
```

---

## Script Usage Patterns for Students

### **Complete Fresh Installation:**
```bash
# Step 1: Install prerequisites (one-time)
./install-prerequisites.sh

# Step 2: Initialize CyberBlue (one-time per location)
./cyberblue_init.sh

# Step 3: Start services
docker compose up -d

# Wait 2-5 minutes...
# Your SOC lab is ready!
```

### **Fix Wazuh Issues:**
```bash
# If Wazuh won't start:
./fix-wazuh-services.sh

# Wait 3-4 minutes...
# Wazuh is fixed and running!
```

### **Fix Network Access Issues:**
```bash
# If you can't reach services from outside:
./fix-docker-external-access.sh

# Now external access works!
```

### **Emergency Restart:**
```bash
# If everything is stuck:
./force-start.sh

# This restarts Docker and all containers
```

---

## Understanding Script Flexibility

### **Scripts Support Multiple Environments:**

**Detection Examples** (from fix-docker-external-access.sh):
```
Platform Auto-Detection:
  AWS EC2          → eth0, security groups optional
  Azure VM         → ens5, network security group config needed
  GCP Instance     → ens4, firewall rules needed
  VMware VM        → ens33, vmnet configuration
  VirtualBox       → vboxnet0, Host-Only/NAT modes
  Physical Server  → eth0/ens0, physical router needed
  WSL2 (Windows)   → eth0, use Windows IP not WSL IP

Scripts detect:
  1. Actual interface name (not assumed!)
  2. IP address (tried multiple methods)
  3. Active bridges (Docker-specific)
  4. Then applies fixes accordingly
```

---

## Key Takeaways About The Scripting Orchestra

✅ **Scripts are the "invisible employees"** - They do the boring work so you don't have to
✅ **Order matters** - Each script runs at the right time for a reason
✅ **Recovery is built-in** - Use fix scripts when things break
✅ **Portable** - Scripts work on AWS, Azure, GCP, bare metal, VMware, VirtualBox
✅ **Idempotent** - You can run scripts multiple times safely (mostly)
✅ **Logged & Visible** - Color-coded output shows you what's happening
✅ **Production-Quality** - Health checks and error handling throughout

---

## Script Management Best Practices (For Students)

```bash
# Always check what scripts exist:
ls -la *.sh

# Read the header of a script before running:
head -20 script-name.sh

# Add execute permissions if needed:
chmod +x script-name.sh

# Test in a safe way first:
./script-name.sh --help    # Read options
./script-name.sh --force   # Run with auto-confirm (vs interactive)

# Check Docker status:
sudo docker ps              # See running containers
sudo docker logs name       # See container logs

# Monitor while scripts run:
watch -n 1 'sudo docker ps' # Update every 1 second
```

---

## Common Script Scenarios for Practice

### **Scenario 1: Fresh Deployment on New Ubuntu VM**
```bash
git clone <repo>
cd letistaburn/MiniCblue
./install-prerequisites.sh        # Install Docker (5-10 min)
./cyberblue_init.sh               # Initialize (2 min)
docker compose up -d              # Deploy (5 min)
# Total: ~22 minutes
# Result: Working SOC lab!
```

### **Scenario 2: Wazuh Won't Start**
```bash
# You see in portal: "Wazuh - Down"
./fix-wazuh-services.sh
# This will:
#   1. Stop all Wazuh containers
#   2. Delete and regenerate SSL certs
#   3. Start them in correct order
#   4. Verify they're up
# Result: Wazuh working again!
```

### **Scenario 3: AWS Deployment - Can't Access MISP**
```bash
# You can SSH to instance but can't reach https://IP:7003
# Cause: iptables FORWARD rules
./fix-docker-external-access.sh
# This will:
#   1. Detect your AWS network interface
#   2. Configure iptables for Docker
#   3. Make it persistent
#   4. Test connectivity
# Result: MISP accessible from browser!
```

### **Scenario 4: System Reboot - Services Not Starting**
```bash
# After reboot, docker compose up -d doesn't work
./force-start.sh
# This will:
#   1. Restart Docker daemon
#   2. Bring up ALL containers
#   3. Verify they're running
# Result: Everything working again!
```

---

## The Philosophy Behind This Automation

**"The best operations are the ones you don't have to think about"**

- Scripts handle **repetitive** tasks (installation, configuration)
- Scripts handle **complex** tasks (certificate generation, networking)
- Scripts handle **error-prone** tasks (service startup order)
- Scripts provide **consistency** (same result every time)
- Scripts create **knowledge** (other people can understand what happened)

This is the Enterprise SOC philosophy:
- **Automation reduces errors**
- **Consistency breeds reliability**
- **Transparency enables learning**

---

---

## Questions for Discussion

1. **Why not just use Wazuh?** - Because different tools excel at different problems
2. **What happens if a tool fails?** - It depends on the tool's role and redundancy
3. **How do you practice incident response?** - Simulate attacks, detect them, respond
4. **What's the biggest challenge in a real SOC?** - Alert fatigue and alert tuning
5. **How would you integrate this with your company's infrastructure?** - Deploy agents to all endpoints and network sensors

---

*Last Updated: 2026*
*For Networking & Cybersecurity Students*
*Let's build the future of security! 🛡️*
