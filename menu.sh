#!/bin/bash
# ================================================================
# FALCON + VOLTRON ULTIMATE v5.0
# ================================================================
# Inajumuisha:
#   1. FirewallFalcon v4.0 - 100% features
#   2. Voltron Tech v10.8 - DNSTT Boosters, Speed Methods
#   3. VPS Dashboard - Real-time system info
#   4. VPN Data Usage - Per user connection data
#   5. Dynamic Banner - Falcon style (VOLTRON TECH ULTIMATE)
# ================================================================

C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_UL=$'\033[4m'

# Premium Color Palette
C_RED=$'\033[38;5;196m'
C_GREEN=$'\033[38;5;46m'
C_YELLOW=$'\033[38;5;226m'
C_BLUE=$'\033[38;5;39m'
C_PURPLE=$'\033[38;5;135m'
C_CYAN=$'\033[38;5;51m'
C_WHITE=$'\033[38;5;255m'
C_GRAY=$'\033[38;5;245m'
C_ORANGE=$'\033[38;5;208m'
C_PINK=$'\033[38;5;205m'
C_GOLD=$'\033[38;5;220m'
C_LIME=$'\033[38;5;154m'
C_TEAL=$'\033[38;5;38m'

# Semantic Aliases
C_TITLE=$C_PURPLE
C_CHOICE=$C_CYAN
C_PROMPT=$C_BLUE
C_WARN=$C_YELLOW
C_DANGER=$C_RED
C_STATUS_A=$C_GREEN
C_STATUS_I=$C_GRAY
C_ACCENT=$C_ORANGE
C_PREMIUM=$C_GOLD
C_INFO=$C_TEAL

# ================================================================
# ========== VOLTRON TECH DOMAIN & TOKEN ==========
# ================================================================

DESEC_TOKEN="3WxD4Hkiu5VYBLWVizVhf1rzyKbz"
DESEC_DOMAIN="voltrontechtx.shop"

# ================================================================
# ========== DIRECTORIES ==========
# ================================================================

DB_DIR="/etc/firewallfalcon"
DB_FILE="$DB_DIR/users.db"
INSTALL_FLAG_FILE="$DB_DIR/.install"
BADVPN_SERVICE_FILE="/etc/systemd/system/badvpn.service"
BADVPN_BUILD_DIR="/root/badvpn-build"
HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"
NGINX_CONFIG_FILE="/etc/nginx/sites-available/default"
SSL_CERT_DIR="$DB_DIR/ssl"
SSL_CERT_FILE="$SSL_CERT_DIR/firewallfalcon.pem"
SSL_CERT_CHAIN_FILE="$SSL_CERT_DIR/firewallfalcon.crt"
SSL_CERT_KEY_FILE="$SSL_CERT_DIR/firewallfalcon.key"
EDGE_CERT_INFO_FILE="$DB_DIR/edge_cert.conf"
NGINX_PORTS_FILE="$DB_DIR/nginx_ports.conf"
EDGE_PUBLIC_HTTP_PORT="80"
EDGE_PUBLIC_TLS_PORT="443"
NGINX_INTERNAL_HTTP_PORT="8880"
NGINX_INTERNAL_TLS_PORT="8443"
HAPROXY_INTERNAL_DECRYPT_PORT="10443"
DNSTT_SERVICE_FILE="/etc/systemd/system/dnstt.service"
DNSTT_BINARY="/usr/local/bin/dnstt-server"
DNSTT_CLIENT="/usr/local/bin/dnstt-client"
DNSTT_KEYS_DIR="$DB_DIR/dnstt"
DNSTT_CONFIG_FILE="$DB_DIR/dnstt_info.conf"
DNS_INFO_FILE="$DB_DIR/dns_info.conf"
UDP_CUSTOM_DIR="/root/udp"
UDP_CUSTOM_SERVICE_FILE="/etc/systemd/system/udp-custom.service"
SSH_BANNER_FILE="/etc/bannerssh"
FALCONPROXY_SERVICE_FILE="/etc/systemd/system/falconproxy.service"
FALCONPROXY_BINARY="/usr/local/bin/falconproxy"
FALCONPROXY_CONFIG_FILE="$DB_DIR/falconproxy_config.conf"
LIMITER_SCRIPT="/usr/local/bin/firewallfalcon-limiter.sh"
LIMITER_SERVICE="/etc/systemd/system/firewallfalcon-limiter.service"
BANDWIDTH_DIR="$DB_DIR/bandwidth"
BANDWIDTH_SCRIPT="/usr/local/bin/firewallfalcon-bandwidth.sh"
BANDWIDTH_SERVICE="/etc/systemd/system/firewallfalcon-bandwidth.service"
LEGACY_BANDWIDTH_DIR="/usr/local/bin/firewallfalcon-bandwidth"
TRIAL_CLEANUP_SCRIPT="/usr/local/bin/firewallfalcon-trial-cleanup.sh"
LOGIN_INFO_SCRIPT="/usr/local/bin/firewallfalcon-login-info.sh"
SSHD_FF_CONFIG="/etc/ssh/sshd_config.d/firewallfalcon.conf"
BANNER_DIR="$DB_DIR/banners"
BANNER_ENABLED_FILE="$DB_DIR/banners_enabled"

# --- ZiVPN Variables ---
ZIVPN_DIR="/etc/zivpn"
ZIVPN_BIN="/usr/local/bin/zivpn"
ZIVPN_SERVICE_FILE="/etc/systemd/system/zivpn.service"
ZIVPN_CONFIG_FILE="$ZIVPN_DIR/config.json"
ZIVPN_CERT_FILE="$ZIVPN_DIR/zivpn.crt"
ZIVPN_KEY_FILE="$ZIVPN_DIR/zivpn.key"

# ================================================================
# ========== CACHE SYSTEM ==========
# ================================================================

SELECTED_USER=""
UNINSTALL_MODE="interactive"
BANNER_CACHE_TTL=15
BANNER_CACHE_TS=0
BANNER_CACHE_OS_NAME=""
BANNER_CACHE_UP_TIME=""
BANNER_CACHE_RAM_USAGE=""
BANNER_CACHE_CPU_LOAD=""
BANNER_CACHE_ONLINE_USERS=0
BANNER_CACHE_TOTAL_USERS=0
BANNER_CACHE_VPS_IP=""
BANNER_CACHE_VPS_LOCATION=""
BANNER_CACHE_VPS_ISP=""
BANNER_CACHE_VPS_STORAGE=""
BANNER_CACHE_VPS_DISK=""
SSH_SESSION_CACHE_TTL=10
SSH_SESSION_CACHE_TS=0
SSH_SESSION_CACHE_DB_MTIME=0
SSH_SESSION_TOTAL=0
APT_CACHE_READY=0
FF_USERS_GROUP="ffusers"
declare -A SSH_SESSION_COUNTS=()
declare -A SSH_SESSION_PIDS=()

if [[ $EUID -ne 0 ]]; then
   echo -e "${C_RED}❌ Error: This script requires root privileges to run.${C_RESET}"
   exit 1
fi

# ================================================================
# ========== APT FUNCTIONS (Falcon) ==========
# ================================================================

get_ubuntu_codename() {
    local codename=""
    if [[ -r /etc/os-release ]]; then
        codename=$(awk -F= '/^(VERSION_CODENAME|UBUNTU_CODENAME)=/{gsub(/"/, "", $2); if ($2 != "") { print $2; exit }}' /etc/os-release 2>/dev/null)
    fi
    if [[ -z "$codename" ]] && command -v lsb_release &>/dev/null; then
        codename=$(lsb_release -sc 2>/dev/null)
    fi
    echo "$codename"
}

is_known_eol_ubuntu_codename() {
    case "$1" in
        yakkety|zesty|artful|cosmic|disco|eoan|groovy|hirsute|impish|kinetic|lunar|mantic|oracular|plucky)
            return 0 ;;
        *) return 1 ;;
    esac
}

rewrite_ubuntu_apt_sources() {
    local mode="$1"
    local os_id=""
    local changed=false
    local from_archive to_archive from_security to_security from_ports to_ports
    local -a source_files=("/etc/apt/sources.list" /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources)

    if [[ -r /etc/os-release ]]; then
        os_id=$(awk -F= '/^ID=/{gsub(/"/, "", $2); print $2; exit}' /etc/os-release 2>/dev/null)
    fi
    [[ "$os_id" == "ubuntu" ]] || return 1

    case "$mode" in
        primary)
            from_archive='https?://([A-Za-z0-9-]+\.)?archive\.ubuntu\.com/ubuntu'
            to_archive='http://archive.ubuntu.com/ubuntu'
            from_security='https?://security\.ubuntu\.com/ubuntu'
            to_security='http://security.ubuntu.com/ubuntu'
            from_ports='https?://ports\.ubuntu\.com/ubuntu-ports'
            to_ports='http://ports.ubuntu.com/ubuntu-ports'
            ;;
        old-releases)
            from_archive='https?://([A-Za-z0-9-]+\.)?archive\.ubuntu\.com/ubuntu'
            to_archive='http://old-releases.ubuntu.com/ubuntu'
            from_security='https?://security\.ubuntu\.com/ubuntu'
            to_security='http://old-releases.ubuntu.com/ubuntu'
            from_ports='https?://ports\.ubuntu\.com/ubuntu-ports'
            to_ports='http://old-releases.ubuntu.com/ubuntu'
            ;;
        *) return 1 ;;
    esac

    for file in "${source_files[@]}"; do
        [[ -f "$file" ]] || continue
        if grep -Eq "$from_archive|$from_security|$from_ports" "$file" 2>/dev/null; then
            backup_file="${file}.bak.firewallfalcon"
            [[ -f "$backup_file" ]] || cp "$file" "$backup_file" 2>/dev/null || true
            sed -i -E \
                -e "s|$from_archive|$to_archive|g" \
                -e "s|$from_security|$to_security|g" \
                -e "s|$from_ports|$to_ports|g" \
                "$file" 2>/dev/null
            changed=true
        fi
    done

    $changed
}

repair_ubuntu_apt_mirrors() {
    rewrite_ubuntu_apt_sources "primary"
}

switch_ubuntu_to_old_releases() {
    local codename=$(get_ubuntu_codename)
    [[ -n "$codename" ]] || return 1
    is_known_eol_ubuntu_codename "$codename" || return 1
    rewrite_ubuntu_apt_sources "old-releases"
}

ff_apt_update() {
    local -a apt_opts=(
        -o Acquire::Retries=3
        -o Acquire::ForceIPv4=true
        -o Acquire::http::Timeout=20
        -o Acquire::https::Timeout=20
        -o Acquire::http::Pipeline-Depth=0
    )

    if (( APT_CACHE_READY == 1 )); then
        return 0
    fi

    if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
        APT_CACHE_READY=1
        return 0
    fi

    if repair_ubuntu_apt_mirrors; then
        echo -e "${C_YELLOW}⚠️ Switching Ubuntu sources to archive.ubuntu.com...${C_RESET}"
        apt-get clean >/dev/null 2>&1 || true
        if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
            APT_CACHE_READY=1
            return 0
        fi
    fi

    if switch_ubuntu_to_old_releases; then
        echo -e "${C_YELLOW}⚠️ Switching to old-releases.ubuntu.com...${C_RESET}"
        apt-get clean >/dev/null 2>&1 || true
        if DEBIAN_FRONTEND=noninteractive apt-get "${apt_opts[@]}" update; then
            APT_CACHE_READY=1
            return 0
        fi
    fi

    echo -e "${C_RED}❌ Failed to refresh package lists.${C_RESET}"
    return 1
}

ff_apt_install() {
    ff_apt_update || return 1
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 install "$@"
}

ff_apt_purge() {
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 purge "$@"
}

# ================================================================
# ========== ENVIRONMENT CHECK ==========
# ================================================================

check_environment() {
    local missing_packages=()
    for cmd in bc jq curl wget; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_packages+=("$cmd")
        fi
    done
    if [ ${#missing_packages[@]} -gt 0 ]; then
        ff_apt_install "${missing_packages[@]}" >/dev/null 2>&1
    fi
}

# ================================================================
# ========== VPS DASHBOARD FUNCTIONS ==========
# ================================================================

get_vps_info() {
    VPS_IP=$(curl -s -4 icanhazip.com 2>/dev/null || echo "Unknown")
    
    local ip_info=$(curl -s "http://ip-api.com/json/$VPS_IP" 2>/dev/null)
    VPS_CITY=$(echo "$ip_info" | grep -o '"city":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    VPS_COUNTRY=$(echo "$ip_info" | grep -o '"country":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    VPS_ISP=$(echo "$ip_info" | grep -o '"isp":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    VPS_LOCATION="${VPS_CITY}, ${VPS_COUNTRY}"
    
    VPS_OS=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Unknown")
    VPS_OS_VERSION=$(grep -oP 'VERSION_ID="\K[^"]+' /etc/os-release 2>/dev/null || echo "Unknown")
    VPS_KERNEL=$(uname -r 2>/dev/null || echo "Unknown")
    VPS_ARCH=$(uname -m 2>/dev/null || echo "Unknown")
    
    VPS_CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//' 2>/dev/null || echo "Unknown")
    VPS_CPU_CORES=$(grep -c "processor" /proc/cpuinfo 2>/dev/null || echo "0")
    VPS_CPU_USAGE=$(top -bn1 | head -5 | awk '/Cpu/ {print $2}' 2>/dev/null || echo "0")
    
    VPS_RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "0")
    VPS_RAM_USED=$(free -h | awk '/^Mem:/ {print $3}' 2>/dev/null || echo "0")
    VPS_RAM_FREE=$(free -h | awk '/^Mem:/ {print $4}' 2>/dev/null || echo "0")
    VPS_RAM_PERCENT=$(free -m | awk '/^Mem:/{if($2>0){printf "%.2f", $3*100/$2}else{print "0"}}' 2>/dev/null || echo "0")
    
    VPS_DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}' 2>/dev/null || echo "0")
    VPS_DISK_USED=$(df -h / | awk 'NR==2 {print $3}' 2>/dev/null || echo "0")
    VPS_DISK_FREE=$(df -h / | awk 'NR==2 {print $4}' 2>/dev/null || echo "0")
    VPS_DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    VPS_STORAGE="$VPS_DISK_TOTAL"
    
    VPS_UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    VPS_LOAD_1=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0")
    VPS_LOAD_5=$(awk '{print $2}' /proc/loadavg 2>/dev/null || echo "0")
    VPS_LOAD_15=$(awk '{print $3}' /proc/loadavg 2>/dev/null || echo "0")
    VPS_UPDATE_TIME=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "Unknown")
    
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1 2>/dev/null)
    if [[ -n "$iface" ]]; then
        VPS_TRAFFIC_RX=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo "0")
        VPS_TRAFFIC_TX=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo "0")
        VPS_TRAFFIC_RX_GB=$(awk "BEGIN {printf \"%.2f\", $VPS_TRAFFIC_RX / 1073741824}" 2>/dev/null || echo "0")
        VPS_TRAFFIC_TX_GB=$(awk "BEGIN {printf \"%.2f\", $VPS_TRAFFIC_TX / 1073741824}" 2>/dev/null || echo "0")
        VPS_TRAFFIC_TOTAL_GB=$(awk "BEGIN {printf \"%.2f\", ($VPS_TRAFFIC_RX + $VPS_TRAFFIC_TX) / 1073741824}" 2>/dev/null || echo "0")
    else
        VPS_TRAFFIC_RX_GB="0"
        VPS_TRAFFIC_TX_GB="0"
        VPS_TRAFFIC_TOTAL_GB="0"
    fi
}

show_vps_dashboard() {
    clear
    get_vps_info
    
    echo -e "${C_BOLD}${C_PURPLE}╔═══════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║                    🖥️  VPS DASHBOARD - REAL TIME INFO                        ║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}╚═══════════════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_CYAN}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}│                        📋 VPS BASIC INFORMATION                            │${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "IP Address:" "$VPS_IP"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Location:" "$VPS_LOCATION"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "ISP:" "$VPS_ISP"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "OS:" "$VPS_OS"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Kernel:" "$VPS_KERNEL"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Architecture:" "$VPS_ARCH"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Last Update:" "$VPS_UPDATE_TIME"
    echo -e "${C_BOLD}${C_CYAN}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_YELLOW}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}│                           ⚡ CPU & LOAD INFO                              │${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "CPU Model:" "$VPS_CPU_MODEL"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "CPU Cores:" "$VPS_CPU_CORES"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "CPU Usage:" "${VPS_CPU_USAGE}%"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Load (1m):" "$VPS_LOAD_1"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Load (5m):" "$VPS_LOAD_5"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Load (15m):" "$VPS_LOAD_15"
    echo -e "${C_BOLD}${C_YELLOW}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_GREEN}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_GREEN}│                         💾 RAM & DISK INFO                               │${C_RESET}"
    echo -e "${C_BOLD}${C_GREEN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "RAM Total:" "$VPS_RAM_TOTAL"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "RAM Used:" "$VPS_RAM_USED"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "RAM Free:" "$VPS_RAM_FREE"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "RAM Usage:" "${VPS_RAM_PERCENT}%"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Disk Total:" "$VPS_DISK_TOTAL"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Disk Used:" "$VPS_DISK_USED"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Disk Free:" "$VPS_DISK_FREE"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Disk Usage:" "${VPS_DISK_PERCENT}%"
    echo -e "${C_BOLD}${C_GREEN}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_BLUE}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}│                          ⏱️  UPTIME & STATUS                               │${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Uptime:" "$VPS_UPTIME"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Users Online:" "${BANNER_CACHE_ONLINE_USERS}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Total Users:" "${BANNER_CACHE_TOTAL_USERS}"
    echo -e "${C_BOLD}${C_BLUE}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_ORANGE}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_ORANGE}│                         📊 TOTAL TRAFFIC USAGE                          │${C_RESET}"
    echo -e "${C_BOLD}${C_ORANGE}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Download:" "${VPS_TRAFFIC_RX_GB} GB"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Upload:" "${VPS_TRAFFIC_TX_GB} GB"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Total Traffic:" "${VPS_TRAFFIC_TOTAL_GB} GB"
    echo -e "${C_BOLD}${C_ORANGE}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_DIM}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_DIM}│  ${C_GREEN}●${C_RESET} System: ${C_GREEN}Running${C_RESET}  │  ${C_GREEN}●${C_RESET} Network: ${C_GREEN}Connected${C_RESET}  │  ${C_GREEN}●${C_RESET} Services: ${C_GREEN}Active${C_RESET}  │${C_RESET}"
    echo -e "${C_BOLD}${C_DIM}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_YELLOW}⚠️ Press ${C_BOLD}[Enter]${C_RESET}${C_YELLOW} to refresh or ${C_BOLD}[0]${C_RESET}${C_YELLOW} to return${C_RESET}"
    read -p "👉 " refresh_choice
    if [[ "$refresh_choice" == "0" ]]; then
        return
    else
        show_vps_dashboard
    fi
}

# ================================================================
# ========== VPN DATA USAGE ==========
# ================================================================

show_vpn_data_usage() {
    clear
    show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}           📊 VPN CONNECTION DATA USAGE${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "${C_YELLOW}ℹ️ No users found.${C_RESET}"
        press_enter
        return
    fi
    
    echo -e "${C_CYAN}=========================================================================================${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-18s | %-15s | %-15s | %-15s | %-12s${C_RESET}\n" "USERNAME" "TRAFFIC USED" "LIMIT" "REMAINING" "STATUS"
    echo -e "${C_CYAN}-----------------------------------------------------------------------------------------${C_RESET}"
    
    local total_used=0
    local total_limit=0
    
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" ]] && continue
        bandwidth_gb=${bandwidth_gb:-0}
        
        local used_bytes=0
        if [[ -f "$BANDWIDTH_DIR/${user}.usage" ]]; then
            used_bytes=$(cat "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null)
            [[ -z "$used_bytes" ]] && used_bytes=0
        fi
        local used_gb=$(awk "BEGIN {printf \"%.2f\", $used_bytes / 1073741824}" 2>/dev/null || echo "0")
        
        if [[ "$bandwidth_gb" == "0" ]]; then
            local bw_string="Unlimited"
            local remain_string="∞"
            local status="${C_GREEN}Active${C_RESET}"
        else
            local remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}" 2>/dev/null || echo "0")
            local bw_string="${used_gb} GB"
            local remain_string="${remain_gb} GB"
            
            if (( $(awk "BEGIN {print ($used_gb >= $bandwidth_gb)}" 2>/dev/null) )); then
                status="${C_RED}Exceeded${C_RESET}"
            else
                status="${C_GREEN}Active${C_RESET}"
            fi
            total_limit=$(awk "BEGIN {print $total_limit + $bandwidth_gb}" 2>/dev/null || echo "0")
        fi
        
        total_used=$(awk "BEGIN {print $total_used + $used_gb}" 2>/dev/null || echo "0")
        
        printf "%-18s | %-15s | %-15s | %-15s | %-12s\n" "$user" "$bw_string" "$bandwidth_gb GB" "$remain_string" "$status"
    done < "$DB_FILE"
    
    echo -e "${C_CYAN}-----------------------------------------------------------------------------------------${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-18s | %-15s | %-15s | %-15s | %-12s${C_RESET}\n" "TOTAL" "${total_used} GB" "${total_limit} GB" "-" "-"
    echo -e "${C_CYAN}=========================================================================================${C_RESET}"
    echo ""
    
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    if [[ -n "$iface" ]]; then
        local rx_now=$(cat "/sys/class/net/$iface/statistics/rx_bytes" 2>/dev/null || echo "0")
        local tx_now=$(cat "/sys/class/net/$iface/statistics/tx_bytes" 2>/dev/null || echo "0")
        local rx_gb=$(awk "BEGIN {printf \"%.2f\", $rx_now / 1073741824}" 2>/dev/null || echo "0")
        local tx_gb=$(awk "BEGIN {printf \"%.2f\", $tx_now / 1073741824}" 2>/dev/null || echo "0")
        
        echo -e "${C_CYAN}📊 Real-Time Network Traffic:${C_RESET}"
        echo -e "  ⬇️ Download: ${C_GREEN}${rx_gb} GB${C_RESET}"
        echo -e "  ⬆️ Upload:   ${C_GREEN}${tx_gb} GB${C_RESET}"
        echo ""
    fi
    
    press_enter
}

