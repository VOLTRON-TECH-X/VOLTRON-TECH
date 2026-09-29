#!/bin/bash
# ================================================================
# VOLTRON TECH ULTIMATE v10.11
# ================================================================
# v10.11 = v10.10 + Limiter ya v10.8 (STABLE)
# ================================================================

# ========== COLOR CODES ==========
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_WHITE='\033[97m'
C_RED='\033[91m'
C_GREEN='\033[92m'
C_YELLOW='\033[93m'
C_BLUE='\033[94m'
C_PURPLE='\033[95m'
C_CYAN='\033[96m'
C_TITLE=$C_PURPLE
C_CHOICE=$C_GREEN
C_PROMPT=$C_BLUE
C_WARN=$C_YELLOW
C_DANGER=$C_RED
C_ACCENT=$C_CYAN
C_ORANGE='\033[38;5;208m'

# ========== DESEC DNS ==========
DESEC_TOKEN="3WxD4Hkiu5VYBLWVizVhf1rzyKbz"
DESEC_DOMAIN="voltrontechtx.shop"

# ========== DIRECTORY STRUCTURE ==========
DB_DIR="/etc/voltrontech"
DB_FILE="$DB_DIR/users.db"
INSTALL_FLAG_FILE="$DB_DIR/.install"
SSL_CERT_DIR="$DB_DIR/ssl"
SSL_CERT_FILE="$SSL_CERT_DIR/voltrontech.pem"
SSH_BANNER_FILE="/etc/voltrontech/banner"
TRAFFIC_DIR="$DB_DIR/traffic"
BANNER_DIR="$DB_DIR/banners"
BANDWIDTH_DIR="$DB_DIR/bandwidth"
DNSTT_KEYS_DIR="$DB_DIR/dnstt"
V2RAY_KEYS_DIR="$DB_DIR/v2ray-keys"
V2RAY_DIR="$DB_DIR/v2ray-dnstt"
V2RAY_USERS_DB="$V2RAY_DIR/users/users.db"
V2RAY_CONFIG="$V2RAY_DIR/v2ray/config.json"
DNSTT_INFO_FILE="$DB_DIR/dnstt_info.conf"
V2RAY_INFO_FILE="$DB_DIR/v2ray_info.conf"
DNS_INFO_FILE="$DB_DIR/dns_info.conf"
BADVPN_BUILD_DIR="/root/badvpn-build"
UDP_CUSTOM_DIR="/root/udp"
ZIVPN_DIR="/etc/zivpn"
BACKUP_DIR="$DB_DIR/backups"
LOGS_DIR="$DB_DIR/logs"
CONFIG_DIR="$DB_DIR/config"
FEC_DIR="$DB_DIR/fec"
BANNER_ENABLED_FILE="$DB_DIR/banners_enabled"
SSHD_FF_CONFIG="/etc/ssh/sshd_config.d/voltron-auto-banner.conf"

# ========== WEB PANEL VARIABLES ==========
WEB_PANEL_API_DIR="/opt/voltrontech-api"
WEB_PANEL_API_PORT="5000"
WEB_PANEL_API_DOMAIN="api.voltrontechtx.shop"
WEB_PANEL_DEFAULT_LIMIT=999
WEB_PANEL_API_KEY_FILE="$DB_DIR/api_key.txt"
WEB_PANEL_API_INFO_FILE="$DB_DIR/api_info.txt"
WEB_PANEL_NGINX_CONFIG="/etc/nginx/sites-available/voltrontech-api"
WEB_PANEL_NGINX_LINK="/etc/nginx/sites-enabled/voltrontech-api"
WEB_PANEL_SSL_EMAIL_FILE="$DB_DIR/ssl_email.txt"

# ========== CACHE CLEANER ==========
CACHE_CRON_FILE="/etc/cron.d/voltron-cache-clean"
CACHE_LOG_FILE="/var/log/voltron-cache.log"
CACHE_STATUS_FILE="$DB_DIR/cache/status"
CACHE_SCRIPT="/usr/local/bin/voltron-cache-clean"

