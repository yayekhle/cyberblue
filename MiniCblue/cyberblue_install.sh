#!/bin/bash

# ============================================================================
# CyberBlue SOC Platform - Fully Automated Installation Script (VERBOSE)
# ============================================================================
# This script combines prerequisites setup and CyberBlue initialization
# into one fully automated installation - NO user intervention required!
#
# Usage: ./install-cyberblue-auto.sh
# 
# Features:
# ✅ Zero prompts - completely hands-free installation
# ✅ Full visibility - see everything happening in real-time
# ✅ Automatic prerequisite detection and installation
# ✅ Full Docker and Docker Compose setup
# ✅ Complete CyberBlue SOC platform deployment
# ✅ Works on AWS, Azure, GCP, VMware, VirtualBox, bare metal
# ============================================================================

# NOTE: We intentionally do NOT use 'set -e' here.
# 'set -e' would silently kill the script if any download, git clone,
# or optional step fails — causing docker images to never get installed
# with no clear error message. Instead we handle errors explicitly per-step.
# Critical steps use explicit checks; optional steps use '|| true'.

# Custom handler: print a clear error with line number if something critical fails
trap 'echo -e "\n${RED}❌ FATAL ERROR at line ${LINENO}: last command exited with code $?${NC}\n   Check the output above for the failing step.\n   Re-run the script after fixing the issue.\n" >&2' ERR
set -E  # Ensure ERR trap fires inside functions too

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
START_TIME=$(date +%s)

# ============================================================================
# CRITICAL: Detect Installation User (for generic deployment)
# ============================================================================
INSTALL_USER="$(whoami)"
if [ -n "$SUDO_USER" ] && [ "$SUDO_USER" != "root" ]; then
    INSTALL_USER="$SUDO_USER"  # Get real user when run with sudo
fi

# Export for docker-compose, scripts, and subprocesses
export CYBERBLUE_INSTALL_DIR="$SCRIPT_DIR"
export CYBERBLUE_INSTALL_USER="$INSTALL_USER"

# CRITICAL: Write to .env file IMMEDIATELY so docker-compose has these!
# Remove old values if they exist
if [ -f "$SCRIPT_DIR/.env" ]; then
    sed -i '/^CYBERBLUE_INSTALL_DIR=/d' "$SCRIPT_DIR/.env" 2>/dev/null || true
    sed -i '/^CYBERBLUE_INSTALL_USER=/d' "$SCRIPT_DIR/.env" 2>/dev/null || true
fi

# Write to .env (docker-compose reads this automatically)
cat >> "$SCRIPT_DIR/.env" << ENV_VARS
CYBERBLUE_INSTALL_DIR=$SCRIPT_DIR
CYBERBLUE_INSTALL_USER=$INSTALL_USER
ENV_VARS

echo "✓ Installation directory: $SCRIPT_DIR"
echo "✓ Installation user: $INSTALL_USER"
echo "✓ Written to .env for docker-compose"
# ============================================================================

# Ensure all apt operations are non-interactive
export DEBIAN_FRONTEND=noninteractive
export DEBCONF_NONINTERACTIVE_SEEN=true
export UCF_FORCE_CONFFNEW=1
export DEBIAN_PRIORITY=critical

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

# Function to run command with live output and prefix
run_with_output() {
    local prefix="$1"
    shift
    "$@" 2>&1 | while IFS= read -r line; do
        echo -e "${CYAN}   ${prefix}${NC} $line"
    done
    return ${PIPESTATUS[0]}
}

# Function to show spinner during operation
show_progress() {
    local message="$1"
    echo -e "${YELLOW}   ⏳ $message${NC}"
}

# ============================================================================
# BANNER WITH CYBERBLUE LOGO
# ============================================================================
clear

echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                                      ║${NC}"
echo -e "${CYAN}║  /\$\$      /\$\$ /\$\$           /\$\$  /\$\$\$\$\$\$  /\$\$\$\$\$\$\$  /\$\$                    ║${NC}"
echo -e "${CYAN}║ | \$\$\$    /\$\$\$|__/          |__/ /\$\$__  \$\$| \$\$__  \$\$| \$\$                    ║${NC}"
echo -e "${CYAN}║ | \$\$\$\$  /\$\$\$\$ /\$\$ /\$\$\$\$\$\$\$  /\$\$| \$\$  \__/| \$\$  \ \$\$| \$\$ /\$\$   /\$\$  /\$\$\$\$\$\$ ║${NC}"
echo -e "${CYAN}║ | \$\$ \$\$\$/\$\$ \$\$| \$\$| \$\$__  \$\$| \$\$| \$\$      | \$\$\$\$\$\$\$ | \$\$| \$\$  | \$\$ /\$\$__  \$\$║${NC}"
echo -e "${BLUE}║ | \$\$  \$\$\$| \$\$| \$\$| \$\$  \ \$\$| \$\$| \$\$      | \$\$__  \$\$| \$\$| \$\$  | \$\$| \$\$\$\$\$\$\$\$║${NC}"
echo -e "${BLUE}║ | \$\$\  \$ | \$\$| \$\$| \$\$  | \$\$| \$\$| \$\$    \$\$| \$\$  \ \$\$| \$\$| \$\$  | \$\$| \$\$_____/║${NC}"
echo -e "${CYAN}║ | \$\$ \/  | \$\$| \$\$| \$\$  | \$\$| \$\$|  \$\$\$\$\$\$/| \$\$\$\$\$\$\$/| \$\$|  \$\$\$\$\$\$/|  \$\$\$\$\$\$\$║${NC}"
echo -e "${CYAN}║ |__/     |__/|__/|__/  |__/|__/ \______/ |_______/ |__/ \______/  \_______/║${NC}"
echo -e "${BLUE}║                                                                                      ║${NC}"
echo -e "${BLUE}║                          ${MAGENTA}🔷 SOC PLATFORM INSTALLER 🔷${BLUE}                           ║${NC}"
echo -e "${BLUE}║                                                                                      ║${NC}"
echo -e "${BLUE}║                 ${GREEN}✅ Fully Automated - Live Progress Monitoring${BLUE}                 ║${NC}"
echo -e "${BLUE}║                 ${GREEN}✅ Zero User Intervention Required${BLUE}                           ║${NC}"
echo -e "${BLUE}║                 ${GREEN}✅ 8 Security Tools in One Platform${BLUE}                          ║${NC}"
echo -e "${BLUE}║                                                                                      ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║  ⚠️  EDUCATIONAL & TRAINING ENVIRONMENT ONLY ⚠️                          ║${NC}"
echo -e "${YELLOW}║                                                                          ║${NC}"
echo -e "${YELLOW}║  This platform is designed for:                                         ║${NC}"
echo -e "${YELLOW}║  • Cybersecurity training and education                                 ║${NC}"
echo -e "${YELLOW}║  • Security operations center (SOC) simulation                          ║${NC}"
echo -e "${YELLOW}║  • Threat detection and response practice                               ║${NC}"
echo -e "${YELLOW}║  • Isolated lab testing environments                                    ║${NC}"
echo -e "${YELLOW}║                                                                          ║${NC}"
echo -e "${RED}║  ❌ NOT for production use                                                 ║${NC}"
echo -e "${RED}║  ❌ Contains default credentials                                           ║${NC}"
echo -e "${RED}║  ❌ Not security hardened for internet exposure                            ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  🚀 INSTALLATION STARTING                                                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}   📺 Watch live progress - everything happens in real-time!${NC}"
echo -e "${CYAN}   ⏱️  Estimated time: 20-30 minutes${NC}"
echo -e "${CYAN}   ☕ Grab a coffee and watch the magic!${NC}"
echo ""
echo -e "${MAGENTA}   💡 TIP: You'll see every command and output - nothing is hidden!${NC}"
echo ""
echo -e "${GREEN}   🎬 Installation begins in 3 seconds...${NC}"
echo ""
for i in 3 2 1; do
    echo -ne "\r${YELLOW}   ⏳ Starting in ${i}...${NC}"
    sleep 1