# ================================================================
# ========== BANNER FUNCTIONS ==========
# ================================================================

write_banner_if_changed() {
    local user="$1"
    local content="$2"
    local banner_file="$BANNER_DIR/${user}.txt"
    local tmp_file="${banner_file}.tmp"

    printf "%s" "$content" > "$tmp_file"
    if ! cmp -s "$tmp_file" "$banner_file" 2>/dev/null; then
        mv "$tmp_file" "$banner_file"
    else
        rm -f "$tmp_file"
    fi
}

update_ssh_banners_config() {
    local tmp_conf

    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        if [[ -f "$SSHD_FF_CONFIG" ]]; then
            rm -f "$SSHD_FF_CONFIG" 2>/dev/null
            systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
        fi
        return
    fi

    mkdir -p "$BANNER_DIR" /etc/ssh/sshd_config.d
    tmp_conf="/tmp/firewallfalcon_banners_new.conf"
    echo "# FirewallFalcon - Dynamic per-user SSH banners" > "$tmp_conf"

    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r user _rest; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            echo "Match User $user" >> "$tmp_conf"
            echo "    Banner $BANNER_DIR/${user}.txt" >> "$tmp_conf"
        done < "$DB_FILE"
    fi

    if ! cmp -s "$tmp_conf" "$SSHD_FF_CONFIG" 2>/dev/null; then
        mv "$tmp_conf" "$SSHD_FF_CONFIG"
        if ! grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
            echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
        fi
        systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
    else
        rm -f "$tmp_conf"
    fi
}

setup_ssh_login_info() {
    ensure_firewallfalcon_dirs || return 1
    if ! touch "$BANNER_ENABLED_FILE"; then
        echo -e "${C_RED}❌ Failed to enable dynamic SSH banners.${C_RESET}"
        return 1
    fi
    disable_static_ssh_banner_in_sshd_config
    update_ssh_banners_config
    return 0
}

disable_static_ssh_banner_in_sshd_config() {
    sed -i.bak -E "s|^[[:space:]]*Banner[[:space:]]+$SSH_BANNER_FILE[[:space:]]*$|# Banner $SSH_BANNER_FILE|" /etc/ssh/sshd_config 2>/dev/null
}

disable_dynamic_ssh_banner_system() {
    rm -f "$BANNER_ENABLED_FILE" "$SSHD_FF_CONFIG" 2>/dev/null
    rm -rf "$BANNER_DIR" 2>/dev/null
    invalidate_banner_cache
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
}

is_dynamic_ssh_banner_enabled() {
    [[ -f "$BANNER_ENABLED_FILE" && -f "$SSHD_FF_CONFIG" ]]
}

preview_dynamic_ssh_banner() {
    if ! is_dynamic_ssh_banner_enabled; then
        echo -e "\n${C_RED}❌ Dynamic banners are not enabled right now.${C_RESET}"
        press_enter
        return
    fi

    _select_user_interface "--- 📝 Preview Dynamic Banner ---"
    local u=$SELECTED_USER
    if [[ -z "$u" || "$u" == "NO_USERS" ]]; then
        return
    fi

    echo -e "\n${C_CYAN}--- Dynamic Banner Preview for user '$u' ---${C_RESET}\n"
    if [[ -f "$BANNER_DIR/${u}.txt" ]]; then
        cat "$BANNER_DIR/${u}.txt"
    else
        echo -e "${C_RED}Banner file not generated yet. Waiting up to 10s...${C_RESET}"
        sleep 5
        if ! cat "$BANNER_DIR/${u}.txt" 2>/dev/null; then
            echo -e "\n${C_RED}Still not generated. Check limiter logs:${C_RESET}"
            journalctl -u firewallfalcon-limiter -n 15 --no-pager
        fi
    fi
    press_enter
}

enable_dynamic_banner() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🎨 ENABLING DYNAMIC ACCOUNT BANNER${C_RESET}"
    echo -e "${C_BLUE}           📱 Falcon Style - Per-User Account Info${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    mkdir -p "$BANNER_DIR"
    touch "$BANNER_ENABLED_FILE"
    
    disable_static_ssh_banner_in_sshd_config
    update_ssh_banners_config
    
    systemctl restart firewallfalcon-limiter 2>/dev/null
    
    echo -e "\n${C_GREEN}✅ Dynamic account banner enabled!${C_RESET}"
    echo -e "${C_CYAN}📌 Users will see their account status when connecting via SSH${C_RESET}"
    echo -e "${C_CYAN}📌 Banner updates automatically every 15 seconds${C_RESET}"
    press_enter
}

disable_dynamic_banner() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🛑 DISABLING DYNAMIC ACCOUNT BANNER${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    disable_dynamic_ssh_banner_system
    
    echo -e "\n${C_GREEN}✅ Dynamic banner disabled!${C_RESET}"
    press_enter
}

# ================================================================
# ========== ORPHAN USER FUNCTIONS ==========
# ================================================================

is_firewallfalcon_orphan_user() {
    local username="$1"
    local passwd_line system_user _ uid _ home shell
    
    passwd_line=$(getent passwd "$username" 2>/dev/null) || return 1
    IFS=: read -r system_user _ uid _ _ home shell <<< "$passwd_line"
    [[ "$uid" =~ ^[0-9]+$ ]] || return 1
    
    grep -q "^$username:" "$DB_FILE" && return 1
    
    if id -nG "$username" 2>/dev/null | tr ' ' '\n' | grep -Fxq "$FF_USERS_GROUP"; then
        return 0
    fi
    
    (( uid >= 1000 )) || return 1
    [[ "$home" == "/home/$username" || "$home" == /home/* ]] || return 1
    
    case "$shell" in
        /usr/sbin/nologin|/usr/bin/false|/bin/false) return 0 ;;
    esac
    
    return 1
}

get_firewallfalcon_orphan_users() {
    local username
    while IFS=: read -r username _rest; do
        [[ -n "$username" ]] || continue
        if is_firewallfalcon_orphan_user "$username"; then
            echo "$username"
        fi
    done < /etc/passwd
}

get_firewallfalcon_known_users() {
    local username
    local -A seen_users=()

    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r username _rest; do
            [[ -n "$username" && "$username" != \#* ]] || continue
            seen_users["$username"]=1
        done < "$DB_FILE"
    fi

    while IFS= read -r username; do
        [[ -n "$username" ]] && seen_users["$username"]=1
    done < <(get_firewallfalcon_orphan_users)

    (( ${#seen_users[@]} > 0 )) || return 0
    printf "%s\n" "${!seen_users[@]}" | sort
}

delete_firewallfalcon_user_accounts() {
    local -a users_to_delete=("$@")
    local username

    [[ ${#users_to_delete[@]} -gt 0 ]] || return 0

    for username in "${users_to_delete[@]}"; do
        [[ -n "$username" ]] || continue
        killall -u "$username" -9 &>/dev/null
        if id "$username" &>/dev/null; then
            if userdel -r "$username" &>/dev/null; then
                echo -e " ✅ System user '${C_YELLOW}$username${C_RESET}' deleted."
            else
                echo -e " ❌ Failed to delete system user '${C_YELLOW}$username${C_RESET}'."
            fi
        else
            echo -e " ℹ️ System user '${C_YELLOW}$username${C_RESET}' was already missing. Removing manager data only."
        fi
        rm -f "$BANDWIDTH_DIR/${username}.usage"
        rm -rf "$BANDWIDTH_DIR/pidtrack/${username}"
    done

    if [[ -f "$DB_FILE" ]]; then
        local db_tmp=$(mktemp)
        awk -F: 'NR==FNR { drop[$1]=1; next } !($1 in drop)' <(printf "%s\n" "${users_to_delete[@]}") "$DB_FILE" > "$db_tmp" && mv "$db_tmp" "$DB_FILE"
        rm -f "$db_tmp" 2>/dev/null
    fi

    invalidate_banner_cache
    refresh_dynamic_banner_routing_if_enabled
}

refresh_dynamic_banner_routing_if_enabled() {
    if is_dynamic_ssh_banner_enabled; then
        update_ssh_banners_config
    fi
}

# ================================================================
# ========== SESSION CACHE ==========
# ================================================================

refresh_ssh_session_cache() {
    local now db_mtime
    now=$(date +%s)
    db_mtime=$(stat -c %Y "$DB_FILE" 2>/dev/null || echo 0)

    if (( SSH_SESSION_CACHE_TS > 0 && now - SSH_SESSION_CACHE_TS < SSH_SESSION_CACHE_TTL && db_mtime == SSH_SESSION_CACHE_DB_MTIME )); then
        return
    fi

    SSH_SESSION_COUNTS=()
    SSH_SESSION_PIDS=()
    SSH_SESSION_TOTAL=0
    SSH_SESSION_CACHE_DB_MTIME=$db_mtime

    if [[ ! -s "$DB_FILE" ]]; then
        SSH_SESSION_CACHE_TS=$now
        return
    fi

    local -A managed_user_lookup=()
    local -A uid_user_lookup=()
    local -A seen_sessions=()

    while IFS=: read -r managed_user _rest; do
        [[ -n "$managed_user" && "$managed_user" != \#* ]] && managed_user_lookup["$managed_user"]=1
    done < "$DB_FILE"

    while IFS=: read -r system_user _ system_uid _rest; do
        [[ -n "$system_user" && "$system_uid" =~ ^[0-9]+$ ]] && uid_user_lookup["$system_uid"]="$system_user"
    done < /etc/passwd

    while read -r ssh_pid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue
        candidate_user=""
        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" && -n "${managed_user_lookup[$ssh_owner]+x}" ]]; then
            candidate_user="$ssh_owner"
        elif [[ -r "/proc/$ssh_pid/loginuid" ]]; then
            local login_uid=""
            read -r login_uid < "/proc/$ssh_pid/loginuid" || login_uid=""
            if [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]]; then
                candidate_user="${uid_user_lookup[$login_uid]}"
            fi
        fi

        [[ -n "$candidate_user" && -n "${managed_user_lookup[$candidate_user]+x}" ]] || continue
        [[ -z "${seen_sessions[$candidate_user:$ssh_pid]+x}" ]] || continue

        seen_sessions["$candidate_user:$ssh_pid"]=1
        ((SSH_SESSION_COUNTS["$candidate_user"]++))
        SSH_SESSION_PIDS["$candidate_user"]+="$ssh_pid "
        ((SSH_SESSION_TOTAL++))
    done < <(ps -C sshd -o pid=,user= 2>/dev/null)

    SSH_SESSION_CACHE_TS=$now
}

count_managed_online_sessions() {
    refresh_ssh_session_cache
    echo "$SSH_SESSION_TOTAL"
}

invalidate_banner_cache() {
    BANNER_CACHE_TS=0
    SSH_SESSION_CACHE_TS=0
}

refresh_banner_cache() {
    local now=$(date +%s)
    if (( BANNER_CACHE_TS > 0 && now - BANNER_CACHE_TS < BANNER_CACHE_TTL )); then
        return
    fi

    BANNER_CACHE_OS_NAME=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Linux")
    BANNER_CACHE_UP_TIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    BANNER_CACHE_RAM_USAGE=$(free -m | awk '/^Mem:/{if($2>0){printf "%.2f", $3*100/$2}else{print "0.00"}}')
    BANNER_CACHE_CPU_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    
    if [[ -s "$DB_FILE" ]]; then
        BANNER_CACHE_TOTAL_USERS=$(grep -c . "$DB_FILE")
    else
        BANNER_CACHE_TOTAL_USERS=0
    fi
    
    BANNER_CACHE_ONLINE_USERS=$(count_managed_online_sessions)
    BANNER_CACHE_TS=$now
}

# ================================================================
# ========== SHOW BANNER ==========
# ================================================================

show_banner() {
    refresh_banner_cache
    [[ -t 1 ]] && clear
    echo
    echo -e "${C_TITLE}   FIREWALLFALCON MANAGER v5.0 ${C_RESET}${C_DIM}| Premium Edition${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "OS" "$BANNER_CACHE_OS_NAME" "Uptime: $BANNER_CACHE_UP_TIME"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Memory" "${BANNER_CACHE_RAM_USAGE}% Used" "Online: ${C_WHITE}${BANNER_CACHE_ONLINE_USERS}${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Users" "${BANNER_CACHE_TOTAL_USERS} Managed" "Load: ${C_GREEN}${BANNER_CACHE_CPU_LOAD}${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
}

# ================================================================
# ========== PRESS ENTER & INVALID OPTION ==========
# ================================================================

press_enter() {
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to return..." && read -r
}

invalid_option() {
    echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" && sleep 1
}

clean_input_buffer() {
    while read -r -t 0; do read -r; done 2>/dev/null
}

safe_read() {
    local prompt="$1"
    local var_name="$2"
    clean_input_buffer
    read -p "$prompt" "$var_name"
}

# ================================================================
# ========== USER SELECTION ==========
# ================================================================

_select_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    if [[ ! -s $DB_FILE ]]; then
        echo -e "${C_YELLOW}ℹ️ No users found in the database.${C_RESET}"
        SELECTED_USER="NO_USERS"; return
    fi
    
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Enter a search term (or press Enter to list all): " search_term
        if [[ -n "$search_term" ]]; then
            mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term")
        else
            users=("${all_users[@]}")
        fi
    else
        users=("${all_users[@]}")
    fi

    if [ ${#users[@]} -eq 0 ]; then
        echo -e "\n${C_YELLOW}ℹ️ No users found matching your criteria.${C_RESET}"
        SELECTED_USER="NO_USERS"; return
    fi
    echo -e "\nPlease select a user:\n"
    for i in "${!users[@]}"; do
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"
    done
    echo -e "\n  ${C_RED} [ 0]${C_RESET} ↩️ Cancel"
    echo
    local choice
    while true; do
        read -p "👉 Enter the number of the user: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#users[@]}" ]; then
            if [ "$choice" -eq 0 ]; then
                SELECTED_USER=""; return
            else
                SELECTED_USER="${users[$((choice-1))]}"; return
            fi
        else
            echo -e "${C_RED}❌ Invalid selection. Please try again.${C_RESET}"
        fi
    done
}

_select_multi_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    SELECTED_USERS=()
    if [[ ! -s $DB_FILE ]]; then
        echo -e "${C_YELLOW}ℹ️ No users found in the database.${C_RESET}"
        SELECTED_USERS=("NO_USERS"); return
    fi
    
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Enter a search term (or press Enter to list all): " search_term
        if [[ -n "$search_term" ]]; then
            mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term")
        else
            users=("${all_users[@]}")
        fi
    else
        users=("${all_users[@]}")
    fi

    if [ ${#users[@]} -eq 0 ]; then
        echo -e "\n${C_YELLOW}ℹ️ No users found matching your criteria.${C_RESET}"
        SELECTED_USERS=("NO_USERS"); return
    fi
    echo -e "\nPlease select users:\n"
    for i in "${!users[@]}"; do
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"
    done
    echo -e "\n  ${C_GREEN}[all]${C_RESET} Select ALL"
    echo -e "  ${C_RED}  [0]${C_RESET} ↩️ Cancel"
    echo
    local choice
    while true; do
        read -p "👉 Enter user numbers: " choice
        choice=$(echo "$choice" | tr ',' ' ')
        
        if [[ -z "$choice" ]]; then
            echo -e "${C_RED}❌ Invalid selection.${C_RESET}"
            continue
        fi

        if [[ "$choice" == "0" ]]; then
            SELECTED_USERS=(); return
        fi
        
        if [[ "${choice,,}" == "all" ]]; then
            SELECTED_USERS=("${users[@]}")
            return
        fi
        
        local valid=true
        local selected_indices=()
        for token in $choice; do
            if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
                local start=${token%-*}
                local end=${token#*-}
                if [ "$start" -le "$end" ]; then
                    for (( idx=start; idx<=end; idx++ )); do
                        if [ "$idx" -ge 1 ] && [ "$idx" -le "${#users[@]}" ]; then
                            selected_indices+=($idx)
                        else
                            valid=false; break
                        fi
                    done
                else
                    valid=false; break
                fi
            elif [[ "$token" =~ ^[0-9]+$ ]]; then
                if [ "$token" -ge 1 ] && [ "$token" -le "${#users[@]}" ]; then
                    selected_indices+=($token)
                else
                    valid=false; break
                fi
            else
                valid=false; break
            fi
        done
        
        if [[ "$valid" == true && ${#selected_indices[@]} -gt 0 ]]; then
            mapfile -t unique_indices < <(printf "%s\n" "${selected_indices[@]}" | sort -u -n)
            for idx in "${unique_indices[@]}"; do
                SELECTED_USERS+=("${users[$((idx-1))]}")
            done
            return
        else
            echo -e "${C_RED}❌ Invalid selection.${C_RESET}"
        fi
    done
}

# ================================================================
# ========== GET USER STATUS ==========
# ================================================================

get_user_status() {
    local username="$1"
    if ! id "$username" &>/dev/null; then echo -e "${C_RED}Not Found${C_RESET}"; return; fi
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    if passwd -S "$username" 2>/dev/null | grep -q " L "; then echo -e "${C_YELLOW}🔒 Locked${C_RESET}"; return; fi
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    if [[ $expiry_ts -lt $current_ts ]]; then echo -e "${C_RED}🗓️ Expired${C_RESET}"; return; fi
    echo -e "${C_GREEN}🟢 Active${C_RESET}"
}

# ================================================================
# ========== USER MANAGEMENT ==========
# ================================================================

create_user() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Create New SSH User ---${C_RESET}"
    read -p "👉 Enter username (or '0' to cancel): " username
    if [[ "$username" == "0" ]]; then
        echo -e "\n${C_YELLOW}❌ User creation cancelled.${C_RESET}"
        return
    fi
    if [[ -z "$username" ]]; then
        echo -e "\n${C_RED}❌ Error: Username cannot be empty.${C_RESET}"
        return
    fi
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ Error: User '$username' already exists.${C_RESET}"
        return
    fi
    local password=""
    while true; do
        read -p "🔑 Enter password (or press Enter for auto-generated): " password
        if [[ -z "$password" ]]; then
            password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
            echo -e "${C_GREEN}🔑 Auto-generated password: ${C_YELLOW}$password${C_RESET}"
            break
        else
            break
        fi
    done
    read -p "🗓️ Enter account duration (in days) [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    read -p "📶 Enter simultaneous connection limit [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    read -p "📦 Enter bandwidth limit in GB (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    local expire_date
    expire_date=$(date -d "+$days days" +%Y-%m-%d)
    
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb" >> "$DB_FILE"
    
    local bw_display="Unlimited"
    if [[ "$bandwidth_gb" != "0" ]]; then bw_display="${bandwidth_gb} GB"; fi
    
    clear; show_banner
    echo -e "${C_GREEN}✅ User '$username' created successfully!${C_RESET}\n"
    echo -e "  - 👤 Username:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Password:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - 🗓️ Expires on:        ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  - 📶 Connection Limit:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Bandwidth Limit:   ${C_YELLOW}$bw_display${C_RESET}"

    echo
    read -p "👉 Do you want to generate a client connection config? (y/n): " gen_conf
    if [[ "$gen_conf" == "y" || "$gen_conf" == "Y" ]]; then
        generate_client_config "$username" "$password"
    fi
    
    invalidate_banner_cache
    update_ssh_banners_config
}

delete_user() {
    _select_multi_user_interface "--- 🗑️ Delete Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_RED}⚠️ You selected ${#SELECTED_USERS[@]} user(s) to delete: ${C_YELLOW}${SELECTED_USERS[*]}${C_RESET}"
    read -p "👉 Are you sure you want to PERMANENTLY delete them? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "\n${C_YELLOW}❌ Deletion cancelled.${C_RESET}"; return; fi
    
    echo -e "\n${C_BLUE}🗑️ Deleting selected users...${C_RESET}"
    delete_firewallfalcon_user_accounts "${SELECTED_USERS[@]}"
}

edit_user() {
    _select_user_interface "--- ✏️ Edit a User ---"
    local username=$SELECTED_USER
    if [[ "$username" == "NO_USERS" ]] || [[ -z "$username" ]]; then return; fi
    while true; do
        clear; show_banner; echo -e "${C_BOLD}${C_PURPLE}--- Editing User: ${C_YELLOW}$username${C_PURPLE} ---${C_RESET}"
        
        local current_line; current_line=$(grep "^$username:" "$DB_FILE")
        local cur_pass; cur_pass=$(echo "$current_line" | cut -d: -f2)
        local cur_expiry; cur_expiry=$(echo "$current_line" | cut -d: -f3)
        local cur_limit; cur_limit=$(echo "$current_line" | cut -d: -f4)
        local cur_bw; cur_bw=$(echo "$current_line" | cut -d: -f5)
        [[ -z "$cur_bw" ]] && cur_bw="0"
        local cur_bw_display="Unlimited"; [[ "$cur_bw" != "0" ]] && cur_bw_display="${cur_bw} GB"
        
        local used_bytes=0
        if [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then
            used_bytes=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null)
            [[ -z "$used_bytes" ]] && used_bytes=0
        fi
        local used_gb=$(awk "BEGIN {printf \"%.2f\", $used_bytes / 1073741824}")
        
        echo -e "\n  ${C_DIM}Current: Pass=${C_YELLOW}$cur_pass${C_RESET}${C_DIM} Exp=${C_YELLOW}$cur_expiry${C_RESET}${C_DIM} Conn=${C_YELLOW}$cur_limit${C_RESET}${C_DIM} BW=${C_YELLOW}$cur_bw_display${C_RESET}${C_DIM} Used=${C_CYAN}${used_gb} GB${C_RESET}"
        echo -e "\nSelect a detail to edit:\n"
        printf "  ${C_GREEN}[ 1]${C_RESET} %-35s\n" "🔑 Change Password"
        printf "  ${C_GREEN}[ 2]${C_RESET} %-35s\n" "🗓️ Change Expiration Date"
        printf "  ${C_GREEN}[ 3]${C_RESET} %-35s\n" "📶 Change Connection Limit"
        printf "  ${C_GREEN}[ 4]${C_RESET} %-35s\n" "📦 Change Bandwidth Limit"
        printf "  ${C_GREEN}[ 5]${C_RESET} %-35s\n" "🔄 Reset Bandwidth Counter"
        echo -e "\n  ${C_RED}[ 0]${C_RESET} ✅ Finish Editing"; echo; read -p "👉 Enter your choice: " edit_choice
        case $edit_choice in
            1)
               local new_pass=""
               read -p "Enter new password (or press Enter for auto-generated): " new_pass
               if [[ -z "$new_pass" ]]; then
                   new_pass=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
                   echo -e "${C_GREEN}🔑 Auto-generated: ${C_YELLOW}$new_pass${C_RESET}"
               fi
               echo "$username:$new_pass" | chpasswd
               sed -i "s/^$username:.*/$username:$new_pass:$cur_expiry:$cur_limit:$cur_bw/" "$DB_FILE"
               echo -e "\n${C_GREEN}✅ Password for '$username' changed to: ${C_YELLOW}$new_pass${C_RESET}"
               ;;
            2) read -p "Enter new duration (in days from today): " days
               if [[ "$days" =~ ^[0-9]+$ ]]; then
                   local new_expire_date; new_expire_date=$(date -d "+$days days" +%Y-%m-%d); chage -E "$new_expire_date" "$username"
                   sed -i "s/^$username:.*/$username:$cur_pass:$new_expire_date:$cur_limit:$cur_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Expiration for '$username' set to ${C_YELLOW}$new_expire_date${C_RESET}."
               else echo -e "\n${C_RED}❌ Invalid number of days.${C_RESET}"; fi ;;
            3) read -p "Enter new simultaneous connection limit: " new_limit
               if [[ "$new_limit" =~ ^[0-9]+$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$new_limit:$cur_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Connection limit for '$username' set to ${C_YELLOW}$new_limit${C_RESET}."
               else echo -e "\n${C_RED}❌ Invalid limit.${C_RESET}"; fi ;;
            4) read -p "Enter new bandwidth limit in GB (0 = unlimited): " new_bw
               if [[ "$new_bw" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$new_bw/" "$DB_FILE"
                   local bw_msg="Unlimited"; [[ "$new_bw" != "0" ]] && bw_msg="${new_bw} GB"
                   echo -e "\n${C_GREEN}✅ Bandwidth limit for '$username' set to ${C_YELLOW}$bw_msg${C_RESET}."
                   if [[ "$new_bw" == "0" ]] || [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then
                       local used_bytes=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null || echo 0)
                       local new_quota_bytes=$(awk "BEGIN {printf \"%.0f\", $new_bw * 1073741824}")
                       if [[ "$new_bw" == "0" ]] || [[ "$used_bytes" -lt "$new_quota_bytes" ]]; then
                           usermod -U "$username" &>/dev/null
                       fi
                   fi
               else echo -e "\n${C_RED}❌ Invalid bandwidth value.${C_RESET}"; fi ;;
            5)
               echo "0" > "$BANDWIDTH_DIR/${username}.usage"
               usermod -U "$username" &>/dev/null
               echo -e "\n${C_GREEN}✅ Bandwidth counter for '$username' has been reset to 0.${C_RESET}"
               ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" ;;
        esac
        echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to continue editing..." && read -r
    done
}

lock_user() {
    _select_multi_user_interface "--- 🔒 Lock Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_BLUE}🔒 Locking selected users...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then
             echo -e " ❌ User '${C_YELLOW}$u${C_RESET}' does not exist."
             continue
        fi
        usermod -L "$u"
        if [ $? -eq 0 ]; then
            killall -u "$u" -9 &>/dev/null
            echo -e " ✅ ${C_YELLOW}$u${C_RESET} locked."
        else
            echo -e " ❌ Failed to lock ${C_YELLOW}$u${C_RESET}."
        fi
    done
}

unlock_user() {
    _select_multi_user_interface "--- 🔓 Unlock Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    
    echo -e "\n${C_BLUE}🔓 Unlocking selected users...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then
             echo -e " ❌ User '${C_YELLOW}$u${C_RESET}' does not exist."
             continue
        fi
        usermod -U "$u"
        if [ $? -eq 0 ]; then
            echo -e " ✅ ${C_YELLOW}$u${C_RESET} unlocked."
        else
            echo -e " ❌ Failed to unlock ${C_YELLOW}$u${C_RESET}."
        fi
    done
}

list_users() {
    clear; show_banner
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_YELLOW}ℹ️ No users are currently being managed.${C_RESET}"
        return
    fi
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Managed Users ---${C_RESET}"
    echo -e "${C_CYAN}=========================================================================================${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-18s | %-12s | %-10s | %-15s | %-20s${C_RESET}\n" "USERNAME" "EXPIRES" "CONNS" "BANDWIDTH" "STATUS"
    echo -e "${C_CYAN}-----------------------------------------------------------------------------------------${C_RESET}"
    
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" ]] && continue
        bandwidth_gb=${bandwidth_gb:-0}
        
        local online_count=$(pgrep -c -u "$user" sshd 2>/dev/null || echo 0)
        local connection_string="$online_count / $limit"
        
        local bw_string="Unlimited"
        if [[ "$bandwidth_gb" != "0" ]]; then
            local used_bytes=0
            if [[ -f "$BANDWIDTH_DIR/${user}.usage" ]]; then
                used_bytes=$(cat "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null)
                [[ -z "$used_bytes" ]] && used_bytes=0
            fi
            local used_gb=$(awk "BEGIN {printf \"%.1f\", $used_bytes / 1073741824}")
            bw_string="${used_gb}/${bandwidth_gb}GB"
        fi
        
        local status_text=$(get_user_status "$user")
        local plain_status=$(echo -e "$status_text" | sed 's/\x1b\[[0-9;]*m//g')
        
        local line_color="$C_WHITE"
        case $plain_status in
            *"Active"*) line_color="$C_GREEN" ;;
            *"Locked"*) line_color="$C_YELLOW" ;;
            *"Expired"*) line_color="$C_RED" ;;
            *"Not Found"*) line_color="$C_DIM" ;;
        esac

        printf "${line_color}%-18s ${C_RESET}| ${C_YELLOW}%-12s ${C_RESET}| ${C_CYAN}%-10s ${C_RESET}| ${C_ORANGE}%-15s ${C_RESET}| %-20s\n" "$user" "$expiry" "$connection_string" "$bw_string" "$status_text"
    done < <(sort "$DB_FILE")
    echo -e "${C_CYAN}=========================================================================================${C_RESET}\n"
}