# ========== SERVICE FILES ==========
DNSTT_SERVICE="/etc/systemd/system/dnstt.service"
V2RAY_SERVICE="/etc/systemd/system/v2ray-dnstt.service"
BADVPN_SERVICE="/etc/systemd/system/badvpn.service"
UDP_CUSTOM_SERVICE="/etc/systemd/system/udp-custom.service"
HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"
NGINX_CONFIG="/etc/nginx/sites-available/default"
VOLTRONPROXY_SERVICE="/etc/systemd/system/voltronproxy.service"
ZIVPN_SERVICE="/etc/systemd/system/zivpn.service"
LIMITER_SERVICE="/etc/systemd/system/voltrontech-limiter.service"
TRAFFIC_SERVICE="/etc/systemd/system/voltron-traffic.service"

# ========== BINARY LOCATIONS ==========
DNSTT_SERVER="/usr/local/bin/dnstt-server"
DNSTT_CLIENT="/usr/local/bin/dnstt-client"
V2RAY_BIN="/usr/local/bin/xray"
BADVPN_BIN="/usr/local/bin/badvpn-udpgw"
UDP_CUSTOM_BIN="$UDP_CUSTOM_DIR/udp-custom"
VOLTRONPROXY_BIN="/usr/local/bin/voltronproxy"
ZIVPN_BIN="/usr/local/bin/zivpn"
LIMITER_SCRIPT="/usr/local/bin/voltrontech-limiter.sh"
TRAFFIC_SCRIPT="/usr/local/bin/voltron-traffic.sh"

# ========== PORTS ==========
DNS_PORT=53
V2RAY_PORT=8787
BADVPN_PORT=7300
UDP_CUSTOM_PORT=36712
SSL_PORT=444
VOLTRON_PROXY_PORT=8080
ZIVPN_PORT=5667

SELECTED_USER=""
SELECTED_USERS=()

OS=""; OS_VERSION=""; OS_NAME=""; UBUNTU_MAJOR=""
PKG_MANAGER=""; PKG_UPDATE=""; PKG_INSTALL=""; PKG_REMOVE=""; PKG_CLEAN=""

# ========== CREATE DIRECTORIES ==========
create_directories() {
    echo -e "${C_BLUE}📁 Creating directories...${C_RESET}"
    mkdir -p $DB_DIR $DNSTT_KEYS_DIR $V2RAY_KEYS_DIR $V2RAY_DIR $BACKUP_DIR $LOGS_DIR $CONFIG_DIR $SSL_CERT_DIR $FEC_DIR $TRAFFIC_DIR $BANNER_DIR $BANDWIDTH_DIR
    mkdir -p $V2RAY_DIR/dnstt $V2RAY_DIR/v2ray $V2RAY_DIR/users
    mkdir -p $UDP_CUSTOM_DIR $ZIVPN_DIR
    mkdir -p $(dirname "$SSH_BANNER_FILE")
    mkdir -p "$DB_DIR/cache"
    touch $DB_FILE
    touch $V2RAY_USERS_DB
}

IP_CACHE_FILE="$DB_DIR/cache/ip"
LOCATION_CACHE_FILE="$DB_DIR/cache/location"
ISP_CACHE_FILE="$DB_DIR/cache/isp"
mkdir -p "$DB_DIR/cache"

# ========== OS DETECTION ==========
detect_os_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID; OS_VERSION=$VERSION_ID; OS_NAME=$PRETTY_NAME
    else
        OS=$(uname -s); OS_VERSION=$(uname -r); OS_NAME="$OS $OS_VERSION"
    fi
    if [[ "$OS" == "ubuntu" ]]; then UBUNTU_MAJOR=$(echo "$OS_VERSION" | cut -d. -f1); echo -e "${C_GREEN}✅ Ubuntu $OS_VERSION${C_RESET}"
    elif [[ "$OS" == "debian" ]]; then echo -e "${C_GREEN}✅ Debian $OS_VERSION${C_RESET}"
    elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]]; then echo -e "${C_GREEN}✅ $OS_NAME${C_RESET}"
    elif [[ "$OS" == "fedora" ]]; then echo -e "${C_GREEN}✅ Fedora $OS_VERSION${C_RESET}"
    else echo -e "${C_YELLOW}⚠️ $OS_NAME - compat${C_RESET}"; fi
}

