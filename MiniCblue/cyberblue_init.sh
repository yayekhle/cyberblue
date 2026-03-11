#!/usr/bin/env bash
# =============================================================================
# cyberblue_init.sh — One-shot initialization for CyberBlue SOC (MiniCblue)
# Run this once before `docker compose up -d` on a fresh clone or new host.
#
# What it does:
#   1. Auto-detects the host's primary IP address and writes it to .env
#   2. Updates MISP_BASE_URL in .env to match the detected HOST_IP
#   3. Sets vm.max_map_count=262144 (required by OpenSearch / Wazuh indexer)
#   4. Creates all directories that Docker bind-mounts need on first boot
#   5. Makes all helper scripts executable
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

# ─── Colours ─────────────────────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
info()    { echo -e "${GREEN}[+]${NC} $*"; }
warn()    { echo -e "${YELLOW}[!]${NC} $*"; }
error()   { echo -e "${RED}[✗]${NC} $*" >&2; }

# ─── 1. Detect HOST_IP ───────────────────────────────────────────────────────
detect_host_ip() {
    local ip=""

    # Method 1: primary default-route interface
    ip=$(ip route get 1.1.1.1 2>/dev/null | awk '/src/{for(i=1;i<=NF;i++) if($i=="src") {print $(i+1); exit}}')

    # Method 2: first non-loopback inet address
    if [[ -z "$ip" ]]; then
        ip=$(ip -4 addr show scope global | awk '/inet /{print $2}' | cut -d/ -f1 | head -1)
    fi

    # Method 3: hostname -I
    if [[ -z "$ip" ]]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi

    # Fallback
    if [[ -z "$ip" ]]; then
        ip="127.0.0.1"
        warn "Could not detect host IP automatically — defaulting to 127.0.0.1"
        warn "Set HOST_IP manually in .env if needed."
    fi

    echo "$ip"
}

# ─── 2. Update .env variable (creates or replaces a KEY=VALUE line) ──────────
set_env() {
    local key="$1" value="$2"
    if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
        sed -i "s|^${key}=.*|${key}=${value}|" "$ENV_FILE"
    else
        echo "${key}=${value}" >> "$ENV_FILE"
    fi
}

# ─── 3. Require root for sysctl ──────────────────────────────────────────────
if [[ "$EUID" -ne 0 ]]; then
    warn "Not running as root — skipping sysctl vm.max_map_count update."
    warn "Run 'sudo sysctl -w vm.max_map_count=262144' manually before starting"
    warn "OpenSearch / Wazuh Indexer, or they may fail to start."
    SKIP_SYSCTL=1
else
    SKIP_SYSCTL=0
fi

# ─── Main ─────────────────────────────────────────────────────────────────────

echo ""
echo "======================================================"
echo "  CyberBlue SOC — Initialization"
echo "======================================================"
echo ""

# 1. Detect and write HOST_IP
HOST_IP=$(detect_host_ip)
info "Detected HOST_IP: $HOST_IP"
set_env "HOST_IP" "$HOST_IP"

# 2. Update MISP_BASE_URL to use the real HOST_IP
# The .env file may have a stale hardcoded IP — replace the whole value.
MISP_PORT="7003"
MISP_BASE_URL="https://${HOST_IP}:${MISP_PORT}"
set_env "MISP_BASE_URL" "$MISP_BASE_URL"
info "MISP_BASE_URL set to: $MISP_BASE_URL"

# 3. Set default install dir / user if still empty
CURRENT_DIR=$(sed -n 's/^CYBERBLUE_INSTALL_DIR=//p' "$ENV_FILE" | head -1)
if [[ -z "$CURRENT_DIR" ]] || [[ "$CURRENT_DIR" == "/opt/cyberblue" ]]; then
    set_env "CYBERBLUE_INSTALL_DIR" "$SCRIPT_DIR"
    info "CYBERBLUE_INSTALL_DIR set to: $SCRIPT_DIR"