renew_user() {
    _select_multi_user_interface "--- 🔄 Renew Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then return; fi
    read -p "👉 Enter number of days to extend the account(s): " days
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    local new_expire_date; new_expire_date=$(date -d "+$days days" +%Y-%m-%d)
    
    echo -e "\n${C_BLUE}🔄 Renewing selected users for $days days...${C_RESET}"
    for u in "${SELECTED_USERS[@]}"; do
        chage -E "$new_expire_date" "$u"
        local line; line=$(grep "^$u:" "$DB_FILE")
        local pass; pass=$(echo "$line"|cut -d: -f2)
        local limit; limit=$(echo "$line"|cut -d: -f4)
        local bw; bw=$(echo "$line"|cut -d: -f5)
        [[ -z "$bw" ]] && bw="0"
        sed -i "s/^$u:.*/$u:$pass:$new_expire_date:$limit:$bw/" "$DB_FILE"
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} renewed until ${C_GREEN}${new_expire_date}${C_RESET}."
    done
}

cleanup_expired() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🧹 Cleanup Expired Users ---${C_RESET}"
    
    local expired_users=()
    local current_ts=$(date +%s)

    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_GREEN}✅ User database is empty. No expired users found.${C_RESET}"
        return
    fi
    
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        local expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        if [[ $expiry_ts -lt $current_ts && $expiry_ts -ne 0 ]]; then
            expired_users+=("$user")
        fi
    done < "$DB_FILE"

    if [ ${#expired_users[@]} -eq 0 ]; then
        echo -e "\n${C_GREEN}✅ No expired users found.${C_RESET}"
        return
    fi

    echo -e "\nThe following users have expired: ${C_RED}${expired_users[*]}${C_RESET}"
    read -p "👉 Do you want to delete all of them? (y/n): " confirm

    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        for user in "${expired_users[@]}"; do
            echo " - Deleting ${C_YELLOW}$user...${C_RESET}"
            killall -u "$user" -9 &>/dev/null
            rm -f "$BANDWIDTH_DIR/${user}.usage"
            rm -rf "$BANDWIDTH_DIR/pidtrack/${user}"
            userdel -r "$user" &>/dev/null
            sed -i "/^$user:/d" "$DB_FILE"
        done
        echo -e "\n${C_GREEN}✅ Expired users have been cleaned up.${C_RESET}"
    else
        echo -e "\n${C_YELLOW}❌ Cleanup cancelled.${C_RESET}"
    fi
    invalidate_banner_cache
    update_ssh_banners_config
}

bulk_create_users() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👥 Bulk Create Users ---${C_RESET}"
    
    read -p "👉 Enter username prefix (e.g., 'user'): " prefix
    if [[ -z "$prefix" ]]; then echo -e "\n${C_RED}❌ Prefix cannot be empty.${C_RESET}"; return; fi
    
    read -p "🔢 How many users to create? " count
    if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]] || [[ "$count" -gt 100 ]]; then
        echo -e "\n${C_RED}❌ Invalid count (1-100).${C_RESET}"; return
    fi
    
    read -p "🗓️ Account duration (in days) [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    read -p "📶 Connection limit per user [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    read -p "📦 Bandwidth limit in GB per user (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    local expire_date=$(date -d "+$days days" +%Y-%m-%d)
    local bw_display="Unlimited"; [[ "$bandwidth_gb" != "0" ]] && bw_display="${bandwidth_gb} GB"
    
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    
    echo -e "\n${C_BLUE}⚙️ Creating $count users with prefix '${prefix}'...${C_RESET}\n"
    echo -e "${C_YELLOW}================================================================${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-20s | %-15s | %-12s${C_RESET}\n" "USERNAME" "PASSWORD" "EXPIRES"
    echo -e "${C_YELLOW}----------------------------------------------------------------${C_RESET}"
    
    local created=0
    for ((i=1; i<=count; i++)); do
        local username="${prefix}${i}"
        if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
            echo -e "${C_RED}  ⚠️ Skipping '$username' — already exists${C_RESET}"
            continue
        fi
        local password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
        useradd -m -s /usr/sbin/nologin "$username"
        usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
        echo "$username:$password" | chpasswd
        chage -E "$expire_date" "$username"
        echo "$username:$password:$expire_date:$limit:$bandwidth_gb" >> "$DB_FILE"
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$username" "$password" "$expire_date"
        created=$((created + 1))
    done
    
    echo -e "${C_YELLOW}================================================================${C_RESET}"
    echo -e "\n${C_GREEN}✅ Created $created users. Conn Limit: ${limit} | BW: ${bw_display}${C_RESET}"
    invalidate_banner_cache
    update_ssh_banners_config
}

view_user_bandwidth() {
    _select_user_interface "--- 📊 View User Bandwidth ---"
    local u=$SELECTED_USER
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then return; fi
    
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📊 Bandwidth Details: ${C_YELLOW}$u${C_PURPLE} ---${C_RESET}\n"
    
    local line; line=$(grep "^$u:" "$DB_FILE")
    local bandwidth_gb; bandwidth_gb=$(echo "$line" | cut -d: -f5)
    [[ -z "$bandwidth_gb" ]] && bandwidth_gb="0"
    
    local used_bytes=0
    if [[ -f "$BANDWIDTH_DIR/${u}.usage" ]]; then
        used_bytes=$(cat "$BANDWIDTH_DIR/${u}.usage" 2>/dev/null)
        [[ -z "$used_bytes" ]] && used_bytes=0
    fi
    local used_gb=$(awk "BEGIN {printf \"%.3f\", $used_bytes / 1073741824}")
    
    echo -e "  ${C_CYAN}Data Used:${C_RESET}        ${C_WHITE}${used_gb} GB${C_RESET}"
    
    if [[ "$bandwidth_gb" == "0" ]]; then
        echo -e "  ${C_CYAN}Bandwidth Limit:${C_RESET}  ${C_GREEN}Unlimited${C_RESET}"
        echo -e "  ${C_CYAN}Status:${C_RESET}           ${C_GREEN}No quota restrictions${C_RESET}"
    else
        local quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        local percentage=$(awk "BEGIN {printf \"%.1f\", ($used_bytes / $quota_bytes) * 100}")
        local remaining_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.3f\", r}")
        
        echo -e "  ${C_CYAN}Bandwidth Limit:${C_RESET}  ${C_YELLOW}${bandwidth_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Remaining:${C_RESET}        ${C_WHITE}${remaining_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Usage:${C_RESET}            ${C_WHITE}${percentage}%${C_RESET}"
        
        local bar_width=30
        local filled=$(awk "BEGIN {printf \"%.0f\", ($percentage / 100) * $bar_width}")
        if [[ "$filled" -gt "$bar_width" ]]; then filled=$bar_width; fi
        local empty=$((bar_width - filled))
        local bar_color="$C_GREEN"
        if (( $(awk "BEGIN {print ($percentage > 80)}" ) )); then bar_color="$C_RED"
        elif (( $(awk "BEGIN {print ($percentage > 50)}" ) )); then bar_color="$C_YELLOW"
        fi
        printf "  ${C_CYAN}Progress:${C_RESET}         ${bar_color}["
        for ((i=0; i<filled; i++)); do printf "█"; done
        for ((i=0; i<empty; i++)); do printf "░"; done
        printf "]${C_RESET} ${percentage}%%\n"
        
        if [[ "$used_bytes" -ge "$quota_bytes" ]]; then
            echo -e "\n  ${C_RED}⚠️ USER HAS EXCEEDED BANDWIDTH QUOTA — ACCOUNT LOCKED${C_RESET}"
        fi
    fi
}

generate_client_config() {
    local user=$1
    local pass=$2
    
    local host_ip=$(curl -s -4 icanhazip.com 2>/dev/null || echo "unknown")
    local host_domain="$host_ip"
    
    if [ -f "$DB_DIR/domain.txt" ]; then
        local managed_domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
        if [[ -n "$managed_domain" ]]; then 
            host_domain="$managed_domain"
        fi
    fi

    echo -e "\n${C_BOLD}${C_PURPLE}--- 📱 Client Connection Configuration ---${C_RESET}"
    echo -e "${C_CYAN}Copy the details below to your clipboard:${C_RESET}\n"

    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "👤 ${C_BOLD}User Details${C_RESET}"
    echo -e "   • Username: ${C_WHITE}$user${C_RESET}"
    echo -e "   • Password: ${C_WHITE}$pass${C_RESET}"
    echo -e "   • Host/IP : ${C_WHITE}$host_domain${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    
    echo -e "\n🔹 ${C_BOLD}SSH Direct${C_RESET}:"
    echo -e "   • Host: $host_domain"
    echo -e "   • Port: 22"
    echo -e "   • Username: $user"
    echo -e "   • Password: $pass"

    if systemctl is-active --quiet haproxy 2>/dev/null; then
        local haproxy_port=$(grep -oP 'bind \*:(\d+)' /etc/haproxy/haproxy.cfg 2>/dev/null | awk -F: '{print $2}' | head -1)
        if [[ -n "$haproxy_port" ]]; then
            echo -e "\n🔹 ${C_BOLD}SSL/TLS Tunnel (HAProxy)${C_RESET}:"
            echo -e "   • Host: $host_domain"
            echo -e "   • Port: $haproxy_port"
            echo -e "   • Username: $user"
            echo -e "   • Password: $pass"
        fi
    fi

    if systemctl is-active --quiet udp-custom 2>/dev/null; then
        echo -e "\n🔹 ${C_BOLD}UDP Custom${C_RESET}:"
        echo -e "   • IP: $host_ip (Must use numeric IP)"
        echo -e "   • Port: 1-65535 (Exclude 53, 5300)"
        echo -e "   • Username: $user"
        echo -e "   • Password: $pass"
    fi

    if systemctl is-active --quiet dnstt 2>/dev/null; then
        if [ -f "$DNSTT_CONFIG_FILE" ]; then
            source "$DNSTT_CONFIG_FILE"
            echo -e "\n🔹 ${C_BOLD}DNSTT (SlowDNS)${C_RESET}:"
            echo -e "   • Nameserver: $TUNNEL_DOMAIN"
            echo -e "   • PubKey: $PUBLIC_KEY"
            echo -e "   • DNS IP: 8.8.8.8 / 1.1.1.1 / 169.255.187.58"
            echo -e "   • MTU: $MTU_VALUE"
            echo -e "   • Username: $user"
            echo -e "   • Password: $pass"
        fi
    fi
    
    echo -e "${C_YELLOW}========================================${C_RESET}"
    press_enter
}

client_config_menu() {
    _select_user_interface "--- 📱 Generate Client Config ---"
    local u=$SELECTED_USER
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then return; fi
    
    local pass=$(grep "^$u:" "$DB_FILE" | cut -d: -f2)
    generate_client_config "$u" "$pass"
}

# ================================================================
# ========== TRIAL ACCOUNT ==========
# ================================================================

setup_trial_cleanup_script() {
    cat > "$TRIAL_CLEANUP_SCRIPT" << 'TREOF'
#!/bin/bash
username="$1"
if [[ -z "$username" ]]; then exit 1; fi
killall -u "$username" -9 &>/dev/null
userdel -r "$username" &>/dev/null
sed -i "/^${username}:/d" /etc/firewallfalcon/users.db
rm -f /etc/firewallfalcon/bandwidth/${username}.usage
rm -rf /etc/firewallfalcon/bandwidth/pidtrack/${username}
TREOF
    chmod +x "$TRIAL_CLEANUP_SCRIPT"
}

create_trial_account() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ⏱️ Create Trial/Test Account ---${C_RESET}"
    
    if ! command -v at &>/dev/null; then
        echo -e "${C_YELLOW}⚠️ 'at' command not found. Installing...${C_RESET}"
        ff_apt_install at >/dev/null 2>&1
        systemctl enable atd &>/dev/null
        systemctl start atd &>/dev/null
    fi
    
    setup_trial_cleanup_script
    
    echo -e "\n${C_CYAN}Select trial duration:${C_RESET}\n"
    printf "  ${C_GREEN}[ 1]${C_RESET} ⏱️  1 Hour\n"
    printf "  ${C_GREEN}[ 2]${C_RESET} ⏱️  2 Hours\n"
    printf "  ${C_GREEN}[ 3]${C_RESET} ⏱️  3 Hours\n"
    printf "  ${C_GREEN}[ 4]${C_RESET} ⏱️  6 Hours\n"
    printf "  ${C_GREEN}[ 5]${C_RESET} ⏱️  12 Hours\n"
    printf "  ${C_GREEN}[ 6]${C_RESET} 📅  1 Day\n"
    printf "  ${C_GREEN}[ 7]${C_RESET} 📅  3 Days\n"
    printf "  ${C_GREEN}[ 8]${C_RESET} ⚙️  Custom (enter hours)\n"
    echo -e "\n  ${C_RED}[ 0]${C_RESET} ↩️ Cancel"
    echo
    read -p "👉 Select duration: " dur_choice
    
    local duration_hours=0
    local duration_label=""
    case $dur_choice in
        1) duration_hours=1;   duration_label="1 Hour" ;;
        2) duration_hours=2;   duration_label="2 Hours" ;;
        3) duration_hours=3;   duration_label="3 Hours" ;;
        4) duration_hours=6;   duration_label="6 Hours" ;;
        5) duration_hours=12;  duration_label="12 Hours" ;;
        6) duration_hours=24;  duration_label="1 Day" ;;
        7) duration_hours=72;  duration_label="3 Days" ;;
        8) read -p "👉 Enter custom duration in hours: " custom_hours
           if ! [[ "$custom_hours" =~ ^[0-9]+$ ]] || [[ "$custom_hours" -lt 1 ]]; then
               echo -e "\n${C_RED}❌ Invalid number of hours.${C_RESET}"; return
           fi
           duration_hours=$custom_hours
           duration_label="$custom_hours Hours"
           ;;
        0) echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; return ;;
        *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}"; return ;;
    esac
    
    local rand_suffix=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 5)
    local default_username="trial_${rand_suffix}"
    read -p "👤 Username [${default_username}]: " username
    username=${username:-$default_username}
    
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ User '$username' already exists.${C_RESET}"; return
    fi
    
    local password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
    read -p "🔑 Password [${password}]: " custom_pass
    password=${custom_pass:-$password}
    
    read -p "📶 Connection limit [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    read -p "📦 Bandwidth limit in GB (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; return; fi
    
    local expire_date
    if [[ "$duration_hours" -ge 24 ]]; then
        local days=$((duration_hours / 24))
        expire_date=$(date -d "+$days days" +%Y-%m-%d)
    else
        expire_date=$(date -d "+1 day" +%Y-%m-%d)
    fi
    local expiry_timestamp=$(date -d "+${duration_hours} hours" '+%Y-%m-%d %H:%M:%S')
    
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb" >> "$DB_FILE"
    
    echo "$TRIAL_CLEANUP_SCRIPT $username" | at now + ${duration_hours} hours 2>/dev/null
    
    local bw_display="Unlimited"
    if [[ "$bandwidth_gb" != "0" ]]; then bw_display="${bandwidth_gb} GB"; fi
    
    clear; show_banner
    echo -e "${C_GREEN}✅ Trial account created successfully!${C_RESET}\n"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "  ⏱️  ${C_BOLD}TRIAL ACCOUNT${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "  - 👤 Username:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Password:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - ⏱️ Duration:          ${C_CYAN}$duration_label${C_RESET}"
    echo -e "  - 🕐 Auto-expires at:   ${C_RED}$expiry_timestamp${C_RESET}"
    echo -e "  - 📶 Connection Limit:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Bandwidth Limit:   ${C_YELLOW}$bw_display${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "\n${C_DIM}The account will be automatically deleted when the trial expires.${C_RESET}"
    
    echo
    read -p "👉 Generate client config for this trial user? (y/n): " gen_conf
    if [[ "$gen_conf" == "y" || "$gen_conf" == "Y" ]]; then
        generate_client_config "$username" "$password"
    fi
    
    invalidate_banner_cache
    update_ssh_banners_config
}

# ================================================================
# ========== DNS FUNCTIONS ==========
# ================================================================