detect_package_manager() {
    if command -v apt &>/dev/null; then
        PKG_MANAGER="apt"; PKG_UPDATE="apt update"; PKG_INSTALL="apt install -y"; PKG_REMOVE="apt remove -y"; PKG_CLEAN="apt autoremove -y"
    elif command -v dnf &>/dev/null; then
        PKG_MANAGER="dnf"; PKG_UPDATE="dnf check-update"; PKG_INSTALL="dnf install -y"; PKG_REMOVE="dnf remove -y"; PKG_CLEAN="dnf autoremove -y"
    elif command -v yum &>/dev/null; then
        PKG_MANAGER="yum"; PKG_UPDATE="yum check-update"; PKG_INSTALL="yum install -y"; PKG_REMOVE="yum remove -y"; PKG_CLEAN="yum autoremove -y"
    else echo -e "${C_RED}❌ No package manager!${C_RESET}"; exit 1; fi
    echo -e "${C_GREEN}✅ $PKG_MANAGER${C_RESET}"
}

detect_service_manager() {
    command -v systemctl &>/dev/null && SERVICE_MANAGER="systemd" || { echo -e "${C_RED}❌ systemd not found${C_RESET}"; exit 1; }
    echo -e "${C_GREEN}✅ systemd${C_RESET}"
}

detect_firewall() {
    if command -v ufw &>/dev/null && ufw status | grep -q "active"; then FIREWALL="ufw"
    elif command -v firewall-cmd &>/dev/null && systemctl is-active firewalld &>/dev/null; then FIREWALL="firewalld"
    elif command -v iptables &>/dev/null; then FIREWALL="iptables"
    else FIREWALL="none"; fi
    echo -e "${C_GREEN}✅ Firewall: $FIREWALL${C_RESET}"
}

install_dependencies() {
    echo -e "${C_BLUE}📦 Installing dependencies...${C_RESET}"
    local core_deps="curl wget bc iptables"
    if [[ "$OS" == "ubuntu" ]] && [[ "$UBUNTU_MAJOR" -le 20 ]]; then core_deps="$core_deps net-tools"; fi
    if [ "$PKG_MANAGER" = "apt" ]; then $PKG_UPDATE > /dev/null 2>&1; $PKG_INSTALL $core_deps > /dev/null 2>&1
    elif [ "$PKG_MANAGER" = "dnf" ] || [ "$PKG_MANAGER" = "yum" ]; then $PKG_INSTALL $core_deps > /dev/null 2>&1; fi
    echo -e "${C_GREEN}✅ Dependencies installed${C_RESET}"
}

ensure_iptables() {
    if [[ "$OS" == "ubuntu" ]] && [[ "$UBUNTU_MAJOR" -ge 22 ]]; then
        if ! command -v iptables &> /dev/null; then
            [ "$PKG_MANAGER" = "apt" ] && { $PKG_UPDATE > /dev/null 2>&1; $PKG_INSTALL iptables iptables-persistent > /dev/null 2>&1; }
        fi
        if ! command -v iptables &> /dev/null && command -v iptables-nft &> /dev/null; then
            ln -sf /usr/sbin/iptables-nft /usr/sbin/iptables 2>/dev/null
        fi
    elif [[ "$OS" == "debian" ]] && [[ "$OS_VERSION" -ge 12 ]]; then
        if ! command -v iptables &> /dev/null; then
            [ "$PKG_MANAGER" = "apt" ] && { $PKG_UPDATE > /dev/null 2>&1; $PKG_INSTALL iptables > /dev/null 2>&1; }
        fi
    else
        if ! command -v iptables &> /dev/null; then
            if [ "$PKG_MANAGER" = "apt" ]; then $PKG_INSTALL iptables > /dev/null 2>&1
            elif [ "$PKG_MANAGER" = "yum" ]; then $PKG_INSTALL iptables > /dev/null 2>&1
            elif [ "$PKG_MANAGER" = "dnf" ]; then $PKG_INSTALL iptables > /dev/null 2>&1
            else return 1; fi
        fi
    fi
    command -v iptables &> /dev/null && return 0 || return 1
}