fi

CURRENT_USER=$(sed -n 's/^CYBERBLUE_INSTALL_USER=//p' "$ENV_FILE" | head -1)
if [[ -z "$CURRENT_USER" ]] || [[ "$CURRENT_USER" == "ubuntu" ]]; then
    set_env "CYBERBLUE_INSTALL_USER" "${SUDO_USER:-${USER:-ubuntu}}"
    info "CYBERBLUE_INSTALL_USER set to: ${SUDO_USER:-${USER:-ubuntu}}"
fi

# 4. vm.max_map_count — required by OpenSearch (Wazuh indexer + Arkime os01)
if [[ "$SKIP_SYSCTL" -eq 0 ]]; then
    CURRENT_MAP=$(sysctl -n vm.max_map_count 2>/dev/null || echo 0)
    if [[ "$CURRENT_MAP" -lt 262144 ]]; then
        sysctl -w vm.max_map_count=262144
        info "vm.max_map_count set to 262144"
        # Persist across reboots
        if ! grep -q "vm.max_map_count" /etc/sysctl.conf 2>/dev/null; then
            echo "vm.max_map_count=262144" >> /etc/sysctl.conf
            info "Persisted vm.max_map_count in /etc/sysctl.conf"
        fi
    else
        info "vm.max_map_count already $CURRENT_MAP — OK"
    fi
fi

# 5. Create directories required by bind mounts
info "Creating required directories..."

declare -a DIRS=(
    # Wazuh SSL certs (populated at runtime by the generator container)
    "wazuh/config/wazuh_indexer_ssl_certs"
    # Wazuh agent install packages
    "wazuh/agents"
    # Arkime packet capture storage
    "arkime/pcaps"
    # Suricata log output (read by EveBox)
    "suricata/logs"
    # MISP persistent data
    "misp/configs"
    "misp/logs"
    "misp/files"
    "misp/ssl"
    "misp/gnupg"
    # MISP custom modules
    "misp/custom/action_mod"
    "misp/custom/expansion"
    "misp/custom/export_mod"
    "misp/custom/import_mod"
    # Portal logs
    "portal/logs"
    # Portal SSL (self-signed certs placed here by cyberblue_install.sh)
    "portal/ssl"
    # Velociraptor agent packages
    "velociraptor/agents"
)

for dir in "${DIRS[@]}"; do
    full="$SCRIPT_DIR/$dir"
    if [[ ! -d "$full" ]]; then
        mkdir -p "$full"
        echo "  created: $dir"
    fi
done

# 6. Make all helper scripts executable
info "Making scripts executable..."
find "$SCRIPT_DIR" -maxdepth 1 -name "*.sh" -exec chmod +x {} \;

echo ""
info "Initialization complete."
echo ""
echo "  Next steps:"
echo "    1. Review $ENV_FILE — especially HOST_IP and passwords"
echo "    2. Run:  docker compose up -d"
echo "    3. Wait for the wazuh-cert-generator to finish before the"
echo "       Wazuh services fully start (~30-60 s on first boot)"
echo ""
echo "  Service URLs (once containers are up):"
printf "    Portal      : https://${HOST_IP}:5443\n"
printf "    Wazuh       : https://${HOST_IP}:7001  (admin / SecretPassword)\n"
printf "    Velociraptor: https://${HOST_IP}:7000  (admin / cyberblue)\n"
printf "    MISP        : %s  (admin@admin.test / admin)\n" "$MISP_BASE_URL"
printf "    TheHive     : http://${HOST_IP}:7005   (admin@thehive.local / secret)\n"
printf "    Cortex      : http://${HOST_IP}:7006\n"
printf "    Arkime      : http://${HOST_IP}:7008   (admin / admin)\n"
printf "    EveBox      : http://${HOST_IP}:7015\n"
printf "    Portainer   : https://${HOST_IP}:9443\n"
echo ""