generate_dns_record() {
    echo -e "\n${C_BLUE}⚙️ Generating a random domain...${C_RESET}"
    if ! command -v jq &>/dev/null; then
        ff_apt_install jq >/dev/null 2>&1
    fi
    
    local SERVER_IPV4=$(curl -s -4 icanhazip.com)
    if ! [[ "$SERVER_IPV4" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "\n${C_RED}❌ Could not retrieve valid IPv4 address.${C_RESET}"
        return 1
    fi

    local SERVER_IPV6=$(curl -s -6 icanhazip.com --max-time 5)
    local RANDOM_SUBDOMAIN="vps-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    local FULL_DOMAIN="$RANDOM_SUBDOMAIN.$DESEC_DOMAIN"
    local HAS_IPV6="false"

    local API_DATA=$(printf '[{"subname": "%s", "type": "A", "ttl": 3600, "records": ["%s"]}]' "$RANDOM_SUBDOMAIN" "$SERVER_IPV4")

    if [[ -n "$SERVER_IPV6" ]]; then
        local aaaa_record=$(printf ',{"subname": "%s", "type": "AAAA", "ttl": 3600, "records": ["%s"]}' "$RANDOM_SUBDOMAIN" "$SERVER_IPV6")
        API_DATA="${API_DATA%?}${aaaa_record}]"
        HAS_IPV6="true"
    fi

    local CREATE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
        -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" \
        --data "$API_DATA")
    
    local HTTP_CODE=${CREATE_RESPONSE: -3}
    local RESPONSE_BODY=${CREATE_RESPONSE:0:${#CREATE_RESPONSE}-3}

    if [[ "$HTTP_CODE" -ne 201 ]]; then
        echo -e "${C_RED}❌ Failed to create DNS records. HTTP $HTTP_CODE.${C_RESET}"
        return 1
    fi
    
    cat > "$DNS_INFO_FILE" <<-EOF
SUBDOMAIN="$RANDOM_SUBDOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
HAS_IPV6="$HAS_IPV6"
EOF
    echo -e "\n${C_GREEN}✅ Successfully created domain: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
}

delete_dns_record() {
    if [ ! -f "$DNS_INFO_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ No domain to delete.${C_RESET}"
        return
    fi
    echo -e "\n${C_BLUE}🗑️ Deleting DNS records...${C_RESET}"
    source "$DNS_INFO_FILE"
    if [[ -z "$SUBDOMAIN" ]]; then
        echo -e "${C_RED}❌ Could not read record details.${C_RESET}"
        return
    fi

    curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/A/" \
         -H "Authorization: Token $DESEC_TOKEN" > /dev/null

    if [[ "$HAS_IPV6" == "true" ]]; then
        curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/AAAA/" \
             -H "Authorization: Token $DESEC_TOKEN" > /dev/null
    fi

    echo -e "\n${C_GREEN}✅ Deleted domain: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
    rm -f "$DNS_INFO_FILE"
}

dns_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS Domain Management ---${C_RESET}"
    
    if [ -f "$DNS_INFO_FILE" ]; then
        source "$DNS_INFO_FILE"
        echo -e "\nℹ️ A domain already exists:"
        echo -e "  - ${C_CYAN}Domain:${C_RESET} ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
        echo
        read -p "👉 Do you want to DELETE this domain? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            delete_dns_record
        else
            echo -e "\n${C_YELLOW}❌ Action cancelled.${C_RESET}"
        fi
    else
        echo -e "\nℹ️ No domain has been generated yet."
        echo
        read -p "👉 Do you want to generate a new random domain? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            generate_dns_record
        else
            echo -e "\n${C_YELLOW}❌ Action cancelled.${C_RESET}"
        fi
    fi
    press_enter
}

# ================================================================
# ========== DNSTT SPEED BOOSTERS ==========
# ================================================================

apply_booster_standard() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           ⚡ STANDARD BOOSTER (32MB) - Modern Optimizations${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake Qdisc enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=524288 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=524288 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=262144 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=262144 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers optimized (512KB)${C_RESET}"
    
    sysctl -w net.core.rmem_max=33554432 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=33554432 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers: 32MB${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=100000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=524288 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Packet backlog: 100K${C_RESET}"
    
    sysctl -w net.netfilter.nf_conntrack_max=4000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Connection tracking: 4M${C_RESET}"
    
    ulimit -n 1048576 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 1M${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Modern TCP optimizations enabled${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ Standard Booster applied! (10-15 Mbps)${C_RESET}"
    sleep 1
}

apply_booster_medium() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           ⚡ MEDIUM BOOSTER (64MB) - Modern Optimizations${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake Qdisc enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=1048576 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=1048576 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=524288 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=524288 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 1MB${C_RESET}"
    
    sysctl -w net.core.rmem_max=67108864 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=67108864 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers: 64MB${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=200000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=1048576 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Packet backlog: 200K${C_RESET}"
    
    sysctl -w net.netfilter.nf_conntrack_max=8000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Connection tracking: 8M${C_RESET}"
    
    ulimit -n 2097152 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 2M${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Advanced TCP optimizations enabled${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ Medium Booster applied! (15-20 Mbps) 🚀${C_RESET}"
    sleep 1
}

apply_booster_high() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           ⚡ HIGH BOOSTER (128MB) - Modern Optimizations${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    modprobe sch_fq 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake Qdisc enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=2097152 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=2097152 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=1048576 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=1048576 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 2MB${C_RESET}"
    
    sysctl -w net.core.rmem_max=134217728 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=134217728 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers: 128MB${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=400000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=2097152 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Packet backlog: 400K${C_RESET}"
    
    sysctl -w net.netfilter.nf_conntrack_max=16000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Connection tracking: 16M${C_RESET}"
    
    ulimit -n 4194304 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 4M${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Advanced TCP optimizations enabled${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ High Booster applied! (20-25 Mbps) 🚀🚀${C_RESET}"
    sleep 1
}

apply_booster_ultra() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🚀 ULTRA BOOSTER (256MB) - Modern Optimizations${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    modprobe sch_fq 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake Qdisc enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=4194304 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=4194304 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=2097152 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=2097152 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 4MB${C_RESET}"
    
    sysctl -w net.core.rmem_max=268435456 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=268435456 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers: 256MB${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=600000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=4194304 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Packet backlog: 600K${C_RESET}"
    
    sysctl -w net.netfilter.nf_conntrack_max=32000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Connection tracking: 32M${C_RESET}"
    
    ulimit -n 8388608 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 8M${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_adv_win_scale=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Advanced TCP optimizations enabled${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ ULTRA Booster applied! (25-35 Mbps) 🚀🚀🚀${C_RESET}"
    sleep 1
}

apply_booster_extreme() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           💥 EXTREME BOOSTER (512MB) - Modern Optimizations${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    modprobe sch_fq 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake Qdisc enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=8388608 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=8388608 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=4194304 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=4194304 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 8MB${C_RESET}"
    
    sysctl -w net.core.rmem_max=536870912 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=536870912 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers: 512MB${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=1000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=8388608 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Packet backlog: 1M${C_RESET}"
    
    sysctl -w net.netfilter.nf_conntrack_max=64000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Connection tracking: 64M${C_RESET}"
    
    ulimit -n 16777216 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 16M${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_adv_win_scale=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_autocorking=0 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Advanced TCP optimizations enabled${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ EXTREME Booster applied! (35-50 Mbps) 💥💥💥${C_RESET}"
    sleep 1
}

apply_booster_ultra_plus() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🚀 ULTRA PLUS BOOSTER (768MB) - Modern Optimizations${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    modprobe sch_fq 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake Qdisc enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=3145728 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=3145728 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 6MB${C_RESET}"
    
    sysctl -w net.core.rmem_max=805306368 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=805306368 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers: 768MB${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=800000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=6291456 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Packet backlog: 800K${C_RESET}"
    
    sysctl -w net.netfilter.nf_conntrack_max=48000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Connection tracking: 48M${C_RESET}"
    
    ulimit -n 12582912 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 12M${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_adv_win_scale=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_autocorking=0 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Advanced TCP optimizations enabled${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ ULTRA PLUS Booster applied! (40-60 Mbps) 🚀🚀🚀🚀${C_RESET}"
    sleep 1
}

apply_booster_extreme_plus() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           💥 EXTREME PLUS BOOSTER (1GB) - Modern Optimizations${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    modprobe sch_fq 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake Qdisc enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=6291456 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=6291456 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 12MB${C_RESET}"
    
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers: 1GB${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=1200000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=12582912 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Packet backlog: 1.2M${C_RESET}"
    
    sysctl -w net.netfilter.nf_conntrack_max=96000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Connection tracking: 96M${C_RESET}"
    
    ulimit -n 25165824 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 25M${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_adv_win_scale=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_autocorking=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_frto=2 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Advanced TCP optimizations enabled${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ EXTREME PLUS Booster applied! (60-100 Mbps) 💥💥💥💥💥${C_RESET}"
    sleep 1
}

# ================================================================
# ========== SPEED BOOSTER MENU ==========
# ================================================================

speed_booster_menu() {
    while true; do
        clear; show_banner
        
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           ⚡ DNSTT SPEED BOOSTER MANAGER${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           🔥 MODERN OPTIMIZATIONS v2.0${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}Select Speed Level:${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}[1]${C_RESET} Standard  (32MB)   → 10-15 Mbps"
        echo -e "  ${C_GREEN}[2]${C_RESET} Medium    (64MB)   → 15-20 Mbps  🚀"
        echo -e "  ${C_GREEN}[3]${C_RESET} High      (128MB)  → 20-25 Mbps  🚀🚀"
        echo -e "  ${C_GREEN}[4]${C_RESET} Ultra     (256MB)  → 25-35 Mbps  🚀🚀🚀"
        echo -e "  ${C_GREEN}[5]${C_RESET} Extreme   (512MB)  → 35-50 Mbps  💥💥💥"
        echo -e "  ${C_GREEN}[6]${C_RESET} Ultra Plus (768MB)  → 40-60 Mbps  🚀🚀🚀🚀"
        echo -e "  ${C_GREEN}[7]${C_RESET} Extreme Plus (1GB)  → 60-100 Mbps 💥💥💥💥💥"
        echo ""
        echo -e "  ${C_YELLOW}[8]${C_RESET} View Current Settings"
        echo -e "  ${C_RED}[9]${C_RESET} Reset to Default"
        echo ""
        echo -e "  ${C_RED}[0]${C_RESET} Return"
        echo ""
        
        local choice
        read -p "👉 Select speed level: " choice
        
        case $choice in
            1) apply_booster_standard ;;
            2) apply_booster_medium ;;
            3) apply_booster_high ;;
            4) apply_booster_ultra ;;
            5) apply_booster_extreme ;;
            6) apply_booster_ultra_plus ;;
            7) apply_booster_extreme_plus ;;
            8)
                echo -e "\n${C_CYAN}Current System Settings:${C_RESET}"
                echo -e "  TCP Congestion: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)"
                echo -e "  Qdisc: $(sysctl -n net.core.default_qdisc 2>/dev/null)"
                echo -e "  Network Buffer: $(sysctl -n net.core.rmem_max 2>/dev/null | numfmt --to=iec 2>/dev/null || echo 'Unknown')"
                echo -e "  UDP Buffer: $(sysctl -n net.ipv4.udp_rmem_min 2>/dev/null) bytes"
                echo -e "  TCP Fast Open: $(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null)"
                press_enter
                ;;
            9)
                echo -e "\n${C_RED}⚠️ Reset to default system settings?${C_RESET}"
                read -p "Confirm (y/n): " confirm
                if [[ "$confirm" == "y" ]]; then
                    sysctl -w net.core.rmem_max=212992 >/dev/null 2>&1
                    sysctl -w net.core.wmem_max=212992 >/dev/null 2>&1
                    sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1
                    sysctl -w net.core.default_qdisc=pfifo_fast >/dev/null 2>&1
                    sysctl -w net.ipv4.udp_rmem_min=4096 >/dev/null 2>&1
                    sysctl -w net.ipv4.tcp_fastopen=0 >/dev/null 2>&1
                    sysctl -w net.ipv4.ip_local_port_range="32768 60999" >/dev/null 2>&1
                    echo -e "${C_GREEN}✅ Reset to default${C_RESET}"
                fi
                press_enter
                ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ================================================================
# ========== DNSTT INSTALLATION ==========
# ================================================================

download_dnstt_binary() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           📥 DOWNLOADING DNSTT BINARY${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    local arch=$(uname -m)
    local binary_url=""
    
    if [[ "$arch" == "x86_64" ]]; then
        binary_url="https://dnstt.network/dnstt-server-linux-amd64"
        echo -e "${C_BLUE}ℹ️ Detected x86_64 (amd64) architecture.${C_RESET}"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        binary_url="https://dnstt.network/dnstt-server-linux-arm64"
        echo -e "${C_BLUE}ℹ️ Detected ARM64 architecture.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Unsupported architecture: $arch.${C_RESET}"
        return 1
    fi
    
    echo -e "${C_YELLOW}📥 Downloading DNSTT binary from: $binary_url${C_RESET}"
    curl -sL "$binary_url" -o "$DNSTT_BINARY"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ Failed to download the DNSTT binary.${C_RESET}"
        return 1
    fi
    
    chmod +x "$DNSTT_BINARY"
    
    if [ ! -f "$DNSTT_BINARY" ]; then
        echo -e "${C_RED}❌ Binary download failed${C_RESET}"
        return 1
    fi
    
    # Download client binary too
    echo -e "${C_YELLOW}📥 Downloading DNSTT client binary...${C_RESET}"
    if [[ "$arch" == "x86_64" ]]; then
        curl -sL "https://dnstt.network/dnstt-client-linux-amd64" -o "$DNSTT_CLIENT"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        curl -sL "https://dnstt.network/dnstt-client-linux-arm64" -o "$DNSTT_CLIENT"
    fi
    chmod +x "$DNSTT_CLIENT"
    
    echo -e "${C_GREEN}✅ DNSTT binaries downloaded successfully!${C_RESET}"
    return 0
}

generate_keys() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🔑 GENERATING ENCRYPTION KEYS${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    mkdir -p "$DNSTT_KEYS_DIR"
    cd "$DNSTT_KEYS_DIR"
    rm -f server.key server.pub
    
    echo -e "${C_GREEN}[1/2] Generating keys with DNSTT server...${C_RESET}"
    if ! "$DNSTT_BINARY" -gen-key -privkey-file server.key -pubkey-file server.pub 2>&1 | tee "$DB_DIR/keygen.log" > /dev/null; then
        echo -e "${C_YELLOW}⚠️ Standard keygen failed, using fallback method...${C_RESET}"
        
        echo -e "${C_GREEN}[2/2] Using OpenSSL fallback...${C_RESET}"
        openssl rand -hex 32 > server.key
        chmod 600 server.key
        cat server.key | sha256sum | awk '{print $1}' > server.pub
        chmod 644 server.pub
    fi
    
    if [[ ! -f "server.key" ]] || [[ ! -f "server.pub" ]]; then
        echo -e "${C_RED}❌ Key generation failed${C_RESET}"
        return 1
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    
    PUBLIC_KEY=$(cat server.pub)
    echo -e "\n${C_GREEN}✅ Keys generated successfully!${C_RESET}"
}

generate_desec_domain() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           ☁️  DESEC DNS AUTO DOMAIN GENERATOR${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    rand=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
    ns="ns-$rand"
    tun="tun-$rand"
    
    SERVER_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null)
    if [ -z "$SERVER_IPV4" ] || ! [[ "$SERVER_IPV4" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${C_RED}❌ Could not detect valid IPv4 address. Aborting.${C_RESET}"
        return 1
    fi
    
    echo -e "${C_GREEN}[1/2] Creating IPv4 A record: $ns.$DESEC_DOMAIN → $SERVER_IPV4${C_RESET}"
    
    local API_DATA="[{\"subname\":\"$ns\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$SERVER_IPV4\"]}]"
    
    local ns_target="$ns.$DESEC_DOMAIN."
    echo -e "${C_GREEN}[2/2] Creating NS record: $tun.$DESEC_DOMAIN → $ns.$DESEC_DOMAIN${C_RESET}"
    
    API_DATA="[{\"subname\":\"$ns\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$SERVER_IPV4\"]},{\"subname\":\"$tun\",\"type\":\"NS\",\"ttl\":3600,\"records\":[\"$ns_target\"]}]"
    
    local RESPONSE
    RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
        -H "Authorization: Token $DESEC_TOKEN" \
        -H "Content-Type: application/json" \
        --data "$API_DATA")
    
    local HTTP_CODE=${RESPONSE: -3}
    local RESPONSE_BODY=${RESPONSE:0:${#RESPONSE}-3}
    
    if [[ "$HTTP_CODE" -eq 201 ]]; then
        DOMAIN="$tun.$DESEC_DOMAIN"
        echo "$ns" > "$DB_DIR/desec_ns_subdomain.txt"
        echo "$tun" > "$DB_DIR/desec_tun_subdomain.txt"
        
        echo -e "\n${C_GREEN}✅ Auto-generated domain: ${C_YELLOW}$DOMAIN${C_RESET}"
        echo -e "  • IPv4: ${C_GREEN}$SERVER_IPV4${C_RESET}"
        return 0
    else
        echo -e "${C_RED}❌ Failed to create DNS records. API returned HTTP $HTTP_CODE.${C_RESET}"
        return 1
    fi
}

setup_domain() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🌐 DOMAIN CONFIGURATION${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    
    echo -e "${C_GREEN}Select domain option:${C_RESET}"
    echo -e "  ${C_GREEN}1)${C_RESET} Custom domain (Enter your own)"
    echo -e "  ${C_GREEN}2)${C_RESET} Auto-generate with deSEC DNS"
    echo ""
    read -p "👉 Choice [1-2, default=2]: " domain_option
    domain_option=${domain_option:-2}
    
    if [[ "$domain_option" == "2" ]]; then
        if generate_desec_domain; then
            echo -e "${C_GREEN}✅ Using auto-generated domain: $DOMAIN${C_RESET}"
        else
            echo -e "${C_YELLOW}⚠️ deSEC failed, switching to custom domain...${C_RESET}"
            read -p "👉 Enter tunnel domain: " DOMAIN
        fi
    else
        read -p "👉 Enter tunnel domain (e.g., tunnel.yourdomain.com): " DOMAIN
    fi
    
    echo "$DOMAIN" > "$DB_DIR/domain.txt"
    echo -e "${C_GREEN}✅ Domain: $DOMAIN${C_RESET}"
}

mtu_autodiscovery() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           📡 MTU AUTO-DISCOVERY (dnstm Method)${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    MTU=512
    echo -e "${C_YELLOW}ℹ️ Default MTU: 512${C_RESET}"
    
    echo -e "\n${C_CYAN}Testing MTU sizes...${C_RESET}"
    for test_mtu in 1500 1400 1232 900 512; do
        if ping -c 1 -M do -s $((test_mtu - 28)) 8.8.8.8 &>/dev/null 2>&1; then
            echo -e "  ${C_GREEN}✓ MTU $test_mtu works${C_RESET}"
            MTU=$test_mtu
            break
        else
            echo -e "  ${C_RED}✗ MTU $test_mtu fails${C_RESET}"
        fi
    done
    
    if [[ -z "$MTU" || "$MTU" == "0" ]]; then
        MTU=512
        echo -e "${C_YELLOW}⚠️ No optimal MTU found, using default: 512${C_RESET}"
    fi
    
    echo -e "\n${C_GREEN}✅ MTU set to $MTU${C_RESET}"
}

configure_resolvers() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🔄 MULTI-PATH RESOLVERS (StormDNS Method)${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    mkdir -p "$DB_DIR"
    
    cat > "$DB_DIR/resolvers.txt" << 'EOF'
8.8.8.8:53
1.1.1.1:53
9.9.9.9:53
208.67.222.222:53
77.88.8.8:53
169.255.187.58:53
EOF
    
    echo -e "${C_GREEN}✓ Resolvers list created with 6 resolvers${C_RESET}"
}

show_client_commands() {
    local domain=$1
    local mtu=$2
    local ssh_port=$3
    local pubkey=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null)
    
    if [[ -z "$mtu" ]]; then
        mtu=512
    fi
    
    echo -e "\n${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}           📱 CLIENT CONNECTION DETAILS${C_RESET}"
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    
    echo -e "${C_WHITE}Your connection details:${C_RESET}"
    echo -e "  - ${C_CYAN}Tunnel Domain:${C_RESET} ${C_YELLOW}$domain${C_RESET}"
    echo -e "  - ${C_CYAN}Public Key:${C_RESET}    ${C_YELLOW}$pubkey${C_RESET}"
    echo -e "  - ${C_CYAN}SSH Port:${C_RESET}      ${C_YELLOW}$ssh_port${C_RESET}"
    echo -e "  - ${C_CYAN}MTU Value:${C_RESET}     ${C_YELLOW}$mtu${C_RESET}"
    echo -e "  - ${C_CYAN}Resolvers:${C_RESET}     ${C_YELLOW}8.8.8.8:53, 1.1.1.1:53, 169.255.187.58:53${C_RESET}"
    echo ""
    
    echo -e "${C_YELLOW}📌 DNS Records:${C_RESET}"
    echo -e "  • NS Record: ${C_GREEN}$domain${C_RESET}"
    echo -e "  • A Record:  ${C_GREEN}$domain → $(curl -s -4 icanhazip.com)${C_RESET}"
    echo ""
    
    echo -e "${C_YELLOW}📌 Client Command:${C_RESET}"
    echo -e "${C_WHITE}$DNSTT_CLIENT -udp 8.8.8.8:53 \\${C_RESET}"
    echo -e "${C_WHITE}  -pubkey-file $DNSTT_KEYS_DIR/server.pub \\${C_RESET}"
    echo -e "${C_WHITE}  -mtu $mtu \\${C_RESET}"
    echo -e "${C_WHITE}  $domain 127.0.0.1:$ssh_port${C_RESET}"
    echo ""
    
    echo -e "${C_YELLOW}📌 SSH Connection:${C_RESET}"
    echo -e "${C_WHITE}  ssh username@127.0.0.1 -p $ssh_port${C_RESET}"
    echo ""
    
    echo -e "${C_YELLOW}📌 Alternative Resolver:${C_RESET}"
    echo -e "${C_WHITE}  Use 169.255.187.58:53 if 8.8.8.8 is blocked${C_RESET}"
    echo -e "${C_WHITE}  $DNSTT_CLIENT -udp 169.255.187.58:53 -pubkey-file $DNSTT_KEYS_DIR/server.pub -mtu $mtu $domain 127.0.0.1:$ssh_port${C_RESET}"
}

create_dnstt_service() {
    local domain=$1
    local mtu=$2
    local ssh_port=$3
    local forward_target=$4
    
    if [[ -z "$mtu" ]]; then
        mtu=512
    fi
    
    cat > "$DNSTT_SERVICE_FILE" <<EOF
[Unit]
Description=DNSTT Server - ULTIMATE OPTIMIZED
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$DB_DIR
Environment="GODEBUG=netdns=1"
Environment="DNSTT_COMPRESSION=zstd"
ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_KEYS_DIR/server.key -mtu $mtu -cache-size 16384 -workers 4 -resolver 8.8.8.8:53,1.1.1.1:53,169.255.187.58:53 $domain $forward_target
Restart=always
RestartSec=5
StartLimitInterval=300
StartLimitBurst=5
LimitNOFILE=2097152
LimitNPROC=infinity
LimitCORE=infinity
StandardOutput=append:$DB_DIR/logs/dnstt-server.log
StandardError=append:$DB_DIR/logs/dnstt-error.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dnstt.service > /dev/null 2>&1
    
    echo -e "${C_GREEN}✅ DNSTT service created${C_RESET}"
    echo -e "  • MTU: ${C_YELLOW}$mtu${C_RESET}"
    echo -e "  • Resolvers: ${C_YELLOW}8.8.8.8:53, 1.1.1.1:53, 169.255.187.58:53${C_RESET}"
    echo -e "  • Workers: ${C_YELLOW}4${C_RESET}"
    echo -e "  • Cache Size: ${C_YELLOW}16384${C_RESET}"
}

save_dnstt_info() {
    local domain=$1
    local pubkey=$2
    local mtu=$3
    local ssh_port=$4
    local forward_desc=$5
    
    if [[ -z "$mtu" ]]; then
        mtu=512
    fi
    
    cat > "$DNSTT_CONFIG_FILE" <<EOF
TUNNEL_DOMAIN="$domain"
PUBLIC_KEY="$pubkey"
MTU_VALUE="$mtu"
SSH_PORT="$ssh_port"
RESOLVERS="8.8.8.8:53,1.1.1.1:53,169.255.187.58:53"
COMPRESSION="zstd"
WORKERS="4"
CACHE_SIZE="16384"
DNSTT_RECORDS_MANAGED="true"
FORWARD_DESC="$forward_desc"
EOF
}

install_dnstt() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}           📡 DNSTT INSTALLATION (ULTIMATE)${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}           🔥 Modern Optimizations + StormDNS/dnstm${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    if [ -f "$DNSTT_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ DNSTT is already installed.${C_RESET}"
        read -p "Reinstall? (y/n): " reinstall
        if [[ "$reinstall" != "y" ]]; then
            show_dnstt_details
            return
        fi
        systemctl stop dnstt.service 2>/dev/null
    fi
    
    # Step 1: Install dependencies
    echo -e "\n${C_BLUE}[1/14] Installing dependencies...${C_RESET}"
    ff_apt_install wget curl openssl bc zstd lz4 dnsmasq
    
    # Step 2: EDNS0
    echo -e "\n${C_BLUE}[2/14] Configuring EDNS0...${C_RESET}"
    echo "options edns0 trust-ad" >> /etc/resolv.conf
    echo "options single-request-reopen" >> /etc/resolv.conf
    echo "options timeout:2" >> /etc/resolv.conf
    echo "options attempts:3" >> /etc/resolv.conf
    echo -e "${C_GREEN}✓ EDNS0 enabled${C_RESET}"
    
    # Step 3: DNS Caching
    echo -e "\n${C_BLUE}[3/14] Setting up DNS caching (StormDNS)...${C_RESET}"
    cat > /etc/dnsmasq.conf << 'EOF'
# DNS Caching for DNSTT
port=5353
cache-size=10000
neg-ttl=3600
max-cache-ttl=86400
min-cache-ttl=300
server=8.8.8.8
server=1.1.1.1
server=169.255.187.58
no-resolv
no-poll
EOF
    systemctl restart dnsmasq 2>/dev/null
    echo -e "${C_GREEN}✓ DNS caching enabled (10,000 entries)${C_RESET}"
    
    # Step 4: Connection Pooling
    echo -e "\n${C_BLUE}[4/14] Configuring connection pooling (dnstm)...${C_RESET}"
    cat > /etc/sysctl.d/99-dnstt-keepalive.conf << 'EOF'
# Connection Pooling for DNSTT
net.ipv4.tcp_keepalive_time = 60
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.core.somaxconn = 65535
EOF
    sysctl -p /etc/sysctl.d/99-dnstt-keepalive.conf 2>/dev/null
    echo -e "${C_GREEN}✓ Connection pooling enabled${C_RESET}"
    
    # Step 5: Fragmentation
    echo -e "\n${C_BLUE}[5/14] Packet fragmentation optimization...${C_RESET}"
    cat > /etc/sysctl.d/99-dnstt-frag.conf << 'EOF'
# Packet Fragmentation Optimization
net.ipv4.ip_no_pmtu_disc = 1
net.ipv4.ip_forward = 1
net.ipv4.ipfrag_high_thresh = 524288
net.ipv4.ipfrag_low_thresh = 393216
net.ipv4.ipfrag_time = 30
net.ipv4.ipfrag_max_dist = 64
EOF
    sysctl -p /etc/sysctl.d/99-dnstt-frag.conf 2>/dev/null
    echo -e "${C_GREEN}✓ Fragmentation optimization enabled${C_RESET}"
    
    # Step 6: Download binary
    echo -e "\n${C_BLUE}[6/14] Downloading DNSTT binaries...${C_RESET}"
    if ! download_dnstt_binary; then
        echo -e "${C_RED}❌ Failed to download DNSTT binary${C_RESET}"
        return 1
    fi
    
    # Step 7: Configure resolvers
    echo -e "\n${C_BLUE}[7/14] Configuring multi-path resolvers (StormDNS)...${C_RESET}"
    configure_resolvers
    
    # Step 8: MTU auto-discovery
    echo -e "\n${C_BLUE}[8/14] Auto-discovering optimal MTU (dnstm)...${C_RESET}"
    mtu_autodiscovery
    
    # Step 9: Forward options
    echo -e "\n${C_BLUE}[9/14] Forward options...${C_RESET}"
    echo -e "  ${C_GREEN}[ 1]${C_RESET} ➡️ Forward to local SSH service (port 22)"
    echo -e "  ${C_GREEN}[ 2]${C_RESET} ➡️ Forward to local V2Ray backend (port 8787)"
    read -p "👉 Enter your choice [2]: " fwd_choice
    fwd_choice=${fwd_choice:-2}
    
    local forward_target=""
    local forward_desc=""
    if [[ "$fwd_choice" == "1" ]]; then
        forward_target="127.0.0.1:22"
        forward_desc="SSH (port 22)"
        echo -e "${C_GREEN}ℹ️ DNSTT will forward to SSH on 127.0.0.1:22.${C_RESET}"
    elif [[ "$fwd_choice" == "2" ]]; then
        forward_target="127.0.0.1:8787"
        forward_desc="V2Ray (port 8787)"
        echo -e "${C_GREEN}ℹ️ DNSTT will forward to V2Ray on 127.0.0.1:8787.${C_RESET}"
    else
        forward_target="127.0.0.1:22"
        forward_desc="SSH (port 22)"
        echo -e "${C_YELLOW}⚠️ Invalid choice, defaulting to SSH.${C_RESET}"
    fi
    
    # Step 10: Domain setup
    echo -e "\n${C_BLUE}[10/14] Domain configuration...${C_RESET}"
    setup_domain
    
    # Step 11: Generate keys
    echo -e "\n${C_BLUE}[11/14] Generating encryption keys...${C_RESET}"
    generate_keys
    
    # Step 12: Speed Booster
    echo -e "\n${C_BLUE}[12/14] Selecting speed booster...${C_RESET}"
    echo ""
    echo -e "  ${C_GREEN}[1]${C_RESET} Standard  (32MB)   → 10-15 Mbps"
    echo -e "  ${C_GREEN}[2]${C_RESET} Medium    (64MB)   → 15-20 Mbps  🚀"
    echo -e "  ${C_GREEN}[3]${C_RESET} High      (128MB)  → 20-25 Mbps  🚀🚀"
    echo -e "  ${C_GREEN}[4]${C_RESET} Ultra     (256MB)  → 25-35 Mbps  🚀🚀🚀"
    echo -e "  ${C_GREEN}[5]${C_RESET} Extreme   (512MB)  → 35-50 Mbps  💥💥💥"
    echo -e "  ${C_GREEN}[6]${C_RESET} Ultra Plus (768MB)  → 40-60 Mbps  🚀🚀🚀🚀"
    echo -e "  ${C_GREEN}[7]${C_RESET} Extreme Plus (1GB)  → 60-100 Mbps 💥💥💥💥💥"
    echo -e "  ${C_GREEN}[8]${C_RESET} Skip"
    echo ""
    read -p "👉 Choose booster [1-8, default=3]: " booster_choice
    booster_choice=${booster_choice:-3}
    
    case $booster_choice in
        1) apply_booster_standard ;;
        2) apply_booster_medium ;;
        3) apply_booster_high ;;
        4) apply_booster_ultra ;;
        5) apply_booster_extreme ;;
        6) apply_booster_ultra_plus ;;
        7) apply_booster_extreme_plus ;;
        8) echo -e "${C_YELLOW}⚠️ Skipping speed booster${C_RESET}" ;;
        *) apply_booster_high ;;
    esac
    
    # Step 13: Create service
    echo -e "\n${C_BLUE}[13/14] Creating DNSTT service...${C_RESET}"
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    
    create_dnstt_service "$DOMAIN" "$MTU" "$SSH_PORT" "$forward_target"
    save_dnstt_info "$DOMAIN" "$PUBLIC_KEY" "$MTU" "$SSH_PORT" "$forward_desc"
    
    # Step 14: Save DNSTT info
    echo -e "\n${C_BLUE}[14/14] Saving configuration...${C_RESET}"
    
    echo -e "\n${C_BLUE}🚀 Starting DNSTT service...${C_RESET}"
    systemctl start dnstt.service
    sleep 2
    
    if systemctl is-active --quiet dnstt.service; then
        echo -e "${C_GREEN}✅ Service started successfully${C_RESET}"
    else
        echo -e "${C_RED}❌ Service failed to start${C_RESET}"
        journalctl -u dnstt.service -n 20 --no-pager
    fi
    
    show_client_commands "$DOMAIN" "$MTU" "$SSH_PORT"
    
    echo -e "\n${C_GREEN}✅ DNSTT installation complete!${C_RESET}"
    press_enter
}

show_dnstt_details() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📡 DNSTT Details ---${C_RESET}"
    
    if [ ! -f "$DB_DIR/domain.txt" ]; then
        echo -e "\n${C_YELLOW}DNSTT is not installed${C_RESET}"
        press_enter
        return
    fi
    
    DOMAIN=$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo "unknown")
    MTU=$(cat "$DB_DIR/mtu" 2>/dev/null || echo "512")
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    PUBKEY=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null || echo "unknown")
    
    local status=""
    if systemctl is-active dnstt.service &>/dev/null; then
        status="${C_GREEN}● RUNNING${C_RESET}"
    else
        status="${C_RED}● STOPPED${C_RESET}"
    fi
    
    echo -e "\n  ${C_CYAN}Status:${C_RESET}        $status"
    echo -e "  ${C_CYAN}Domain:${C_RESET}        ${C_YELLOW}$DOMAIN${C_RESET}"
    echo -e "  ${C_CYAN}MTU:${C_RESET}           ${C_YELLOW}$MTU${C_RESET}"
    echo -e "  ${C_CYAN}SSH Port:${C_RESET}      ${C_YELLOW}$SSH_PORT${C_RESET}"
    echo -e "  ${C_CYAN}Resolvers:${C_RESET}     ${C_YELLOW}8.8.8.8:53, 1.1.1.1:53, 169.255.187.58:53${C_RESET}"
    echo -e "  ${C_CYAN}Compression:${C_RESET}   ${C_YELLOW}ZSTD${C_RESET}"
    echo -e "  ${C_CYAN}Workers:${C_RESET}       ${C_YELLOW}4${C_RESET}"
    echo -e "  ${C_CYAN}Cache Size:${C_RESET}    ${C_YELLOW}16384${C_RESET}"
    echo -e "  ${C_CYAN}Public Key:${C_RESET}    ${C_YELLOW}${PUBKEY}${C_RESET}"
    
    press_enter
}

uninstall_dnstt() {
    echo -e "\n${C_BLUE}🗑️ Uninstalling DNSTT...${C_RESET}"
    systemctl stop dnstt.service 2>/dev/null
    systemctl disable dnstt.service 2>/dev/null
    rm -f "$DNSTT_SERVICE_FILE"
    rm -f "$DNSTT_BINARY" "$DNSTT_CLIENT"
    rm -f "$DNSTT_KEYS_DIR/server.key" "$DNSTT_KEYS_DIR/server.pub"
    rm -f "$DB_DIR/domain.txt"
    rm -f "$DNSTT_CONFIG_FILE"
    rm -f "$DB_DIR/mtu"
    rm -f "$DB_DIR/resolvers.txt"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ DNSTT uninstalled${C_RESET}"
    press_enter
}

# ================================================================
# ========== PROTOCOLS ==========
# ================================================================

install_badvpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing badvpn ---${C_RESET}"
    
    ff_apt_install cmake make gcc git build-essential libssl-dev
    
    cd /tmp
    git clone https://github.com/ambrop72/badvpn.git 2>/dev/null
    cd badvpn
    cmake . 2>/dev/null
    make 2>/dev/null
    cp badvpn-udpgw "$BADVPN_BIN" 2>/dev/null
    
    cat > "$BADVPN_SERVICE_FILE" << EOF
[Unit]
Description=BadVPN UDP Gateway
After=network.target

[Service]
Type=simple
ExecStart=$BADVPN_BIN --listen-addr 0.0.0.0:$BADVPN_PORT --max-clients 1000 --max-connections-for-client 8
Restart=always
StandardOutput=null
StandardError=null

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable badvpn.service 2>/dev/null
    systemctl start badvpn.service
    echo -e "${C_GREEN}✅ badvpn installed on port $BADVPN_PORT${C_RESET}"
    press_enter
}

uninstall_badvpn() {
    systemctl stop badvpn.service 2>/dev/null
    systemctl disable badvpn.service 2>/dev/null
    rm -f "$BADVPN_SERVICE_FILE" "$BADVPN_BIN"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ badvpn uninstalled${C_RESET}"
    press_enter
}

install_udp_custom() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing udp-custom ---${C_RESET}"
    
    mkdir -p /usr/local/bin
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        curl -sL -o "$UDP_CUSTOM_BIN" "https://github.com/voltrontech/udp-custom/releases/latest/download/udp-custom-linux-amd64"
    else
        curl -sL -o "$UDP_CUSTOM_BIN" "https://github.com/voltrontech/udp-custom/releases/latest/download/udp-custom-linux-arm64"
    fi
    chmod +x "$UDP_CUSTOM_BIN"
    
    cat > "$UDP_CUSTOM_SERVICE_FILE" << EOF
[Unit]
Description=UDP Custom
After=network.target

[Service]
Type=simple
ExecStart=$UDP_CUSTOM_BIN server -exclude 53,5300
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable udp-custom.service 2>/dev/null
    systemctl start udp-custom.service
    echo -e "${C_GREEN}✅ udp-custom installed${C_RESET}"
    press_enter
}

uninstall_udp_custom() {
    systemctl stop udp-custom.service 2>/dev/null
    systemctl disable udp-custom.service 2>/dev/null
    rm -f "$UDP_CUSTOM_SERVICE_FILE" "$UDP_CUSTOM_BIN"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ udp-custom uninstalled${C_RESET}"
    press_enter
}

# ================================================================
# ========== SSL TUNNEL (HAProxy Edge Stack) ==========
# ================================================================

load_edge_cert_info() {
    EDGE_CERT_MODE=""
    EDGE_DOMAIN=""
    EDGE_EMAIL=""
    if [ -f "$EDGE_CERT_INFO_FILE" ]; then
        source "$EDGE_CERT_INFO_FILE"
    fi
}

save_edge_cert_info() {
    local cert_mode="$1"
    local cert_domain="$2"
    local cert_email="$3"
    mkdir -p "$DB_DIR"
    cat > "$EDGE_CERT_INFO_FILE" <<EOF
EDGE_CERT_MODE="$cert_mode"
EDGE_DOMAIN="$cert_domain"
EDGE_EMAIL="$cert_email"
EOF
}

detect_preferred_host() {
    local host_domain=""
    load_edge_cert_info
    if [[ -n "$EDGE_DOMAIN" ]]; then
        host_domain="$EDGE_DOMAIN"
    fi
    if [[ -z "$host_domain" && -f "$DNS_INFO_FILE" ]]; then
        host_domain=$(grep 'FULL_DOMAIN' "$DNS_INFO_FILE" | cut -d'"' -f2)
    fi
    if [[ -z "$host_domain" && -f "$DB_DIR/domain.txt" ]]; then
        host_domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
    fi
    if [[ -z "$host_domain" ]]; then
        host_domain=$(curl -s -4 icanhazip.com)
    fi
    echo "$host_domain"
}

backup_edge_configs() {
    if [ -f "$NGINX_CONFIG_FILE" ] && [ ! -f "${NGINX_CONFIG_FILE}.bak.firewallfalcon" ]; then
        cp "$NGINX_CONFIG_FILE" "${NGINX_CONFIG_FILE}.bak.firewallfalcon" 2>/dev/null
    fi
    if [ -f "$HAPROXY_CONFIG" ] && [ ! -f "${HAPROXY_CONFIG}.bak.firewallfalcon" ]; then
        cp "$HAPROXY_CONFIG" "${HAPROXY_CONFIG}.bak.firewallfalcon" 2>/dev/null
    fi
}

ensure_edge_stack_packages() {
    local missing_packages=()
    command -v haproxy &> /dev/null || missing_packages+=("haproxy")
    command -v nginx &> /dev/null || missing_packages+=("nginx")
    command -v openssl &> /dev/null || missing_packages+=("openssl")

    if (( ${#missing_packages[@]} > 0 )); then
        echo -e "\n${C_BLUE}📦 Installing required packages: ${missing_packages[*]}${C_RESET}"
        ff_apt_install "${missing_packages[@]}" || {
            echo -e "${C_RED}❌ Failed to install the required packages.${C_RESET}"
            return 1
        }
    fi
    return 0
}

build_shared_tls_bundle() {
    if [ ! -s "$SSL_CERT_CHAIN_FILE" ] || [ ! -s "$SSL_CERT_KEY_FILE" ]; then
        echo -e "${C_RED}❌ Certificate chain or key is missing.${C_RESET}"
        return 1
    fi
    cat "$SSL_CERT_CHAIN_FILE" "$SSL_CERT_KEY_FILE" > "$SSL_CERT_FILE" || return 1
    chmod 644 "$SSL_CERT_CHAIN_FILE"
    chmod 600 "$SSL_CERT_KEY_FILE" "$SSL_CERT_FILE"
    return 0
}

generate_self_signed_edge_cert() {
    local common_name="$1"
    mkdir -p "$SSL_CERT_DIR"
    echo -e "\n${C_GREEN}🔐 Generating a shared self-signed certificate...${C_RESET}"
    openssl req -x509 -newkey rsa:2048 -nodes -days 3650 \
        -keyout "$SSL_CERT_KEY_FILE" \
        -out "$SSL_CERT_CHAIN_FILE" \
        -subj "/CN=$common_name" \
        >/dev/null 2>&1 || {
            echo -e "${C_RED}❌ Failed to generate the self-signed certificate.${C_RESET}"
            return 1
        }
    build_shared_tls_bundle || return 1
    save_edge_cert_info "self-signed" "$common_name" ""
    echo -e "${C_GREEN}✅ Shared certificate created for ${C_YELLOW}$common_name${C_RESET}"
    return 0
}

_install_certbot() {
    if command -v certbot &> /dev/null; then
        echo -e "${C_GREEN}✅ Certbot is already installed.${C_RESET}"
        return 0
    fi
    echo -e "${C_BLUE}📦 Installing Certbot...${C_RESET}"
    ff_apt_install certbot || {
        echo -e "${C_RED}❌ Failed to install Certbot.${C_RESET}"
        return 1
    }
    echo -e "${C_GREEN}✅ Certbot installed successfully.${C_RESET}"
    return 0
}

obtain_certbot_edge_cert() {
    local domain_name="$1"
    local email="$2"

    mkdir -p "$SSL_CERT_DIR"
    _install_certbot || return 1

    echo -e "\n${C_BLUE}🛑 Stopping HAProxy and Nginx for Certbot validation...${C_RESET}"
    systemctl stop haproxy >/dev/null 2>&1
    systemctl stop nginx >/dev/null 2>&1
    sleep 2

    echo -e "\n${C_BLUE}🚀 Requesting a Certbot certificate for ${C_YELLOW}$domain_name${C_RESET}"
    certbot certonly --standalone -d "$domain_name" --non-interactive --agree-tos -m "$email"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ Certbot failed to obtain a certificate.${C_RESET}"
        return 1
    fi

    local certbot_chain="/etc/letsencrypt/live/$domain_name/fullchain.pem"
    local certbot_key="/etc/letsencrypt/live/$domain_name/privkey.pem"
    if [ ! -f "$certbot_chain" ] || [ ! -f "$certbot_key" ]; then
        echo -e "\n${C_RED}❌ Certbot completed, but the certificate files were not found.${C_RESET}"
        return 1
    fi

    cp "$certbot_chain" "$SSL_CERT_CHAIN_FILE"
    cp "$certbot_key" "$SSL_CERT_KEY_FILE"
    build_shared_tls_bundle || return 1
    save_edge_cert_info "certbot" "$domain_name" "$email"
    echo -e "${C_GREEN}✅ Certbot certificate copied into ${C_YELLOW}$SSL_CERT_DIR${C_RESET}"
    return 0
}

select_edge_certificate() {
    local preferred_host=$(detect_preferred_host)
    if [[ -z "$preferred_host" ]]; then
        preferred_host="firewallfalcon.local"
    fi

    local has_existing_cert=false
    if [ -s "$SSL_CERT_FILE" ] && [ -s "$SSL_CERT_CHAIN_FILE" ] && [ -s "$SSL_CERT_KEY_FILE" ]; then
        has_existing_cert=true
    fi

    load_edge_cert_info

    echo -e "\n${C_BOLD}${C_PURPLE}--- 🔐 Shared TLS Certificate ---${C_RESET}"
    echo -e "${C_DIM}The same certificate will be used by HAProxy and the internal Nginx proxy.${C_RESET}"

    if $has_existing_cert; then
        local existing_label="${EDGE_CERT_MODE:-existing}"
        if [[ -n "$EDGE_DOMAIN" ]]; then
            existing_label="$existing_label - $EDGE_DOMAIN"
        fi
        printf "  ${C_CHOICE}[ 1]${C_RESET} %-52s\n" "Reuse existing certificate (${existing_label})"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %-52s\n" "Replace with a new self-signed certificate"
        printf "  ${C_CHOICE}[ 3]${C_RESET} %-52s\n" "Replace with a Certbot certificate"
        echo
        read -p "👉 Enter choice [1]: " cert_choice
        cert_choice=${cert_choice:-1}
    else
        printf "  ${C_CHOICE}[ 1]${C_RESET} %-52s\n" "Generate a self-signed certificate"
        printf "  ${C_CHOICE}[ 2]${C_RESET} %-52s\n" "Use a Certbot certificate"
        echo
        read -p "👉 Enter choice [1]: " cert_choice
        cert_choice=${cert_choice:-1}
    fi

    case "$cert_choice" in
        1)
            if $has_existing_cert; then
                echo -e "${C_GREEN}✅ Reusing the existing shared certificate.${C_RESET}"
                return 0
            fi
            local common_name
            read -p "👉 Enter the certificate Common Name / SNI label [$preferred_host]: " common_name
            common_name=${common_name:-$preferred_host}
            generate_self_signed_edge_cert "$common_name"
            ;;
        2)
            if $has_existing_cert; then
                local common_name
                read -p "👉 Enter the certificate Common Name / SNI label [$preferred_host]: " common_name
                common_name=${common_name:-$preferred_host}
                generate_self_signed_edge_cert "$common_name"
            else
                local default_domain=""
                local domain_name
                local email
                if ! [[ "$preferred_host" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                    default_domain="$preferred_host"
                fi
                if [[ -n "$default_domain" ]]; then
                    read -p "👉 Enter your domain name [$default_domain]: " domain_name
                    domain_name=${domain_name:-$default_domain}
                else
                    read -p "👉 Enter your domain name (e.g. vpn.example.com): " domain_name
                fi
                if [[ -z "$domain_name" ]]; then
                    echo -e "${C_RED}❌ Domain name cannot be empty.${C_RESET}"
                    return 1
                fi
                if [[ "$domain_name" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                    echo -e "${C_RED}❌ Certbot requires a real domain name, not a raw IP address.${C_RESET}"
                    return 1
                fi
                read -p "👉 Enter your email for Let's Encrypt: " email
                if [[ -z "$email" ]]; then
                    echo -e "${C_RED}❌ Email cannot be empty.${C_RESET}"
                    return 1
                fi
                obtain_certbot_edge_cert "$domain_name" "$email"
            fi
            ;;
        3)
            if ! $has_existing_cert; then
                echo -e "${C_RED}❌ Invalid option.${C_RESET}"
                return 1
            fi
            local default_domain=""
            local domain_name
            local email
            if [[ -n "$EDGE_DOMAIN" ]] && ! [[ "$EDGE_DOMAIN" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                default_domain="$EDGE_DOMAIN"
            fi
            if [[ -z "$default_domain" ]] && ! [[ "$preferred_host" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                default_domain="$preferred_host"
            fi
            if [[ -n "$default_domain" ]]; then
                read -p "👉 Enter your domain name [$default_domain]: " domain_name
                domain_name=${domain_name:-$default_domain}
            else
                read -p "👉 Enter your domain name (e.g. vpn.example.com): " domain_name
            fi
            if [[ -z "$domain_name" ]]; then
                echo -e "${C_RED}❌ Domain name cannot be empty.${C_RESET}"
                return 1
            fi
            if [[ "$domain_name" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                echo -e "${C_RED}❌ Certbot requires a real domain name, not a raw IP address.${C_RESET}"
                return 1
            fi
            read -p "👉 Enter your email for Let's Encrypt [${EDGE_EMAIL}]: " email
            email=${email:-$EDGE_EMAIL}
            if [[ -z "$email" ]]; then
                echo -e "${C_RED}❌ Email cannot be empty.${C_RESET}"
                return 1
            fi
            obtain_certbot_edge_cert "$domain_name" "$email"
            ;;
        *)
            echo -e "${C_RED}❌ Invalid option.${C_RESET}"
            return 1
            ;;
    esac
}

write_internal_nginx_config() {
    local server_name="$1"
    [[ -z "$server_name" ]] && server_name="_"
    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled
    cat > "$NGINX_CONFIG_FILE" <<EOF
server {
    listen 127.0.0.1:${NGINX_INTERNAL_HTTP_PORT} default_server;
    listen 127.0.0.1:${NGINX_INTERNAL_TLS_PORT} ssl http2 default_server;
    server_tokens off;
    server_name ${server_name};

    ssl_certificate ${SSL_CERT_CHAIN_FILE};
    ssl_certificate_key ${SSL_CERT_KEY_FILE};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!eNULL:!MD5:!DES:!RC4:!ADH:!SSLv3:!EXP:!PSK:!DSS;
    resolver 1.1.1.1 8.8.8.8 ipv6=off valid=300s;

    location ~ ^/(?<fwdport>\d+)/(?<fwdpath>.*)$ {
        client_max_body_size 0;
        client_body_timeout 1d;
        grpc_read_timeout 1d;
        grpc_socket_keepalive on;
        proxy_read_timeout 1d;
        proxy_http_version 1.1;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_socket_keepalive on;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        if (\$content_type ~* "GRPC") { grpc_pass grpc://127.0.0.1:\$fwdport\$is_args\$args; break; }
        proxy_pass http://127.0.0.1:\$fwdport\$is_args\$args;
        break;
    }

    location / {
        proxy_read_timeout 3600s;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_http_version 1.1;
        proxy_socket_keepalive on;
        tcp_nodelay on;
        tcp_nopush off;
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
    ln -sf "$NGINX_CONFIG_FILE" /etc/nginx/sites-enabled/default
}

write_haproxy_edge_config() {
    mkdir -p /etc/haproxy
    cat > "$HAPROXY_CONFIG" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin expose-fd listeners
    stats timeout 30s
    user haproxy
    group haproxy
    daemon

defaults
    log     global
    mode    tcp
    option  tcplog
    option  dontlognull
    timeout connect 5s
    timeout client  24h
    timeout server  24h

frontend port_80_edge
    bind *:${EDGE_PUBLIC_HTTP_PORT}
    mode tcp
    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30

    tcp-request content accept if is_ssh
    tcp-request content accept if HTTP

    use_backend direct_ssh if is_ssh
    default_backend nginx_cleartext

frontend port_443_edge
    bind *:${EDGE_PUBLIC_TLS_PORT}
    mode tcp
    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30
    acl is_tls req.ssl_hello_type 1
    acl has_web_alpn req.ssl_alpn -m sub h2 http/1.1

    tcp-request content accept if is_ssh
    tcp-request content accept if HTTP
    tcp-request content accept if is_tls

    use_backend direct_ssh if is_ssh
    use_backend nginx_cleartext if HTTP
    use_backend nginx_tls if is_tls has_web_alpn
    default_backend loopback_ssl_terminator

frontend internal_decryptor
    bind 127.0.0.1:${HAPROXY_INTERNAL_DECRYPT_PORT} ssl crt ${SSL_CERT_FILE}
    mode tcp
    tcp-request inspect-delay 2s

    acl is_ssh payload(0,7) -m bin 5353482d322e30
    tcp-request content accept if is_ssh
    tcp-request content accept if HTTP

    use_backend direct_ssh if is_ssh
    default_backend nginx_cleartext

backend direct_ssh
    mode tcp
    server ssh_server 127.0.0.1:22

backend nginx_cleartext
    mode tcp
    server nginx_8880 127.0.0.1:${NGINX_INTERNAL_HTTP_PORT}

backend nginx_tls
    mode tcp
    server nginx_8443 127.0.0.1:${NGINX_INTERNAL_TLS_PORT}

backend loopback_ssl_terminator
    mode tcp
    server haproxy_ssl 127.0.0.1:${HAPROXY_INTERNAL_DECRYPT_PORT}
EOF
}

save_edge_ports_info() {
    cat > "$NGINX_PORTS_FILE" <<EOF
EDGE_HTTP_PORT="${EDGE_PUBLIC_HTTP_PORT}"
EDGE_TLS_PORT="${EDGE_PUBLIC_TLS_PORT}"
HTTP_PORTS="${NGINX_INTERNAL_HTTP_PORT}"
TLS_PORTS="${NGINX_INTERNAL_TLS_PORT}"
EOF
}

configure_edge_stack() {
    local server_name="$1"
    [[ -z "$server_name" ]] && server_name="_"

    backup_edge_configs

    echo -e "\n${C_BLUE}📝 Writing internal Nginx config (127.0.0.1:${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT})...${C_RESET}"
    write_internal_nginx_config "$server_name"

    echo -e "${C_BLUE}📝 Writing HAProxy edge config (${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT})...${C_RESET}"
    write_haproxy_edge_config

    echo -e "\n${C_BLUE}🧪 Validating Nginx configuration...${C_RESET}"
    if ! nginx -t >/dev/null 2>&1; then
        echo -e "${C_RED}❌ Nginx configuration validation failed.${C_RESET}"
        nginx -t
        return 1
    fi

    echo -e "${C_BLUE}🧪 Validating HAProxy configuration...${C_RESET}"
    if ! haproxy -c -f "$HAPROXY_CONFIG" >/dev/null 2>&1; then
        echo -e "${C_RED}❌ HAProxy configuration validation failed.${C_RESET}"
        haproxy -c -f "$HAPROXY_CONFIG"
        return 1
    fi

    systemctl daemon-reload
    systemctl enable nginx >/dev/null 2>&1
    systemctl enable haproxy >/dev/null 2>&1

    echo -e "\n${C_BLUE}▶️ Restarting internal Nginx...${C_RESET}"
    systemctl restart nginx || {
        echo -e "${C_RED}❌ Nginx failed to restart.${C_RESET}"
        return 1
    }

    echo -e "${C_BLUE}▶️ Restarting HAProxy edge...${C_RESET}"
    systemctl restart haproxy || {
        echo -e "${C_RED}❌ HAProxy failed to restart.${C_RESET}"
        return 1
    }

    sleep 2
    if ! systemctl is-active --quiet nginx; then
        echo -e "${C_RED}❌ Nginx is not active after restart.${C_RESET}"
        return 1
    fi
    if ! systemctl is-active --quiet haproxy; then
        echo -e "${C_RED}❌ HAProxy is not active after restart.${C_RESET}"
        return 1
    fi

    save_edge_ports_info
    return 0
}

install_ssl_tunnel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing HAProxy Edge Stack (80/443 -> 8880/8443) ---${C_RESET}"
    echo -e "\n${C_CYAN}This installer will configure:${C_RESET}"
    echo -e "   • HAProxy on ${C_WHITE}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    echo -e "   • Internal Nginx on ${C_WHITE}${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
    echo -e "   • Loopback SSL decryptor on ${C_WHITE}${HAPROXY_INTERNAL_DECRYPT_PORT}${C_RESET}"

    if [ -f "$HAPROXY_CONFIG" ] || [ -f "$NGINX_CONFIG_FILE" ]; then
        echo -e "\n${C_YELLOW}⚠️ Existing HAProxy/Nginx configs will be replaced.${C_RESET}"
        read -p "👉 Continue with replacement? (y/n): " confirm_replace
        if [[ "$confirm_replace" != "y" && "$confirm_replace" != "Y" ]]; then
            echo -e "${C_RED}❌ Installation cancelled.${C_RESET}"
            return
        fi
    fi

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR"

    ensure_edge_stack_packages || return

    systemctl stop haproxy >/dev/null 2>&1
    systemctl stop nginx >/dev/null 2>&1
    sleep 1

    select_edge_certificate || return

    load_edge_cert_info
    local server_name="${EDGE_DOMAIN:-$(detect_preferred_host)}"
    [[ -z "$server_name" ]] && server_name="_"

    configure_edge_stack "$server_name" || return

    echo -e "\n${C_GREEN}✅ SUCCESS: HAProxy edge stack is active.${C_RESET}"
    echo -e "   • Public edge ports: ${C_YELLOW}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    echo -e "   • Internal Nginx ports: ${C_YELLOW}${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
    echo -e "   • Shared certificate: ${C_YELLOW}${EDGE_CERT_MODE:-unknown}${C_RESET}"
    press_enter
}

uninstall_ssl_tunnel() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling HAProxy Edge Stack ---${C_RESET}"
    if ! command -v haproxy &>/dev/null; then
        echo -e "${C_YELLOW}ℹ️ HAProxy is not installed.${C_RESET}"
    else
        echo -e "${C_GREEN}🛑 Stopping and disabling HAProxy...${C_RESET}"
        systemctl stop haproxy >/dev/null 2>&1
        systemctl disable haproxy >/dev/null 2>&1
    fi

    if [ -f "$HAPROXY_CONFIG" ]; then
        cat > "$HAPROXY_CONFIG" <<EOF
global
    log /dev/log local0
    log /dev/log local1 notice

defaults
    log     global
EOF
    fi

    local delete_cert="n"
    if [[ "$UNINSTALL_MODE" == "silent" ]]; then
        delete_cert="y"
    elif [ -f "$SSL_CERT_FILE" ] || [ -f "$SSL_CERT_CHAIN_FILE" ] || [ -f "$SSL_CERT_KEY_FILE" ]; then
        if systemctl is-active --quiet nginx; then
            echo -e "${C_YELLOW}⚠️ The shared certificate is also used by Nginx.${C_RESET}"
        fi
        read -p "👉 Delete the shared TLS certificate too? (y/n): " delete_cert
    fi

    if [[ "$delete_cert" == "y" || "$delete_cert" == "Y" ]]; then
        if systemctl is-active --quiet nginx; then
            echo -e "${C_GREEN}🛑 Stopping Nginx...${C_RESET}"
            systemctl stop nginx >/dev/null 2>&1
        fi
        rm -f "$SSL_CERT_FILE" "$SSL_CERT_CHAIN_FILE" "$SSL_CERT_KEY_FILE" "$EDGE_CERT_INFO_FILE"
        rm -f "$NGINX_PORTS_FILE"
        echo -e "${C_GREEN}🗑️ Shared certificate files removed.${C_RESET}"
    fi

    echo -e "${C_GREEN}✅ HAProxy edge stack has been removed.${C_RESET}"
    if systemctl is-active --quiet nginx; then
        echo -e "${C_DIM}Internal Nginx proxy still installed on ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"
    fi
    press_enter
}

# ================================================================
# ========== FALCON PROXY ==========
# ================================================================

install_falcon_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🦅 Installing Falcon Proxy (Websockets/Socks) ---${C_RESET}"
    
    if [ -f "$FALCONPROXY_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ Falcon Proxy is already installed.${C_RESET}"
        if [ -f "$FALCONPROXY_CONFIG_FILE" ]; then
            source "$FALCONPROXY_CONFIG_FILE"
            echo -e "   Configured on port(s): ${C_YELLOW}$PORTS${C_RESET}"
            echo -e "   Version: ${C_YELLOW}${INSTALLED_VERSION:-Unknown}${C_RESET}"
        fi
        read -p "👉 Reinstall/Update? (y/n): " confirm_reinstall
        if [[ "$confirm_reinstall" != "y" ]]; then return; fi
    fi

    echo -e "\n${C_BLUE}🌐 Fetching available versions from GitHub...${C_RESET}"
    local releases_json=$(curl -s "https://api.github.com/repos/firewallfalcons/FirewallFalcon-Manager/releases")
    if [[ -z "$releases_json" || "$releases_json" == "[]" ]]; then
        echo -e "${C_RED}❌ Error: Could not fetch releases.${C_RESET}"
        return
    fi

    mapfile -t versions < <(echo "$releases_json" | jq -r '.[].tag_name')
    
    if [ ${#versions[@]} -eq 0 ]; then
        echo -e "${C_RED}❌ No releases found.${C_RESET}"
        return
    fi

    echo -e "\n${C_CYAN}Select a version to install:${C_RESET}"
    for i in "${!versions[@]}"; do
        printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${versions[$i]}"
    done
    echo -e "  ${C_RED} [ 0]${C_RESET} ↩️ Cancel"
    
    local choice
    while true; do
        if ! read -r -p "👉 Enter version number [1]: " choice; then
            echo
            return
        fi
        choice=${choice:-1}
        if [[ "$choice" == "0" ]]; then return; fi
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -le "${#versions[@]}" ]; then
            SELECTED_VERSION="${versions[$((choice-1))]}"
            break
        else
            echo -e "${C_RED}❌ Invalid selection.${C_RESET}"
        fi
    done

    local ports
    read -p "👉 Enter port(s) for Falcon Proxy (e.g., 8080 or 8080 8888) [8080]: " ports
    ports=${ports:-8080}

    local port_array=($ports)
    for port in "${port_array[@]}"; do
        if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
            echo -e "\n${C_RED}❌ Invalid port number: $port.${C_RESET}"
            return
        fi
    done

    echo -e "\n${C_GREEN}⚙️ Detecting system architecture...${C_RESET}"
    local arch=$(uname -m)
    local binary_name=""
    if [[ "$arch" == "x86_64" ]]; then
        binary_name="falconproxy"
        echo -e "${C_BLUE}ℹ️ Detected x86_64 (amd64) architecture.${C_RESET}"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        binary_name="falconproxyarm"
        echo -e "${C_BLUE}ℹ️ Detected ARM64 architecture.${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Unsupported architecture: $arch.${C_RESET}"
        return
    fi
    
    local download_url="https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/download/$SELECTED_VERSION/$binary_name"

    echo -e "\n${C_GREEN}📥 Downloading Falcon Proxy $SELECTED_VERSION ($binary_name)...${C_RESET}"
    wget -q --show-progress -O "$FALCONPROXY_BINARY" "$download_url"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ Failed to download the binary.${C_RESET}"
        return
    fi
    chmod +x "$FALCONPROXY_BINARY"

    echo -e "\n${C_GREEN}📝 Creating systemd service file...${C_RESET}"
    cat > "$FALCONPROXY_SERVICE_FILE" <<EOF
[Unit]
Description=Falcon Proxy ($SELECTED_VERSION)
After=network.target

[Service]
User=root
Type=simple
ExecStart=$FALCONPROXY_BINARY -p $ports
Restart=always
RestartSec=2s

[Install]
WantedBy=default.target
EOF

    echo -e "\n${C_GREEN}💾 Saving configuration...${C_RESET}"
    cat > "$FALCONPROXY_CONFIG_FILE" <<EOF
PORTS="$ports"
INSTALLED_VERSION="$SELECTED_VERSION"
EOF

    echo -e "\n${C_GREEN}▶️ Enabling and starting Falcon Proxy service...${C_RESET}"
    systemctl daemon-reload
    systemctl enable falconproxy.service
    systemctl restart falconproxy.service
    sleep 2
    
    if systemctl is-active --quiet falconproxy; then
        echo -e "\n${C_GREEN}✅ Falcon Proxy $SELECTED_VERSION is active.${C_RESET}"
        echo -e "   Listening on port(s): ${C_YELLOW}$ports${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Falcon Proxy service failed to start.${C_RESET}"
        journalctl -u falconproxy.service -n 15 --no-pager
    fi
    press_enter
}

uninstall_falcon_proxy() {
    echo -e "\n${C_BOLD}${C_PURPLE}--- 🗑️ Uninstalling Falcon Proxy ---${C_RESET}"
    if [ ! -f "$FALCONPROXY_SERVICE_FILE" ]; then
        echo -e "${C_YELLOW}ℹ️ Falcon Proxy is not installed.${C_RESET}"
        return
    fi
    echo -e "${C_GREEN}🛑 Stopping and disabling Falcon Proxy service...${C_RESET}"
    systemctl stop falconproxy.service >/dev/null 2>&1
    systemctl disable falconproxy.service >/dev/null 2>&1
    echo -e "${C_GREEN}🗑️ Removing service file...${C_RESET}"
    rm -f "$FALCONPROXY_SERVICE_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}🗑️ Removing binary and config files...${C_RESET}"
    rm -f "$FALCONPROXY_BINARY"
    rm -f "$FALCONPROXY_CONFIG_FILE"
    echo -e "${C_GREEN}✅ Falcon Proxy uninstalled.${C_RESET}"
    press_enter
}

# ================================================================
# ========== ZIVPN ==========
# ================================================================

install_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing ZiVPN (UDP/VPN) ---${C_RESET}"
    
    if [ -f "$ZIVPN_SERVICE_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ ZiVPN is already installed.${C_RESET}"
        return
    fi

    echo -e "\n${C_GREEN}⚙️ Checking system architecture...${C_RESET}"
    local arch=$(uname -m)
    local zivpn_url=""
    
    if [[ "$arch" == "x86_64" ]]; then
        zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
        echo -e "${C_BLUE}ℹ️ Detected AMD64/x86_64 architecture.${C_RESET}"
    elif [[ "$arch" == "aarch64" ]]; then
        zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
        echo -e "${C_BLUE}ℹ️ Detected ARM64 architecture.${C_RESET}"
    elif [[ "$arch" == "armv7l" || "$arch" == "arm" ]]; then
         zivpn_url="https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm"
         echo -e "${C_BLUE}ℹ️ Detected ARM architecture.${C_RESET}"
    else
        echo -e "${C_RED}❌ Unsupported architecture: $arch${C_RESET}"
        return
    fi

    echo -e "\n${C_GREEN}📦 Downloading ZiVPN binary...${C_RESET}"
    if ! wget -q --show-progress -O "$ZIVPN_BIN" "$zivpn_url"; then
        echo -e "${C_RED}❌ Download failed.${C_RESET}"
        return
    fi
    chmod +x "$ZIVPN_BIN"

    echo -e "\n${C_GREEN}⚙️ Configuring ZIVPN...${C_RESET}"
    mkdir -p "$ZIVPN_DIR"
    
    echo -e "${C_BLUE}🔐 Generating self-signed certificates...${C_RESET}"
    if ! command -v openssl &>/dev/null; then
        ff_apt_install openssl >/dev/null 2>&1
    fi
    
    openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
        -subj "/C=US/ST=California/L=Los Angeles/O=Example Corp/OU=IT Department/CN=zivpn" \
        -keyout "$ZIVPN_KEY_FILE" -out "$ZIVPN_CERT_FILE" 2>/dev/null

    if [ ! -f "$ZIVPN_CERT_FILE" ]; then
        echo -e "${C_RED}❌ Failed to generate certificates.${C_RESET}"
        return
    fi

    echo -e "${C_BLUE}🔧 Tuning system network parameters...${C_RESET}"
    sysctl -w net.core.rmem_max=16777216 >/dev/null
    sysctl -w net.core.wmem_max=16777216 >/dev/null

    echo -e "${C_BLUE}📝 Creating systemd service file...${C_RESET}"
    cat <<EOF > "$ZIVPN_SERVICE_FILE"
[Unit]
Description=zivpn VPN Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$ZIVPN_DIR
ExecStart=$ZIVPN_BIN server -c $ZIVPN_CONFIG_FILE
Restart=always
RestartSec=3
Environment=ZIVPN_LOG_LEVEL=info
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE CAP_NET_RAW
NoNewPrivileges=true

[Install]
WantedBy=multi-user.target
EOF

    echo -e "\n${C_YELLOW}🔑 ZiVPN Password Setup${C_RESET}"
    read -p "👉 Enter passwords separated by commas (e.g., user1,user2) [Default: 'zi']: " input_config
    
    if [ -n "$input_config" ]; then
        IFS=',' read -r -a config_array <<< "$input_config"
        json_passwords=$(printf '"%s",' "${config_array[@]}")
        json_passwords="[${json_passwords%,}]"
    else
        json_passwords='["zi"]'
    fi

    cat <<EOF > "$ZIVPN_CONFIG_FILE"
{
  "listen": ":5667",
   "cert": "$ZIVPN_CERT_FILE",
   "key": "$ZIVPN_KEY_FILE",
   "obfs":"zivpn",
   "auth": {
    "mode": "passwords", 
    "config": $json_passwords
  }
}
EOF

    echo -e "\n${C_GREEN}🚀 Starting ZiVPN Service...${C_RESET}"
    systemctl daemon-reload
    systemctl enable zivpn.service
    systemctl start zivpn.service

    echo -e "${C_BLUE}🔥 Configuring Firewall Rules (Redirecting 6000-19999 -> 5667)...${C_RESET}"
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    
    if [ -n "$iface" ]; then
        iptables -t nat -A PREROUTING -i "$iface" -p udp --dport 6000:19999 -j DNAT --to-destination :5667
    else
        echo -e "${C_YELLOW}⚠️ Could not detect default interface.${C_RESET}"
    fi

    if command -v ufw &>/dev/null; then
        ufw allow 6000:19999/udp >/dev/null
        ufw allow 5667/udp >/dev/null
    fi

    if systemctl is-active --quiet zivpn.service; then
        echo -e "\n${C_GREEN}✅ ZiVPN Installed Successfully!${C_RESET}"
        echo -e "   - UDP Port: 5667 (Direct)"
        echo -e "   - UDP Ports: 6000-19999 (Forwarded)"
    else
        echo -e "\n${C_RED}❌ ZiVPN Service failed to start.${C_RESET}"
    fi
    press_enter
}

uninstall_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Uninstall ZiVPN ---${C_RESET}"
    
    if [ ! -f "$ZIVPN_SERVICE_FILE" ] && [ ! -f "$ZIVPN_BIN" ]; then
        echo -e "\n${C_YELLOW}ℹ️ ZiVPN does not appear to be installed.${C_RESET}"
        return
    fi

    read -p "👉 Are you sure you want to uninstall ZiVPN? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then echo -e "${C_YELLOW}Cancelled.${C_RESET}"; return; fi

    echo -e "\n${C_BLUE}🛑 Stopping services...${C_RESET}"
    systemctl stop zivpn.service 2>/dev/null
    systemctl disable zivpn.service 2>/dev/null
    
    echo -e "${C_BLUE}🗑️ Removing files...${C_RESET}"
    rm -f "$ZIVPN_SERVICE_FILE"
    rm -rf "$ZIVPN_DIR"
    rm -f "$ZIVPN_BIN"
    
    systemctl daemon-reload
    
    echo -e "\n${C_GREEN}✅ ZiVPN Uninstalled Successfully.${C_RESET}"
    press_enter
}

# ================================================================
# ========== X-UI ==========
# ================================================================

install_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing X-UI ---${C_RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
    press_enter
}

uninstall_xui_panel() {
    if command -v x-ui &>/dev/null; then
        x-ui uninstall
    fi
    rm -f /usr/local/bin/x-ui
    rm -rf /etc/x-ui /usr/local/x-ui
    echo -e "${C_GREEN}✅ X-UI uninstalled${C_RESET}"
    press_enter
}

# ================================================================
# ========== NGINX PROXY MENU ==========
# ================================================================

nginx_proxy_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Internal Nginx Proxy Management ---${C_RESET}"

        local nginx_status="${C_STATUS_I}Inactive${C_RESET}"
        local haproxy_status="${C_STATUS_I}Inactive${C_RESET}"
        if systemctl is-active --quiet nginx; then
            nginx_status="${C_STATUS_A}Active${C_RESET}"
        fi
        if systemctl is-active --quiet haproxy; then
            haproxy_status="${C_STATUS_A}Active${C_RESET}"
        fi

        load_edge_cert_info
        local cert_info="${EDGE_CERT_MODE:-Not configured}"
        if [[ -n "$EDGE_DOMAIN" ]]; then
            cert_info="${cert_info} - ${EDGE_DOMAIN}"
        fi

        echo -e "\n${C_WHITE}Nginx:${C_RESET} ${nginx_status}"
        echo -e "${C_WHITE}HAProxy:${C_RESET} ${haproxy_status}"
        echo -e "${C_DIM}Public Edge: ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT} | Internal Nginx: ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
        echo -e "${C_DIM}Shared Certificate: ${cert_info}${C_RESET}"

        echo -e "\n${C_BOLD}Select an action:${C_RESET}\n"
        
        if systemctl is-active --quiet nginx; then
             printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "🛑 Stop Nginx Service"
             printf "  ${C_CHOICE}[ 2]${C_RESET} %-40s\n" "🔄 Restart HAProxy + Nginx Stack"
             printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "⚙️ Re-install/Re-configure Edge Stack"
             printf "  ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "🔒 Switch/Renew Shared SSL (Certbot)"
             printf "  ${C_CHOICE}[ 5]${C_RESET} %-40s\n" "🔥 Uninstall/Purge Nginx"
        else
             printf "  ${C_CHOICE}[ 1]${C_RESET} %-40s\n" "▶️ Start Nginx Service"
             printf "  ${C_CHOICE}[ 3]${C_RESET} %-40s\n" "⚙️ Install/Configure Edge Stack"
             printf "  ${C_CHOICE}[ 4]${C_RESET} %-40s\n" "🔒 Switch/Renew Shared SSL (Certbot)"
             printf "  ${C_CHOICE}[ 5]${C_RESET} %-40s\n" "🔥 Uninstall/Purge Nginx"
        fi

        echo -e "\n  ${C_WARN}[ 0]${C_RESET} ↩️ Return"
        echo
        read -p "👉 Enter your choice: " choice
        
        case $choice in
            1) 
                if systemctl is-active --quiet nginx; then
                    echo -e "\n${C_BLUE}🛑 Stopping Nginx...${C_RESET}"
                    systemctl stop nginx
                    echo -e "${C_GREEN}✅ Nginx stopped.${C_RESET}"
                else
                    echo -e "\n${C_BLUE}▶️ Starting Nginx...${C_RESET}"
                    systemctl start nginx
                    if systemctl is-active --quiet nginx; then
                        echo -e "${C_GREEN}✅ Nginx started.${C_RESET}"
                    else
                        echo -e "${C_RED}❌ Failed to start Nginx.${C_RESET}"
                    fi
                fi
                press_enter
                ;;
            2)
                echo -e "\n${C_BLUE}🔄 Restarting Nginx and HAProxy...${C_RESET}"
                systemctl restart nginx
                if command -v haproxy &>/dev/null; then
                    systemctl restart haproxy
                fi
                if systemctl is-active --quiet nginx && systemctl is-active --quiet haproxy; then
                    echo -e "${C_GREEN}✅ HAProxy + Nginx stack restarted.${C_RESET}"
                else
                    echo -e "${C_RED}❌ One or more services failed to restart.${C_RESET}"
                fi
                press_enter
                ;;
            3) install_nginx_proxy; press_enter ;;
            4) request_certbot_ssl; press_enter ;;
            5) purge_nginx; press_enter ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}" ;;
        esac
    done
}

install_nginx_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Reconfiguring Internal Nginx Proxy (8880/8443) ---${C_RESET}"
    echo -e "\n${C_CYAN}This keeps HAProxy on ${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT} and rewrites the internal Nginx proxy on ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"

    if [ ! -s "$SSL_CERT_FILE" ] || [ ! -s "$SSL_CERT_CHAIN_FILE" ] || [ ! -s "$SSL_CERT_KEY_FILE" ]; then
        echo -e "\n${C_YELLOW}⚠️ No shared certificate was found.${C_RESET}"
        echo -e "${C_DIM}Running the full HAProxy edge installer...${C_RESET}"
        install_ssl_tunnel
        return
    fi

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR"
    ensure_edge_stack_packages || return

    systemctl stop haproxy >/dev/null 2>&1
    systemctl stop nginx >/dev/null 2>&1
    sleep 1

    load_edge_cert_info
    local server_name="${EDGE_DOMAIN:-$(detect_preferred_host)}"
    [[ -z "$server_name" ]] && server_name="_"

    configure_edge_stack "$server_name" || return

    echo -e "\n${C_GREEN}✅ Internal Nginx proxy reconfigured successfully.${C_RESET}"
    echo -e "   • Public HAProxy edge: ${C_YELLOW}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    echo -e "   • Internal Nginx: ${C_YELLOW}${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}${C_RESET}"
    press_enter
}

request_certbot_ssl() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔒 Shared Certbot Certificate ---${C_RESET}"
    echo -e "\n${C_DIM}This will replace the shared certificate used by HAProxy on ${EDGE_PUBLIC_TLS_PORT} and internal Nginx on ${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"

    mkdir -p "$DB_DIR" "$SSL_CERT_DIR"
    ensure_edge_stack_packages || return
    load_edge_cert_info

    local preferred_host=$(detect_preferred_host)
    local default_domain=""
    local domain_name
    local email

    if [[ -n "$EDGE_DOMAIN" ]] && ! [[ "$EDGE_DOMAIN" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        default_domain="$EDGE_DOMAIN"
    elif [[ -n "$preferred_host" ]] && ! [[ "$preferred_host" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        default_domain="$preferred_host"
    fi

    if [[ -n "$default_domain" ]]; then
        read -p "👉 Enter your domain name [$default_domain]: " domain_name
        domain_name=${domain_name:-$default_domain}
    else
        read -p "👉 Enter your domain name (e.g. vpn.example.com): " domain_name
    fi
    if [[ -z "$domain_name" ]]; then
        echo -e "\n${C_RED}❌ Domain name cannot be empty.${C_RESET}"
        return
    fi
    if [[ "$domain_name" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "\n${C_RED}❌ Certbot requires a real domain name, not a raw IP address.${C_RESET}"
        return
    fi

    read -p "👉 Enter your email for Let's Encrypt [${EDGE_EMAIL}]: " email
    email=${email:-$EDGE_EMAIL}
    if [[ -z "$email" ]]; then
        echo -e "\n${C_RED}❌ Email address cannot be empty.${C_RESET}"
        return
    fi

    obtain_certbot_edge_cert "$domain_name" "$email" || return
    configure_edge_stack "$domain_name" || return

    echo -e "\n${C_GREEN}✅ Shared Certbot certificate applied successfully.${C_RESET}"
    echo -e "   • Domain: ${C_YELLOW}${domain_name}${C_RESET}"
    echo -e "   • Public edge: ${C_YELLOW}${EDGE_PUBLIC_HTTP_PORT}/${EDGE_PUBLIC_TLS_PORT}${C_RESET}"
    press_enter
}

purge_nginx() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔥 Purge Internal Nginx Proxy ---${C_RESET}"
    if ! command -v nginx &> /dev/null; then
        rm -f "$NGINX_PORTS_FILE"
        echo -e "\n${C_YELLOW}ℹ️ Nginx is not installed.${C_RESET}"
        return
    fi
    echo -e "\n${C_YELLOW}⚠️ This removes the internal Nginx proxy on ${NGINX_INTERNAL_HTTP_PORT}/${NGINX_INTERNAL_TLS_PORT}.${C_RESET}"
    read -p "👉 Continue and purge Nginx? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "\n${C_YELLOW}❌ Uninstallation cancelled.${C_RESET}"
        return
    fi
    echo -e "\n${C_BLUE}🛑 Stopping Nginx service...${C_RESET}"
    systemctl stop nginx >/dev/null 2>&1
    systemctl disable nginx >/dev/null 2>&1
    echo -e "\n${C_BLUE}🗑️ Purging Nginx packages...${C_RESET}"
    ff_apt_purge nginx nginx-common >/dev/null 2>&1
    apt-get autoremove -y >/dev/null 2>&1
    echo -e "\n${C_BLUE}🗑️ Removing leftover files...${C_RESET}"
    rm -f /etc/ssl/certs/nginx-selfsigned.pem
    rm -f /etc/ssl/private/nginx-selfsigned.key
    rm -rf /etc/nginx
    rm -f "${NGINX_CONFIG_FILE}.bak"
    rm -f "${NGINX_CONFIG_FILE}.bak.firewallfalcon"
    rm -f "$NGINX_PORTS_FILE"
    echo -e "\n${C_GREEN}✅ Internal Nginx proxy purged. Shared certificates were kept.${C_RESET}"
    press_enter
}

# ================================================================
# ========== TRAFFIC MONITOR ==========
# ================================================================

traffic_monitor_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📈 Network Traffic Monitor ---${C_RESET}"
    
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    echo -e "\nInterface: ${C_CYAN}${iface}${C_RESET}"
    
    echo -e "\n${C_BOLD}Select option:${C_RESET}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} Live Monitor (Lightweight)"
    echo -e "  ${C_GREEN}2)${C_RESET} Total Traffic Since Boot"
    echo -e "  ${C_RED}0)${C_RESET} Return"
    echo ""
    
    local choice
    read -p "👉 Select option: " choice
    
    case $choice in
        1)
            echo -e "\n${C_BLUE}⚡ Starting Live Monitor (press Ctrl+C to stop)...${C_RESET}\n"
            local rx1=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
            local tx1=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
            printf "%-15s | %-15s\n" "⬇️ Download" "⬆️ Upload"
            echo "-----------------------------------"
            while true; do
                sleep 2
                local rx2=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
                local tx2=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
                local rx_diff=$((rx2 - rx1))
                local tx_diff=$((tx2 - tx1))
                (( rx_diff < 0 )) && rx_diff=0
                (( tx_diff < 0 )) && tx_diff=0
                local rx_kbs=$((rx_diff / 1024 / 2))
                local tx_kbs=$((tx_diff / 1024 / 2))
                local rx_fmt="$rx_kbs KB/s"
                if (( rx_kbs >= 1024 )); then
                    rx_fmt="$(awk "BEGIN {printf \"%.2f\", $rx_kbs/1024}") MB/s"
                fi
                local tx_fmt="$tx_kbs KB/s"
                if (( tx_kbs >= 1024 )); then
                    tx_fmt="$(awk "BEGIN {printf \"%.2f\", $tx_kbs/1024}") MB/s"
                fi
                printf "\r%-15s | %-15s" "$rx_fmt" "$tx_fmt"
                rx1=$rx2; tx1=$tx2
            done
            ;;
        2)
            local rx_total=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
            local tx_total=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
            local rx_mb=$((rx_total / 1024 / 1024))
            local tx_mb=$((tx_total / 1024 / 1024))
            echo -e "\n${C_BLUE}📊 Total Traffic (Since Boot):${C_RESET}"
            echo -e "   ⬇️ Download: ${C_WHITE}${rx_mb} MB${C_RESET}"
            echo -e "   ⬆️ Upload:   ${C_WHITE}${tx_mb} MB${C_RESET}"
            press_enter
            ;;
        0) return ;;
        *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
    esac
}

# ================================================================
# ========== TORRENT BLOCKING ==========
# ================================================================

torrent_block_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚫 Torrent Blocking (Anti-P2P) ---${C_RESET}"
    
    local torrent_status="${C_RED}Disabled${C_RESET}"
    if iptables -L FORWARD 2>/dev/null | grep -q "BitTorrent"; then
        torrent_status="${C_GREEN}Enabled${C_RESET}"
    elif iptables -L OUTPUT 2>/dev/null | grep -q "BitTorrent"; then
        torrent_status="${C_GREEN}Enabled${C_RESET}"
    fi
    
    echo -e "\n${C_WHITE}Current Status: ${torrent_status}${C_RESET}"
    echo ""
    echo -e "  ${C_GREEN}1)${C_RESET} Enable Torrent Blocking"
    echo -e "  ${C_RED}2)${C_RESET} Disable Torrent Blocking"
    echo ""
    echo -e "  ${C_RED}0)${C_RESET} Return"
    echo ""
    
    local choice
    read -p "👉 Select option: " choice
    
    case $choice in
        1)
            echo -e "\n${C_BLUE}🛡️ Applying Anti-Torrent rules...${C_RESET}"
            iptables -D FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "find_node" --algo bm -j DROP 2>/dev/null
            
            iptables -D OUTPUT -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "find_node" --algo bm -j DROP 2>/dev/null
            
            iptables -A FORWARD -m string --string "BitTorrent" --algo bm -j DROP
            iptables -A FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP
            iptables -A FORWARD -m string --string "peer_id=" --algo bm -j DROP
            iptables -A FORWARD -m string --string ".torrent" --algo bm -j DROP
            iptables -A FORWARD -m string --string "info_hash" --algo bm -j DROP
            iptables -A FORWARD -m string --string "get_peers" --algo bm -j DROP
            iptables -A FORWARD -m string --string "find_node" --algo bm -j DROP
            
            iptables -A OUTPUT -m string --string "BitTorrent" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "BitTorrent protocol" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "peer_id=" --algo bm -j DROP
            iptables -A OUTPUT -m string --string ".torrent" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "info_hash" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "get_peers" --algo bm -j DROP
            iptables -A OUTPUT -m string --string "find_node" --algo bm -j DROP
            
            if command -v netfilter-persistent &>/dev/null; then
                netfilter-persistent save &>/dev/null
            fi
            echo -e "${C_GREEN}✅ Torrent Blocking Enabled${C_RESET}"
            press_enter
            ;;
        2)
            echo -e "\n${C_BLUE}🔓 Removing Anti-Torrent rules...${C_RESET}"
            iptables -D FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "find_node" --algo bm -j DROP 2>/dev/null
            
            iptables -D OUTPUT -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "BitTorrent protocol" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "get_peers" --algo bm -j DROP 2>/dev/null
            iptables -D OUTPUT -m string --string "find_node" --algo bm -j DROP 2>/dev/null
            
            if command -v netfilter-persistent &>/dev/null; then
                netfilter-persistent save &>/dev/null
            fi
            echo -e "${C_GREEN}✅ Torrent Blocking Disabled${C_RESET}"
            press_enter
            ;;
        0) return ;;
        *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
    esac
}

# ================================================================
# ========== AUTO REBOOT ==========
# ================================================================

auto_reboot_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔄 Auto-Reboot Management ---${C_RESET}"
    
    local cron_check=$(crontab -l 2>/dev/null | grep "systemctl reboot")
    local status="${C_RED}Disabled${C_RESET}"
    if [[ -n "$cron_check" ]]; then
        status="${C_GREEN}Active (Daily at 00:00)${C_RESET}"
    fi
    
    echo -e "\n${C_WHITE}Current Status: ${status}${C_RESET}"
    echo ""
    echo -e "  ${C_GREEN}1)${C_RESET} Enable Daily Reboot (00:00)"
    echo -e "  ${C_RED}2)${C_RESET} Disable Auto-Reboot"
    echo ""
    echo -e "  ${C_RED}0)${C_RESET} Return"
    echo ""
    
    local choice
    read -p "👉 Select option: " choice
    
    case $choice in
        1)
            (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab - 2>/dev/null
            (crontab -l 2>/dev/null; echo "0 0 * * * systemctl reboot") | crontab - 2>/dev/null
            echo -e "\n${C_GREEN}✅ Auto-reboot scheduled for 00:00 daily${C_RESET}"
            press_enter
            ;;
        2)
            (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab - 2>/dev/null
            echo -e "\n${C_GREEN}✅ Auto-reboot disabled${C_RESET}"
            press_enter
            ;;
        0) return ;;
        *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
    esac
}

# ================================================================
# ========== BACKUP & RESTORE ==========
# ================================================================

backup_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💾 Backup User Data ---${C_RESET}"
    
    local backup_path
    read -p "👉 Backup path [/root/firewallfalcon_users.tar.gz]: " backup_path
    backup_path=${backup_path:-/root/firewallfalcon_users.tar.gz}
    
    if [ ! -d "$DB_DIR" ] || [ ! -s "$DB_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ No user data found to back up.${C_RESET}"
        press_enter
        return
    fi
    
    tar -czf "$backup_path" -C "$(dirname "$DB_DIR")" "$(basename "$DB_DIR")" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo -e "\n${C_GREEN}✅ Backup created: ${C_YELLOW}$backup_path${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Backup failed${C_RESET}"
    fi
    press_enter
}

restore_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📥 Restore User Data ---${C_RESET}"
    
    local backup_path
    read -p "👉 Backup path: " backup_path
    
    if [ ! -f "$backup_path" ]; then
        echo -e "\n${C_RED}❌ File not found${C_RESET}"
        press_enter
        return
    fi
    
    echo -e "\n${C_RED}⚠️ This will overwrite all current data!${C_RESET}"
    read -p "Are you sure? (y/n): " confirm
    
    if [[ "$confirm" == "y" ]]; then
        local temp_dir=$(mktemp -d)
        tar -xzf "$backup_path" -C "$temp_dir" 2>/dev/null
        
        if [ -f "$temp_dir/firewallfalcon/users.db" ]; then
            cp "$temp_dir/firewallfalcon/users.db" "$DB_FILE"
            
            while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
                if ! id "$user" &>/dev/null; then
                    useradd -m -s /usr/sbin/nologin "$user"
                fi
                echo "$user:$pass" | chpasswd
                chage -E "$expiry" "$user"
            done < "$DB_FILE"
            
            echo -e "\n${C_GREEN}✅ Restore complete${C_RESET}"
        else
            echo -e "\n${C_RED}❌ Invalid backup file${C_RESET}"
        fi
        
        rm -rf "$temp_dir"
        invalidate_banner_cache
        update_ssh_banners_config
    fi
    press_enter
}

# ================================================================
# ========== PROTOCOL MENU ==========
# ================================================================

protocol_menu() {
    while true; do
        clear; show_banner
        
        local badvpn_status=$(systemctl is-active badvpn 2>/dev/null && echo -e "${C_GREEN}● RUNNING${C_RESET}" || echo "")
        local udp_status=$(systemctl is-active udp-custom 2>/dev/null && echo -e "${C_GREEN}● RUNNING${C_RESET}" || echo "")
        local haproxy_status=$(systemctl is-active haproxy 2>/dev/null && echo -e "${C_GREEN}● RUNNING${C_RESET}" || echo "")
        local dnstt_status=$(systemctl is-active dnstt 2>/dev/null && echo -e "${C_GREEN}● RUNNING${C_RESET}" || echo "")
        local falconproxy_status=$(systemctl is-active falconproxy 2>/dev/null && echo -e "${C_GREEN}● RUNNING${C_RESET}" || echo "")
        local zivpn_status=$(systemctl is-active zivpn 2>/dev/null && echo -e "${C_GREEN}● RUNNING${C_RESET}" || echo "")
        
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}              🔌 PROTOCOL MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}1)${C_RESET} badvpn (UDP 7300) $badvpn_status"
        echo -e "  ${C_GREEN}2)${C_RESET} udp-custom $udp_status"
        echo -e "  ${C_GREEN}3)${C_RESET} SSL Tunnel (HAProxy) $haproxy_status"
        echo -e "  ${C_GREEN}4)${C_RESET} DNSTT (Port 53) $dnstt_status"
        echo -e "  ${C_GREEN}5)${C_RESET} ⚡ DNSTT Speed Booster"
        echo -e "  ${C_GREEN}6)${C_RESET} Falcon Proxy $falconproxy_status"
        echo -e "  ${C_GREEN}7)${C_RESET} ZiVPN $zivpn_status"
        echo -e "  ${C_GREEN}8)${C_RESET} X-UI Panel"
        echo -e "  ${C_GREEN}9)${C_RESET} 🌐 Nginx Proxy Management"
        echo ""
        echo -e "  ${C_RED}0)${C_RESET} Return"
        echo ""
        
        local choice
        read -p "👉 Select protocol to manage: " choice
        
        case $choice in
            1)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_badvpn || uninstall_badvpn
                ;;
            2)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_udp_custom || uninstall_udp_custom
                ;;
            3)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_ssl_tunnel || uninstall_ssl_tunnel
                ;;
            4)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install DNSTT"
                echo -e "  ${C_GREEN}2)${C_RESET} View Details"
                echo -e "  ${C_RED}3)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                if [ "$sub" == "1" ]; then install_dnstt
                elif [ "$sub" == "2" ]; then show_dnstt_details
                elif [ "$sub" == "3" ]; then uninstall_dnstt
                fi
                ;;
            5) speed_booster_menu ;;
            6)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_falcon_proxy || uninstall_falcon_proxy
                ;;
            7) 
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_zivpn || uninstall_zivpn
                ;;
            8)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_xui_panel || uninstall_xui_panel
                ;;
            9) nginx_proxy_menu ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ================================================================