get_ip_info() {
    if [ ! -f "$IP_CACHE_FILE" ] || [ $(( $(date +%s) - $(stat -c %Y "$IP_CACHE_FILE" 2>/dev/null || echo 0) )) -gt 3600 ]; then
        curl -s -4 icanhazip.com > "$IP_CACHE_FILE" 2>/dev/null || echo "Unknown" > "$IP_CACHE_FILE"
    fi
    IP=$(cat "$IP_CACHE_FILE")
    if [ ! -f "$LOCATION_CACHE_FILE" ] || [ ! -f "$ISP_CACHE_FILE" ] || [ $(( $(date +%s) - $(stat -c %Y "$LOCATION_CACHE_FILE" 2>/dev/null || echo 0) )) -gt 86400 ]; then
        local ip_info=$(curl -s "http://ip-api.com/json/$IP" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$ip_info" ]; then
            echo "$ip_info" | grep -o '"city":"[^"]*"' | cut -d'"' -f4 2>/dev/null | tr -d '\n' > "$LOCATION_CACHE_FILE"
            echo "$ip_info" | grep -o '"country":"[^"]*"' | cut -d'"' -f4 2>/dev/null >> "$LOCATION_CACHE_FILE"
            echo "$ip_info" | grep -o '"isp":"[^"]*"' | cut -d'"' -f4 2>/dev/null > "$ISP_CACHE_FILE"
        else
            echo "Unknown" > "$LOCATION_CACHE_FILE"; echo "Unknown" >> "$LOCATION_CACHE_FILE"; echo "Unknown" > "$ISP_CACHE_FILE"
        fi
    fi
    LOCATION=$(head -1 "$LOCATION_CACHE_FILE" 2>/dev/null || echo "Unknown")
    COUNTRY=$(tail -1 "$LOCATION_CACHE_FILE" 2>/dev/null || echo "Unknown")
    ISP=$(cat "$ISP_CACHE_FILE" 2>/dev/null || echo "Unknown")
}

clean_input_buffer() { while read -r -t 0; do read -r; done 2>/dev/null; }
safe_read() { local prompt="$1"; local var_name="$2"; clean_input_buffer; read -p "$prompt" "$var_name"; }

get_current_mtu() { [ -f "$CONFIG_DIR/mtu" ] && cat "$CONFIG_DIR/mtu" || echo "512"; }

check_service() {
    local service=$1
    systemctl is-active "$service" &>/dev/null && echo -e "${C_GREEN}● RUNNING${C_RESET}" || echo ""
}

check_internet() {
    ping -c 1 8.8.8.8 &>/dev/null && return 0 || { echo -e "${C_RED}❌ No internet${C_RESET}"; return 1; }
}

check_and_open_firewall_port() {
    local port="$1"; local protocol="${2:-tcp}"
    if command -v ufw &>/dev/null && ufw status | grep -q "active"; then
        ufw status | grep -qw "$port/$protocol" || ufw allow "$port/$protocol"
    elif command -v firewall-cmd &>/dev/null && systemctl is-active firewalld &>/dev/null; then
        firewall-cmd --list-ports --permanent | grep -qw "$port/$protocol" || { firewall-cmd --add-port="$port/$protocol" --permanent; firewall-cmd --reload; }
    fi
}

_is_valid_ipv4() { [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && return 0 || return 1; }
_is_valid_ipv6() { [[ $1 =~ ^([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}$ ]] && return 0 || return 1; }

show_banner() {
    clear
    get_ip_info
    local current_mtu=$(get_current_mtu)
    if [[ -n "$LOCATION" && "$LOCATION" != "Unknown" && -n "$COUNTRY" && "$COUNTRY" != "Unknown" ]]; then
        LOCATION_FULL="$LOCATION, $COUNTRY"
    elif [[ -n "$COUNTRY" && "$COUNTRY" != "Unknown" ]]; then LOCATION_FULL="$COUNTRY"
    elif [[ -n "$LOCATION" && "$LOCATION" != "Unknown" ]]; then LOCATION_FULL="$LOCATION"
    else LOCATION_FULL="Unknown"; fi
    echo -e "${C_BOLD}${C_PURPLE}╔═══════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║         🔥 VOLTRON TECH ULTIMATE v10.11 🔥                     ║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║      SSH • DNSTT • V2RAY • BADVPN • UDP • SSL • ZiVPN          ║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║         + WEB PANEL + DYNAMIC BANNER (STABLE)                  ║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}╠═══════════════════════════════════════════════════════════════╣${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║  Server IP: ${C_GREEN}$IP${C_PURPLE}${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║  Location:  ${C_GREEN}$LOCATION_FULL${C_PURPLE}${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║  ISP:       ${C_GREEN}$ISP${C_PURPLE}${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║  MTU:       ${C_GREEN}$current_mtu${C_PURPLE}${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║  OS:        ${C_GREEN}$OS_NAME${C_PURPLE}${C_RESET}"
    if [ -f "$CACHE_CRON_FILE" ]; then
        echo -e "${C_BOLD}${C_PURPLE}║  Cache:     ${C_GREEN}AUTO CLEAN ACTIVE${C_PURPLE}${C_RESET}"
    else
        echo -e "${C_BOLD}${C_PURPLE}║  Cache:     ${C_YELLOW}AUTO CLEAN DISABLED${C_PURPLE}${C_RESET}"
    fi
    echo -e "${C_BOLD}${C_PURPLE}╚═══════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
}

press_enter() { echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to continue..." && read -r; }

generate_user_banner() {
    local username="$1"; local expiry="$2"; local limit="$3"; local bandwidth_gb="$4"
    local bw_display="Unlimited"
    [[ "$bandwidth_gb" != "0" ]] && bw_display="${bandwidth_gb} GB"
    mkdir -p "$BANNER_DIR"
    cat > "$BANNER_DIR/${username}.txt" << EOF
<br><br>
<center><font color="#9B59B6">‎▬▬▬▬▬ஜ۩</font><font color="#FF6B6B" size="8"><b> 🌍VOLTRON VPN🌍</b></font><font color="#9B59B6">‎۩ஜ▬▬▬▬▬</font></center><br>
<br>
<center><font color="#4D96FF" size="5"><b>📋 ACCOUNT DETAILS 📋</b></font></center><br>
<br>
<center><font color="#000000">👤 <b>Username      :</b> $username</font></center><br>
<center><font color="#000000">📅 <b>Expiration    :</b> $expiry</font></center><br>
<center><font color="#4D96FF">📊 <b>Bandwidth     :</b> $bw_display</font></center><br>
<center><font color="#000000">🔌 <b>Sessions      :</b> 0/$limit</font></center><br>
<center><font color="#6BCB77" size="4"><b>📌 Account Status : ✅ ACTIVE</b></font></center><br>
<br>
<center><font color="#000000">⏱️ <b>Server Uptime :</b> $(uptime -p | sed 's/up //')</font></center><br>
<center><font color="#000000">📈 <b>Server Load   :</b> $(awk '{print $1}' /proc/loadavg)</font></center><br>
<br>
<center><font color="#6BCB77" size="4"><b>📢 JOIN OUR COMMUNITY 📢</b></font></center><br>
<center><font color="#000000">📱 Telegram  : https://t.me/voltrontech</font></center><br>
<center><font color="#000000">💬 WhatsApp  : https://chat.whatsapp.com/EZtAFt9dmS5DVKbNN5iSPz</font></center><br>
<br>
<center><font color="#FF6B6B" size="4"><b>⚠️ IMPORTANT NOTICE ⚠️</b></font></center><br>
<center><font color="#000000">• Account expires on: $expiry</font></center><br>
<center><font color="#000000">• No torrent or illegal activity</font></center><br>
<center><font color="#000000">• Account sharing is prohibited</font></center><br>
<br>
<center><font color="#9B59B6">‎▬▬▬▬▬ஜ۩</font><font color="#FF6B6B" size="8"><b>  🌍VOLTRON VPN🌍 </b></font><font color="#9B59B6">‎۩ஜ▬▬▬▬▬</font></center><br>
EOF
}