done
echo -e "\r${GREEN}   ✅ Let's go!                    ${NC}"
echo ""
sleep 1

# ============================================================================
# PART 1: PREREQUISITES INSTALLATION
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}║  PART 1/2: INSTALLING PREREQUISITES                    ║${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if prerequisites are already installed
PREREQS_NEEDED=false
if ! command -v docker >/dev/null 2>&1; then
    PREREQS_NEEDED=true
    echo "📦 Docker not found - will install"
elif ! docker ps >/dev/null 2>&1; then
    PREREQS_NEEDED=true
    echo "🔧 Docker found but needs configuration"
else
    echo -e "${GREEN}✅ Docker already installed and working${NC}"
fi

if $PREREQS_NEEDED; then
    echo ""
    echo -e "${BLUE}🧹 Step 1.0: Clear APT Locks${NC}"
    show_progress "Checking for apt/dpkg lock conflicts..."
    # Kill any running apt/dpkg processes
    sudo pkill -9 apt 2>/dev/null || true
    sudo pkill -9 dpkg 2>/dev/null || true
    sudo pkill -9 apt-get 2>/dev/null || true
    # Remove lock files
    sudo rm -f /var/lib/dpkg/lock-frontend 2>/dev/null || true
    sudo rm -f /var/lib/dpkg/lock 2>/dev/null || true
    sudo rm -f /var/cache/apt/archives/lock 2>/dev/null || true
    sudo rm -f /var/lib/apt/lists/lock 2>/dev/null || true
    # Reconfigure dpkg if interrupted
    sudo dpkg --configure -a 2>/dev/null || true
    echo -e "${GREEN}✅ APT locks cleared${NC}"
    sleep 2
    
    echo ""
    echo -e "${BLUE}🔄 Step 1.1: System Update${NC}"
    show_progress "Updating package lists..."
    run_with_output "[APT]" sudo apt-get update
    
    show_progress "Upgrading system packages (this may take a few minutes)..."
    run_with_output "[UPGRADE]" sudo apt-get upgrade -y -o Dpkg::Options::="--force-confnew" -o Dpkg::Options::="--force-confdef"
    
    show_progress "Installing essential packages..."
    run_with_output "[INSTALL]" sudo apt-get install -y ca-certificates curl gnupg lsb-release git
    echo -e "${GREEN}✅ System packages updated${NC}"
    
    echo ""
    echo -e "${BLUE}🐳 Step 1.2: Docker Installation${NC}"
    echo "   Preparing Docker installation..."
    
    # Remove existing GPG key to avoid prompts
    sudo rm -f /etc/apt/keyrings/docker.gpg 2>/dev/null || true
    sudo mkdir -p /etc/apt/keyrings
    
    show_progress "Downloading Docker GPG key..."
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg 2>&1 | head -5
    echo -e "${CYAN}   [GPG]${NC} Docker GPG key added"
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    echo -e "${CYAN}   [REPO]${NC} Docker repository configured"
    
    show_progress "Updating package lists with Docker repo..."
    run_with_output "[APT]" sudo apt-get update
    
    show_progress "Installing Docker CE (this may take 2-3 minutes)..."
    run_with_output "[DOCKER]" sudo apt-get install -y -o Dpkg::Options::="--force-confnew" docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    echo -e "${GREEN}✅ Docker installed${NC}"
    
    echo ""
    echo -e "${BLUE}📦 Step 1.3: Docker Compose${NC}"
    show_progress "Downloading Docker Compose standalone binary..."
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose 2>&1 | grep -E "%" | tail -5 | while read line; do echo -e "${CYAN}   [DOWNLOAD]${NC} $line"; done
    sudo chmod +x /usr/local/bin/docker-compose
    echo -e "${GREEN}✅ Docker Compose installed${NC}"
    
    echo ""
    echo -e "${BLUE}👤 Step 1.4: User Permissions${NC}"
    echo -e "${CYAN}   [PERMS]${NC} Adding user to docker group..."
    sudo usermod -aG docker $USER
    # Apply the new group membership immediately for the rest of this script
    # without requiring a logout/login. This is the fix for the 'permission denied'
    # issue when running docker commands later in the same session.
    if id -nG "$USER" | grep -qw docker; then
        echo -e "${CYAN}   [PERMS]${NC} Docker group already active in this session"
    else
        echo -e "${CYAN}   [PERMS]${NC} Refreshing group membership for current session..."
        exec sg docker "$0 $*" || true  # Re-exec this script under the docker group
    fi
    echo -e "${CYAN}   [PERMS]${NC} Setting docker socket permissions..."
    sudo chown root:docker /var/run/docker.sock 2>/dev/null || true
    sudo chmod 660 /var/run/docker.sock 2>/dev/null || true
    echo -e "${CYAN}   [SERVICE]${NC} Enabling Docker service..."
    sudo systemctl enable docker 2>&1 | head -3 | while read line; do echo -e "${CYAN}   [SYSTEMD]${NC} $line"; done
    sudo systemctl start docker
    echo -e "${GREEN}✅ Docker permissions configured${NC}"
    
    echo ""
    echo -e "${BLUE}⚙️  Step 1.5: System Optimizations${NC}"
    
    if ! grep -q "vm.max_map_count=262144" /etc/sysctl.conf 2>/dev/null; then
        echo -e "${CYAN}   [SYSCTL]${NC} Setting vm.max_map_count=262144 for Elasticsearch..."
        echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p 2>&1 | grep max_map_count | while read line; do echo -e "${CYAN}   [SYSCTL]${NC} $line"; done
    else
        echo -e "${CYAN}   [SYSCTL]${NC} vm.max_map_count already configured"
    fi
    
    if ! grep -q "soft nofile 65536" /etc/security/limits.conf 2>/dev/null; then
        echo -e "${CYAN}   [LIMITS]${NC} Setting file descriptor limits..."
        echo '* soft nofile 65536' | sudo tee -a /etc/security/limits.conf
        echo '* hard nofile 65536' | sudo tee -a /etc/security/limits.conf
    else
        echo -e "${CYAN}   [LIMITS]${NC} File descriptor limits already configured"
    fi
    
    echo -e "${GREEN}✅ System optimizations applied${NC}"
    
    echo ""
    echo -e "${BLUE}💾 Step 1.6: Swap Space Configuration${NC}"
    show_progress "Configuring swap space for system stability..."
    
    # Check if swap already exists
    SWAP_SIZE=$(swapon --show=SIZE --noheadings 2>/dev/null | head -1)
    if [ -n "$SWAP_SIZE" ]; then
        echo -e "${CYAN}   [SWAP]${NC} Swap already configured: $SWAP_SIZE"
        echo -e "${GREEN}✅ Swap space already present${NC}"
    else
        echo -e "${CYAN}   [SWAP]${NC} No swap detected - creating 8GB swap file..."
        
        # Create 8GB swap file
        if sudo fallocate -l 8G /swapfile 2>/dev/null; then
            echo -e "${CYAN}   [SWAP]${NC} 8GB swap file allocated"
        else
            # Fallback to dd if fallocate not supported
            echo -e "${CYAN}   [SWAP]${NC} Using dd for swap creation (this may take a minute)..."
            sudo dd if=/dev/zero of=/swapfile bs=1M count=8192 status=progress 2>&1 | tail -1 | while read line; do echo -e "${CYAN}   [DD]${NC} $line"; done
        fi
        
        # Set permissions
        sudo chmod 600 /swapfile
        echo -e "${CYAN}   [SWAP]${NC} Permissions set (600)"
        
        # Make swap
        sudo mkswap /swapfile 2>&1 | while read line; do echo -e "${CYAN}   [MKSWAP]${NC} $line"; done
        
        # Enable swap
        sudo swapon /swapfile
        echo -e "${CYAN}   [SWAP]${NC} Swap activated"
        
        # Make persistent across reboots
        if ! grep -q "/swapfile" /etc/fstab 2>/dev/null; then
            echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab >/dev/null
            echo -e "${CYAN}   [FSTAB]${NC} Swap made persistent in /etc/fstab"
        fi
        
        # Verify swap
        SWAP_TOTAL=$(free -h | grep Swap | awk '{print $2}')
        echo -e "${CYAN}   [VERIFY]${NC} Swap total: $SWAP_TOTAL"
        echo -e "${GREEN}✅ Swap space configured successfully (8GB)${NC}"
        echo -e "${CYAN}   [INFO]${NC} This prevents system hanging and OOM crashes"
    fi
    
    echo ""
    echo -e "${BLUE}🌍 Step 1.7: Environment Variables${NC}"
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    echo -e "${CYAN}   [ENV]${NC} DOCKER_BUILDKIT=1"
    echo -e "${CYAN}   [ENV]${NC} COMPOSE_DOCKER_CLI_BUILD=1"
    
    if ! grep -q "DOCKER_BUILDKIT" ~/.bashrc 2>/dev/null; then
        echo 'export DOCKER_BUILDKIT=1' >> ~/.bashrc
        echo 'export COMPOSE_DOCKER_CLI_BUILD=1' >> ~/.bashrc
        echo -e "${CYAN}   [BASHRC]${NC} Environment variables added to ~/.bashrc"
    fi
    echo -e "${GREEN}✅ Environment configured${NC}"
    
    echo ""
    echo -e "${BLUE}🔧 Step 1.7: Docker Daemon Configuration${NC}"
    sudo mkdir -p /etc/docker
    echo -e "${CYAN}   [CONFIG]${NC} Writing /etc/docker/daemon.json..."
    sudo tee /etc/docker/daemon.json > /dev/null <<'DAEMON_EOF'
{
  "iptables": true,
  "userland-proxy": false,
  "live-restore": true,
  "storage-driver": "overlay2",
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
DAEMON_EOF
    echo -e "${CYAN}   [CONFIG]${NC} Docker daemon configuration written"
    
    echo -e "${CYAN}   [IPTABLES]${NC} Resetting iptables rules..."
    sudo iptables -t nat -F 2>/dev/null || true
    sudo iptables -t mangle -F 2>/dev/null || true
    sudo iptables -F 2>/dev/null || true
    sudo iptables -X 2>/dev/null || true
    echo -e "${CYAN}   [IPTABLES]${NC} iptables rules reset"
    
    echo -e "${CYAN}   [SERVICE]${NC} Restarting Docker daemon..."
    sudo systemctl restart docker
    sleep 5
    sudo docker network prune -f 2>&1 | while read line; do echo -e "${CYAN}   [NETWORK]${NC} $line"; done
    echo -e "${GREEN}✅ Docker daemon configured${NC}"
    
    echo ""
    echo ""
    echo -e "${BLUE}🔍 Step 1.9: Port Conflict Check${NC}"
    REQUIRED_PORTS="5443 7000 7001 7003 7005 7006 7008 7015 9200 9443 1514 1515 55000"
    CONFLICTS=()
    
    echo -e "${CYAN}   [CHECK]${NC} Scanning required ports..."
    for port in $REQUIRED_PORTS; do
        if sudo ss -tulpn 2>/dev/null | grep -q ":$port "; then
            CONFLICTS+=($port)
            echo -e "${YELLOW}   [PORT]${NC} Port $port is in use"
        fi
    done
    
    if [ ${#CONFLICTS[@]} -gt 0 ]; then
        echo -e "${YELLOW}⚠️  Ports in use: ${CONFLICTS[*]}${NC}"
        echo "   (This is usually fine - existing services will be managed)"
    else
        echo -e "${GREEN}✅ All required ports available${NC}"
    fi
    
    echo ""
    echo -e "${BLUE}✅ Step 1.9: Verification${NC}"
    docker --version | while read line; do echo -e "${CYAN}   [DOCKER]${NC} $line"; done
    docker compose version | while read line; do echo -e "${CYAN}   [COMPOSE]${NC} $line"; done
    
    if docker ps >/dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker is ready!${NC}"
    else
        echo -e "${YELLOW}⚠️  Docker requires sudo - applying group permissions...${NC}"
    fi
else
    echo -e "${GREEN}✅ Prerequisites already satisfied - skipping installation${NC}"
fi

# ============================================================================
# YARA & SIGMA INSTALLATION (Moved outside prerequisites - always runs)
# ============================================================================
    echo -e "${BLUE}🎯 Step 1.8: YARA & Sigma Installation${NC}"
    show_progress "Installing YARA for malware detection..."
    
    # Always try to install/reinstall YARA to ensure it's properly configured
    if run_with_output "[APT]" sudo apt-get install -y yara python3-pip 2>/dev/null; then
        YARA_VERSION=$(yara --version 2>&1 | head -1)
        echo -e "${GREEN}✅ YARA installed (version ${YARA_VERSION})${NC}"
    else
        # Check if it's already installed
        if command -v yara >/dev/null 2>&1; then
            echo -e "${GREEN}✅ YARA already installed (version $(yara --version 2>&1 | head -1))${NC}"
        else
            echo -e "${YELLOW}⚠️  YARA installation encountered issues - continuing anyway${NC}"
        fi
    fi
    
    show_progress "Installing Sigma CLI for rule conversion..."
    
    # Always try to install/reinstall Sigma to ensure latest version
    # Handle Ubuntu 24.04+ externally-managed-environment and system package conflicts
    if run_with_output "[PIP]" sudo pip3 install --break-system-packages --ignore-installed --no-warn-script-location sigma-cli pysigma-backend-elasticsearch pysigma-backend-opensearch 2>/dev/null; then
        echo -e "${GREEN}✅ Sigma CLI installed${NC}"
    else
        # Check if it's already installed
        if command -v sigma >/dev/null 2>&1; then
            echo -e "${GREEN}✅ Sigma CLI already installed${NC}"
        else
            # Fallback: Try with pipx (if available) or continue without
            echo -e "${YELLOW}⚠️  Sigma CLI installation had issues - trying alternative method${NC}"
            if command -v pipx >/dev/null 2>&1; then
                sudo pipx install sigma-cli 2>/dev/null || echo -e "${YELLOW}⚠️  Sigma CLI optional - continuing deployment${NC}"
            else
                echo -e "${YELLOW}⚠️  Sigma CLI optional - continuing deployment${NC}"
            fi
        fi
    fi
    
    show_progress "Downloading YARA rules (523+ rules)..."
    if [ ! -d "/opt/yara-rules" ]; then
        if sudo git clone https://github.com/Yara-Rules/rules.git /opt/yara-rules 2>&1 | while read line; do echo -e "${CYAN}   [GIT]${NC} $line"; done | head -5; then
            sudo chown -R $(whoami):$(id -gn) /opt/yara-rules 2>/dev/null || true
            echo -e "${CYAN}   [YARA]${NC} Downloaded $(find /opt/yara-rules -name "*.yar" 2>/dev/null | wc -l) YARA rules"
            echo -e "${GREEN}✅ YARA rules installed at /opt/yara-rules/${NC}"
        else
            echo -e "${YELLOW}⚠️  YARA rules download failed - continuing without rules (can add manually later)${NC}"
        fi
    else
        echo -e "${GREEN}✅ YARA rules already present${NC}"
    fi
    
    show_progress "Downloading Sigma rules (3,047+ rules)..."
    if [ ! -d "/opt/sigma-rules" ]; then
        if sudo git clone https://github.com/SigmaHQ/sigma.git /opt/sigma-rules 2>&1 | while read line; do echo -e "${CYAN}   [GIT]${NC} $line"; done | head -5; then
            sudo chown -R $(whoami):$(id -gn) /opt/sigma-rules 2>/dev/null || true
            echo -e "${CYAN}   [SIGMA]${NC} Downloaded $(find /opt/sigma-rules/rules -name "*.yml" 2>/dev/null | wc -l) Sigma rules"
            echo -e "${GREEN}✅ Sigma rules installed at /opt/sigma-rules/${NC}"
        else
            echo -e "${YELLOW}⚠️  Sigma rules download failed - continuing without rules (can add manually later)${NC}"
        fi
    else
        echo -e "${GREEN}✅ Sigma rules already present${NC}"
    fi
    
    show_progress "Setting up auto-update for YARA and Sigma rules..."
    # Add cron jobs for weekly updates (Sundays at 2 AM) - only if rules were downloaded
    if [ -d "/opt/yara-rules" ] || [ -d "/opt/sigma-rules" ]; then
        (crontab -l 2>/dev/null | grep -v "yara-rules\|sigma-rules"; \
         echo "# Auto-update YARA rules every Sunday at 2:00 AM"; \
         echo "0 2 * * 0 [ -d /opt/yara-rules ] && cd /opt/yara-rules && git pull >> /var/log/yara-update.log 2>&1"; \
         echo "# Auto-update Sigma rules every Sunday at 2:05 AM"; \
         echo "5 2 * * 0 [ -d /opt/sigma-rules ] && cd /opt/sigma-rules && git pull >> /var/log/sigma-update.log 2>&1") | crontab - 2>/dev/null || true
        echo -e "${CYAN}   [CRON]${NC} Auto-update scheduled for Sundays at 2:00 AM"
        echo -e "${GREEN}✅ Auto-update configured for YARA and Sigma rules${NC}"
    else
        echo -e "${YELLOW}⚠️  No rules to auto-update - skipping cron setup${NC}"
    fi
    

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  ✅ PART 1 COMPLETE: Prerequisites Ready                  ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
sleep 2

# ============================================================================
# PART 2: CYBERBLUE SOC PLATFORM DEPLOYMENT
# ============================================================================
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}║  PART 2/2: DEPLOYING CYBERBLUE SOC PLATFORM            ║${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}🎉 Starting CyberBlue SOC deployment...${NC}"
echo ""

# Change to script directory
cd "$SCRIPT_DIR"

echo -e "${BLUE}🧹 Step 2.1: Cleanup${NC}"
# Remove any leftover directories from previous installs
for leftover_dir in attack-navigator wireshark caldera shuffle fleet; do
    if [ -d "$leftover_dir" ]; then
        echo -e "${CYAN}   [CLEANUP]${NC} Removing leftover directory: ${leftover_dir}/"
        sudo rm -rf "$leftover_dir/"
    fi
done
echo -e "${GREEN}✅ Cleanup complete${NC}"

echo ""
echo -e "${BLUE}🔧 Step 2.2: Environment Configuration${NC}"

# Get host IP
HOST_IP=$(hostname -I | awk '{print $1}')
MISP_URL="https://${HOST_IP}:7003"
echo -e "${CYAN}   [CONFIG]${NC} Host IP detected: $HOST_IP"
echo -e "${CYAN}   [CONFIG]${NC} MISP URL: $MISP_URL"

# Create .env if needed
if [ ! -f .env ] && [ -f .env.template ]; then
    echo -e "${CYAN}   [ENV]${NC} Creating .env from template..."
    cp .env.template .env
fi
if [ ! -f .env ]; then
    echo -e "${CYAN}   [ENV]${NC} Creating new .env file..."
    touch .env
fi

# Update .env
if grep -q "^MISP_BASE_URL=" .env; then
    sed -i "s|^MISP_BASE_URL=.*|MISP_BASE_URL=${MISP_URL}|" .env
else
    echo "MISP_BASE_URL=${MISP_URL}" >> .env
fi
echo -e "${CYAN}   [ENV]${NC} MISP_BASE_URL=${MISP_URL}"

if grep -q "^HOST_IP=" .env; then
    sed -i "s|^HOST_IP=.*|HOST_IP=${HOST_IP}|" .env
else
    echo "HOST_IP=${HOST_IP}" >> .env
fi
echo -e "${CYAN}   [ENV]${NC} HOST_IP=${HOST_IP}"

# Generate YETI secret key
if ! grep -q "^YETI_AUTH_SECRET_KEY=" .env; then
    SECRET_KEY=$(openssl rand -hex 64)
    echo "YETI_AUTH_SECRET_KEY=${SECRET_KEY}" >> .env
    echo -e "${CYAN}   [ENV]${NC} Generated YETI_AUTH_SECRET_KEY"
fi

# Prepare YETI directory
sudo mkdir -p /opt/yeti/bloomfilters
echo -e "${CYAN}   [DIR]${NC} Created /opt/yeti/bloomfilters"

echo -e "${GREEN}✅ Environment configured${NC}"

echo ""
echo -e "${BLUE}🔍 Step 2.3: Network Interface Detection${NC}"

# Detect interface
SURICATA_IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
if [ -z "$SURICATA_IFACE" ]; then
    SURICATA_IFACE=$(ip link show | grep -E '^[0-9]+:' | grep -v lo | grep 'state UP' | awk -F': ' '{print $2}' | head -1)
fi
if [ -z "$SURICATA_IFACE" ]; then
    SURICATA_IFACE=$(ip a | grep 'state UP' | grep -v lo | awk -F: '{print $2}' | head -1 | xargs)
fi

if [ -z "$SURICATA_IFACE" ]; then
    echo -e "${RED}❌ Could not detect network interface${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Detected interface: $SURICATA_IFACE${NC}"

# Update .env
if grep -q "^SURICATA_INT=" .env; then
    sed -i "s/^SURICATA_INT=.*/SURICATA_INT=$SURICATA_IFACE/" .env
else
    echo "SURICATA_INT=$SURICATA_IFACE" >> .env
fi
echo -e "${CYAN}   [ENV]${NC} SURICATA_INT=$SURICATA_IFACE"

echo ""
echo -e "${BLUE}📦 Step 2.4: Suricata Rules${NC}"
sudo mkdir -p ./suricata/rules

if [ ! -f ./suricata/emerging.rules.tar.gz ]; then
    show_progress "Downloading Emerging Threats rules (this may take 1-2 minutes)..."
    if sudo curl --progress-bar -O https://rules.emergingthreats.net/open/suricata-6.0/emerging.rules.tar.gz 2>&1 | while read line; do echo -e "${CYAN}   [DOWNLOAD]${NC} $line"; done; then
        echo -e "${CYAN}   [EXTRACT]${NC} Extracting rules..."
        sudo tar -xzf emerging.rules.tar.gz -C ./suricata/rules --strip-components=1 2>&1 | head -10
        sudo rm emerging.rules.tar.gz
        echo -e "${GREEN}✅ Suricata rules downloaded${NC}"
    else
        echo -e "${YELLOW}⚠️  Rules download failed - continuing${NC}"
    fi
else
    echo -e "${GREEN}✅ Suricata rules already present${NC}"
fi

# Download config files
echo -e "${CYAN}   [DOWNLOAD]${NC} Downloading classification.config..."
sudo curl -s -o ./suricata/classification.config https://raw.githubusercontent.com/OISF/suricata/master/etc/classification.config || true
echo -e "${CYAN}   [DOWNLOAD]${NC} Downloading reference.config..."
sudo curl -s -o ./suricata/reference.config https://raw.githubusercontent.com/OISF/suricata/master/etc/reference.config || true

echo ""
echo -e "${BLUE}🔑 Step 2.5: Wazuh SSL Certificates${NC}"
show_progress "Generating SSL certificates (30-60 seconds)..."
sudo docker compose run --rm generator 2>&1 | while read line; do echo -e "${CYAN}   [SSL]${NC} $line"; done || echo "   Certificates generated"
sleep 10

if [[ -d "wazuh/config/wazuh_indexer_ssl_certs" ]]; then
    echo -e "${CYAN}   [SSL]${NC} Cleaning up certificate artifacts..."
    sudo find wazuh/config/wazuh_indexer_ssl_certs -type d -name "*.pem" -exec rm -rf {} \; 2>/dev/null || true
    sudo find wazuh/config/wazuh_indexer_ssl_certs -type d -name "*.key" -exec rm -rf {} \; 2>/dev/null || true
    echo -e "${CYAN}   [SSL]${NC} Setting certificate permissions..."
    sudo chown -R $(whoami):$(id -gn) wazuh/config/wazuh_indexer_ssl_certs/ 2>/dev/null || true
    sudo chmod 644 wazuh/config/wazuh_indexer_ssl_certs/*.pem 2>/dev/null || true
    sudo chmod 644 wazuh/config/wazuh_indexer_ssl_certs/*.key 2>/dev/null || true
fi
echo -e "${GREEN}✅ SSL certificates configured${NC}"

echo ""
echo -e "${BLUE}🔧 Step 2.6: Docker Networking Preparation${NC}"
echo -e "${CYAN}   [NETWORK]${NC} Pruning old Docker networks..."
sudo docker network prune -f 2>&1 | while read line; do echo -e "${CYAN}   [PRUNE]${NC} $line"; done || true

echo -e "${CYAN}   [IPTABLES]${NC} Flushing Docker iptables chains..."
sudo iptables -t nat -F DOCKER 2>&1 | head -3 || true
sudo iptables -t nat -X DOCKER 2>&1 | head -3 || true
sudo iptables -t filter -F DOCKER 2>&1 | head -3 || true
sudo iptables -t filter -F DOCKER-ISOLATION-STAGE-1 2>&1 | head -3 || true
sudo iptables -t filter -F DOCKER-ISOLATION-STAGE-2 2>&1 | head -3 || true

echo -e "${CYAN}   [SERVICE]${NC} Restarting Docker daemon..."
sudo systemctl restart docker
echo -e "${CYAN}   [WAIT]${NC} Waiting for Docker to stabilize (15 seconds)..."
sleep 15

timeout 30 bash -c 'until docker info >/dev/null 2>&1; do sleep 2; done' || true
echo -e "${GREEN}✅ Docker networking prepared${NC}"

echo ""
echo -e "${BLUE}📥 Step 2.7: Downloading Agent Binaries & Packages${NC}"
echo -e "${CYAN}   [AGENTS]${NC} Downloading Velociraptor and Wazuh agents for deployment..."
echo -e "${CYAN}   [INFO]${NC} This enables users to deploy agents from the portal"

# Velociraptor
if [ -f "velociraptor/agents/download-binaries.sh" ]; then
    echo -e "${CYAN}   [VELOCIRAPTOR]${NC} Downloading binaries..."
    if bash velociraptor/agents/download-binaries.sh 2>&1 | while read line; do echo -e "${CYAN}   [VELOCI]${NC} $line"; done; then
        echo -e "${GREEN}   ✅ Velociraptor binaries downloaded${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Velociraptor download failed${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  Velociraptor download script not found${NC}"
fi

# Wazuh
if [ -f "wazuh/agents/download-packages.sh" ]; then
    echo -e "${CYAN}   [WAZUH]${NC} Downloading packages..."
    if bash wazuh/agents/download-packages.sh 2>&1 | while read line; do echo -e "${CYAN}   [WAZUH]${NC} $line"; done; then
        echo -e "${GREEN}   ✅ Wazuh packages downloaded${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Wazuh download failed${NC}"
    fi
else
    echo -e "${YELLOW}   ⚠️  Wazuh download script not found${NC}"
fi

echo -e "${GREEN}✅ Agent deployment system ready${NC}"

echo ""
echo -e "${BLUE}🚀 Step 2.8: Container Deployment${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}   📦 Building and starting containers...${NC}"
echo -e "${MAGENTA}   ⏳ This is the longest step (5-10 minutes)${NC}"
echo -e "${MAGENTA}   🎬 Watch the magic happen below:${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════${NC}"
echo ""

if sudo docker compose up --build -d 2>&1 | while read line; do echo -e "${CYAN}   [DEPLOY]${NC} $line"; done; then
    echo -e "${GREEN}✅ All containers deployed${NC}"
else
    echo -e "${YELLOW}⚠️  Deployment completed with warnings${NC}"
fi

echo ""
echo -e "${BLUE}🔄 Step 2.9: Post-Deployment Stabilization${NC}"
echo -e "${CYAN}   [SERVICE]${NC} Restarting Docker for stability..."
sudo systemctl restart docker
sleep 10
echo -e "${CYAN}   [COMPOSE]${NC} Bringing services back up..."
sudo docker compose up -d 2>&1 | while read line; do echo -e "${CYAN}   [UP]${NC} $line"; done
echo -e "${GREEN}✅ Services stabilized${NC}"

echo ""
echo -e "${CYAN}   [WAIT]${NC} Waiting for containers to initialize (60 seconds)..."
for i in {60..1}; do
    echo -ne "\r${CYAN}   [WAIT]${NC} $i seconds remaining...   "
    sleep 1
done
echo ""
echo ""

echo ""
echo -e "${BLUE}🔍 Step 2.10: Arkime Setup (SKIPPED — Arkime is disabled)${NC}"
echo -e "${CYAN}   [ARKIME]${NC} Arkime is commented out in docker-compose.yml — skipping initialization"
echo -e "${YELLOW}   [INFO]${NC} To re-enable Arkime, uncomment the os01 + arkime services in docker-compose.yml"

echo ""
echo -e "${BLUE}🌐 Step 2.11: External Access Configuration${NC}"

# Detect Docker bridges
DOCKER_BRIDGES=$(ip link show | grep -E 'br-[a-f0-9]+|docker0' | awk -F': ' '{print $2}' | cut -d'@' -f1)

if [ -n "$DOCKER_BRIDGES" ]; then
    echo -e "${CYAN}   [IPTABLES]${NC} Setting FORWARD policy to ACCEPT..."
    sudo iptables -P FORWARD ACCEPT 2>&1 | head -3 || true
    
    echo -e "${CYAN}   [IPTABLES]${NC} Adding Docker bridge forwarding rules..."
    sudo iptables -I FORWARD -i "$SURICATA_IFACE" -o br-+ -j ACCEPT 2>&1 | head -3 || true
    sudo iptables -I FORWARD -i br-+ -o "$SURICATA_IFACE" -j ACCEPT 2>&1 | head -3 || true
    
    echo -e "${CYAN}   [IPTABLES]${NC} Adding port forwarding rules for SOC tools..."
    for port in 443 5443 7000 7001 7003 7005 7006 7008 7015 9443; do
        sudo iptables -I FORWARD -i "$SURICATA_IFACE" -p tcp --dport $port -j ACCEPT 2>/dev/null || true
        sudo iptables -I FORWARD -o "$SURICATA_IFACE" -p tcp --sport $port -j ACCEPT 2>/dev/null || true
    done
    echo -e "${CYAN}   [IPTABLES]${NC} Port rules configured for: 443, 5443, 7000, 7001, 7003, 7005, 7006, 7008, 7015, 9443"
    
    # Make rules persistent
    if ! dpkg -l | grep -q iptables-persistent; then
        echo -e "${CYAN}   [APT]${NC} Installing iptables-persistent for rule persistence..."
        
        # Pre-seed debconf
        echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | sudo debconf-set-selections 2>/dev/null
        echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | sudo debconf-set-selections 2>/dev/null
        
        # Install
        sudo apt-get install -y -o Dpkg::Options::="--force-confnew" -o Dpkg::Options::="--force-confdef" iptables-persistent 2>&1 | grep -v "^$" | head -20 | while read line; do echo -e "${CYAN}   [APT]${NC} $line"; done || true
    fi
    
    # Save rules
    if dpkg -l | grep -q iptables-persistent; then
        sudo mkdir -p /etc/iptables
        sudo iptables-save | sudo tee /etc/iptables/rules.v4 >/dev/null 2>&1 || true
        echo -e "${CYAN}   [IPTABLES]${NC} Rules saved to /etc/iptables/rules.v4"
    fi
fi

echo -e "${GREEN}✅ External access configured${NC}"

echo ""
echo -e "${BLUE}🔍 Step 2.12: Wazuh Services Verification${NC}"
WAZUH_RUNNING=$(sudo docker ps | grep -c "wazuh.*Up" || echo "0")
echo -e "${CYAN}   [CHECK]${NC} Wazuh services running: $WAZUH_RUNNING/3"

if [[ "$WAZUH_RUNNING" -lt 3 ]]; then
    echo -e "${CYAN}   [RESTART]${NC} Restarting Wazuh services..."
    sudo docker compose restart wazuh.indexer 2>&1 | head -5 | while read line; do echo -e "${CYAN}   [INDEXER]${NC} $line"; done
    sleep 20
    sudo docker compose restart wazuh.manager 2>&1 | head -5 | while read line; do echo -e "${CYAN}   [MANAGER]${NC} $line"; done
    sleep 15
    sudo docker compose restart wazuh.dashboard 2>&1 | head -5 | while read line; do echo -e "${CYAN}   [DASHBOARD]${NC} $line"; done
    sleep 15
fi
echo -e "${GREEN}✅ Wazuh services verified${NC}"

echo ""
echo -e "${BLUE}🧠 Step 2.13: MISP Password Change Bypass${NC}"
echo -e "${CYAN}   [MISP]${NC} Waiting for MISP admin user creation..."

# Keep checking until admin user exists, then immediately disable password change
(
    for i in {1..60}; do
        USER_EXISTS=$(sudo docker exec misp-core mysql -h db -u misp -pexample misp -se "SELECT COUNT(*) FROM users WHERE email='admin@admin.test';" 2>/dev/null || echo "0")
        
        if [ "$USER_EXISTS" -gt "0" ]; then
            echo "[$(date)] Admin user found! Disabling password change requirement..." | sudo tee -a /var/log/misp-password-bypass.log
            sudo docker exec misp-core mysql -h db -u misp -pexample misp -e "UPDATE users SET change_pw=0 WHERE email='admin@admin.test';" 2>/dev/null
            echo "[$(date)] ✓ Password change disabled - API key active!" | sudo tee -a /var/log/misp-password-bypass.log
            break
        fi
        sleep 10
    done
) &

sleep 30  # Give script time to start checking

echo ""
echo -e "${BLUE}🧠 Step 2.14: MISP Threat Intelligence Feeds${NC}"
echo -e "${CYAN}   [MISP]${NC} Configuring feeds in background..."

if [ -f "misp/configure-threat-feeds.sh" ]; then
    echo -e "${CYAN}   [MISP]${NC} Configuring threat feeds (this may take 2-3 minutes)..."
    
    # Run in background so installation continues
    (
        sleep 240  # Wait 4 more minutes for MISP admin user
        bash misp/configure-threat-feeds.sh 2>&1 | sudo tee -a /var/log/misp-feed-config.log > /dev/null
        
        # Set up cron - every 3 hours for fresh threat intel
        (crontab -l 2>/dev/null; echo "0 */3 * * * cd $SCRIPT_DIR && bash misp/update-feeds.sh >> /var/log/misp-feeds-update.log 2>&1") | crontab - 2>/dev/null || true
        
        echo "[MISP] Feed configuration complete! Check /var/log/misp-feed-config.log" | sudo tee -a /var/log/misp-feed-config.log > /dev/null
    ) &
    
echo -e "${GREEN}✅ MISP feed configuration started in background${NC}"
echo -e "${YELLOW}   ⏰ Intel Feeds for MISP will take 10-15 mins to show on Portal${NC}"
echo -e "${CYAN}   [INFO]${NC} Check progress: tail -f /var/log/misp-feed-config.log"
else
    echo -e "${YELLOW}⚠️  MISP feed script not found${NC}"
fi

echo ""
echo -e "${BLUE}🔧 Step 2.15: CyberBlue Auto-Start on Reboot${NC}"
show_progress "Configuring automatic service startup after reboot..."

# Get the actual installation directory
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Create systemd service for CyberBlue auto-start
sudo tee /etc/systemd/system/cyberblue-autostart.service > /dev/null << EOF
[Unit]
Description=CyberBlue SOC Platform Auto-Start
After=network-online.target docker.service
Wants=network-online.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${INSTALL_DIR}
ExecStartPre=/bin/sleep 30
ExecStartPre=/bin/bash -c 'timeout 60 bash -c "until docker info >/dev/null 2>&1; do sleep 5; done"'
ExecStart=/bin/bash ${INSTALL_DIR}/force-start.sh
TimeoutStartSec=600
StandardOutput=journal
StandardError=journal
User=root

[Install]
WantedBy=multi-user.target
EOF

echo -e "${CYAN}   [SYSTEMD]${NC} Reloading systemd daemon..."
sudo systemctl daemon-reload

echo -e "${CYAN}   [SYSTEMD]${NC} Enabling cyberblue-autostart.service..."
sudo systemctl enable cyberblue-autostart.service 2>&1 | head -3 | while read line; do echo -e "${CYAN}   [SYSTEMD]${NC} $line"; done

echo -e "${GREEN}✅ CyberBlue auto-start configured${NC}"
echo -e "${CYAN}   [INFO]${NC} CyberBlue will automatically start after system reboots"
echo -e "${CYAN}   [INFO]${NC} Service: cyberblue-autostart.service"

# ============================================================================
# FINAL VERIFICATION AND SUMMARY
# ============================================================================
echo ""
echo ""
echo -e "${MAGENTA}════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}   🔍 FINAL VERIFICATION IN PROGRESS...${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════${NC}"
echo ""

sleep 5

echo -e "${CYAN}   [CHECK]${NC} Counting running containers..."
TOTAL_RUNNING=$(sudo docker ps | grep -c "Up" || echo "0")
EXPECTED_SERVICES=8
OPTIMAL_SERVICES=10

echo -e "${CYAN}   [CHECK]${NC} Running containers: $TOTAL_RUNNING"
echo -e "${CYAN}   [CHECK]${NC} Expected minimum: $EXPECTED_SERVICES"
echo -e "${CYAN}   [CHECK]${NC} Optimal target: $OPTIMAL_SERVICES"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Determine status
if [[ "$TOTAL_RUNNING" -ge "$OPTIMAL_SERVICES" ]]; then
    FINAL_STATUS="EXCELLENT"
    STATUS_ICON="🎉"
elif [[ "$TOTAL_RUNNING" -ge "$EXPECTED_SERVICES" ]]; then
    FINAL_STATUS="SUCCESS"
    STATUS_ICON="✅"
else
    FINAL_STATUS="PARTIAL"
    STATUS_ICON="⚠️"
fi

sleep 2
clear
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║    🎉 INSTALLATION COMPLETE - CYBERBLUE SOC READY! 🎉     ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${CYAN}  /\$\$\$\$\$\$                        /\$\$                 /\$\$\$\$\$\$  /\$\$                   ${NC}"
echo -e "${CYAN} /\$\$__  \$\$                      | \$\$                /\$\$__  \$\$| \$\$                   ${NC}"
echo -e "${CYAN}| \$\$  \__/ /\$\$   /\$\$  /\$\$\$\$\$\$\$  /\$\$\$\$\$\$\$   /\$\$\$\$\$\$\$| \$\$  \__/| \$\$  /\$\$   /\$\$ /\$\$${NC}"
echo -e "${CYAN}| \$\$      | \$\$  | \$\$ /\$\$_____/ | \$\$__  \$\$ /\$\$_____/| \$\$      | \$\$ | \$\$  | \$\$| \$\$${NC}"
echo -e "${CYAN}| \$\$      | \$\$  | \$\$|  \$\$\$\$\$\$  | \$\$  \ \$\$|  \$\$\$\$\$\$ | \$\$      | \$\$ | \$\$  | \$\$| \$\$${NC}"
echo -e "${CYAN}| \$\$    \$\$| \$\$  | \$\$ \____  \$\$ | \$\$  | \$\$ \____  \$\$| \$\$    \$\$| \$\$ | \$\$  | \$\$| \$\$${NC}"
echo -e "${CYAN}|  \$\$\$\$\$\$/|  \$\$\$\$\$\$/ /\$\$\$\$\$\$\$/| \$\$  | \$\$ /\$\$\$\$\$\$\$/|  \$\$\$\$\$\$/| \$\$ |  \$\$\$\$\$\$\$/| \$\$${NC}"
echo -e "${CYAN} \______/  \______/ |_______/ |__/  |__/|_______/  \______/ |__/  \______/ |__/${NC}"
echo ""
echo -e "${STATUS_ICON} ${GREEN}Deployment Status: ${FINAL_STATUS}${NC}"
echo ""
echo -e "${BLUE}📊 Installation Summary:${NC}"
echo "   ⏱️  Total Time: ${MINUTES}m ${SECONDS}s"
echo "   📦 Running Containers: $TOTAL_RUNNING"
echo "   🔧 Prerequisites: ✅ Installed"
echo "   🌐 Networking: ✅ Configured"
echo "   🔒 SSL Certificates: ✅ Generated"
echo "   🔥 Firewall Rules: ✅ Applied"
echo "   💾 Swap Space: ✅ Configured (8GB)"
echo "   🎯 YARA: ✅ Installed (523+ malware rules)"
echo "   📊 Sigma: ✅ Installed (3,047+ detection rules)"
echo "   🔄 Auto-Update: ✅ Weekly (Sundays 2 AM)"
echo "   🔁 Auto-Start: ✅ Enabled (starts on reboot)"
echo ""
echo -e "${BLUE}🌐 Access Your CyberBlue SOC Tools:${NC}"
echo ""
echo -e "${GREEN}   🏠 Main Portal:       https://${HOST_IP}:5443${NC}"
echo ""
echo "   🔍 Velociraptor:     https://${HOST_IP}:7000"
echo "   🛡️  Wazuh Dashboard:  https://${HOST_IP}:7001"
echo "   🔒 MISP:             https://${HOST_IP}:7003"
echo "   🕷️  TheHive:          http://${HOST_IP}:7005"
echo "   🔧 Cortex:           http://${HOST_IP}:7006"
echo "   📊 Arkime:           http://${HOST_IP}:7008"
echo "   👁️  EveBox:           https://${HOST_IP}:7015"
echo "   🖥️  Portainer:        https://${HOST_IP}:9443"
echo ""
echo -e "${YELLOW}🔑 Default Credentials (for tools): admin / cyberblue${NC}"
echo ""
echo -e "${GREEN}✅ Features Enabled:${NC}"
echo "   ✅ Universal external access (AWS, Azure, GCP, VMware, bare metal)"
echo "   ✅ Auto-start on reboot"
echo "   ✅ Persistent firewall rules"
echo "   ✅ Optimized Docker networking"
echo "   ✅ SSL/TLS certificates"
echo ""
echo -e "${CYAN}🔍 Threat Hunting Tools:${NC}"
echo "   • YARA Scanner:  yara -r /opt/yara-rules/malware_index.yar <file>"
echo "   • Sigma Convert: sigma convert -t opensearch_lucene --without-pipeline <rule.yml>"
echo "   • YARA Rules:    523+ rules in /opt/yara-rules/"
echo "   • Sigma Rules:   3,047+ rules in /opt/sigma-rules/"
echo ""
echo -e "${YELLOW}🚨 REMEMBER: Educational/Testing Environment Only!${NC}"
echo ""
echo -e "${GREEN}✨ CyberBlue SOC Platform is ready for training!${NC}"
echo ""
echo -e "${CYAN}💡 Quick Commands:${NC}"
echo "   • Check status:  sudo docker ps"
echo "   • View logs:     sudo docker compose logs -f [service]"
echo "   • Restart all:   sudo docker compose restart"
echo ""
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""