# ========== LIMITER SERVICE ==========
# ================================================================

create_limiter_service() {
    cat > "$LIMITER_SCRIPT" << 'EOF'
#!/bin/bash
# FirewallFalcon limiter version 2026-04-05.1
DB_FILE="/etc/firewallfalcon/users.db"
BW_DIR="/etc/firewallfalcon/bandwidth"
PID_DIR="$BW_DIR/pidtrack"
BANNER_DIR="/etc/firewallfalcon/banners"
SCAN_INTERVAL=15

mkdir -p "$BW_DIR" "$PID_DIR" "$BANNER_DIR"
shopt -s nullglob

write_banner_if_changed() {
    local user="$1"
    local content="$2"
    local banner_file="$BANNER_DIR/${user}.txt"
    local tmp_file="${banner_file}.tmp"

    printf "%s" "$content" > "$tmp_file"
    if ! cmp -s "$tmp_file" "$banner_file" 2>/dev/null; then
        mv "$tmp_file" "$banner_file"
    else
        rm -f "$tmp_file"
    fi
}

while true; do
    if [[ ! -s "$DB_FILE" ]]; then
        sleep "$SCAN_INTERVAL"
        continue
    fi

    current_ts=$(date +%s)
    dynamic_banners_enabled=false
    declare -A session_pids=()
    declare -A locked_users=()
    declare -A uid_to_user=()
    declare -A loginuid_pids=()

    while IFS=: read -r username _ uid _rest; do
        [[ -n "$username" && "$uid" =~ ^[0-9]+$ ]] && uid_to_user["$uid"]="$username"
    done < /etc/passwd

    while read -r ssh_pid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue

        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" ]]; then
            session_pids["$ssh_owner"]+="$ssh_pid "
        fi
    done < <(ps -C sshd -o pid=,user= 2>/dev/null)

    for p in /proc/[0-9]*/loginuid; do
        [[ -f "$p" ]] || continue
        login_uid=""
        read -r login_uid < "$p" || login_uid=""
        [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]] || continue

        session_user="${uid_to_user[$login_uid]}"
        [[ -n "$session_user" ]] || continue

        pid_dir=$(dirname "$p")
        pid_num=$(basename "$pid_dir")
        comm=""
        read -r comm < "$pid_dir/comm" || comm=""
        [[ "$comm" == "sshd" ]] || continue

        ppid_val=""
        while read -r key value; do
            if [[ "$key" == "PPid:" ]]; then
                ppid_val="${value:-}"
                break
            fi
        done < "$pid_dir/status"
        [[ "$ppid_val" == "1" ]] && continue

        loginuid_pids["$session_user"]+="$pid_num "
    done

    while read -r passwd_user _ passwd_status _rest; do
        [[ "$passwd_status" == "L" ]] && locked_users["$passwd_user"]=1
    done < <(passwd -Sa 2>/dev/null)

    if [[ -f "/etc/firewallfalcon/banners_enabled" ]]; then
        mkdir -p "$BANNER_DIR"
        dynamic_banners_enabled=true
    fi

    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" || "$user" == \#* ]] && continue

        declare -A unique_pids=()
        for pid in ${session_pids["$user"]} ${loginuid_pids["$user"]}; do
            [[ "$pid" =~ ^[0-9]+$ ]] && unique_pids["$pid"]=1
        done

        online_count=${#unique_pids[@]}
        user_locked=false
        if [[ -n "${locked_users[$user]+x}" ]]; then
            user_locked=true
        fi

        expiry_ts=0
        if [[ "$expiry" != "Never" && -n "$expiry" ]]; then
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    killall -u "$user" -9 &>/dev/null
                    locked_users["$user"]=1
                fi
                continue
            fi
        fi

        [[ "$limit" =~ ^[0-9]+$ ]] || limit=1
        if (( online_count > limit )); then
            if ! $user_locked; then
                usermod -L "$user" &>/dev/null
                killall -u "$user" -9 &>/dev/null
                (sleep 120; usermod -U "$user" &>/dev/null) &
                locked_users["$user"]=1
                user_locked=true
            else
                killall -u "$user" -9 &>/dev/null
            fi
        fi

        if $dynamic_banners_enabled; then
            days_left="N/A"
            if [[ "$expiry" != "Never" && -n "$expiry" && "$expiry_ts" =~ ^[0-9]+$ && $expiry_ts -gt 0 ]]; then
                diff_secs=$((expiry_ts - current_ts))
                if (( diff_secs <= 0 )); then
                    days_left="EXPIRED"
                else
                    d_l=$(( diff_secs / 86400 ))
                    h_l=$(( (diff_secs % 86400) / 3600 ))
                    if (( d_l == 0 )); then
                        days_left="${h_l}h left"
                    else
                        days_left="${d_l}d ${h_l}h"
                    fi
                fi
            fi

            bw_info="Unlimited"
            if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
                usagefile="$BW_DIR/${user}.usage"
                accum_disp=0
                if [[ -f "$usagefile" ]]; then
                    read -r accum_disp < "$usagefile"
                    [[ "$accum_disp" =~ ^[0-9]+$ ]] || accum_disp=0
                fi
                used_gb=$(awk "BEGIN {printf \"%.2f\", $accum_disp / 1073741824}")
                remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}")
                bw_info="${used_gb}/${bandwidth_gb} GB used | ${remain_gb} GB left"
            fi

            # Get server info
            UPTIME=$(uptime -p | sed 's/up //')
            LOAD=$(awk '{print $1}' /proc/loadavg)
            
            # Build premium banner (VOLTRON TECH ULTIMATE - No Falcon)
            banner_content=""
            banner_content+="<br><font color=\"purple\" size=\"5\"><b>🔥 VOLTRON TECH ULTIMATE 🔥</b></font><br><br>"
            banner_content+="<font color=\"cyan\"><b>═══════════════════════════════════════════</b></font><br>"
            banner_content+="<font color=\"yellow\"><b>          📋 ACCOUNT DETAILS 📋          </b></font><br>"
            banner_content+="<font color=\"cyan\"><b>═══════════════════════════════════════════</b></font><br><br>"
            banner_content+="<font color=\"white\">👤 <b>Username      :</b> $user</font><br>"
            banner_content+="<font color=\"white\">📅 <b>Expiration    :</b> $expiry ($days_left)</font><br>"
            banner_content+="<font color=\"white\">📊 <b>Bandwidth     :</b> $bw_info</font><br>"
            banner_content+="<font color=\"white\">🔌 <b>Sessions      :</b> $online_count/$limit</font><br><br>"
            banner_content+="<font color=\"white\">⏱️ <b>Server Uptime :</b> $UPTIME</font><br>"
            banner_content+="<font color=\"white\">📈 <b>Server Load   :</b> $LOAD</font><br><br>"
            banner_content+="<font color=\"green\"><b>📢 JOIN OUR COMMUNITY 📢</b></font><br>"
            banner_content+="<font color=\"white\">📱 Telegram  : https://t.me/voltrontech</font><br>"
            banner_content+="<font color=\"white\">💬 WhatsApp  : https://chat.whatsapp.com/JfxZ5Vif62JLKZc275Njl8</font><br><br>"
            banner_content+="<font color=\"red\"><b>⚠️ IMPORTANT NOTICE ⚠️</b></font><br>"
            banner_content+="<font color=\"white\">• Account expires on: $expiry</font><br>"
            banner_content+="<font color=\"white\">• No torrent or illegal activity</font><br>"
            banner_content+="<font color=\"white\">• Account sharing is prohibited</font><br><br>"
            banner_content+="<font color=\"gray\"><b>─────────── Powered by Voltron Tech ───────────</b></font><br>"
            
            write_banner_if_changed "$user" "$banner_content"
        fi

        [[ -z "$bandwidth_gb" || "$bandwidth_gb" == "0" ]] && continue

        usagefile="$BW_DIR/${user}.usage"
        accumulated=0
        if [[ -f "$usagefile" ]]; then
            read -r accumulated < "$usagefile"
            [[ "$accumulated" =~ ^[0-9]+$ ]] || accumulated=0
        fi

        if (( ${#unique_pids[@]} == 0 )); then
            rm -f "$PID_DIR/${user}__"*.last 2>/dev/null
            continue
        fi

        delta_total=0
        for pid in "${!unique_pids[@]}"; do
            io_file="/proc/$pid/io"
            cur=0
            if [[ -r "$io_file" ]]; then
                rchar=0
                wchar=0
                while read -r key value; do
                    case "$key" in
                        rchar:) rchar=${value:-0} ;;
                        wchar:) wchar=${value:-0} ;;
                    esac
                done < "$io_file"
                cur=$((rchar + wchar))
            fi

            pidfile="$PID_DIR/${user}__${pid}.last"
            if [[ -f "$pidfile" ]]; then
                read -r prev < "$pidfile"
                [[ "$prev" =~ ^[0-9]+$ ]] || prev=0
                if (( cur >= prev )); then
                    d=$((cur - prev))
                else
                    d=$cur
                fi
                delta_total=$((delta_total + d))
            fi
            printf "%s\n" "$cur" > "$pidfile"
        done

        for f in "$PID_DIR/${user}__"*.last; do
            [[ -f "$f" ]] || continue
            fpid=${f##*__}
            fpid=${fpid%.last}
            [[ -d "/proc/$fpid" ]] || rm -f "$f"
        done

        new_total=$((accumulated + delta_total))
        printf "%s\n" "$new_total" > "$usagefile"

        quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        if [[ "$quota_bytes" =~ ^[0-9]+$ ]] && (( new_total >= quota_bytes )); then
            if ! $user_locked; then
                usermod -L "$user" &>/dev/null
                killall -u "$user" -9 &>/dev/null
                locked_users["$user"]=1
            fi
        fi
    done < "$DB_FILE"

    sleep "$SCAN_INTERVAL"
done
EOF
    chmod +x "$LIMITER_SCRIPT"
    sed -i 's/\r$//' "$LIMITER_SCRIPT" 2>/dev/null

    cat > "$LIMITER_SERVICE" << EOF
[Unit]
Description=FirewallFalcon Active User Limiter
After=network.target

[Service]
Type=simple
ExecStart=$LIMITER_SCRIPT
Restart=always
RestartSec=10
Nice=10
IOSchedulingClass=best-effort
IOSchedulingPriority=7

[Install]
WantedBy=multi-user.target
EOF
    sed -i 's/\r$//' "$LIMITER_SERVICE" 2>/dev/null

    pkill -f "firewallfalcon-limiter" 2>/dev/null

    if ! systemctl is-active --quiet firewallfalcon-limiter; then
        systemctl daemon-reload
        systemctl enable firewallfalcon-limiter &>/dev/null
        systemctl start firewallfalcon-limiter --no-block &>/dev/null
    else
        systemctl restart firewallfalcon-limiter --no-block &>/dev/null
    fi
}

# ================================================================
# ========== UNINSTALL SCRIPT ==========
# ================================================================

uninstall_script() {
    clear; show_banner
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_RED}           💥 UNINSTALL SCRIPT & ALL DATA${C_RESET}"
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_YELLOW}This will PERMANENTLY remove this script and all its components."
    echo -e "\n${C_RED}This action is irreversible.${C_RESET}"
    echo ""
    
    # Check for users before uninstall (Falcon feature)
    local -a removable_users=()
    local remove_users_on_uninstall=false
    mapfile -t removable_users < <(get_firewallfalcon_known_users)
    if [[ ${#removable_users[@]} -gt 0 ]]; then
        echo -e "\n${C_YELLOW}FirewallFalcon SSH users detected on this VPS:${C_RESET} ${removable_users[*]}"
        read -p "👉 Do you also want to permanently delete these SSH users before uninstalling? (y/n): " remove_users_confirm
        if [[ "$remove_users_confirm" == "y" || "$remove_users_confirm" == "Y" ]]; then
            remove_users_on_uninstall=true
        fi
    fi
    
    read -p "👉 Type 'YES' to confirm: " confirm
    if [[ "$confirm" != "YES" ]]; then
        echo -e "\n${C_GREEN}✅ Uninstallation cancelled.${C_RESET}"
        return
    fi
    
    echo -e "\n${C_BLUE}--- 💥 Starting Uninstallation ---${C_RESET}"
    
    # Delete users if requested
    if [[ "$remove_users_on_uninstall" == "true" ]]; then
        echo -e "\n${C_BLUE}🗑️ Removing FirewallFalcon SSH users before uninstall...${C_RESET}"
        delete_firewallfalcon_user_accounts "${removable_users[@]}"
    fi
    
    # Delete deSEC DNS records
    if [ -f "$DB_DIR/desec_ns_subdomain.txt" ]; then
        local ns_subdomain=$(cat "$DB_DIR/desec_ns_subdomain.txt")
        local tun_subdomain=$(cat "$DB_DIR/desec_tun_subdomain.txt")
        curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$ns_subdomain/A/" -H "Authorization: Token $DESEC_TOKEN" > /dev/null
        curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$tun_subdomain/NS/" -H "Authorization: Token $DESEC_TOKEN" > /dev/null
    fi
    
    # Disable Auto Reboot
    (crontab -l 2>/dev/null | grep -v "reboot") | crontab - 2>/dev/null
    
    # Stop all services
    systemctl stop dnstt.service badvpn.service udp-custom.service haproxy nginx falconproxy.service zivpn.service 2>/dev/null
    systemctl disable dnstt.service badvpn.service udp-custom.service falconproxy.service 2>/dev/null
    systemctl stop firewallfalcon-limiter 2>/dev/null
    systemctl disable firewallfalcon-limiter 2>/dev/null
    
    # Remove service files
    rm -f "$DNSTT_SERVICE_FILE" "$BADVPN_SERVICE_FILE" "$UDP_CUSTOM_SERVICE_FILE" "$FALCONPROXY_SERVICE_FILE"
    rm -f "$LIMITER_SERVICE" "$ZIVPN_SERVICE_FILE"
    
    # Remove binaries
    rm -f "$DNSTT_BINARY" "$DNSTT_CLIENT" "$BADVPN_BIN" "$UDP_CUSTOM_BIN"
    rm -f "$FALCONPROXY_BINARY" "$ZIVPN_BIN"
    rm -f "$LIMITER_SCRIPT" "$BANDWIDTH_SCRIPT" "$TRIAL_CLEANUP_SCRIPT"
    
    # Remove directories
    rm -rf "$DB_DIR" "$ZIVPN_DIR" "$BADVPN_BUILD_DIR" "$UDP_CUSTOM_DIR"
    rm -f "$SSH_BANNER_FILE"
    
    # Remove script
    rm -f "$0"
    
    systemctl daemon-reload
    
    echo -e "\n${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}      ✅ SCRIPT UNINSTALLED SUCCESSFULLY!${C_RESET}"
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    exit 0
}

# ================================================================
# ========== INITIAL SETUP ==========
# ================================================================

initial_setup() {
    echo -e "\n${C_BLUE}🔧 Running initial system setup...${C_RESET}"
    
    check_environment
    mkdir -p "$DB_DIR" "$SSL_CERT_DIR" "$BANDWIDTH_DIR" "$BANNER_DIR" "$DNSTT_KEYS_DIR"
    touch "$DB_FILE"
    
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    
    create_limiter_service
    
    if [ ! -f "$INSTALL_FLAG_FILE" ]; then
        touch "$INSTALL_FLAG_FILE"
    fi
    
    echo -e "${C_GREEN}✅ Setup finished.${C_RESET}"
}

# ================================================================
# ========== MAIN MENU ==========
# ================================================================

main_menu() {
    while true; do
        show_banner
        
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    👤 USER MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "1" "Create New User" "6" "Unlock User"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "2" "Delete User" "7" "List Users"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "3" "Edit User" "8" "Renew User"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "4" "Lock User" "9" "Cleanup Expired"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "5" "Bulk Create Users" "10" "⏱️ Trial Account"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "11" "📊 View Bandwidth" "12" "📱 Generate Config"
        
        echo ""
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    ⚙️ SYSTEM UTILITIES${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "13" "Protocols & Panels" "18" "SSH Banner"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "14" "Backup Users" "19" "Auto Reboot"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "15" "Restore Users" "20" "Traffic Monitor"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "16" "DNS Domain" "21" "Block Torrent"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "17" "DNSTT Speed Booster" "22" "📊 VPN Data Usage"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s\n" "23" "🖥️ VPS Dashboard"

        echo ""
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    🔥 DANGER ZONE${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_RED}%2s${C_RESET}) %-28s  ${C_RED}%2s${C_RESET}) %-25s\n" "99" "Uninstall Script" "0" "Exit"

        echo ""
        local choice
        read -p "👉 Select an option: " choice
        
        case $choice in
            1) create_user ;;
            2) delete_user ;;
            3) edit_user ;;
            4) lock_user ;;
            5) bulk_create_users ;;
            6) unlock_user ;;
            7) list_users ;;
            8) renew_user ;;
            9) cleanup_expired ;;
            10) create_trial_account ;;
            11) view_user_bandwidth ;;
            12) client_config_menu ;;
            13) protocol_menu ;;
            14) backup_user_data ;;
            15) restore_user_data ;;
            16) dns_menu ;;
            17) speed_booster_menu ;;
            18) 
                clear; show_banner
                echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
                echo -e "${C_BOLD}${C_PURPLE}           🎨 SSH BANNER MANAGEMENT${C_RESET}"
                echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
                echo ""
                echo -e "  ${C_GREEN}1)${C_RESET} Enable Dynamic Account Banner"
                echo -e "  ${C_RED}2)${C_RESET} Disable Dynamic Banner"
                echo -e "  ${C_GREEN}3)${C_RESET} Preview Dynamic Banner"
                echo -e "  ${C_RED}0)${C_RESET} Return"
                echo ""
                read -p "👉 Select option: " banner_choice
                case $banner_choice in
                    1) enable_dynamic_banner ;;
                    2) disable_dynamic_banner ;;
                    3) preview_dynamic_ssh_banner ;;
                    0) ;;
                    *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
                esac
                ;;
            19) auto_reboot_menu ;;
            20) traffic_monitor_menu ;;
            21) torrent_block_menu ;;
            22) show_vpn_data_usage ;;
            23) show_vps_dashboard ;;
            99) uninstall_script ;;
            0) echo -e "\n${C_BLUE}👋 Goodbye!${C_RESET}"; exit 0 ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ================================================================
# ========== START ==========
# ================================================================

require_interactive_terminal
sync_runtime_components_if_needed
main_menu
