#!/bin/bash
# ================================================================
# VOLTRON TECH ULTIMATE v10.10
# ================================================================
# v10.10 = v10.8 + Web Panel + Dynamic Banner (Match User *)
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

# OS Detection
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

# ========== CACHE FILES ==========
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
    else echo -e "${C_YELLOW}⚠️ $OS_NAME - compat mode${C_RESET}"; fi
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

# ========== GET IP, LOCATION, ISP ==========
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

# ========== SHOW BANNER ==========
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
    echo -e "${C_BOLD}${C_PURPLE}║         🔥 VOLTRON TECH ULTIMATE v10.10 🔥                     ║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║      SSH • DNSTT • V2RAY • BADVPN • UDP • SSL • ZiVPN          ║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║         + WEB PANEL + DYNAMIC BANNER EDITION                   ║${C_RESET}"
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

# ========== GENERATE BANNER ==========
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

# ========== DNSTT BINARY ==========
download_dnstt_binary() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           📥 DOWNLOADING DNSTT BINARY${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    local arch=$(uname -m)
    local binary_url=""
    if [[ "$arch" == "x86_64" ]]; then binary_url="https://dnstt.network/dnstt-server-linux-amd64"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then binary_url="https://dnstt.network/dnstt-server-linux-arm64"
    else echo -e "\n${C_RED}❌ Unsupported: $arch${C_RESET}"; return 1; fi
    echo -e "${C_YELLOW}📥 Downloading: $binary_url${C_RESET}"
    curl -sL "$binary_url" -o "$DNSTT_SERVER"
    [ $? -ne 0 ] && { echo -e "${C_RED}❌ Failed${C_RESET}"; return 1; }
    chmod +x "$DNSTT_SERVER"
    local binary_size=$(stat -c%s "$DNSTT_SERVER" 2>/dev/null || echo "0")
    [ "$binary_size" -lt 1000000 ] && { echo -e "${C_RED}❌ Binary too small${C_RESET}"; return 1; }
    if [[ "$arch" == "x86_64" ]]; then curl -sL "https://dnstt.network/dnstt-client-linux-amd64" -o "$DNSTT_CLIENT"
    else curl -sL "https://dnstt.network/dnstt-client-linux-arm64" -o "$DNSTT_CLIENT"; fi
    chmod +x "$DNSTT_CLIENT"
    echo -e "${C_GREEN}✅ Downloaded${C_RESET}"
    return 0
}

# ========== SPEED BOOSTERS (7 LEVELS) ==========
apply_dnstt_standard() {
    echo -e "\n${C_BLUE}⚡ STANDARD BOOSTER (32MB)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=524288 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=524288 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=33554432 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=33554432 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=100000 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=4000000 >/dev/null 2>&1
    ulimit -n 1048576 2>/dev/null
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Standard applied${C_RESET}"; sleep 1
}

apply_dnstt_medium() {
    echo -e "\n${C_BLUE}⚡ MEDIUM BOOSTER (64MB)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=1048576 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=1048576 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=67108864 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=67108864 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=200000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=524288 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=4000000 >/dev/null 2>&1
    ulimit -n 1048576 2>/dev/null
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Medium applied${C_RESET}"; sleep 1
}

apply_dnstt_high() {
    echo -e "\n${C_BLUE}⚡ HIGH BOOSTER (128MB)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=2097152 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=2097152 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=134217728 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=134217728 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=400000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=1048576 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=8000000 >/dev/null 2>&1
    ulimit -n 2097152 2>/dev/null
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✅ High applied${C_RESET}"; sleep 1
}

apply_dnstt_ultra() {
    echo -e "\n${C_BLUE}🚀 ULTRA BOOSTER (256MB)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=4194304 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=4194304 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=268435456 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=268435456 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=600000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=2097152 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=16000000 >/dev/null 2>&1
    ulimit -n 4194304 2>/dev/null
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Ultra applied${C_RESET}"; sleep 1
}

apply_dnstt_extreme() {
    echo -e "\n${C_BLUE}💥 EXTREME BOOSTER (512MB)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=8388608 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=8388608 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=536870912 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=536870912 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=1000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=4194304 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=32000000 >/dev/null 2>&1
    ulimit -n 8388608 2>/dev/null
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Extreme applied${C_RESET}"; sleep 1
}

apply_dnstt_ultra_plus() {
    echo -e "\n${C_BLUE}🚀 ULTRA PLUS BOOSTER (768MB)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=805306368 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=805306368 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=800000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=3145728 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=24000000 >/dev/null 2>&1
    ulimit -n 6291456 2>/dev/null
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Ultra Plus applied${C_RESET}"; sleep 1
}

apply_dnstt_extreme_plus() {
    echo -e "\n${C_BLUE}💥 EXTREME PLUS BOOSTER (1GB)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=1200000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=6291456 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=48000000 >/dev/null 2>&1
    ulimit -n 12582912 2>/dev/null
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Extreme Plus applied${C_RESET}"; sleep 1
}

# ========== KEY GENERATION ==========
generate_keys() {
    echo -e "\n${C_BLUE}🔑 GENERATING KEYS${C_RESET}"
    cd "$DB_DIR"
    rm -f server.key server.pub
    if ! "$DNSTT_SERVER" -gen-key -privkey-file server.key -pubkey-file server.pub 2>&1 | tee "$DB_DIR/keygen.log" > /dev/null; then
        openssl rand -hex 32 > server.key
        chmod 600 server.key
        cat server.key | sha256sum | awk '{print $1}' > server.pub
        chmod 644 server.pub
    fi
    chmod 600 server.key; chmod 644 server.pub
    PUBLIC_KEY=$(cat server.pub)
    echo -e "${C_GREEN}✅ Keys generated${C_RESET}"
}

# ========== DESEC DNS ==========
generate_desec_domain() {
    echo -e "\n${C_BLUE}☁️ DESEC DNS AUTO DOMAIN${C_RESET}"
    rand=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
    ns="ns-$rand"; tun="tun-$rand"
    SERVER_IPV4=$(curl -s -4 ifconfig.me 2>/dev/null || curl -s -4 icanhazip.com 2>/dev/null)
    if [ -z "$SERVER_IPV4" ] || ! _is_valid_ipv4 "$SERVER_IPV4"; then
        echo -e "${C_RED}❌ Invalid IPv4${C_RESET}"; return 1
    fi
    local ns_target="$ns.$DESEC_DOMAIN."
    API_DATA="[{\"subname\":\"$ns\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$SERVER_IPV4\"]},{\"subname\":\"$tun\",\"type\":\"NS\",\"ttl\":3600,\"records\":[\"$ns_target\"]}]"
    local RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
        -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$API_DATA")
    local HTTP_CODE=${RESPONSE: -3}
    if [[ "$HTTP_CODE" -eq 201 ]]; then
        DOMAIN="$tun.$DESEC_DOMAIN"
        echo "$ns" > "$DB_DIR/desec_ns_subdomain.txt"
        echo "$tun" > "$DB_DIR/desec_tun_subdomain.txt"
        echo -e "${C_GREEN}✅ Domain: $DOMAIN${C_RESET}"
        return 0
    fi
    echo -e "${C_RED}❌ Failed (HTTP $HTTP_CODE)${C_RESET}"
    return 1
}

delete_desec_dns_records() {
    echo -e "\n${C_BLUE}🗑️ Deleting DNS records...${C_RESET}"
    local ns_subdomain=""; local tun_subdomain=""
    [ -f "$DB_DIR/desec_ns_subdomain.txt" ] && ns_subdomain=$(cat "$DB_DIR/desec_ns_subdomain.txt")
    [ -f "$DB_DIR/desec_tun_subdomain.txt" ] && tun_subdomain=$(cat "$DB_DIR/desec_tun_subdomain.txt")
    [ -n "$ns_subdomain" ] && curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$ns_subdomain/A/" -H "Authorization: Token $DESEC_TOKEN" > /dev/null
    [ -n "$tun_subdomain" ] && curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$tun_subdomain/NS/" -H "Authorization: Token $DESEC_TOKEN" > /dev/null
    rm -f "$DB_DIR/desec_ns_subdomain.txt" "$DB_DIR/desec_tun_subdomain.txt"
}

# ========== DOMAIN SETUP ==========
setup_domain() {
    echo -e "\n${C_BLUE}🌐 DOMAIN CONFIG${C_RESET}\n"
    echo -e "${C_GREEN}1)${C_RESET} Custom domain"
    echo -e "${C_GREEN}2)${C_RESET} Auto-generate with deSEC"
    read -p "👉 Choice [1-2, default=2]: " domain_option
    domain_option=${domain_option:-2}
    if [[ "$domain_option" == "2" ]]; then
        if generate_desec_domain; then echo -e "${C_GREEN}✅ $DOMAIN${C_RESET}"
        else read -p "👉 Enter domain: " DOMAIN; fi
    else read -p "👉 Enter domain: " DOMAIN; fi
    echo "$DOMAIN" > "$DB_DIR/domain.txt"
}

# ========== MTU ==========
mtu_selection_during_install() {
    MTU=512
    echo -e "${C_GREEN}✅ MTU: $MTU${C_RESET}"
    mkdir -p "$CONFIG_DIR"
    echo "$MTU" > "$CONFIG_DIR/mtu"
}

# ========== FIREWALL ==========
configure_firewall() {
    echo -e "\n${C_BLUE}🔥 FIREWALL${C_RESET}"
    ensure_iptables || { echo -e "${C_RED}❌ iptables missing${C_RESET}"; return 1; }
    command -v ufw &> /dev/null && { ufw --force disable 2>/dev/null || true; systemctl stop ufw 2>/dev/null || true; systemctl disable ufw 2>/dev/null || true; }
    if systemctl is-active --quiet systemd-resolved 2>/dev/null; then
        systemctl stop systemd-resolved 2>/dev/null; systemctl disable systemd-resolved 2>/dev/null
        rm -f /etc/resolv.conf
        echo "nameserver 8.8.8.8" > /etc/resolv.conf
        echo "nameserver 1.1.1.1" >> /etc/resolv.conf
        chattr +i /etc/resolv.conf 2>/dev/null || true
    fi
    iptables -F 2>/dev/null || true
    iptables -t nat -F 2>/dev/null || true
    iptables -X 2>/dev/null || true
    iptables -P INPUT ACCEPT; iptables -P FORWARD ACCEPT; iptables -P OUTPUT ACCEPT
    iptables -A INPUT -i lo -j ACCEPT
    iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
    iptables -I INPUT 1 -p udp --dport 5300 -j ACCEPT
    iptables -I OUTPUT 1 -p udp --sport 5300 -j ACCEPT
    iptables -I INPUT 1 -p udp --dport 53 -j ACCEPT
    iptables -I OUTPUT 1 -p udp --sport 53 -j ACCEPT
    iptables -t nat -I PREROUTING 1 -p udp --dport 53 -j REDIRECT --to-ports 5300
    iptables -I INPUT 2 -p tcp --dport 22 -j ACCEPT
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    command -v netfilter-persistent &> /dev/null && netfilter-persistent save > /dev/null 2>&1
    echo -e "${C_GREEN}✅ Firewall configured${C_RESET}"
    return 0
}

# ========== DNSTT SERVICE ==========
create_dnstt_service_live() {
    local domain=$1; local mtu=$2; local ssh_port=$3
    cat > "$DNSTT_SERVICE" <<EOF
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DB_DIR
ExecStart=$DNSTT_SERVER -udp :5300 -privkey-file $DB_DIR/server.key -mtu $mtu $domain 127.0.0.1:$ssh_port
Restart=no
StandardOutput=append:$LOGS_DIR/dnstt-server.log
StandardError=append:$LOGS_DIR/dnstt-error.log

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable dnstt.service > /dev/null 2>&1
    echo -e "${C_GREEN}✅ DNSTT service created${C_RESET}"
}

save_dnstt_info() {
    cat > "$DNSTT_INFO_FILE" <<EOF
TUNNEL_DOMAIN="$1"
PUBLIC_KEY="$2"
MTU_VALUE="$3"
SSH_PORT="$4"
EOF
}

show_client_commands_falcon_style() {
    local domain=$1; local mtu=$2; local ssh_port=$3
    local pubkey=$(cat "$DB_DIR/server.pub")
    echo -e "\n${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}           📱 CLIENT CONNECTION${C_RESET}"
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_CYAN}Tunnel Domain:${C_RESET} ${C_YELLOW}$domain${C_RESET}"
    echo -e "  ${C_CYAN}Public Key:${C_RESET}    ${C_YELLOW}$pubkey${C_RESET}"
    echo -e "  ${C_CYAN}SSH Port:${C_RESET}      ${C_YELLOW}$ssh_port${C_RESET}"
    echo -e "  ${C_CYAN}MTU:${C_RESET}           ${C_YELLOW}$mtu${C_RESET}"
}

# ========== SELECT USER ==========
_select_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    [[ ! -s $DB_FILE ]] && { echo -e "${C_YELLOW}ℹ️ No users${C_RESET}"; SELECTED_USER="NO_USERS"; return; }
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Search: " search_term
        if [[ -n "$search_term" ]]; then mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term"); else users=("${all_users[@]}"); fi
    else users=("${all_users[@]}"); fi
    [[ ${#users[@]} -eq 0 ]] && { echo -e "${C_YELLOW}ℹ️ None${C_RESET}"; SELECTED_USER="NO_USERS"; return; }
    echo -e "\nSelect user:\n"
    for i in "${!users[@]}"; do printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"; done
    echo -e "\n  ${C_RED}[ 0]${C_RESET} Cancel"
    local choice
    while true; do
        read -p "👉 Number: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#users[@]}" ]; then
            [ "$choice" -eq 0 ] && { SELECTED_USER=""; return; } || { SELECTED_USER="${users[$((choice-1))]}"; return; }
        fi
        echo -e "${C_RED}❌ Invalid${C_RESET}"
    done
}

_select_multi_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    SELECTED_USERS=()
    [[ ! -s $DB_FILE ]] && { SELECTED_USERS=("NO_USERS"); return; }
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Search: " search_term
        if [[ -n "$search_term" ]]; then mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term"); else users=("${all_users[@]}"); fi
    else users=("${all_users[@]}"); fi
    [[ ${#users[@]} -eq 0 ]] && { SELECTED_USERS=("NO_USERS"); return; }
    echo -e "\nSelect users:\n"
    for i in "${!users[@]}"; do printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"; done
    echo -e "\n  ${C_GREEN}[all]${C_RESET} Select ALL"
    echo -e "  ${C_RED}  [0]${C_RESET} Cancel"
    local choice
    while true; do
        read -p "👉 Numbers: " choice
        choice=$(echo "$choice" | tr ',' ' ')
        [[ -z "$choice" ]] && { echo -e "${C_RED}❌ Invalid${C_RESET}"; continue; }
        [[ "$choice" == "0" ]] && { SELECTED_USERS=(); return; }
        [[ "${choice,,}" == "all" ]] && { SELECTED_USERS=("${users[@]}"); return; }
        local valid=true; local selected_indices=()
        for token in $choice; do
            if [[ "$token" =~ ^[0-9]+-[0-9]+$ ]]; then
                local start=${token%-*}; local end=${token#*-}
                if [ "$start" -le "$end" ]; then
                    for (( idx=start; idx<=end; idx++ )); do
                        if [ "$idx" -ge 1 ] && [ "$idx" -le "${#users[@]}" ]; then selected_indices+=($idx); else valid=false; break; fi
                    done
                else valid=false; break; fi
            elif [[ "$token" =~ ^[0-9]+$ ]]; then
                if [ "$token" -ge 1 ] && [ "$token" -le "${#users[@]}" ]; then selected_indices+=($token); else valid=false; break; fi
            else valid=false; break; fi
        done
        if [[ "$valid" == true && ${#selected_indices[@]} -gt 0 ]]; then
            mapfile -t unique_indices < <(printf "%s\n" "${selected_indices[@]}" | sort -u -n)
            for idx in "${unique_indices[@]}"; do SELECTED_USERS+=("${users[$((idx-1))]}"); done
            return
        else echo -e "${C_RED}❌ Invalid${C_RESET}"; SELECTED_USERS=(); selected_indices=(); fi
    done
}

get_user_status() {
    local username="$1"
    id "$username" &>/dev/null || { echo -e "${C_RED}Not Found${C_RESET}"; return; }
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    passwd -S "$username" 2>/dev/null | grep -q " L " && { echo -e "${C_YELLOW}🔒 Locked${C_RESET}"; return; }
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    [[ $expiry_ts -lt $current_ts ]] && { echo -e "${C_RED}🗓️ Expired${C_RESET}"; return; }
    echo -e "${C_GREEN}🟢 Active${C_RESET}"
}

_get_real_connection_count() { pgrep -c -u "$1" sshd 2>/dev/null; }

# ========== USER MANAGEMENT ==========
_create_user() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Create New SSH User ---${C_RESET}"
    read -p "👉 Username (or '0' cancel): " username
    [[ "$username" == "0" ]] && { echo -e "\n${C_YELLOW}❌ Cancelled${C_RESET}"; return; }
    [[ -z "$username" ]] && { echo -e "\n${C_RED}❌ Empty${C_RESET}"; return; }
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ Exists${C_RESET}"; return
    fi
    local password=""
    read -p "🔑 Password (Enter auto): " password
    if [[ -z "$password" ]]; then
        password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
        echo -e "${C_GREEN}🔑 Generated: ${C_YELLOW}$password${C_RESET}"
    fi
    read -p "🗓️ Duration (days) [30]: " days; days=${days:-30}
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${C_RED}❌ Invalid${C_RESET}"; return; }
    read -p "📶 Connection limit [999]: " limit; limit=${limit:-999}
    [[ ! "$limit" =~ ^[0-9]+$ ]] && { echo -e "${C_RED}❌ Invalid${C_RESET}"; return; }
    read -p "📦 BW GB (0=unlimited) [0]: " bandwidth_gb; bandwidth_gb=${bandwidth_gb:-0}
    local expire_date=$(date -d "+$days days" +%Y-%m-%d)
    getent group ffusers >/dev/null 2>&1 || groupadd ffusers >/dev/null 2>&1
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG ffusers "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb:0:ACTIVE" >> "$DB_FILE"
    local bw_display="Unlimited"
    [[ "$bandwidth_gb" != "0" ]] && bw_display="${bandwidth_gb} GB"
    if [[ -f "$BANNER_ENABLED_FILE" ]]; then
        generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
        update_ssh_banners_config
    fi
    clear; show_banner
    echo -e "${C_GREEN}✅ User '$username' created!${C_RESET}\n"
    echo -e "  👤 ${C_YELLOW}$username${C_RESET}"
    echo -e "  🔑 ${C_YELLOW}$password${C_RESET}"
    echo -e "  🗓️ ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  📶 ${C_YELLOW}$limit${C_RESET}"
    echo -e "  📦 ${C_YELLOW}$bw_display${C_RESET}"
    echo ""
    read -p "👉 Generate client config? (y/n): " gen_conf
    [[ "$gen_conf" == "y" || "$gen_conf" == "Y" ]] && generate_client_config "$username" "$password"
    safe_read "" dummy
}

_delete_user() {
    _select_multi_user_interface "--- 🗑️ Delete Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && return
    echo -e "\n${C_RED}⚠️ Delete ${#SELECTED_USERS[@]} user(s)?${C_RESET}"
    read -p "👉 Confirm (y/n): " confirm
    [[ "$confirm" != "y" ]] && { echo -e "\n${C_YELLOW}❌ Cancelled${C_RESET}"; return; }
    for username in "${SELECTED_USERS[@]}"; do
        killall -u "$username" -9 &>/dev/null
        sleep 0.2
        userdel -r "$username" &>/dev/null
        [ $? -eq 0 ] && echo -e " ✅ ${C_YELLOW}$username${C_RESET} deleted" || echo -e " ❌ Failed: $username"
        rm -f "$BANDWIDTH_DIR/${username}.usage"
        rm -rf "$BANDWIDTH_DIR/pidtrack/${username}"
        sed -i "/^$username:/d" "$DB_FILE"
    done
    update_ssh_banners_config
    safe_read "" dummy
}

_edit_user() {
    _select_user_interface "--- ✏️ Edit User ---"
    local username=$SELECTED_USER
    [[ "$username" == "NO_USERS" || -z "$username" ]] && return
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- Editing: ${C_YELLOW}$username${C_RESET}"
        local current_line=$(grep "^$username:" "$DB_FILE")
        local cur_pass=$(echo "$current_line" | cut -d: -f2)
        local cur_expiry=$(echo "$current_line" | cut -d: -f3)
        local cur_limit=$(echo "$current_line" | cut -d: -f4)
        local cur_bw=$(echo "$current_line" | cut -d: -f5)
        local cur_traffic=$(echo "$current_line" | cut -d: -f6)
        [[ -z "$cur_bw" ]] && cur_bw="0"; [[ -z "$cur_traffic" ]] && cur_traffic="0"
        local cur_bw_display="Unlimited"; [[ "$cur_bw" != "0" ]] && cur_bw_display="${cur_bw} GB"
        echo -e "\n  Current: Pass=${C_YELLOW}$cur_pass${C_RESET} Exp=${C_YELLOW}$cur_expiry${C_RESET} Conn=${C_YELLOW}$cur_limit${C_RESET} BW=${C_YELLOW}$cur_bw_display${C_RESET} Used=${C_CYAN}$cur_traffic GB${C_RESET}"
        echo -e "\n  1) 🔑 Change Password"
        echo -e "  2) 🗓️ Change Expiration"
        echo -e "  3) 📶 Change Limit"
        echo -e "  4) 📦 Change Bandwidth"
        echo -e "  5) 🔄 Reset Bandwidth"
        echo -e "  0) ✅ Finish"
        read -p "👉 Choice: " edit_choice
        case $edit_choice in
            1) local new_pass=""; read -p "New password: " new_pass
               [[ -z "$new_pass" ]] && { new_pass=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8); echo -e "${C_GREEN}🔑 $new_pass${C_RESET}"; }
               echo "$username:$new_pass" | chpasswd
               sed -i "s/^$username:.*/$username:$new_pass:$cur_expiry:$cur_limit:$cur_bw:$cur_traffic:ACTIVE/" "$DB_FILE"
               echo -e "\n${C_GREEN}✅ Pass: $new_pass${C_RESET}"; read -r ;;
            2) read -p "New days: " days
               if [[ "$days" =~ ^[0-9]+$ ]]; then
                   local new_exp=$(date -d "+$days days" +%Y-%m-%d)
                   chage -E "$new_exp" "$username"
                   sed -i "s/^$username:.*/$username:$cur_pass:$new_exp:$cur_limit:$cur_bw:$cur_traffic:ACTIVE/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ $new_exp${C_RESET}"
               fi; read -r ;;
            3) read -p "New limit: " nl
               [[ "$nl" =~ ^[0-9]+$ ]] && { sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$nl:$cur_bw:$cur_traffic:ACTIVE/" "$DB_FILE"; echo -e "\n${C_GREEN}✅ $nl${C_RESET}"; }; read -r ;;
            4) read -p "New BW (0=unlimited): " nb
               [[ "$nb" =~ ^[0-9]+\.?[0-9]*$ ]] && { sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$nb:$cur_traffic:ACTIVE/" "$DB_FILE"; echo -e "\n${C_GREEN}✅ $nb${C_RESET}"; }; read -r ;;
            5) echo "0" > "$BANDWIDTH_DIR/${username}.usage"
               sed -i "s/^$username:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*/$username:$cur_pass:$cur_expiry:$cur_limit:$cur_bw:0:ACTIVE/" "$DB_FILE"
               usermod -U "$username" &>/dev/null
               echo -e "\n${C_GREEN}✅ Reset${C_RESET}"; read -r ;;
            0) return ;;
            *) read -r ;;
        esac
    done
}

_lock_user() {
    _select_multi_user_interface "--- 🔒 Lock Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && return
    for u in "${SELECTED_USERS[@]}"; do
        id "$u" &>/dev/null || { echo -e " ❌ $u missing"; continue; }
        usermod -L "$u" && killall -u "$u" -9 &>/dev/null && echo -e " ✅ ${C_YELLOW}$u${C_RESET} locked"
    done
    safe_read "" dummy
}

_unlock_user() {
    _select_multi_user_interface "--- 🔓 Unlock Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && return
    for u in "${SELECTED_USERS[@]}"; do
        id "$u" &>/dev/null || { echo -e " ❌ $u missing"; continue; }
        usermod -U "$u" && echo -e " ✅ ${C_YELLOW}$u${C_RESET} unlocked"
    done
    safe_read "" dummy
}

_list_users() {
    clear; show_banner
    [[ ! -s "$DB_FILE" ]] && { echo -e "\n${C_YELLOW}ℹ️ No users${C_RESET}"; safe_read "" dummy; return; }
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Managed Users ---${C_RESET}"
    echo -e "${C_CYAN}=========================================================================================${C_RESET}"
    printf "${C_BOLD}${C_WHITE}%-18s | %-12s | %-10s | %-15s | %-20s${C_RESET}\n" "USERNAME" "EXPIRES" "CONNS" "BANDWIDTH" "STATUS"
    echo -e "${C_CYAN}-----------------------------------------------------------------------------------------${C_RESET}"
    while IFS=: read -r user pass expiry limit bandwidth_gb traffic_used status; do
        [[ -z "$user" ]] && continue
        bandwidth_gb=${bandwidth_gb:-0}; traffic_used=${traffic_used:-0}
        local online_count=$(_get_real_connection_count "$user")
        local status_text=$(get_user_status "$user")
        local plain_status=$(echo -e "$status_text" | sed 's/\x1b\[[0-9;]*m//g')
        local connection_string="$online_count / $limit"
        local bw_string="Unlimited"; [[ "$bandwidth_gb" != "0" ]] && bw_string="${traffic_used}/${bandwidth_gb}GB"
        printf "${C_WHITE}%-18s ${C_RESET}| ${C_YELLOW}%-12s ${C_RESET}| ${C_CYAN}%-10s ${C_RESET}| ${C_ORANGE}%-15s ${C_RESET}| %-20s\n" "$user" "$expiry" "$connection_string" "$bw_string" "$status_text"
    done < <(sort "$DB_FILE")
    echo -e "${C_CYAN}=========================================================================================${C_RESET}\n"
    safe_read "" dummy
}

_renew_user() {
    _select_multi_user_interface "--- 🔄 Renew Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && return
    read -p "👉 Days: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${C_RED}❌ Invalid${C_RESET}"; return; }
    local new_exp=$(date -d "+$days days" +%Y-%m-%d)
    for u in "${SELECTED_USERS[@]}"; do
        chage -E "$new_exp" "$u"
        local line=$(grep "^$u:" "$DB_FILE")
        local pass=$(echo "$line"|cut -d: -f2); local limit=$(echo "$line"|cut -d: -f4); local bw=$(echo "$line"|cut -d: -f5); local traffic=$(echo "$line"|cut -d: -f6)
        [[ -z "$bw" ]] && bw="0"; [[ -z "$traffic" ]] && traffic="0"
        sed -i "s/^$u:.*/$u:$pass:$new_exp:$limit:$bw:$traffic:ACTIVE/" "$DB_FILE"
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} → ${C_GREEN}$new_exp${C_RESET}"
    done
    safe_read "" dummy
}

_cleanup_expired() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🧹 Cleanup Expired ---${C_RESET}"
    local expired_users=(); local current_ts=$(date +%s)
    [[ ! -s "$DB_FILE" ]] && { echo -e "\n${C_GREEN}✅ Empty${C_RESET}"; safe_read "" dummy; return; }
    while IFS=: read -r user pass expiry limit bandwidth_gb traffic_used status; do
        local expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        [[ $expiry_ts -lt $current_ts && $expiry_ts -ne 0 ]] && expired_users+=("$user")
    done < "$DB_FILE"
    [[ ${#expired_users[@]} -eq 0 ]] && { echo -e "\n${C_GREEN}✅ None expired${C_RESET}"; safe_read "" dummy; return; }
    echo -e "\nExpired: ${C_RED}${expired_users[*]}${C_RESET}"
    read -p "👉 Delete? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        for user in "${expired_users[@]}"; do
            echo " - ${C_YELLOW}$user${C_RESET}"
            killall -u "$user" -9 &>/dev/null
            rm -f "$BANDWIDTH_DIR/${user}.usage"
            rm -rf "$BANDWIDTH_DIR/pidtrack/${user}"
            userdel -r "$user" &>/dev/null
            sed -i "/^$user:/d" "$DB_FILE"
        done
        echo -e "\n${C_GREEN}✅ Cleaned${C_RESET}"
    fi
    update_ssh_banners_config
    safe_read "" dummy
}

_bulk_create_users() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👥 Bulk Create Users ---${C_RESET}"
    read -p "👉 Prefix: " prefix
    [[ -z "$prefix" ]] && { echo -e "${C_RED}❌ Empty${C_RESET}"; return; }
    read -p "🔢 Count: " count
    [[ ! "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]] || [[ "$count" -gt 100 ]] && { echo -e "${C_RED}❌ 1-100${C_RESET}"; return; }
    read -p "🗓️ Days [30]: " days; days=${days:-30}
    read -p "📶 Limit [999]: " limit; limit=${limit:-999}
    read -p "📦 BW GB [0]: " bandwidth_gb; bandwidth_gb=${bandwidth_gb:-0}
    local expire_date=$(date -d "+$days days" +%Y-%m-%d)
    getent group ffusers >/dev/null 2>&1 || groupadd ffusers >/dev/null 2>&1
    echo -e "\n${C_BLUE}⚙️ Creating...${C_RESET}\n"
    printf "${C_BOLD}${C_WHITE}%-20s | %-15s | %-12s${C_RESET}\n" "USERNAME" "PASSWORD" "EXPIRES"
    echo -e "${C_YELLOW}────────────────────────────────────────────────────────────${C_RESET}"
    local created=0
    for ((i=1; i<=count; i++)); do
        local username="${prefix}${i}"
        if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
            echo -e "${C_RED}  ⚠️ Skip $username${C_RESET}"; continue
        fi
        local password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
        useradd -m -s /usr/sbin/nologin "$username"
        usermod -aG ffusers "$username" 2>/dev/null
        echo "$username:$password" | chpasswd
        chage -E "$expire_date" "$username"
        echo "$username:$password:$expire_date:$limit:$bandwidth_gb:0:ACTIVE" >> "$DB_FILE"
        [[ -f "$BANNER_ENABLED_FILE" ]] && generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$username" "$password" "$expire_date"
        created=$((created + 1))
    done
    echo -e "${C_YELLOW}────────────────────────────────────────────────────────────${C_RESET}"
    echo -e "\n${C_GREEN}✅ Created $created users${C_RESET}"
    safe_read "" dummy
}

_view_user_bandwidth() {
    _select_user_interface "--- 📊 View Bandwidth ---"
    local u=$SELECTED_USER
    [[ "$u" == "NO_USERS" || -z "$u" ]] && return
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📊 Bandwidth: $u ---${C_RESET}\n"
    local line=$(grep "^$u:" "$DB_FILE")
    local bandwidth_gb=$(echo "$line" | cut -d: -f5)
    local traffic_used=$(echo "$line" | cut -d: -f6)
    [[ -z "$bandwidth_gb" ]] && bandwidth_gb="0"; [[ -z "$traffic_used" ]] && traffic_used="0"
    echo -e "  ${C_CYAN}Used:${C_RESET}  ${C_WHITE}${traffic_used} GB${C_RESET}"
    if [[ "$bandwidth_gb" == "0" ]]; then
        echo -e "  ${C_CYAN}Limit:${C_RESET} ${C_GREEN}Unlimited${C_RESET}"
    else
        local percentage=$(echo "scale=1; $traffic_used * 100 / $bandwidth_gb" | bc 2>/dev/null || echo "0")
        local remaining_gb=$(echo "scale=2; $bandwidth_gb - $traffic_used" | bc 2>/dev/null || echo "0")
        echo -e "  ${C_CYAN}Limit:${C_RESET}     ${C_YELLOW}${bandwidth_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Remaining:${C_RESET} ${C_WHITE}${remaining_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Usage:${C_RESET}     ${C_WHITE}${percentage}%${C_RESET}"
    fi
    safe_read "" dummy
}

generate_client_config() {
    local user=$1; local pass=$2
    local host_ip=$(curl -s -4 icanhazip.com)
    local host_domain="$host_ip"
    [ -f "$DB_DIR/domain.txt" ] && host_domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
    echo -e "\n${C_BOLD}${C_PURPLE}--- 📱 Client Config ---${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "👤 User: ${C_WHITE}$user${C_RESET}"
    echo -e "🔑 Pass: ${C_WHITE}$pass${C_RESET}"
    echo -e "🌐 Host: ${C_WHITE}$host_domain${C_RESET}"
    echo -e "${C_YELLOW}========================================${C_RESET}"
    echo -e "\n🔹 ${C_BOLD}SSH Direct${C_RESET}:"
    echo -e "   Host: $host_domain"
    echo -e "   Port: 22"
    echo -e "   Username: $user"
    echo -e "   Password: $pass"
    if systemctl is-active --quiet haproxy 2>/dev/null; then
        local hp=$(grep -oP 'bind \*:(\d+)' /etc/haproxy/haproxy.cfg 2>/dev/null | awk -F: '{print $2}' | head -1)
        [[ -n "$hp" ]] && { echo -e "\n🔹 ${C_BOLD}SSL/TLS${C_RESET}:"; echo -e "   Host: $host_domain"; echo -e "   Port: $hp"; }
    fi
    if systemctl is-active --quiet udp-custom 2>/dev/null; then
        echo -e "\n🔹 ${C_BOLD}UDP Custom${C_RESET}:"; echo -e "   IP: $host_ip"; echo -e "   Port: 1-65535 (exclude 53,5300)"
    fi
    if systemctl is-active --quiet dnstt 2>/dev/null && [ -f "$DNSTT_INFO_FILE" ]; then
        source "$DNSTT_INFO_FILE"
        echo -e "\n🔹 ${C_BOLD}DNSTT${C_RESET}:"
        echo -e "   Nameserver: $TUNNEL_DOMAIN"
        echo -e "   PubKey: $PUBLIC_KEY"
        echo -e "   DNS IP: 1.1.1.1 / 8.8.8.8"
    fi
    if systemctl is-active --quiet zivpn 2>/dev/null; then
        echo -e "\n🔹 ${C_BOLD}ZiVPN${C_RESET}:"; echo -e "   UDP Port: 5667"
    fi
    echo -e "${C_YELLOW}========================================${C_RESET}"
    safe_read "" dummy
}

client_config_menu() {
    _select_user_interface "--- 📱 Generate Client Config ---"
    local u=$SELECTED_USER
    [[ "$u" == "NO_USERS" || -z "$u" ]] && return
    local pass=$(grep "^$u:" "$DB_FILE" | cut -d: -f2)
    generate_client_config "$u" "$pass"
}

# ========== V2RAY ==========
install_v2ray_dnstt() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}           🚀 V2RAY INSTALLATION${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    if [ -f "$V2RAY_SERVICE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ V2RAY already installed.${C_RESET}"
        read -p "Reinstall? (y/n): " reinstall
        [[ "$reinstall" != "y" ]] && return
        systemctl stop v2ray-dnstt.service 2>/dev/null
    fi
    echo -e "\n${C_BLUE}[1/4] Installing Xray...${C_RESET}"
    bash -c 'curl -sL https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh | bash -s -- install'
    echo -e "${C_BLUE}[2/4] Creating directories...${C_RESET}"
    mkdir -p "$V2RAY_DIR"/{v2ray,users}
    echo -e "${C_BLUE}[3/4] Creating config...${C_RESET}"
    cat > "$V2RAY_CONFIG" <<EOF
{
    "log": {"loglevel": "warning"},
    "inbounds": [{"port": 1080, "listen": "127.0.0.1", "protocol": "vmess", "settings": {"clients": []}, "tag": "vmess"}],
    "outbounds": [{"protocol": "freedom"}]
}
EOF
    echo -e "${C_BLUE}[4/4] Creating service...${C_RESET}"
    cat > "$V2RAY_SERVICE" <<EOF
[Unit]
Description=V2RAY over DNSTT
After=network.target

[Service]
Type=simple
ExecStart=$V2RAY_BIN run -config $V2RAY_CONFIG
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable v2ray-dnstt.service
    systemctl start v2ray-dnstt.service
    echo -e "\n${C_GREEN}✅ V2RAY installed!${C_RESET}"
    safe_read "" dummy
}

uninstall_v2ray_dnstt() {
    echo -e "\n${C_BLUE}🗑️ Uninstalling V2RAY...${C_RESET}"
    systemctl stop v2ray-dnstt.service 2>/dev/null
    systemctl disable v2ray-dnstt.service 2>/dev/null
    rm -f "$V2RAY_SERVICE"
    rm -rf "$V2RAY_DIR"
    bash -c 'curl -sL https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh | bash -s -- remove' > /dev/null 2>&1
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ V2RAY uninstalled${C_RESET}"
    safe_read "" dummy
}

v2ray_main_menu() {
    while true; do
        clear; show_banner
        if [ -f "$V2RAY_SERVICE" ]; then installed_status="${C_GREEN}(installed)${C_RESET}"
        else installed_status="${C_RED}(not installed)${C_RESET}"; fi
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}              🚀 V2RAY MANAGEMENT $installed_status${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        if [ -f "$V2RAY_SERVICE" ]; then
            echo -e "  ${C_GREEN}1)${C_RESET} Reinstall V2RAY"
            echo -e "  ${C_GREEN}2)${C_RESET} Restart Service"
            echo -e "  ${C_GREEN}3)${C_RESET} Stop Service"
            echo -e "  ${C_RED}4)${C_RESET} Uninstall"
            echo ""
            echo -e "  ${C_GREEN}5)${C_RESET} 👤 V2Ray User Management"
        else
            echo -e "  ${C_GREEN}1)${C_RESET} Install V2RAY"
        fi
        echo ""
        echo -e "  ${C_RED}0)${C_RESET} Return"
        echo ""
        local choice
        safe_read "👉 Select option: " choice
        if [ ! -f "$V2RAY_SERVICE" ]; then
            case $choice in
                1) install_v2ray_dnstt ;;
                0) return ;;
                *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
            esac
        else
            case $choice in
                1) uninstall_v2ray_dnstt; install_v2ray_dnstt ;;
                2) systemctl restart v2ray-dnstt.service; echo -e "${C_GREEN}✅ Restarted${C_RESET}"; safe_read "" dummy ;;
                3) systemctl stop v2ray-dnstt.service; echo -e "${C_YELLOW}🛑 Stopped${C_RESET}"; safe_read "" dummy ;;
                4) uninstall_v2ray_dnstt ;;
                5) v2ray_user_menu ;;
                0) return ;;
                *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
            esac
        fi
    done
}

v2ray_user_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}              👤 V2RAY USER MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}1)${C_RESET} Create V2Ray User"
        echo -e "  ${C_GREEN}2)${C_RESET} List V2Ray Users"
        echo -e "  ${C_GREEN}3)${C_RESET} View User Details"
        echo -e "  ${C_GREEN}4)${C_RESET} Edit User"
        echo -e "  ${C_GREEN}5)${C_RESET} Delete User"
        echo -e "  ${C_GREEN}6)${C_RESET} Lock User"
        echo -e "  ${C_GREEN}7)${C_RESET} Unlock User"
        echo -e "  ${C_GREEN}8)${C_RESET} Reset Traffic"
        echo ""
        echo -e "  ${C_RED}0)${C_RESET} Return"
        echo ""
        local choice
        safe_read "👉 Select option: " choice
        case $choice in
            1) create_v2ray_user ;;
            2) list_v2ray_users ;;
            3) view_v2ray_user ;;
            4) edit_v2ray_user ;;
            5) delete_v2ray_user ;;
            6) lock_v2ray_user ;;
            7) unlock_v2ray_user ;;
            8) reset_v2ray_traffic ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
        esac
    done
}

create_v2ray_user() {
    clear
    echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    echo -e "${C_GREEN}           👤 CREATE V2RAY USER${C_RESET}"
    echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"
    read -p "Username: " username
    echo -e "\n${C_GREEN}Select protocol:${C_RESET}"
    echo "1) VMess"; echo "2) VLESS"; echo "3) Trojan"
    read -p "Choice [1]: " proto_choice
    proto_choice=${proto_choice:-1}
    case $proto_choice in
        1) protocol="vmess" ;;
        2) protocol="vless" ;;
        3) protocol="trojan" ;;
        *) protocol="vmess" ;;
    esac
    read -p "Traffic limit (GB) [0=unlimited]: " traffic_limit
    traffic_limit=${traffic_limit:-0}
    read -p "Expiry (days) [30]: " days
    days=${days:-30}
    expire=$(date -d "+$days days" +%Y-%m-%d)
    uuid=$(cat /proc/sys/kernel/random/uuid 2>/dev/null || uuidgen 2>/dev/null)
    password=""
    [ "$protocol" == "trojan" ] && password=$(openssl rand -base64 12 | tr -dc 'a-zA-Z0-9')
    echo "$username:$uuid:$password:$protocol:$traffic_limit:0:$expire:active" >> "$V2RAY_USERS_DB"
    clear
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}           ✅ V2RAY USER CREATED!${C_RESET}"
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "  Username: ${C_YELLOW}$username${C_RESET}"
    echo -e "  UUID:     ${C_YELLOW}$uuid${C_RESET}"
    [ "$protocol" == "trojan" ] && echo -e "  Password: ${C_YELLOW}$password${C_RESET}"
    echo -e "  Protocol: ${C_YELLOW}$protocol${C_RESET}"
    echo -e "  Expiry:   ${C_YELLOW}$expire${C_RESET}"
    safe_read "" dummy
}

list_v2ray_users() {
    clear
    echo -e "${C_GREEN}           📋 V2RAY USERS${C_RESET}"
    if [ ! -s "$V2RAY_USERS_DB" ]; then
        echo -e "${C_YELLOW}No V2Ray users${C_RESET}"
        safe_read "" dummy; return
    fi
    printf "${C_BOLD}%-15s %-8s %-36s %-20s %-12s %-10s${C_RESET}\n" "USERNAME" "PROTO" "UUID" "TRAFFIC" "EXPIRY" "STATUS"
    echo -e "${C_CYAN}───────────────────────────────────────────────────────────────────────────────────────${C_RESET}"
    while IFS=: read -r user uuid pass proto limit used expiry status; do
        [[ -z "$user" ]] && continue
        local traffic_disp=""; [ "$limit" == "0" ] && traffic_disp="${used}GB/∞" || traffic_disp="${used}/${limit} GB"
        local short_uuid="${uuid:0:8}...${uuid: -8}"
        printf "%-15s %-8s %-36s %-20s %-12s %-10s\n" "$user" "$proto" "$short_uuid" "$traffic_disp" "$expiry" "$status"
    done < "$V2RAY_USERS_DB"
    safe_read "" dummy
}

view_v2ray_user() {
    clear
    read -p "Username: " username
    local user_line=$(grep "^$username:" "$V2RAY_USERS_DB" 2>/dev/null)
    if [ -z "$user_line" ]; then echo -e "${C_RED}❌ Not found${C_RESET}"; safe_read "" dummy; return; fi
    IFS=: read -r user uuid pass proto limit used expiry status <<< "$user_line"
    echo -e "\n  Username:  ${C_YELLOW}$user${C_RESET}"
    echo -e "  UUID:      ${C_YELLOW}$uuid${C_RESET}"
    echo -e "  Protocol:  ${C_YELLOW}$proto${C_RESET}"
    echo -e "  Traffic:   ${C_YELLOW}$used/$limit GB${C_RESET}"
    echo -e "  Expiry:    ${C_YELLOW}$expiry${C_RESET}"
    echo -e "  Status:    ${C_YELLOW}$status${C_RESET}"
    safe_read "" dummy
}

edit_v2ray_user() {
    clear
    read -p "Username: " username
    local user_line=$(grep "^$username:" "$V2RAY_USERS_DB" 2>/dev/null)
    if [ -z "$user_line" ]; then echo -e "${C_RED}❌ Not found${C_RESET}"; safe_read "" dummy; return; fi
    IFS=: read -r user uuid pass proto limit used expiry status <<< "$user_line"
    echo -e "\n1) Traffic Limit\n2) Expiry\n3) Status\n0) Cancel"
    read -p "Choice: " edit_choice
    case $edit_choice in
        1) read -p "New limit: " new_limit
           sed -i "s/^$user:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*/$user:$uuid:$pass:$proto:$new_limit:$used:$expiry:$status/" "$V2RAY_USERS_DB" ;;
        2) read -p "New expiry (YYYY-MM-DD): " new_expiry
           sed -i "s/^$user:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*/$user:$uuid:$pass:$proto:$limit:$used:$new_expiry:$status/" "$V2RAY_USERS_DB" ;;
        3) read -p "New status: " new_status
           sed -i "s/^$user:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*/$user:$uuid:$pass:$proto:$limit:$used:$expiry:$new_status/" "$V2RAY_USERS_DB" ;;
    esac
    safe_read "" dummy
}

delete_v2ray_user() {
    read -p "Username: " username
    if grep -q "^$username:" "$V2RAY_USERS_DB" 2>/dev/null; then
        sed -i "/^$username:/d" "$V2RAY_USERS_DB"
        echo -e "${C_GREEN}✅ Deleted${C_RESET}"
    else echo -e "${C_RED}❌ Not found${C_RESET}"; fi
    safe_read "" dummy
}
lock_v2ray_user() { read -p "Username: " username; sed -i "s/^\($username:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\)active/\1locked/" "$V2RAY_USERS_DB"; echo -e "${C_GREEN}✅ Locked${C_RESET}"; safe_read "" dummy; }
unlock_v2ray_user() { read -p "Username: " username; sed -i "s/^\($username:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:\)locked/\1active/" "$V2RAY_USERS_DB"; echo -e "${C_GREEN}✅ Unlocked${C_RESET}"; safe_read "" dummy; }
reset_v2ray_traffic() { read -p "Username: " username; sed -i "s/^\($username:[^:]*:[^:]*:[^:]*:[^:]*:\)[^:]*:/\10:/" "$V2RAY_USERS_DB"; echo -e "${C_GREEN}✅ Reset${C_RESET}"; safe_read "" dummy; }

# ========== PROTOCOLS ==========
install_badvpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing badvpn ---${C_RESET}"
    $PKG_INSTALL cmake make gcc git
    cd /tmp; rm -rf badvpn
    git clone https://github.com/ambrop72/badvpn.git 2>/dev/null
    cd badvpn; cmake . 2>/dev/null; make 2>/dev/null
    cp badvpn-udpgw "$BADVPN_BIN" 2>/dev/null
    cat > "$BADVPN_SERVICE" <<EOF
[Unit]
Description=BadVPN
After=network.target
[Service]
Type=simple
ExecStart=$BADVPN_BIN --listen-addr 0.0.0.0:$BADVPN_PORT --max-clients 1000
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable badvpn.service; systemctl start badvpn.service
    echo -e "${C_GREEN}✅ badvpn installed${C_RESET}"; safe_read "" dummy
}
uninstall_badvpn() {
    systemctl stop badvpn.service 2>/dev/null; systemctl disable badvpn.service 2>/dev/null
    rm -f "$BADVPN_SERVICE" "$BADVPN_BIN"; systemctl daemon-reload
    echo -e "${C_GREEN}✅ Uninstalled${C_RESET}"; safe_read "" dummy
}

install_udp_custom() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing udp-custom ---${C_RESET}"
    mkdir -p "$UDP_CUSTOM_DIR"
    arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then curl -L -o "$UDP_CUSTOM_BIN" "https://github.com/voltrontech/udp-custom/releases/latest/download/udp-custom-linux-amd64"
    else curl -L -o "$UDP_CUSTOM_BIN" "https://github.com/voltrontech/udp-custom/releases/latest/download/udp-custom-linux-arm64"; fi
    chmod +x "$UDP_CUSTOM_BIN"
    cat > "$UDP_CUSTOM_DIR/config.json" <<EOF
{"listen": ":$UDP_CUSTOM_PORT", "auth": {"mode": "passwords"}}
EOF
    cat > "$UDP_CUSTOM_SERVICE" <<EOF
[Unit]
Description=UDP Custom
After=network.target
[Service]
Type=simple
WorkingDirectory=$UDP_CUSTOM_DIR
ExecStart=$UDP_CUSTOM_BIN server -exclude 53,5300
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable udp-custom.service; systemctl start udp-custom.service
    echo -e "${C_GREEN}✅ udp-custom installed${C_RESET}"; safe_read "" dummy
}
uninstall_udp_custom() {
    systemctl stop udp-custom.service 2>/dev/null; systemctl disable udp-custom.service 2>/dev/null
    rm -f "$UDP_CUSTOM_SERVICE"; rm -rf "$UDP_CUSTOM_DIR"; systemctl daemon-reload
    echo -e "${C_GREEN}✅ Uninstalled${C_RESET}"; safe_read "" dummy
}

install_ssl_tunnel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔒 Installing SSL Tunnel ---${C_RESET}"
    $PKG_INSTALL haproxy openssl
    mkdir -p "$SSL_CERT_DIR"
    openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout "$SSL_CERT_DIR/voltrontech.key" -out "$SSL_CERT_DIR/voltrontech.crt" -subj "/CN=VOLTRON TECH" 2>/dev/null
    cat "$SSL_CERT_DIR/voltrontech.crt" "$SSL_CERT_DIR/voltrontech.key" > "$SSL_CERT_FILE" 2>/dev/null
    cat > "$HAPROXY_CONFIG" <<EOF
global
    log /dev/log local0
    chroot /var/lib/haproxy
    user haproxy
    group haproxy
    daemon
defaults
    log global
    mode tcp
    timeout connect 5000
    timeout client 50000
    timeout server 50000
frontend ssh_ssl_in
    bind *:$SSL_PORT ssl crt $SSL_CERT_FILE
    default_backend ssh_backend
backend ssh_backend
    server ssh_server 127.0.0.1:22
EOF
    systemctl restart haproxy
    echo -e "${C_GREEN}✅ SSL Tunnel on port $SSL_PORT${C_RESET}"; safe_read "" dummy
}
uninstall_ssl_tunnel() {
    systemctl stop haproxy 2>/dev/null
    $PKG_REMOVE haproxy; rm -f "$HAPROXY_CONFIG" "$SSL_CERT_FILE"
    echo -e "${C_GREEN}✅ Uninstalled${C_RESET}"; safe_read "" dummy
}

install_voltron_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🦅 Installing VOLTRON Proxy ---${C_RESET}"
    arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then curl -L -o "$VOLTRONPROXY_BIN" "https://github.com/HumbleTechtz/voltron-tech/releases/latest/download/voltronproxy"
    else curl -L -o "$VOLTRONPROXY_BIN" "https://github.com/HumbleTechtz/voltron-tech/releases/latest/download/voltronproxyarm"; fi
    chmod +x "$VOLTRONPROXY_BIN"
    read -p "Port(s) [8080]: " ports; ports=${ports:-8080}
    cat > "$VOLTRONPROXY_SERVICE" <<EOF
[Unit]
Description=VOLTRON Proxy
After=network.target
[Service]
Type=simple
ExecStart=$VOLTRONPROXY_BIN -p $ports
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable voltronproxy.service; systemctl start voltronproxy.service
    echo "$ports" > "$CONFIG_DIR/voltronproxy_ports.conf"
    echo -e "${C_GREEN}✅ VOLTRON Proxy installed${C_RESET}"; safe_read "" dummy
}
uninstall_voltron_proxy() {
    systemctl stop voltronproxy.service 2>/dev/null; systemctl disable voltronproxy.service 2>/dev/null
    rm -f "$VOLTRONPROXY_SERVICE" "$VOLTRONPROXY_BIN" "$CONFIG_DIR/voltronproxy_ports.conf"; systemctl daemon-reload
    echo -e "${C_GREEN}✅ Uninstalled${C_RESET}"; safe_read "" dummy
}

install_nginx_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Installing Nginx Proxy ---${C_RESET}"
    $PKG_INSTALL nginx
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.pem -subj "/CN=VOLTRON TECH" 2>/dev/null
    cat > "$NGINX_CONFIG" <<'EOF'
server {
    listen 80;
    listen 443 ssl http2;
    ssl_certificate /etc/ssl/certs/nginx-selfsigned.pem;
    ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
    }
}
EOF
    systemctl restart nginx
    echo -e "${C_GREEN}✅ Nginx Proxy installed${C_RESET}"; safe_read "" dummy
}
uninstall_nginx_proxy() {
    systemctl stop nginx 2>/dev/null; $PKG_REMOVE nginx; rm -f "$NGINX_CONFIG"
    echo -e "${C_GREEN}✅ Uninstalled${C_RESET}"; safe_read "" dummy
}

install_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🛡️ Installing ZiVPN ---${C_RESET}"
    arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then curl -L -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    else curl -L -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"; fi
    chmod +x "$ZIVPN_BIN"
    mkdir -p "$ZIVPN_DIR"
    openssl req -x509 -newkey rsa:4096 -nodes -days 365 -keyout "$ZIVPN_DIR/server.key" -out "$ZIVPN_DIR/server.crt" -subj "/CN=ZiVPN" 2>/dev/null
    read -p "Passwords (comma-sep) [user1,user2]: " passwords; passwords=${passwords:-user1,user2}
    IFS=',' read -ra pass_array <<< "$passwords"
    json_passwords=$(printf '"%s",' "${pass_array[@]}")
    json_passwords="[${json_passwords%,}]"
    cat > "$ZIVPN_DIR/config.json" <<EOF
{"listen": ":$ZIVPN_PORT", "cert": "$ZIVPN_DIR/server.crt", "key": "$ZIVPN_DIR/server.key", "obfs": "zivpn", "auth": {"mode": "passwords", "config": $json_passwords}}
EOF
    cat > "$ZIVPN_SERVICE" <<EOF
[Unit]
Description=ZiVPN Server
After=network.target
[Service]
Type=simple
ExecStart=$ZIVPN_BIN server -c $ZIVPN_DIR/config.json
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable zivpn.service; systemctl start zivpn.service
    echo -e "${C_GREEN}✅ ZiVPN installed${C_RESET}"; safe_read "" dummy
}
uninstall_zivpn() {
    systemctl stop zivpn.service 2>/dev/null; systemctl disable zivpn.service 2>/dev/null
    rm -f "$ZIVPN_SERVICE" "$ZIVPN_BIN"; rm -rf "$ZIVPN_DIR"; systemctl daemon-reload
    echo -e "${C_GREEN}✅ Uninstalled${C_RESET}"; safe_read "" dummy
}

install_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💻 Installing X-UI Panel ---${C_RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
    safe_read "" dummy
}
uninstall_xui_panel() {
    command -v x-ui &>/dev/null && x-ui uninstall
    rm -f /usr/local/bin/x-ui; rm -rf /etc/x-ui /usr/local/x-ui
    echo -e "${C_GREEN}✅ X-UI uninstalled${C_RESET}"; safe_read "" dummy
}

# ========== DT PROXY ==========
install_dt_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing DT Proxy ---${C_RESET}"
    if curl -sL https://raw.githubusercontent.com/voltrontech/ProxyMods/main/install.sh | bash; then
        echo -e "${C_GREEN}✅ DT Proxy installed${C_RESET}"
    else echo -e "${C_RED}❌ Failed${C_RESET}"; fi
    safe_read "" dummy
}
uninstall_dt_proxy() {
    echo -e "\n${C_BLUE}🗑️ Uninstalling DT Proxy...${C_RESET}"
    systemctl list-units --type=service --state=running | grep 'proxy-' | awk '{print $1}' | while read service; do
        systemctl stop "$service" 2>/dev/null; systemctl disable "$service" 2>/dev/null
    done
    rm -f /etc/systemd/system/proxy-*.service
    systemctl daemon-reload
    rm -f /usr/local/bin/proxy /usr/local/bin/main "$HOME/.proxy_token" /usr/local/bin/install_mod /var/log/proxy-*.log
    echo -e "${C_GREEN}✅ Uninstalled${C_RESET}"; safe_read "" dummy
}
check_dt_proxy_status() { [ -f "/usr/local/bin/main" ] && echo -e "${C_BLUE}(installed)${C_RESET}" || echo ""; }

dt_proxy_menu() {
    while true; do
        clear; show_banner
        local status=""
        if [ -f "/usr/local/bin/main" ]; then status="${C_GREEN}(installed)${C_RESET}"
        else status="${C_RED}(not installed)${C_RESET}"; fi
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}              🚀 DT PROXY MANAGEMENT ${status}${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        if [ -f "/usr/local/bin/main" ]; then
            echo -e "  ${C_GREEN}1)${C_RESET} Reinstall DT Proxy"
            echo -e "  ${C_GREEN}2)${C_RESET} Launch DT Proxy Menu"
            echo -e "  ${C_GREEN}3)${C_RESET} Restart DT Proxy Services"
            echo -e "  ${C_RED}4)${C_RESET} Uninstall DT Proxy"
        else
            echo -e "  ${C_GREEN}1)${C_RESET} Install DT Proxy"
        fi
        echo -e "  ${C_RED}0)${C_RESET} Return"
        echo ""
        local choice
        safe_read "👉 Select option: " choice
        if [ ! -f "/usr/local/bin/main" ]; then
            case $choice in
                1) install_dt_proxy ;;
                0) return ;;
                *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
            esac
        else
            case $choice in
                1) uninstall_dt_proxy; install_dt_proxy ;;
                2) clear; /usr/local/bin/main ;;
                3) systemctl restart proxy-*.service 2>/dev/null; echo -e "${C_GREEN}✅ Restarted${C_RESET}"; safe_read "" dummy ;;
                4) uninstall_dt_proxy ;;
                0) return ;;
                *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
            esac
        fi
    done
}

# ========== AUTO REBOOT ==========
_enable_auto_reboot() {
    echo -e "\n${C_BLUE}🔄 ENABLING AUTO REBOOT (Daily 00:00)${C_RESET}"
    (crontab -l 2>/dev/null | grep -v "reboot") | crontab - 2>/dev/null
    (crontab -l 2>/dev/null; echo "0 0 * * * /sbin/reboot") | crontab - 2>/dev/null
    echo -e "${C_GREEN}✅ Auto reboot scheduled${C_RESET}"
    safe_read "" dummy
}
_disable_auto_reboot() {
    echo -e "\n${C_BLUE}🛑 DISABLING AUTO REBOOT${C_RESET}"
    (crontab -l 2>/dev/null | grep -v "reboot") | crontab - 2>/dev/null
    echo -e "${C_GREEN}✅ Disabled${C_RESET}"
    safe_read "" dummy
}
_view_auto_reboot_status() {
    clear; show_banner
    local cron_check=$(crontab -l 2>/dev/null | grep "reboot")
    if [[ -n "$cron_check" ]]; then echo -e "\n${C_GREEN}✅ ENABLED (Daily 00:00)${C_RESET}"
    else echo -e "\n${C_RED}❌ DISABLED${C_RESET}"; fi
    safe_read "" dummy
}
auto_reboot_menu() {
    while true; do
        clear; show_banner
        local reboot_status=""
        local cron_check=$(crontab -l 2>/dev/null | grep "reboot")
        [[ -n "$cron_check" ]] && reboot_status="${C_GREEN}ENABLED${C_RESET}" || reboot_status="${C_RED}DISABLED${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           🔄 AUTO REBOOT MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "\n  ${C_CYAN}Status:${C_RESET} $reboot_status\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Enable Auto Reboot"
        echo -e "  ${C_RED}2)${C_RESET} Disable Auto Reboot"
        echo -e "  ${C_GREEN}3)${C_RESET} View Status"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        local choice
        safe_read "👉 Select option: " choice
        case $choice in
            1) _enable_auto_reboot ;;
            2) _disable_auto_reboot ;;
            3) _view_auto_reboot_status ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ========== CACHE CLEANER ==========
enable_cache_cleaner() {
    echo -e "\n${C_BLUE}🔧 ENABLING AUTO CACHE CLEANER${C_RESET}"
    touch "$CACHE_LOG_FILE" 2>/dev/null
    cat > "$CACHE_SCRIPT" << 'EOF'
#!/bin/bash
LOG_FILE="/var/log/voltron-cache.log"
log() { echo "$(date): $1" >> "$LOG_FILE"; }
log "Starting cache clean..."
apt clean >> "$LOG_FILE" 2>&1
apt autoclean >> "$LOG_FILE" 2>&1
apt autoremove -y >> "$LOG_FILE" 2>&1
journalctl --vacuum-time=3d >> "$LOG_FILE" 2>&1
rm -f /var/log/*.gz /var/log/*.old 2>/dev/null
rm -rf /tmp/* 2>/dev/null
rm -rf /var/tmp/* 2>/dev/null
log "Cache clean completed"
EOF
    chmod +x "$CACHE_SCRIPT"
    cat > "$CACHE_CRON_FILE" << EOF
0 0 * * * root $CACHE_SCRIPT
EOF
    (crontab -l 2>/dev/null | grep -v "voltron-cache-clean"; echo "0 0 * * * $CACHE_SCRIPT") | crontab - 2>/dev/null
    echo -e "${C_GREEN}✅ Cache cleaner enabled${C_RESET}"
    safe_read "" dummy
}
disable_cache_cleaner() {
    echo -e "\n${C_BLUE}🛑 DISABLING CACHE CLEANER${C_RESET}"
    rm -f "$CACHE_CRON_FILE" 2>/dev/null
    crontab -l 2>/dev/null | grep -v "voltron-cache-clean" | crontab - 2>/dev/null
    echo -e "${C_GREEN}✅ Disabled${C_RESET}"
    safe_read "" dummy
}
check_cache_status() { [ -f "$CACHE_CRON_FILE" ] && echo -e "${C_GREEN}ENABLED${C_RESET}" || echo -e "${C_RED}DISABLED${C_RESET}"; }
cache_cleaner_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           🧹 AUTO CACHE CLEANER${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "\n  ${C_CYAN}Status:${C_RESET} $(check_cache_status)"
        echo -e "  ${C_CYAN}Schedule:${C_RESET} ${C_YELLOW}Daily 12:00 AM${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Enable"
        echo -e "  ${C_RED}2)${C_RESET} Disable"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        local choice
        safe_read "👉 Select option: " choice
        case $choice in
            1) enable_cache_cleaner ;;
            2) disable_cache_cleaner ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ========== DNS MENU ==========
dns_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS Domain Management ---${C_RESET}"
    safe_read "" dummy
}

# ========== PROTOCOL MENU ==========
protocol_menu() {
    while true; do
        clear; show_banner
        local badvpn_status=$(check_service "badvpn")
        local udp_status=$(check_service "udp-custom")
        local haproxy_status=$(check_service "haproxy")
        local dnstt_status=$(check_service "dnstt")
        local v2ray_status=$(check_service "v2ray-dnstt")
        local voltronproxy_status=$(check_service "voltronproxy")
        local nginx_status=$(check_service "nginx")
        local zivpn_status=$(check_service "zivpn")
        local xui_status=$(command -v x-ui &>/dev/null && echo -e "${C_BLUE}(installed)${C_RESET}" || echo "")
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}              🔌 PROTOCOL & PANEL MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}1)${C_RESET} badvpn (UDP 7300) $badvpn_status"
        echo -e "  ${C_GREEN}2)${C_RESET} udp-custom $udp_status"
        echo -e "  ${C_GREEN}3)${C_RESET} SSL Tunnel (HAProxy) $haproxy_status"
        echo -e "  ${C_GREEN}4)${C_RESET} DNSTT (Port 5300) $dnstt_status"
        echo -e "  ${C_GREEN}5)${C_RESET} ⚡ DNSTT Speed Booster"
        echo -e "  ${C_GREEN}6)${C_RESET} V2RAY over DNSTT $v2ray_status"
        echo -e "  ${C_GREEN}7)${C_RESET} VOLTRON Proxy $voltronproxy_status"
        echo -e "  ${C_GREEN}8)${C_RESET} Nginx Proxy $nginx_status"
        echo -e "  ${C_GREEN}9)${C_RESET} ZiVPN $zivpn_status"
        echo -e "  ${C_GREEN}10)${C_RESET} X-UI Panel $xui_status"
        echo -e "  ${C_GREEN}11)${C_RESET} DT Proxy $(check_dt_proxy_status)"
        echo ""
        echo -e "  ${C_RED}0)${C_RESET} Return"
        echo ""
        local choice
        safe_read "👉 Select: " choice
        case $choice in
            1) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; safe_read "👉 " sub; [ "$sub" == "1" ] && install_badvpn || uninstall_badvpn ;;
            2) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; safe_read "👉 " sub; [ "$sub" == "1" ] && install_udp_custom || uninstall_udp_custom ;;
            3) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; safe_read "👉 " sub; [ "$sub" == "1" ] && install_ssl_tunnel || uninstall_ssl_tunnel ;;
            4) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_GREEN}2)${C_RESET} View Details\n  ${C_RED}3)${C_RESET} Uninstall"; safe_read "👉 " sub
               if [ "$sub" == "1" ]; then install_dnstt_falcon
               elif [ "$sub" == "2" ]; then show_dnstt_details
               elif [ "$sub" == "3" ]; then uninstall_dnstt
               else echo -e "${C_RED}Invalid${C_RESET}"; sleep 2; fi ;;
            5) speed_booster_menu ;;
            6) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; safe_read "👉 " sub; [ "$sub" == "1" ] && install_v2ray_dnstt || uninstall_v2ray_dnstt ;;
            7) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; safe_read "👉 " sub; [ "$sub" == "1" ] && install_voltron_proxy || uninstall_voltron_proxy ;;
            8) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; safe_read "👉 " sub; [ "$sub" == "1" ] && install_nginx_proxy || uninstall_nginx_proxy ;;
            9) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; safe_read "👉 " sub; [ "$sub" == "1" ] && install_zivpn || uninstall_zivpn ;;
            10) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; safe_read "👉 " sub; [ "$sub" == "1" ] && install_xui_panel || uninstall_xui_panel ;;
            11) dt_proxy_menu ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ========== SPEED BOOSTER MENU ==========
speed_booster_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           ⚡ DNSTT SPEED BOOSTER MANAGER${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}[1]${C_RESET} Standard  (32MB)   → 10-15 Mbps"
        echo -e "  ${C_GREEN}[2]${C_RESET} Medium     (64MB)   → 15-20 Mbps  🚀"
        echo -e "  ${C_GREEN}[3]${C_RESET} High       (128MB)  → 20-25 Mbps  🚀🚀"
        echo -e "  ${C_GREEN}[4]${C_RESET} Ultra      (256MB)  → 25-35 Mbps  🚀🚀🚀"
        echo -e "  ${C_GREEN}[5]${C_RESET} Extreme    (512MB)  → 35-50 Mbps  💥💥💥"
        echo -e "  ${C_GREEN}[6]${C_RESET} Ultra Plus (768MB)  → 40-60 Mbps  🚀🚀🚀🚀"
        echo -e "  ${C_GREEN}[7]${C_RESET} Extreme Plus (1GB)  → 60-100 Mbps 💥💥💥💥💥"
        echo ""
        echo -e "  ${C_YELLOW}[8]${C_RESET} View Current Settings"
        echo -e "  ${C_RED}[9]${C_RESET} Reset to Default"
        echo -e "\n  ${C_RED}[0]${C_RESET} Return"
        echo ""
        local choice
        safe_read "👉 Select: " choice
        case $choice in
            1) apply_dnstt_standard ;;
            2) apply_dnstt_medium ;;
            3) apply_dnstt_high ;;
            4) apply_dnstt_ultra ;;
            5) apply_dnstt_extreme ;;
            6) apply_dnstt_ultra_plus ;;
            7) apply_dnstt_extreme_plus ;;
            8) echo -e "\n${C_CYAN}Current:${C_RESET}"
               echo -e "  TCP: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)"
               echo -e "  Buffer: $(sysctl -n net.core.rmem_max 2>/dev/null | numfmt --to=iec 2>/dev/null)"
               safe_read "" dummy ;;
            9) read -p "Reset? (y/n): " confirm
               if [[ "$confirm" == "y" ]]; then
                   sysctl -w net.core.rmem_max=212992 >/dev/null 2>&1
                   sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1
                   echo -e "${C_GREEN}✅ Reset${C_RESET}"
               fi
               safe_read "" dummy ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ========== DNSTT INSTALL ==========
install_dnstt_falcon() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}           📡 DNSTT INSTALLATION${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    if [ -f "$DNSTT_SERVICE" ]; then
        read -p "Reinstall? (y/n): " reinstall
        [[ "$reinstall" != "y" ]] && return
        systemctl stop dnstt.service 2>/dev/null
    fi
    echo -e "\n${C_BLUE}[1/8] Dependencies...${C_RESET}"
    $PKG_INSTALL wget curl openssl bc
    echo -e "\n${C_BLUE}[2/8] DNSTT binary...${C_RESET}"
    download_dnstt_binary || { echo -e "${C_RED}❌ Failed${C_RESET}"; safe_read "" dummy; return 1; }
    echo -e "\n${C_BLUE}[3/8] Firewall...${C_RESET}"
    configure_firewall || return 1
    echo -e "\n${C_BLUE}[4/8] Domain...${C_RESET}"
    setup_domain
    echo -e "\n${C_BLUE}[5/8] MTU...${C_RESET}"
    mtu_selection_during_install
    echo -e "\n${C_BLUE}[6/8] Keys...${C_RESET}"
    generate_keys
    echo -e "\n${C_BLUE}[7/8] Speed Booster...${C_RESET}"
    echo -e "  ${C_GREEN}1)${C_RESET} 1000x  ${C_GREEN}2)${C_RESET} 2000x  ${C_GREEN}3)${C_RESET} 3000x  ${C_GREEN}4)${C_RESET} 5000x  ${C_GREEN}5)${C_RESET} 10000x  ${C_GREEN}6)${C_RESET} Skip"
    read -p "👉 [3]: " b; b=${b:-3}
    case $b in 1) apply_dnstt_standard ;; 2) apply_dnstt_medium ;; 3) apply_dnstt_high ;; 4) apply_dnstt_ultra ;; 5) apply_dnstt_extreme ;; esac
    echo -e "\n${C_BLUE}[8/8] Service...${C_RESET}"
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    create_dnstt_service_live "$DOMAIN" "$MTU" "$SSH_PORT"
    save_dnstt_info "$DOMAIN" "$PUBLIC_KEY" "$MTU" "$SSH_PORT"
    systemctl start dnstt.service
    sleep 2
    if systemctl is-active --quiet dnstt.service; then echo -e "${C_GREEN}✅ Running${C_RESET}"
    else echo -e "${C_RED}❌ Failed${C_RESET}"; journalctl -u dnstt.service -n 20 --no-pager; fi
    show_client_commands_falcon_style "$DOMAIN" "$MTU" "$SSH_PORT"
    safe_read "" dummy
}

uninstall_dnstt() {
    echo -e "\n${C_BLUE}🗑️ Uninstalling DNSTT...${C_RESET}"
    systemctl stop dnstt.service 2>/dev/null; systemctl disable dnstt.service 2>/dev/null
    rm -f "$DNSTT_SERVICE" "$DNSTT_SERVER" "$DNSTT_CLIENT"
    rm -f "$DB_DIR/server.key" "$DB_DIR/server.pub" "$DB_DIR/domain.txt" "$DNSTT_INFO_FILE"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ DNSTT uninstalled${C_RESET}"
    safe_read "" dummy
}

show_dnstt_details() {
    clear
    echo -e "${C_GREEN}           📡 DNSTT DETAILS${C_RESET}"
    if [ ! -f "$DB_DIR/domain.txt" ]; then
        echo -e "${C_YELLOW}DNSTT not installed${C_RESET}"
        safe_read "" dummy; return
    fi
    DOMAIN=$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo "unknown")
    MTU=$(cat "$CONFIG_DIR/mtu" 2>/dev/null || echo "512")
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    PUBKEY=$(cat "$DB_DIR/server.pub" 2>/dev/null || echo "unknown")
    local status=""
    systemctl is-active dnstt.service &>/dev/null && status="${C_GREEN}● RUNNING${C_RESET}" || status="${C_RED}● STOPPED${C_RESET}"
    echo -e "  Status:    $status"
    echo -e "  Domain:    ${C_YELLOW}$DOMAIN${C_RESET}"
    echo -e "  MTU:       ${C_YELLOW}$MTU${C_RESET}"
    echo -e "  SSH Port:  ${C_YELLOW}$SSH_PORT${C_RESET}"
    echo -e "  Public Key: ${C_YELLOW}${PUBKEY:0:30}...${PUBKEY: -30}${C_RESET}"
    safe_read "" dummy
}

# ================================================================
# 🎨 DYNAMIC SSH BANNER (FIXED — Match User *)
# ================================================================
# MUHIMU: Inatumia "Match User *" — SI "Match User $user"
# Hii inafanya SSH kufanya kazi bila kugoma
# ================================================================

# ========== SSH BANNER STATIC ==========
_set_ssh_banner() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Paste SSH Banner ---${C_RESET}"
    echo -e "Paste banner code below. Press ${C_YELLOW}[Ctrl+D]${C_RESET} when finished."
    echo -e "--------------------------------------------------"
    cat > "$SSH_BANNER_FILE"
    chmod 644 "$SSH_BANNER_FILE"
    echo -e "\n--------------------------------------------------"
    echo -e "\n${C_GREEN}✅ Banner saved!${C_RESET}"
    _enable_banner_in_sshd_config
    _restart_ssh
    safe_read "" dummy
}

_view_ssh_banner() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👁️ Current SSH Banner ---${C_RESET}"
    if [ -f "$SSH_BANNER_FILE" ]; then
        echo -e "\n${C_CYAN}--- BEGIN BANNER ---${C_RESET}"
        cat "$SSH_BANNER_FILE"
        echo -e "${C_CYAN}---- END BANNER ----${C_RESET}"
    else
        echo -e "\n${C_YELLOW}ℹ️ No banner found.${C_RESET}"
    fi
    safe_read "" dummy
}

_remove_ssh_banner() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🗑️ Remove SSH Banner ---${C_RESET}"
    read -p "👉 Are you sure? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then
        echo -e "\n${C_YELLOW}Cancelled.${C_RESET}"
        safe_read "" dummy; return
    fi
    rm -f "$SSH_BANNER_FILE"
    rm -f "/etc/ssh/sshd_config.d/voltrontech-banner.conf"
    echo -e "\n${C_GREEN}✅ Banner removed.${C_RESET}"
    _restart_ssh
    safe_read "" dummy
}

_enable_banner_in_sshd_config() {
    echo -e "\n${C_BLUE}⚙️ Configuring sshd_config...${C_RESET}"
    mkdir -p /etc/ssh/sshd_config.d
    cat > /etc/ssh/sshd_config.d/voltrontech-banner.conf <<EOF
# Voltron Tech SSH Banner
Banner $SSH_BANNER_FILE
EOF
    if ! grep -q "Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
        echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
    fi
    echo -e "${C_GREEN}✅ sshd_config updated.${C_RESET}"
}

_restart_ssh() {
    echo -e "\n${C_BLUE}🔄 Restarting SSH service...${C_RESET}"
    if systemctl list-units --full -all | grep -q "sshd.service"; then
        systemctl restart sshd
    elif systemctl list-units --full -all | grep -q "ssh.service"; then
        systemctl restart ssh
    else
        echo -e "${C_RED}❌ SSH service not found.${C_RESET}"
        return 1
    fi
    echo -e "${C_GREEN}✅ SSH service restarted.${C_RESET}"
}

# ================================================================
# 🎨 UPDATE SSH BANNERS CONFIG — FIXED (Match User *)
# ================================================================
# Tofauti na v9.3: Inatumia "Match User *" (moja) badala ya "Match User $user" (kila user)
# Hii inafanya SSH kufanya kazi hata kama banner file haipo
# ================================================================
update_ssh_banners_config() {
    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        # Kama banner imezimwa, ondoa config
        rm -f "$SSHD_FF_CONFIG" 2>/dev/null
        systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        return
    fi
    
    mkdir -p "$BANNER_DIR" /etc/ssh/sshd_config.d
    
    # Unda banner files kwa kila user (kama hazipo)
    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r user pass expiry limit bandwidth_gb _rest; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            [[ ! -f "$BANNER_DIR/${user}.txt" ]] && generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"
        done < "$DB_FILE"
    fi
    
    # Unda config MOJA kwa wote (Match User *) — INAFANYA KAZI
    cat > "$SSHD_FF_CONFIG" << 'EOF'
# Voltron Tech - Dynamic Banners (Match User *)
# Banner ya kila user inasomwa kutoka /etc/voltrontech/banners/%u.txt
Match User *
    Banner /etc/voltrontech/banners/%u.txt
EOF
    
    # Hakikisha Include ipo kwenye sshd_config
    grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null || \
        echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
    
    # Test config kabla ya reload
    if sshd -t 2>/dev/null; then
        systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    else
        echo -e "${C_RED}⚠️ SSH config test failed, removing banner config${C_RESET}"
        rm -f "$SSHD_FF_CONFIG"
        systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    fi
}

# ================================================================
# 🎨 ENABLE DYNAMIC BANNER
# ================================================================
enable_dynamic_banner() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🎨 ENABLING DYNAMIC ACCOUNT BANNER${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    mkdir -p "$BANNER_DIR"
    touch "$BANNER_ENABLED_FILE"
    
    echo -e "\n${C_CYAN}📝 Creating banners for all existing users...${C_RESET}"
    
    if [[ -f "$DB_FILE" ]]; then
        local count=0
        while IFS=: read -r user pass expiry limit bandwidth_gb _rest; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"
            echo -e "${C_GREEN}✅ Banner created: ${C_YELLOW}$user${C_RESET}"
            ((count++))
        done < "$DB_FILE"
        echo -e "\n${C_GREEN}✅ Banners created for $count users${C_RESET}"
    fi
    
    # Update SSH config (Match User *)
    update_ssh_banners_config
    
    # Restart limiter
    systemctl restart voltrontech-limiter 2>/dev/null
    
    echo -e "\n${C_GREEN}✅ Dynamic account banner enabled!${C_RESET}"
    echo -e "${C_CYAN}📌 Users will see account status when connecting via SSH${C_RESET}"
    echo -e "${C_CYAN}📌 Banner updates automatically every 15 seconds${C_RESET}"
    
    # Test SSH config
    if sshd -t 2>/dev/null; then
        echo -e "${C_GREEN}✅ SSH config is valid${C_RESET}"
    else
        echo -e "${C_RED}❌ SSH config ERROR — banner config removed${C_RESET}"
        rm -f "$SSHD_FF_CONFIG"
        systemctl restart sshd 2>/dev/null
    fi
    
    press_enter
}

# ================================================================
# 🎨 DISABLE DYNAMIC BANNER
# ================================================================
disable_dynamic_banner() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🛑 DISABLING DYNAMIC ACCOUNT BANNER${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    rm -f "$BANNER_ENABLED_FILE"
    rm -f "$SSHD_FF_CONFIG" 2>/dev/null
    rm -rf "$BANNER_DIR" 2>/dev/null
    
    systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    
    echo -e "\n${C_GREEN}✅ Dynamic banner disabled!${C_RESET}"
    press_enter
}

# ================================================================
# 🎨 PREVIEW DYNAMIC BANNER
# ================================================================
preview_dynamic_ssh_banner() {
    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        echo -e "\n${C_RED}❌ Dynamic banners are not enabled.${C_RESET}"
        press_enter
        return
    fi
    _select_user_interface "--- 📝 Preview Dynamic Banner ---"
    local u=$SELECTED_USER
    [[ -z "$u" || "$u" == "NO_USERS" ]] && return
    echo -e "\n${C_CYAN}--- Dynamic Banner Preview for user '$u' ---${C_RESET}\n"
    if [[ -f "$BANNER_DIR/${u}.txt" ]]; then
        cat "$BANNER_DIR/${u}.txt"
    else
        echo -e "${C_RED}Banner file not generated yet. Waiting 10s...${C_RESET}"
        sleep 5
        if ! cat "$BANNER_DIR/${u}.txt" 2>/dev/null; then
            echo -e "\n${C_RED}Still not generated. Check limiter logs:${C_RESET}"
            journalctl -u voltrontech-limiter -n 15 --no-pager
        fi
    fi
    press_enter
}

# ================================================================
# 🎨 SSH BANNER MENU
# ================================================================
ssh_banner_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           🎨 SSH BANNER MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}Dynamic Banner (per-user):${C_RESET}"
        if [[ -f "$BANNER_ENABLED_FILE" ]]; then
            echo -e "    Status: ${C_GREEN}ENABLED${C_RESET}"
        else
            echo -e "    Status: ${C_RED}DISABLED${C_RESET}"
        fi
        echo ""
        echo -e "  ${C_GREEN}1)${C_RESET} Enable Dynamic Banner"
        echo -e "  ${C_RED}2)${C_RESET} Disable Dynamic Banner"
        echo -e "  ${C_GREEN}3)${C_RESET} Preview Dynamic Banner"
        echo ""
        echo -e "  ${C_CYAN}Static Banner:${C_RESET}"
        echo -e "  ${C_GREEN}4)${C_RESET} Set Static Banner"
        echo -e "  ${C_GREEN}5)${C_RESET} View Static Banner"
        echo -e "  ${C_RED}6)${C_RESET} Remove Static Banner"
        echo ""
        echo -e "  ${C_RED}0)${C_RESET} Return"
        echo ""
        read -p "👉 Choice: " c
        case $c in
            1) enable_dynamic_banner ;;
            2) disable_dynamic_banner ;;
            3) preview_dynamic_ssh_banner ;;
            4) _set_ssh_banner ;;
            5) _view_ssh_banner ;;
            6) _remove_ssh_banner ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ========== BACKUP & RESTORE ==========
backup_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💾 Backup User Data ---${C_RESET}"
    local backup_path
    safe_read "👉 Backup path [/root/voltrontech_backup.tar.gz]: " backup_path
    backup_path=${backup_path:-/root/voltrontech_backup.tar.gz}
    tar -czf "$backup_path" $DB_DIR $TRAFFIC_DIR 2>/dev/null
    [ $? -eq 0 ] && echo -e "${C_GREEN}✅ Backup: $backup_path${C_RESET}" || echo -e "${C_RED}❌ Failed${C_RESET}"
    safe_read "" dummy
}

restore_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📥 Restore User Data ---${C_RESET}"
    local backup_path
    safe_read "👉 Backup path: " backup_path
    if [ ! -f "$backup_path" ]; then
        echo -e "${C_RED}❌ Not found${C_RESET}"
        safe_read "" dummy; return
    fi
    echo -e "${C_RED}⚠️ This will overwrite all current data!${C_RESET}"
    local confirm
    safe_read "Are you sure? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        tar -xzf "$backup_path" -C / 2>/dev/null
        echo -e "${C_GREEN}✅ Restore complete${C_RESET}"
    fi
    safe_read "" dummy
}

# ========== TRAFFIC MONITOR ==========
traffic_monitor_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📈 Network Traffic Monitor ---${C_RESET}"
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    echo -e "\nInterface: ${C_CYAN}${iface}${C_RESET}"
    echo -e "\n${C_BOLD}Select option:${C_RESET}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} Live Monitor"
    echo -e "  ${C_GREEN}2)${C_RESET} Total Traffic Since Boot"
    echo -e "  ${C_RED}0)${C_RESET} Return"
    echo ""
    local choice
    safe_read "👉 Select option: " choice
    case $choice in
        1)
            echo -e "\n${C_BLUE}⚡ Live Monitor (Ctrl+C to stop)...${C_RESET}\n"
            local rx1=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
            local tx1=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
            printf "%-15s | %-15s\n" "⬇️ Download" "⬆️ Upload"
            echo "-----------------------------------"
            while true; do
                sleep 2
                local rx2=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
                local tx2=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
                local rx_diff=$((rx2 - rx1)); local tx_diff=$((tx2 - tx1))
                (( rx_diff < 0 )) && rx_diff=0; (( tx_diff < 0 )) && tx_diff=0
                local rx_kbs=$((rx_diff / 1024 / 2)); local tx_kbs=$((tx_diff / 1024 / 2))
                local rx_fmt="$rx_kbs KB/s"; (( rx_kbs >= 1024 )) && rx_fmt="$(awk "BEGIN {printf \"%.2f\", $rx_kbs/1024}") MB/s"
                local tx_fmt="$tx_kbs KB/s"; (( tx_kbs >= 1024 )) && tx_fmt="$(awk "BEGIN {printf \"%.2f\", $tx_kbs/1024}") MB/s"
                printf "\r%-15s | %-15s" "$rx_fmt" "$tx_fmt"
                rx1=$rx2; tx1=$tx2
            done ;;
        2)
            local rx_total=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
            local tx_total=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
            local rx_mb=$((rx_total / 1024 / 1024)); local tx_mb=$((tx_total / 1024 / 1024))
            echo -e "\n${C_BLUE}📊 Total Traffic:${C_RESET}"
            echo -e "   ⬇️ Download: ${C_WHITE}${rx_mb} MB${C_RESET}"
            echo -e "   ⬆️ Upload:   ${C_WHITE}${tx_mb} MB${C_RESET}"
            safe_read "" dummy ;;
        0) return ;;
        *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
    esac
}

# ========== TORRENT BLOCK ==========
torrent_block_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚫 Torrent Blocking ---${C_RESET}"
    local torrent_status="${C_RED}Disabled${C_RESET}"
    iptables -L FORWARD 2>/dev/null | grep -q "BitTorrent" && torrent_status="${C_GREEN}Enabled${C_RESET}"
    echo -e "\n${C_WHITE}Current Status: ${torrent_status}${C_RESET}"
    echo ""
    echo -e "  ${C_GREEN}1)${C_RESET} Enable Torrent Blocking"
    echo -e "  ${C_RED}2)${C_RESET} Disable Torrent Blocking"
    echo -e "  ${C_RED}0)${C_RESET} Return"
    echo ""
    local choice
    safe_read "👉 Select option: " choice
    case $choice in
        1)
            iptables -A FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
            iptables -A FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
            iptables -A FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
            iptables -A FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
            echo -e "\n${C_GREEN}✅ Enabled${C_RESET}"
            safe_read "" dummy ;;
        2)
            iptables -D FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
            echo -e "\n${C_GREEN}✅ Disabled${C_RESET}"
            safe_read "" dummy ;;
        0) return ;;
        *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
    esac
}

# ========== DNS MENU ==========
dns_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS Domain Management ---${C_RESET}"
    if [ -f "$DNS_INFO_FILE" ]; then
        source "$DNS_INFO_FILE"
        echo -e "\nℹ️ Existing: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
        read -p "👉 Delete? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/A/" -H "Authorization: Token $DESEC_TOKEN" > /dev/null
            rm -f "$DNS_INFO_FILE"
            echo -e "\n${C_GREEN}✅ Deleted${C_RESET}"
        fi
    else
        read -p "👉 Generate new domain? (y/n): " choice
        [[ "$choice" == "y" || "$choice" == "Y" ]] && generate_dns_record
    fi
    safe_read "" dummy
}

generate_dns_record() {
    echo -e "\n${C_BLUE}⚙️ Generating random domain...${C_RESET}"
    local SERVER_IPV4=$(curl -s -4 icanhazip.com)
    if ! _is_valid_ipv4 "$SERVER_IPV4"; then
        echo -e "\n${C_RED}❌ Invalid IPv4${C_RESET}"
        return 1
    fi
    local RANDOM_SUBDOMAIN="vps-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    local FULL_DOMAIN="$RANDOM_SUBDOMAIN.$DESEC_DOMAIN"
    local API_DATA=$(printf '[{"subname": "%s", "type": "A", "ttl": 3600, "records": ["%s"]}]' "$RANDOM_SUBDOMAIN" "$SERVER_IPV4")
    local CREATE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
        -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$API_DATA")
    local HTTP_CODE=${CREATE_RESPONSE: -3}
    if [[ "$HTTP_CODE" -ne 201 ]]; then
        echo -e "${C_RED}❌ Failed (HTTP $HTTP_CODE)${C_RESET}"
        return 1
    fi
    cat > "$DNS_INFO_FILE" <<-EOF
SUBDOMAIN="$RANDOM_SUBDOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
EOF
    echo -e "\n${C_GREEN}✅ Domain: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
}

# ========== VPS DASHBOARD ==========
show_vps_dashboard() {
    clear
    local HOSTNAME=$(hostname)
    local OS=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null | cut -d' ' -f1-2)
    local KERNEL=$(uname -r)
    local ARCH=$(uname -m)
    local UPTIME=$(uptime -p | sed 's/up //')
    local DATE=$(date '+%Y-%m-%d %H:%M:%S')
    local IP=$(curl -s -4 icanhazip.com 2>/dev/null || echo "Unknown")
    local LOCATION=$(curl -s "http://ip-api.com/json/$IP" 2>/dev/null | grep -o '"city":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    local COUNTRY=$(curl -s "http://ip-api.com/json/$IP" 2>/dev/null | grep -o '"country":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    local ISP=$(curl -s "http://ip-api.com/json/$IP" 2>/dev/null | grep -o '"isp":"[^"]*"' | cut -d'"' -f4 2>/dev/null | cut -d' ' -f1-2)
    local CPU_CORES=$(grep -c "processor" /proc/cpuinfo)
    local RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    local RAM_USED=$(free -h | awk '/^Mem:/ {print $3}')
    local RAM_PERCENT=$(free -m | awk '/^Mem:/ {printf "%.0f", $3*100/$2}')
    local DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    local DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    local DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    local LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)
    local TOTAL_USERS=$(grep -c . "$DB_FILE" 2>/dev/null || echo "0")
    local SSH_STATUS=$(systemctl is-active sshd 2>/dev/null || systemctl is-active ssh 2>/dev/null || echo "inactive")
    local DNSTT_STATUS=$(systemctl is-active dnstt 2>/dev/null || echo "inactive")
    local V2RAY_STATUS=$(systemctl is-active v2ray-dnstt 2>/dev/null || echo "inactive")
    make_bar() {
        local p=$1; local w=20
        local f=$((p * w / 100)); [[ $f -gt $w ]] && f=$w
        local e=$((w - f))
        local color=""
        [[ $p -lt 50 ]] && color="\033[38;5;46m" || { [[ $p -lt 75 ]] && color="\033[38;5;226m" || color="\033[38;5;196m"; }
        printf "${color}["
        printf "%${f}s" | tr ' ' '█'
        printf "%${e}s" | tr ' ' '░'
        printf "]${C_RESET} ${p}%%"
    }
    echo ""
    echo -e "${C_BOLD}${C_PURPLE}╔═══════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║${C_RESET}  ${C_BOLD}${C_WHITE}🖥️  VPS DASHBOARD${C_RESET}                                              ${C_BOLD}${C_PURPLE}║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║${C_RESET}  ${C_DIM}${HOSTNAME}  |  ${DATE}${C_RESET}                                                ${C_BOLD}${C_PURPLE}║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}╚═══════════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "${C_BOLD}${C_CYAN}┌─────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}🌐 IP:${C_RESET} ${C_GREEN}%-15s${C_RESET}  ${C_YELLOW}📍 Location:${C_RESET} ${C_GREEN}%-20s${C_RESET}  ${C_YELLOW}🏢 ISP:${C_RESET} ${C_GREEN}%-15s${C_RESET}  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$IP" "$LOCATION, $COUNTRY" "$ISP"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}💻 OS:${C_RESET} ${C_GREEN}%-12s${C_RESET}  ${C_YELLOW}⚙️ Kernel:${C_RESET} ${C_GREEN}%-18s${C_RESET}  ${C_YELLOW}📦 Arch:${C_RESET} ${C_GREEN}%-8s${C_RESET}  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$OS" "$KERNEL" "$ARCH"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}⏱️ Uptime:${C_RESET} ${C_GREEN}%-20s${C_RESET}  ${C_YELLOW}📊 Load:${C_RESET} ${C_GREEN}%-15s${C_RESET}  ${C_YELLOW}👥 Users:${C_RESET} ${C_GREEN}%s${C_RESET}  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$UPTIME" "$LOAD" "$TOTAL_USERS"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}🔹 CPU:${C_RESET} ${C_WHITE}%2s cores${C_RESET}  ${C_YELLOW}🔹 RAM:${C_RESET} ${C_WHITE}%5s / %5s${C_RESET}  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$CPU_CORES" "$RAM_USED" "$RAM_TOTAL"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}CPU:${C_RESET}  %-28s  ${C_YELLOW}RAM:${C_RESET}  %-28s  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$(make_bar 0)" "$(make_bar $RAM_PERCENT)"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}📀 Disk:${C_RESET} %4s / %4s  %-20s  ${C_YELLOW}📶 Net:${C_RESET} ${C_GREEN}●${C_RESET} Active  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$DISK_USED" "$DISK_TOTAL" "$(make_bar $DISK_PERCENT)"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    local sc=""; [[ "$SSH_STATUS" == "active" ]] && sc="${C_GREEN}● RUNNING${C_RESET}" || sc="${C_RED}● STOPPED${C_RESET}"
    local dc=""; [[ "$DNSTT_STATUS" == "active" ]] && dc="${C_GREEN}● RUNNING${C_RESET}" || dc="${C_RED}● STOPPED${C_RESET}"
    local vc=""; [[ "$V2RAY_STATUS" == "active" ]] && vc="${C_GREEN}● RUNNING${C_RESET}" || vc="${C_RED}● STOPPED${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}🔌 SSH:${C_RESET} %-15s ${C_YELLOW}📡 DNSTT:${C_RESET} %-15s ${C_YELLOW}🚀 V2RAY:${C_RESET} %-15s ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$sc" "$dc" "$vc"
    echo -e "${C_BOLD}${C_CYAN}└─────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    echo -e "${C_DIM}  💡 Press ${C_WHITE}[Enter]${C_DIM} to refresh  |  ${C_WHITE}[0]${C_DIM} to return${C_RESET}"
    read -p "👉 " rc
    [[ "$rc" != "0" ]] && show_vps_dashboard
}

# ================================================================
# 🌐 WEB PANEL MODULE (kutoka v9.3)
# ================================================================

web_panel_menu() {
    while true; do
        clear; show_banner
        local api_status=""
        if [ -f "/etc/systemd/system/voltrontech-api.service" ]; then
            systemctl is-active --quiet voltrontech-api 2>/dev/null && api_status="${C_GREEN}● RUNNING${C_RESET}" || api_status="${C_RED}● STOPPED${C_RESET}"
        else api_status="${C_DIM}● NOT INSTALLED${C_RESET}"; fi
        local nginx_status=""
        if command -v nginx &>/dev/null; then
            systemctl is-active --quiet nginx 2>/dev/null && nginx_status="${C_GREEN}● RUNNING${C_RESET}" || nginx_status="${C_RED}● STOPPED${C_RESET}"
        else nginx_status="${C_DIM}● NOT INSTALLED${C_RESET}"; fi
        local ssl_status=""
        if [ -d "/etc/letsencrypt/live/$WEB_PANEL_API_DOMAIN" ]; then ssl_status="${C_GREEN}● INSTALLED${C_RESET}"
        else ssl_status="${C_DIM}● NOT INSTALLED${C_RESET}"; fi
        local dns_status=""
        local current_ip=$(curl -s -4 icanhazip.com 2>/dev/null)
        local dns_ip=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
        if [[ "$dns_ip" == "$current_ip" ]] && [[ -n "$dns_ip" ]]; then dns_status="${C_GREEN}● OK${C_RESET}"
        else dns_status="${C_YELLOW}● NOT SET${C_RESET}"; fi

        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}              🌐 WEB PANEL MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}API Domain:${C_RESET}   ${C_YELLOW}$WEB_PANEL_API_DOMAIN${C_RESET}"
        echo -e "  ${C_CYAN}VPS IP:${C_RESET}       ${C_YELLOW}$current_ip${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}API:${C_RESET}          $api_status"
        echo -e "  ${C_CYAN}Nginx:${C_RESET}        $nginx_status"
        echo -e "  ${C_CYAN}SSL:${C_RESET}          $ssl_status"
        echo -e "  ${C_CYAN}DNS:${C_RESET}          $dns_status"
        echo ""
        echo -e "${C_BOLD}${C_PURPLE}───────────────────────────────────────────────────────────────${C_RESET}"
        echo -e "  ${C_GREEN}[ 1]${C_RESET} 🚀 Full Setup (API + DNS + Nginx + SSL + CORS)"
        echo -e "  ${C_GREEN}[ 2]${C_RESET} 📥 Install API Server Only"
        echo -e "  ${C_GREEN}[ 3]${C_RESET} 🌐 Setup DNS Only"
        echo -e "  ${C_GREEN}[ 4]${C_RESET} ⚙️  Setup Nginx Only"
        echo -e "  ${C_GREEN}[ 5]${C_RESET} 🔒 Setup SSL Only"
        echo -e "  ${C_GREEN}[ 6]${C_RESET} 🔓 Setup CORS Only"
        echo -e "  ${C_GREEN}[ 7]${C_RESET} 🧪 Test Everything (8 tests)"
        echo -e "  ${C_GREEN}[ 8]${C_RESET} 📋 View Logs"
        echo -e "  ${C_GREEN}[ 9]${C_RESET} 🔄 Renew SSL"
        echo -e "  ${C_GREEN}[10]${C_RESET} 🔑 View API Info"
        echo -e "  ${C_GREEN}[11]${C_RESET} 🔄 Restart API"
        echo -e "  ${C_GREEN}[12]${C_RESET} 📝 Copy for Lovable AI"
        echo -e ""
        echo -e "  ${C_RED}[13]${C_RESET} 🗑️  Remove Web Panel"
        echo -e "  ${C_RED}[ 0]${C_RESET} Return to Main Menu"
        echo ""
        read -p "👉 Select option: " choice
        case $choice in
            1) web_panel_full_setup ;;
            2) web_panel_install_api ;;
            3) web_panel_dns_setup ;;
            4) web_panel_nginx_setup ;;
            5) web_panel_ssl_setup ;;
            6) web_panel_cors_setup ;;
            7) web_panel_test_all ;;
            8) web_panel_view_logs ;;
            9) web_panel_renew_ssl ;;
            10) web_panel_view_api_info ;;
            11) web_panel_restart_api ;;
            12) web_panel_copy_for_lovable ;;
            13) web_panel_remove ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
        esac
    done
}

web_panel_full_setup() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}       🚀 FULL WEB PANEL SETUP${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    echo -e "${C_CYAN}Hii itafanya:${C_RESET}"
    echo -e "  ${C_GREEN}1.${C_RESET} Install API Server"
    echo -e "  ${C_GREEN}2.${C_RESET} Setup DNS record"
    echo -e "  ${C_GREEN}3.${C_RESET} Install Nginx + config"
    echo -e "  ${C_GREEN}4.${C_RESET} Get SSL certificate"
    echo -e "  ${C_GREEN}5.${C_RESET} Setup CORS"
    echo -e "  ${C_GREEN}6.${C_RESET} Test kila kitu"
    echo ""
    read -p "👉 Continue? (y/n): " confirm
    [[ "$confirm" != "y" ]] && return
    echo ""
    echo -e "${C_BLUE}═══ HATUA 1/6: API INSTALLATION ═══${C_RESET}"
    web_panel_install_api
    sleep 2
    echo -e "\n${C_BLUE}═══ HATUA 2/6: DNS SETUP ═══${C_RESET}"
    web_panel_dns_setup
    sleep 2
    echo -e "\n${C_BLUE}═══ HATUA 3/6: NGINX SETUP ═══${C_RESET}"
    web_panel_nginx_setup
    sleep 2
    echo -e "\n${C_BLUE}═══ HATUA 4/6: SSL SETUP ═══${C_RESET}"
    web_panel_ssl_setup
    sleep 2
    echo -e "\n${C_BLUE}═══ HATUA 5/6: CORS SETUP ═══${C_RESET}"
    web_panel_cors_setup
    sleep 2
    echo -e "\n${C_BLUE}═══ HATUA 6/6: TESTING ═══${C_RESET}"
    web_panel_test_all
    echo ""
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}           ✅ FULL SETUP COMPLETE!${C_RESET}"
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    press_enter
}

web_panel_install_api() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📥 Installing API Server ---${C_RESET}\n"
    if [ -f "/etc/systemd/system/voltrontech-api.service" ]; then
        echo -e "${C_YELLOW}⚠️  API already installed${C_RESET}"
        read -p "👉 Reinstall? (y/n): " reinstall
        [[ "$reinstall" != "y" ]] && return
        systemctl stop voltrontech-api 2>/dev/null
    fi
    local API_KEY="voltron_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)"
    echo -e "${C_BLUE}[1/6] Installing dependencies...${C_RESET}"
    $PKG_INSTALL python3 python3-pip python3-venv curl jq
    echo -e "\n${C_BLUE}[2/6] Creating directory...${C_RESET}"
    mkdir -p "$WEB_PANEL_API_DIR"
    echo -e "\n${C_BLUE}[3/6] Python environment...${C_RESET}"
    cd "$WEB_PANEL_API_DIR"
    [ ! -d "venv" ] && python3 -m venv venv
    source venv/bin/activate
    pip install -q --upgrade pip
    pip install -q flask flask-cors gunicorn
    deactivate
    echo -e "\n${C_BLUE}[4/6] Creating API code...${C_RESET}"
    web_panel_create_api_code
    echo -e "\n${C_BLUE}[5/6] Systemd service...${C_RESET}"
    local SERVER_IP_DETECTED=$(curl -s -4 icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')
    cat > /etc/systemd/system/voltrontech-api.service << EOF
[Unit]
Description=Voltron Tech API Server v10.10
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$WEB_PANEL_API_DIR
Environment="API_KEY=$API_KEY"
Environment="DB_DIR=$DB_DIR"
Environment="SERVER_HOST=$SERVER_IP_DETECTED"
Environment="DEFAULT_LIMIT=999"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$WEB_PANEL_API_DIR/venv/bin/gunicorn --workers 4 --bind 0.0.0.0:$WEB_PANEL_API_PORT --timeout 120 api:app
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable voltrontech-api >/dev/null 2>&1
    echo -e "\n${C_BLUE}[6/6] Starting API...${C_RESET}"
    systemctl start voltrontech-api
    sleep 3
    if systemctl is-active --quiet voltrontech-api; then
        local SERVER_IP=$(curl -s -4 icanhazip.com)
        mkdir -p "$DB_DIR"
        cat > "$WEB_PANEL_API_INFO_FILE" << EOF
API_URL=http://$SERVER_IP:$WEB_PANEL_API_PORT
API_KEY=$API_KEY
EOF
        echo "$API_KEY" > "$WEB_PANEL_API_KEY_FILE"
        chmod 600 "$WEB_PANEL_API_KEY_FILE"
        echo ""
        echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_GREEN}           ✅ API SERVER INSTALLED!${C_RESET}"
        echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}🌐 URL:${C_RESET}      ${C_YELLOW}http://$SERVER_IP:$WEB_PANEL_API_PORT${C_RESET}"
        echo -e "  ${C_CYAN}🔑 API Key:${C_RESET}  ${C_GREEN}$API_KEY${C_RESET}"
    else
        echo -e "\n${C_RED}❌ Failed${C_RESET}"
        journalctl -u voltrontech-api -n 20 --no-pager
    fi
    press_enter
}

web_panel_create_api_code() {
    cat > "$WEB_PANEL_API_DIR/api.py" << 'APIEOF'
#!/usr/bin/env python3
"""Voltron Tech API Server v10.10"""
from flask import Flask, request, jsonify
from flask_cors import CORS
from functools import wraps
from datetime import datetime, timedelta
import subprocess, os, logging, shutil

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}}, supports_credentials=True)

API_KEY = os.environ.get('API_KEY', 'CHANGE_ME')
DB_DIR = os.environ.get('DB_DIR', '/etc/voltrontech')
DB_FILE = f'{DB_DIR}/users.db'
SERVER_HOST = os.environ.get('SERVER_HOST', '')
DEFAULT_LIMIT = int(os.environ.get('DEFAULT_LIMIT', '999'))
BANDWIDTH_DIR = f'{DB_DIR}/bandwidth'

logging.basicConfig(filename='/var/log/voltrontech-api.log', level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')

def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        key = request.headers.get('X-API-Key') or request.args.get('api_key')
        if not key or key != API_KEY:
            return jsonify({'success': False, 'error': 'Invalid API key'}), 401
        return f(*args, **kwargs)
    return decorated

def run_safe(args, timeout=30):
    try:
        if isinstance(args, str): args = args.split()
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return {'success': r.returncode == 0, 'stdout': r.stdout.strip() if r.stdout else '', 'stderr': r.stderr.strip() if r.stderr else ''}
    except Exception as e:
        return {'success': False, 'stdout': '', 'stderr': str(e)}

def run_shell(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return r.stdout.strip() if r.stdout else ''
    except Exception:
        return ''

def service_active(name):
    if not shutil.which('systemctl'): return False
    return run_shell(f'systemctl is-active {name} 2>/dev/null').strip() == 'active'

def ssh_active(): return service_active('ssh') or service_active('sshd')

def read_users():
    users = []
    if not os.path.exists(DB_FILE): return users
    try:
        with open(DB_FILE) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'): continue
                parts = line.split(':')
                if len(parts) >= 4:
                    users.append({'username': parts[0], 'password': parts[1], 'expiry': parts[2], 'limit': parts[3], 'bandwidth': parts[4] if len(parts) > 4 else '0'})
    except Exception: pass
    return users

def user_exists(username): return run_safe(['id', username]).get('success', False)

def get_status(username):
    if not user_exists(username): return 'not_found'
    r = run_safe(['passwd', '-S', username])
    parts = r.get('stdout', '').split()
    if len(parts) >= 2 and parts[1] == 'L': return 'locked'
    user = next((u for u in read_users() if u['username'] == username), None)
    if user and user.get('expiry'):
        try:
            if datetime.strptime(user['expiry'], '%Y-%m-%d') < datetime.now(): return 'expired'
        except: pass
    return 'active'

def get_online(username):
    out = run_shell(f'pgrep -c -u {username} sshd 2>/dev/null')
    try: return int(out or '0')
    except: return 0

def get_server_ip():
    for cmd in ['curl -s -4 icanhazip.com', 'curl -s -4 ifconfig.me', "hostname -I | awk '{print $1}'"]:
        out = run_shell(cmd, timeout=5).strip()
        if out and out.count('.') == 3 and not out.startswith('127.'): return out
    return 'unknown'

def get_server_host():
    if SERVER_HOST: return SERVER_HOST
    return get_server_ip()

def get_protocols(username=None, password=None, limit=DEFAULT_LIMIT):
    protocols = {}
    server_ip = get_server_ip()
    server_host = get_server_host()
    if ssh_active():
        protocols['ssh'] = {'id': 'ssh', 'name': 'SSH Direct', 'icon': '🔐', 'color': '#6BCB77', 'host': server_host, 'ip': server_ip, 'port': 22, 'username': username, 'password': password, 'limit': limit, 'type': 'ssh'}
    if service_active('haproxy'):
        protocols['ssl'] = {'id': 'ssl', 'name': 'SSL/TLS Tunnel', 'icon': '🔒', 'color': '#4D96FF', 'host': server_host, 'ip': server_ip, 'port': 444, 'username': username, 'password': password, 'limit': limit, 'type': 'ssl'}
    if service_active('dnstt'):
        domain = ''; pubkey = ''; mtu = 512
        if os.path.exists(f'{DB_DIR}/domain.txt'):
            try:
                with open(f'{DB_DIR}/domain.txt') as f: domain = f.read().strip()
            except: pass
        if os.path.exists(f'{DB_DIR}/dnstt/server.pub'):
            try:
                with open(f'{DB_DIR}/dnstt/server.pub') as f: pubkey = f.read().strip()
            except: pass
        if os.path.exists(f'{DB_DIR}/config/mtu'):
            try:
                with open(f'{DB_DIR}/config/mtu') as f: mtu = int(f.read().strip())
            except: mtu = 512
        protocols['dnstt'] = {'id': 'dnstt', 'name': 'DNSTT (SlowDNS)', 'icon': '📡', 'color': '#9B59B6', 'domain': domain, 'pubkey': pubkey, 'mtu': mtu, 'dns': '8.8.8.8', 'dns_alt': '1.1.1.1', 'username': username, 'password': password, 'limit': limit, 'type': 'dnstt'}
    if service_active('udp-custom'):
        protocols['udp_custom'] = {'id': 'udp_custom', 'name': 'UDP Custom', 'icon': '🚀', 'color': '#FF6B6B', 'host': server_host, 'ip': server_ip, 'port_range': '1-65535', 'exclude': '53,5300', 'username': username, 'password': password, 'limit': limit, 'type': 'udp'}
    if service_active('badvpn'):
        protocols['badvpn'] = {'id': 'badvpn', 'name': 'BadVPN UDPGW', 'icon': '⚡', 'color': '#FFD93D', 'host': server_host, 'ip': server_ip, 'port': 7300, 'username': username, 'password': password, 'limit': limit, 'type': 'badvpn'}
    if service_active('zivpn'):
        protocols['zivpn'] = {'id': 'zivpn', 'name': 'ZiVPN', 'icon': '🛡️', 'color': '#6BCB77', 'host': server_host, 'ip': server_ip, 'port': 5667, 'username': username, 'password': password, 'limit': limit, 'type': 'zivpn'}
    return protocols

def now_iso(): return datetime.now().isoformat()

@app.route('/api/health')
def health():
    protocols = get_protocols()
    return jsonify({'success': True, 'status': 'ok', 'service': 'Voltron Tech API', 'version': '10.10', 'protocols_active': len(protocols), 'timestamp': now_iso()})

@app.route('/api/trial/check', methods=['POST'])
@require_api_key
def trial_check():
    data = request.get_json() or {}
    username = data.get('username', '').strip().lower()
    if not username: return jsonify({'available': False, 'error': 'Username required'}), 400
    if not username.replace('-', '').replace('_', '').isalnum(): return jsonify({'available': False, 'error': 'Only letters, numbers, - and _'}), 400
    if len(username) < 3 or len(username) > 20: return jsonify({'available': False, 'error': 'Username must be 3-20 chars'}), 400
    if user_exists(username) or any(u['username'] == username for u in read_users()):
        return jsonify({'available': False, 'error': 'Username already used'})
    return jsonify({'available': True, 'username': username, 'timestamp': now_iso()})

@app.route('/api/trial/create', methods=['POST'])
@require_api_key
def trial_create():
    data = request.get_json() or {}
    username = data.get('username', '').strip().lower()
    password = data.get('password', '').strip()
    days = int(data.get('days', 1))
    if not username or len(username) < 3 or len(username) > 20: return jsonify({'success': False, 'error': 'Invalid username'}), 400
    if not username.replace('-', '').replace('_', '').isalnum(): return jsonify({'success': False, 'error': 'Invalid chars'}), 400
    if not password or len(password) < 4: return jsonify({'success': False, 'error': 'Password too short'}), 400
    if days not in [1, 3, 7]: return jsonify({'success': False, 'error': 'Days must be 1, 3, or 7'}), 400
    if user_exists(username): return jsonify({'success': False, 'error': 'Username already used'}), 400
    try:
        run_safe(['useradd', '-m', '-s', '/usr/sbin/nologin', username])
        run_safe(['usermod', '-aG', 'ffusers', username])
        try: subprocess.run(['chpasswd'], input=f'{username}:{password}', text=True, capture_output=True, timeout=10)
        except: pass
        expire_date = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', expire_date, username])
        os.makedirs(DB_DIR, exist_ok=True)
        with open(DB_FILE, 'a') as f: f.write(f'{username}:{password}:{expire_date}:{DEFAULT_LIMIT}:0\n')
        protocols = get_protocols(username, password, DEFAULT_LIMIT)
        return jsonify({'success': True, 'message': f'Trial created ({days} days)', 'timestamp': now_iso(), 'account': {'username': username, 'password': password, 'expiry': expire_date, 'days': days, 'limit': DEFAULT_LIMIT, 'bandwidth': 'Unlimited', 'server': get_server_host(), 'server_ip': get_server_ip()}, 'protocols': protocols, 'protocol_count': len(protocols)})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/api/trial/status/<username>')
@require_api_key
def trial_status(username):
    user = next((u for u in read_users() if u['username'] == username), None)
    if not user: return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        expiry = datetime.strptime(user['expiry'], '%Y-%m-%d')
        days_left = (expiry - datetime.now()).days
    except: days_left = 0
    return jsonify({'success': True, 'timestamp': now_iso(), 'account': {'username': username, 'status': get_status(username), 'expiry': user['expiry'], 'days_left': max(0, days_left), 'online': get_online(username), 'limit': int(user['limit']), 'bandwidth': user['bandwidth']}})

@app.route('/api/users/list')
@require_api_key
def users_list():
    users = read_users()
    result = []
    for u in users:
        used_bytes = 0
        usage_file = f'{BANDWIDTH_DIR}/{u["username"]}.usage'
        if os.path.exists(usage_file):
            try:
                with open(usage_file) as f: used_bytes = int(f.read().strip() or 0)
            except: pass
        result.append({'username': u['username'], 'expiry': u['expiry'], 'limit': int(u['limit']), 'bandwidth_limit': float(u['bandwidth']), 'bandwidth_used_gb': round(used_bytes / 1073741824, 2), 'status': get_status(u['username']), 'online': get_online(u['username'])})
    return jsonify({'success': True, 'timestamp': now_iso(), 'users': result, 'total': len(result)})

@app.route('/api/protocols/status')
@require_api_key
def protocols_status():
    protocols = get_protocols()
    return jsonify({'success': True, 'timestamp': now_iso(), 'protocols': protocols, 'count': len(protocols), 'active_list': list(protocols.keys())})

@app.route('/api/dashboard/info')
@require_api_key
def dashboard_info():
    try:
        ip = get_server_ip()
        try:
            with open('/proc/uptime') as f:
                uptime_sec = float(f.read().split()[0])
            days = int(uptime_sec // 86400); hours = int((uptime_sec % 86400) // 3600)
            uptime_str = f'{days}d {hours}h'
        except: uptime_str = 'unknown'
        users = read_users()
        online = sum(get_online(u['username']) for u in users)
        return jsonify({'success': True, 'timestamp': now_iso(), 'info': {'ip': ip, 'uptime': uptime_str, 'users': {'total': len(users), 'online': online}, 'services': {'ssh': ssh_active(), 'dnstt': service_active('dnstt'), 'haproxy': service_active('haproxy'), 'badvpn': service_active('badvpn'), 'udp_custom': service_active('udp-custom'), 'zivpn': service_active('zivpn')}}})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
APIEOF
    chmod +x "$WEB_PANEL_API_DIR/api.py"
}

web_panel_dns_setup() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS Setup ---${C_RESET}\n"
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    if ! _is_valid_ipv4 "$ip"; then
        echo -e "${C_RED}❌ Cannot detect IP${C_RESET}"
        press_enter; return 1
    fi
    echo -e "  ${C_CYAN}VPS IP:${C_RESET}      ${C_YELLOW}$ip${C_RESET}"
    echo -e "  ${C_CYAN}API Domain:${C_RESET}  ${C_YELLOW}$WEB_PANEL_API_DOMAIN${C_RESET}"
    echo ""
    local existing=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
    if [[ "$existing" == "$ip" ]]; then
        echo -e "${C_GREEN}✅ DNS record exists${C_RESET}"
        press_enter; return 0
    fi
    echo -e "${C_BLUE}🔄 Adding DNS record...${C_RESET}"
    local api_sub=$(echo "$WEB_PANEL_API_DOMAIN" | cut -d. -f1)
    local api_data="[{\"subname\":\"$api_sub\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$ip\"]}]"
    local resp=$(curl -s -w "\n%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$api_data" 2>/dev/null)
    local http_code=$(echo "$resp" | tail -1)
    if [[ "$http_code" -eq 201 ]] || [[ "$http_code" -eq 200 ]]; then
        echo -e "${C_GREEN}✅ DNS created${C_RESET}"
        sleep 5
    elif [[ "$http_code" -eq 409 ]]; then
        curl -s -X PATCH "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$api_sub/A/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "{\"records\":[\"$ip\"],\"ttl\":3600}" >/dev/null 2>&1
        echo -e "${C_GREEN}✅ DNS updated${C_RESET}"
    else
        echo -e "${C_RED}❌ Failed (HTTP $http_code)${C_RESET}"
    fi
    press_enter
}

web_panel_nginx_setup() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ⚙️ Nginx Setup ---${C_RESET}\n"
    if ! command -v nginx &>/dev/null; then
        echo -e "${C_BLUE}[1/4] Installing Nginx + Certbot...${C_RESET}"
        $PKG_INSTALL nginx certbot python3-certbot-nginx >/dev/null 2>&1
    else
        echo -e "${C_GREEN}✅ Nginx installed${C_RESET}"
    fi
    echo -e "\n${C_BLUE}[2/4] Writing config...${C_RESET}"
    [ -f "$WEB_PANEL_NGINX_CONFIG" ] && cp "$WEB_PANEL_NGINX_CONFIG" "$WEB_PANEL_NGINX_CONFIG.bak.$(date +%s)"
    cat > "$WEB_PANEL_NGINX_CONFIG" << EOF
server {
    listen 80;
    server_name $WEB_PANEL_API_DOMAIN;
    location / {
        proxy_pass http://127.0.0.1:$WEB_PANEL_API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, X-API-Key' always;
        if (\$request_method = 'OPTIONS') { return 204; }
    }
}
EOF
    echo -e "${C_GREEN}✅ Config written${C_RESET}"
    echo -e "\n${C_BLUE}[3/4] Enabling...${C_RESET}"
    ln -sf "$WEB_PANEL_NGINX_CONFIG" "$WEB_PANEL_NGINX_LINK"
    [ -f /etc/nginx/sites-enabled/default ] && rm -f /etc/nginx/sites-enabled/default
    echo -e "\n${C_BLUE}[4/4] Reloading...${C_RESET}"
    if nginx -t 2>&1 | grep -q "successful"; then
        systemctl reload nginx
        echo -e "${C_GREEN}✅ Nginx reloaded${C_RESET}"
    else
        echo -e "${C_RED}❌ Config error${C_RESET}"
        nginx -t
    fi
    press_enter
}

web_panel_ssl_setup() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔒 SSL Setup ---${C_RESET}\n"
    [ -d "/etc/letsencrypt/live/$WEB_PANEL_API_DOMAIN" ] && { echo -e "${C_YELLOW}⚠️  SSL exists${C_RESET}"; read -p "Renew? (y/n): " renew; [[ "$renew" != "y" ]] && return; }
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    local dns_ip=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
    if [[ "$dns_ip" != "$ip" ]]; then
        echo -e "${C_RED}❌ DNS not pointing!${C_RESET}"
        echo -e "  Expected: $ip"; echo -e "  Got:      $dns_ip"
        press_enter; return 1
    fi
    ! systemctl is-active --quiet nginx && { echo -e "${C_RED}❌ Nginx not running${C_RESET}"; press_enter; return 1; }
    echo -e "${C_BLUE}🔄 Requesting SSL...${C_RESET}\n"
    local ssl_email
    if [ -f "$WEB_PANEL_SSL_EMAIL_FILE" ]; then ssl_email=$(cat "$WEB_PANEL_SSL_EMAIL_FILE")
    else
        read -p "👉 Email (or Enter to skip): " ssl_email
        [ -n "$ssl_email" ] && echo "$ssl_email" > "$WEB_PANEL_SSL_EMAIL_FILE"
    fi
    local cmd
    if [ -n "$ssl_email" ]; then
        cmd="certbot --nginx -d $WEB_PANEL_API_DOMAIN --non-interactive --agree-tos -m $ssl_email --redirect"
    else
        cmd="certbot --nginx -d $WEB_PANEL_API_DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect"
    fi
    if eval "$cmd" 2>&1 | tee /tmp/certbot_webpanel.log | grep -q "Successfully"; then
        echo -e "\n${C_GREEN}✅ SSL installed!${C_RESET}"
        echo -e "${C_GREEN}🌐 https://$WEB_PANEL_API_DOMAIN${C_RESET}"
        systemctl enable certbot.timer &>/dev/null
        systemctl start certbot.timer &>/dev/null
    else
        echo -e "\n${C_RED}❌ SSL failed${C_RESET}"
        tail -15 /tmp/certbot_webpanel.log
    fi
    press_enter
}

web_panel_cors_setup() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔓 CORS Setup ---${C_RESET}\n"
    local api_file="$WEB_PANEL_API_DIR/api.py"
    [ ! -f "$api_file" ] && { echo -e "${C_RED}❌ API not found${C_RESET}"; press_enter; return 1; }
    grep -q "from flask_cors import CORS" "$api_file" && echo -e "${C_GREEN}✅ CORS in API${C_RESET}" || {
        sed -i 's/^from flask import Flask, request, jsonify$/from flask import Flask, request, jsonify\nfrom flask_cors import CORS/' "$api_file"
        echo -e "${C_GREEN}✅ CORS added${C_RESET}"
    }
    grep -q "CORS(app" "$api_file" && echo -e "${C_GREEN}✅ CORS initialized${C_RESET}" || {
        sed -i 's/^app = Flask(__name__)$/app = Flask(__name__)\nCORS(app, resources={r"\/api\/*": {"origins": "*"}}, supports_credentials=True)/' "$api_file"
    }
    [ -d "$WEB_PANEL_API_DIR/venv" ] && { source "$WEB_PANEL_API_DIR/venv/bin/activate"; pip install -q flask-cors 2>/dev/null; deactivate; }
    systemctl restart voltrontech-api
    sleep 2
    systemctl is-active --quiet voltrontech-api && echo -e "${C_GREEN}✅ API restarted${C_RESET}" || echo -e "${C_RED}❌ Failed${C_RESET}"
    press_enter
}

web_panel_test_all() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}       🧪 TESTING WEB PANEL${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}\n"
    local passed=0; local failed=0
    echo -e "${C_BLUE}[1/8] API service...${C_RESET}"
    systemctl is-active --quiet voltrontech-api 2>/dev/null && { echo -e "     ${C_GREEN}✅ Running${C_RESET}"; ((passed++)); } || { echo -e "     ${C_RED}❌ Not running${C_RESET}"; ((failed++)); }
    echo -e "${C_BLUE}[2/8] Nginx service...${C_RESET}"
    systemctl is-active --quiet nginx 2>/dev/null && { echo -e "     ${C_GREEN}✅ Running${C_RESET}"; ((passed++)); } || { echo -e "     ${C_RED}❌ Not running${C_RESET}"; ((failed++)); }
    echo -e "${C_BLUE}[3/8] Local API...${C_RESET}"
    curl -s http://localhost:$WEB_PANEL_API_PORT/api/health 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅ Responds${C_RESET}"; ((passed++)); } || { echo -e "     ${C_RED}❌ No response${C_RESET}"; ((failed++)); }
    echo -e "${C_BLUE}[4/8] DNS resolution...${C_RESET}"
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    local dns_ip=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
    [[ "$dns_ip" == "$ip" ]] && { echo -e "     ${C_GREEN}✅ $dns_ip${C_RESET}"; ((passed++)); } || { echo -e "     ${C_RED}❌ $dns_ip${C_RESET}"; ((failed++)); }
    echo -e "${C_BLUE}[5/8] HTTPS API...${C_RESET}"
    curl -s "https://$WEB_PANEL_API_DOMAIN/api/health" 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅ HTTPS works${C_RESET}"; ((passed++)); } || { echo -e "     ${C_RED}❌ HTTPS fails${C_RESET}"; ((failed++)); }
    echo -e "${C_BLUE}[6/8] SSL cert...${C_RESET}"
    [ -d "/etc/letsencrypt/live/$WEB_PANEL_API_DOMAIN" ] && { echo -e "     ${C_GREEN}✅ Installed${C_RESET}"; ((passed++)); } || { echo -e "     ${C_RED}❌ Not installed${C_RESET}"; ((failed++)); }
    echo -e "${C_BLUE}[7/8] CORS...${C_RESET}"
    curl -s -I -X OPTIONS "https://$WEB_PANEL_API_DOMAIN/api/trial/check" -H "Origin: https://example.com" -H "Access-Control-Request-Method: POST" 2>/dev/null | grep -qi "access-control-allow-origin" && { echo -e "     ${C_GREEN}✅ CORS enabled${C_RESET}"; ((passed++)); } || { echo -e "     ${C_RED}❌ CORS missing${C_RESET}"; ((failed++)); }
    echo -e "${C_BLUE}[8/8] API key...${C_RESET}"
    local api_key=$(cat "$WEB_PANEL_API_KEY_FILE" 2>/dev/null)
    [ -n "$api_key" ] && curl -s -H "X-API-Key: $api_key" "https://$WEB_PANEL_API_DOMAIN/api/protocols/status" 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅ Valid${C_RESET}"; ((passed++)); } || { echo -e "     ${C_RED}❌ Invalid${C_RESET}"; ((failed++)); }
    echo ""
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    [[ $failed -eq 0 ]] && echo -e "${C_GREEN}✅ ALL PASSED ($passed/8)${C_RESET}" || echo -e "${C_YELLOW}⚠️  Passed: $passed/8 Failed: $failed${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    press_enter
}

web_panel_view_logs() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 Logs ---${C_RESET}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} API log"
    echo -e "  ${C_GREEN}2)${C_RESET} Nginx access"
    echo -e "  ${C_GREEN}3)${C_RESET} Nginx error"
    echo -e "  ${C_GREEN}4)${C_RESET} Certbot"
    echo -e "  ${C_RED}0)${C_RESET} Return"
    read -p "👉 Choice: " c
    case $c in
        1) tail -30 /var/log/voltrontech-api.log 2>/dev/null; press_enter ;;
        2) tail -20 /var/log/nginx/access.log 2>/dev/null; press_enter ;;
        3) tail -20 /var/log/nginx/error.log 2>/dev/null; press_enter ;;
        4) tail -20 /var/log/letsencrypt/letsencrypt.log 2>/dev/null; press_enter ;;
        0) return ;;
    esac
}

web_panel_renew_ssl() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔄 Renew SSL ---${C_RESET}\n"
    certbot renew --nginx --non-interactive 2>&1 | tail -10
    echo -e "\n${C_GREEN}✅ Done${C_RESET}"
    press_enter
}

web_panel_view_api_info() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔑 API Information ---${C_RESET}\n"
    [ ! -f "$WEB_PANEL_API_INFO_FILE" ] && { echo -e "${C_RED}❌ Not installed${C_RESET}"; press_enter; return; }
    local api_key=$(cat "$WEB_PANEL_API_KEY_FILE" 2>/dev/null)
    echo -e "  ${C_YELLOW}🌐 HTTPS:${C_RESET}    ${C_GREEN}https://$WEB_PANEL_API_DOMAIN${C_RESET}"
    echo -e "  ${C_YELLOW}🔑 API Key:${C_RESET}  ${C_GREEN}$api_key${C_RESET}"
    echo -e "  ${C_YELLOW}📊 Limit:${C_RESET}    ${C_WHITE}999 connections${C_RESET}"
    echo -e "  ${C_YELLOW}📦 BW:${C_RESET}       ${C_WHITE}Unlimited${C_RESET}"
    echo ""
    echo -e "  ${C_YELLOW}📋 Endpoints:${C_RESET}"
    echo -e "    POST /api/trial/check"
    echo -e "    POST /api/trial/create"
    echo -e "    GET  /api/trial/status/<username>"
    echo -e "    GET  /api/protocols/status"
    echo -e "    GET  /api/users/list"
    echo -e "    GET  /api/dashboard/info"
    echo -e "    GET  /api/health"
    press_enter
}

web_panel_restart_api() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔄 Restart API ---${C_RESET}\n"
    systemctl restart voltrontech-api
    sleep 2
    systemctl is-active --quiet voltrontech-api && echo -e "${C_GREEN}✅ Restarted${C_RESET}" || echo -e "${C_RED}❌ Failed${C_RESET}"
    press_enter
}

web_panel_copy_for_lovable() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📝 Copy for Lovable AI ---${C_RESET}\n"
    [ ! -f "$WEB_PANEL_API_KEY_FILE" ] && { echo -e "${C_RED}❌ Not installed${C_RESET}"; press_enter; return; }
    local api_key=$(cat "$WEB_PANEL_API_KEY_FILE")
    echo -e "${C_YELLOW}═══════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_WHITE}COPY HII KWA LOVABLE AI:${C_RESET}"
    echo -e "${C_YELLOW}═══════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "${C_CYAN}API URL:${C_RESET} ${C_GREEN}https://$WEB_PANEL_API_DOMAIN${C_RESET}"
    echo -e "${C_CYAN}API Key:${C_RESET} ${C_GREEN}$api_key${C_RESET}"
    echo -e "${C_CYAN}Default Limit:${C_RESET} ${C_GREEN}999${C_RESET}"
    echo -e "${C_CYAN}Default BW:${C_RESET} ${C_GREEN}Unlimited${C_RESET}"
    press_enter
}

web_panel_remove() {
    clear; show_banner
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_RED}       🗑️ REMOVE WEB PANEL${C_RESET}"
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}\n"
    read -p "⚠️  Confirm? (y/n): " confirm
    [[ "$confirm" != "y" ]] && return
    systemctl stop voltrontech-api 2>/dev/null
    systemctl disable voltrontech-api 2>/dev/null
    rm -f /etc/systemd/system/voltrontech-api.service
    rm -rf "$WEB_PANEL_API_DIR"
    rm -f "$WEB_PANEL_NGINX_LINK" "$WEB_PANEL_NGINX_CONFIG"
    nginx -t 2>&1 | grep -q "successful" && systemctl reload nginx
    [ -d "/etc/letsencrypt/live/$WEB_PANEL_API_DOMAIN" ] && certbot delete --cert-name "$WEB_PANEL_API_DOMAIN" --non-interactive 2>/dev/null
    systemctl daemon-reload
    echo -e "\n${C_GREEN}✅ Removed${C_RESET}"
    press_enter
}

# ========== SPEED OPTIMIZATION MENU ==========
speed_optimization_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           ⚡ DNSTT SPEED BOOSTERS${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_GREEN}[1]${C_RESET} Standard (32MB) → 10-15 Mbps"
        echo -e "  ${C_GREEN}[2]${C_RESET} Medium (64MB) → 15-20 Mbps"
        echo -e "  ${C_GREEN}[3]${C_RESET} High (128MB) → 20-25 Mbps"
        echo -e "  ${C_GREEN}[4]${C_RESET} Ultra (256MB) → 25-35 Mbps"
        echo -e "  ${C_GREEN}[5]${C_RESET} Extreme (512MB) → 35-50 Mbps"
        echo -e "  ${C_GREEN}[6]${C_RESET} Ultra Plus (768MB) → 40-60 Mbps"
        echo -e "  ${C_GREEN}[7]${C_RESET} Extreme Plus (1GB) → 60-100 Mbps"
        echo -e "\n  ${C_RED}[0]${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) apply_dnstt_standard; press_enter ;;
            2) apply_dnstt_medium; press_enter ;;
            3) apply_dnstt_high; press_enter ;;
            4) apply_dnstt_ultra; press_enter ;;
            5) apply_dnstt_extreme; press_enter ;;
            6) apply_dnstt_ultra_plus; press_enter ;;
            7) apply_dnstt_extreme_plus; press_enter ;;
            0) return ;;
        esac
    done
}

# ================================================================
# 🔧 LIMITER SERVICE — Inaunda Dynamic Banner (Match User *)
# ================================================================
create_limiter_service() {
    cat > "$LIMITER_SCRIPT" << 'LIMEOF'
#!/bin/bash
DB_FILE="/etc/voltrontech/users.db"
BW_DIR="/etc/voltrontech/bandwidth"
PID_DIR="$BW_DIR/pidtrack"
BANNER_DIR="/etc/voltrontech/banners"
BANNER_ENABLED_FILE="/etc/voltrontech/banners_enabled"
SCAN_INTERVAL=15

mkdir -p "$BW_DIR" "$PID_DIR" "$BANNER_DIR"
shopt -s nullglob

write_banner_if_changed() {
    local user="$1"
    local content="$2"
    local bf="$BANNER_DIR/${user}.txt"
    local tf="${bf}.tmp"
    printf "%s" "$content" > "$tf"
    if ! cmp -s "$tf" "$bf" 2>/dev/null; then mv "$tf" "$bf"; else rm -f "$tf"; fi
}

while true; do
    [[ ! -s "$DB_FILE" ]] && { sleep "$SCAN_INTERVAL"; continue; }

    current_ts=$(date +%s)
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
        loginuid_pids["$session_user"]+="$pid_num "
    done

    while read -r passwd_user _ passwd_status _rest; do
        [[ "$passwd_status" == "L" ]] && locked_users["$passwd_user"]=1
    done < <(passwd -Sa 2>/dev/null)

    while IFS=: read -r user pass expiry limit bandwidth_gb traffic_used status; do
        [[ -z "$user" || "$user" == \#* ]] && continue
        [[ -z "$status" ]] && status="ACTIVE"

        declare -A unique_pids=()
        for pid in ${session_pids["$user"]} ${loginuid_pids["$user"]}; do
            [[ "$pid" =~ ^[0-9]+$ ]] && unique_pids["$pid"]=1
        done

        online_count=${#unique_pids[@]}
        user_locked=false
        is_expired=false
        bw_exhausted=false

        if passwd -S "$user" 2>/dev/null | grep -q " L "; then user_locked=true; fi
        [[ -n "${locked_users[$user]+x}" ]] && user_locked=true

        expiry_ts=0
        if [[ "$expiry" != "Never" && -n "$expiry" ]]; then
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                is_expired=true
                if ! $user_locked; then usermod -L "$user" &>/dev/null; user_locked=true; fi
            fi
        fi

        [[ "$limit" =~ ^[0-9]+$ ]] || limit=999
        if (( online_count > limit )); then
            if ! $user_locked; then
                usermod -L "$user" &>/dev/null
                killall -u "$user" -9 &>/dev/null
                user_locked=true
            fi
        fi

        usagefile="$BW_DIR/${user}.usage"
        accum_disp=0
        if [[ -f "$usagefile" ]]; then
            read -r accum_disp < "$usagefile"
            [[ "$accum_disp" =~ ^[0-9]+$ ]] || accum_disp=0
        fi

        if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
            quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
            if (( quota_bytes > 0 && accum_disp >= quota_bytes )); then
                bw_exhausted=true
                if ! $user_locked; then usermod -L "$user" &>/dev/null; user_locked=true; fi
            fi
        fi

        if $user_locked; then account_status="🔒 LOCKED"; status_color="#FF6B6B"
        elif $is_expired; then account_status="🗓️ EXPIRED"; status_color="#FF9F43"
        elif $bw_exhausted; then account_status="⚠️ DATA EXHAUSTED"; status_color="#FF6B6B"
        else account_status="✅ ACTIVE"; status_color="#6BCB77"; fi

        days_left="N/A"
        if [[ "$expiry" != "Never" && -n "$expiry" && "$expiry_ts" =~ ^[0-9]+$ && $expiry_ts -gt 0 ]]; then
            diff_secs=$((expiry_ts - current_ts))
            if (( diff_secs <= 0 )); then days_left="EXPIRED"
            else
                d_l=$(( diff_secs / 86400 ))
                h_l=$(( (diff_secs % 86400) / 3600 ))
                if (( d_l == 0 )); then days_left="${h_l}h left"
                else days_left="${d_l}d ${h_l}h"; fi
            fi
        fi

        bw_info="Unlimited"
        if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
            used_gb=$(awk "BEGIN {printf \"%.2f\", $accum_disp / 1073741824}")
            remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}")
            bw_info="${used_gb}/${bandwidth_gb} GB | ${remain_gb} GB left"
        fi

        if [[ -f "$BANNER_ENABLED_FILE" ]]; then
            UPTIME=$(uptime -p | sed 's/up //')
            LOAD=$(awk '{print $1}' /proc/loadavg)

            banner_content=""
            banner_content+="<br><br>"
            banner_content+="<center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b> 🌍VOLTRON VPN🌍</b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"
            banner_content+="<br>"
            banner_content+="<center><font color=\"#4D96FF\" size=\"5\"><b>📋 ACCOUNT DETAILS 📋</b></font></center><br>"
            banner_content+="<br>"
            banner_content+="<center><font color=\"#000000\">👤 <b>Username      :</b> $user</font></center><br>"
            banner_content+="<center><font color=\"#000000\">📅 <b>Expiration    :</b> $expiry ($days_left)</font></center><br>"
            banner_content+="<center><font color=\"#4D96FF\">📊 <b>Bandwidth     :</b> $bw_info</font></center><br>"
            banner_content+="<center><font color=\"#000000\">🔌 <b>Sessions      :</b> $online_count/$limit</font></center><br>"
            banner_content+="<center><font color=\"$status_color\" size=\"4\"><b>📌 Account Status : $account_status</b></font></center><br>"
            banner_content+="<br>"
            banner_content+="<center><font color=\"#000000\">⏱️ <b>Server Uptime :</b> $UPTIME</font></center><br>"
            banner_content+="<center><font color=\"#000000\">📈 <b>Server Load   :</b> $LOAD</font></center><br>"
            banner_content+="<br>"
            banner_content+="<center><font color=\"#6BCB77\" size=\"4\"><b>📢 JOIN OUR COMMUNITY 📢</b></font></center><br>"
            banner_content+="<center><font color=\"#000000\">📱 Telegram  : https://t.me/voltrontech</font></center><br>"
            banner_content+="<center><font color=\"#000000\">💬 WhatsApp  : https://chat.whatsapp.com/EZtAFt9dmS5DVKbNN5iSPz</font></center><br>"
            banner_content+="<br>"
            banner_content+="<center><font color=\"#FF6B6B\" size=\"4\"><b>⚠️ IMPORTANT NOTICE ⚠️</b></font></center><br>"
            banner_content+="<center><font color=\"#000000\">• Account expires on: $expiry</font></center><br>"
            banner_content+="<center><font color=\"#000000\">• No torrent or illegal activity</font></center><br>"
            banner_content+="<center><font color=\"#000000\">• Account sharing is prohibited</font></center><br>"
            banner_content+="<br>"
            banner_content+="<center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b>  🌍VOLTRON VPN🌍 </b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"

            write_banner_if_changed "$user" "$banner_content"
        fi

        [[ -z "$bandwidth_gb" || "$bandwidth_gb" == "0" ]] && continue

        accumulated=$accum_disp

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
                if (( cur >= prev )); then d=$((cur - prev))
                else d=$cur; fi
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

        traffic_used_gb=$(awk "BEGIN {printf \"%.2f\", $new_total / 1073741824}" 2>/dev/null)
        if [[ -n "$traffic_used_gb" ]]; then
            sed -i "s/^$user:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*/$user:$pass:$expiry:$limit:$bandwidth_gb:$traffic_used_gb:$status/" "$DB_FILE" 2>/dev/null
        fi
    done < "$DB_FILE"

    sleep "$SCAN_INTERVAL"
done
LIMEOF
    chmod +x "$LIMITER_SCRIPT"
    sed -i 's/\r$//' "$LIMITER_SCRIPT" 2>/dev/null

    cat > "$LIMITER_SERVICE" << EOF
[Unit]
Description=Voltron Connection & Traffic Limiter with Dynamic Banner
After=network.target

[Service]
Type=simple
ExecStart=$LIMITER_SCRIPT
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    sed -i 's/\r$//' "$LIMITER_SERVICE" 2>/dev/null

    pkill -f "voltrontech-limiter" 2>/dev/null

    if ! systemctl is-active --quiet voltrontech-limiter; then
        systemctl daemon-reload
        systemctl enable voltrontech-limiter &>/dev/null
        systemctl start voltrontech-limiter --no-block &>/dev/null
    else
        systemctl restart voltrontech-limiter --no-block &>/dev/null
    fi
}

# ========== TRAFFIC MONITOR (service) ==========
create_traffic_monitor() {
    cat > "$TRAFFIC_SCRIPT" <<'EOF'
#!/bin/bash
DB_FILE="/etc/voltrontech/users.db"
TRAFFIC_DIR="/etc/voltrontech/traffic"
mkdir -p "$TRAFFIC_DIR"

while true; do
    if [ -f "$DB_FILE" ]; then
        while IFS=: read -r user pass expiry limit traffic_limit traffic_used status; do
            [[ -z "$user" ]] && continue
            if id "$user" &>/dev/null; then
                traffic_file="$TRAFFIC_DIR/$user"
                if [ -f "$traffic_file" ]; then
                    current_bytes=$(cat "$traffic_file" 2>/dev/null || echo "0")
                    current_gb=$(echo "scale=3; $current_bytes / 1073741824" | bc 2>/dev/null || echo "0")
                    sed -i "s/^$user:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*/$user:$pass:$expiry:$limit:$traffic_limit:$current_gb:$status/" "$DB_FILE" 2>/dev/null
                fi
            fi
        done < "$DB_FILE"
    fi
    sleep 60
done
EOF
    chmod +x "$TRAFFIC_SCRIPT"

    cat > "$TRAFFIC_SERVICE" <<EOF
[Unit]
Description=Voltron Traffic Monitor
After=network.target

[Service]
Type=simple
ExecStart=$TRAFFIC_SCRIPT
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable voltron-traffic.service 2>/dev/null
    systemctl restart voltron-traffic.service 2>/dev/null
}

# ========== INITIAL SETUP ==========
initial_setup() {
    echo -e "\n${C_BLUE}🔧 Running initial system setup...${C_RESET}"

    detect_os_version
    detect_package_manager
    detect_service_manager
    detect_firewall
    install_dependencies

    create_directories
    create_limiter_service
    create_traffic_monitor

    get_ip_info

    if [[ -f "$BANNER_ENABLED_FILE" ]]; then
        update_ssh_banners_config
    fi
}

# ========== UNINSTALL SCRIPT ==========
uninstall_script() {
    clear
    show_banner
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_RED}           💥 UNINSTALL SCRIPT & ALL DATA${C_RESET}"
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_YELLOW}This will PERMANENTLY remove this script and all its components."
    echo -e "\n${C_RED}This action is irreversible.${C_RESET}"
    echo ""

    read -p "👉 Type 'YES' to confirm: " confirm
    if [[ "$confirm" != "YES" ]]; then
        echo -e "\n${C_GREEN}✅ Uninstallation cancelled.${C_RESET}"
        safe_read "" dummy
        return
    fi

    echo -e "\n${C_BLUE}--- 💥 Starting Uninstallation ---${C_RESET}"

    delete_desec_dns_records

    (crontab -l 2>/dev/null | grep -v "reboot") | crontab - 2>/dev/null
    rm -f "$CACHE_CRON_FILE" 2>/dev/null
    crontab -l 2>/dev/null | grep -v "voltron-cache-clean" | crontab - 2>/dev/null

    systemctl stop dnstt.service v2ray-dnstt.service badvpn.service udp-custom.service haproxy voltronproxy.service nginx zivpn.service 2>/dev/null
    systemctl disable dnstt.service v2ray-dnstt.service badvpn.service udp-custom.service voltronproxy.service 2>/dev/null
    systemctl stop voltrontech-limiter.service voltron-traffic.service 2>/dev/null
    systemctl disable voltrontech-limiter.service voltron-traffic.service 2>/dev/null

    systemctl stop voltrontech-api 2>/dev/null
    systemctl disable voltrontech-api 2>/dev/null
    rm -f /etc/systemd/system/voltrontech-api.service
    rm -rf "$WEB_PANEL_API_DIR"
    rm -f "$WEB_PANEL_NGINX_LINK" "$WEB_PANEL_NGINX_CONFIG"
    [ -d "/etc/letsencrypt/live/$WEB_PANEL_API_DOMAIN" ] && certbot delete --cert-name "$WEB_PANEL_API_DOMAIN" --non-interactive 2>/dev/null
    nginx -t 2>&1 | grep -q "successful" && systemctl reload nginx 2>/dev/null

    rm -f "$DNSTT_SERVICE" "$V2RAY_SERVICE" "$BADVPN_SERVICE" "$UDP_CUSTOM_SERVICE" "$VOLTRONPROXY_SERVICE" "$ZIVPN_SERVICE"
    rm -f "$TRAFFIC_SERVICE" "$LIMITER_SERVICE"

    rm -f "$DNSTT_SERVER" "$DNSTT_CLIENT" "$V2RAY_BIN" "$BADVPN_BIN" "$UDP_CUSTOM_BIN" "$VOLTRONPROXY_BIN" "$ZIVPN_BIN"
    rm -f "$LIMITER_SCRIPT" "$TRAFFIC_SCRIPT"
    rm -f "$CACHE_SCRIPT"

    rm -rf "$BADVPN_BUILD_DIR" "$UDP_CUSTOM_DIR" "$ZIVPN_DIR"
    rm -rf "$DB_DIR" "$TRAFFIC_DIR"

    chattr -i /etc/resolv.conf 2>/dev/null
    rm -f /etc/resolv.conf
    echo "nameserver 8.8.8.8" > /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf

    systemctl restart sshd

    rm -f /usr/local/bin/menu
    rm -f "$0"

    systemctl daemon-reload

    echo -e "\n${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}      ✅ SCRIPT UNINSTALLED SUCCESSFULLY!${C_RESET}"
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "\nPress any key to exit..."
    read -n 1
    exit 0
}

# ================================================================
# MAIN MENU + STARTUP
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
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "5" "Bulk Create Users" "10" "📊 View Bandwidth"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "11" "📱 Generate Config" "12" "Protocols & Panels"

        echo ""
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    ⚙️ SYSTEM UTILITIES${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "13" "Backup Users" "18" "Auto Reboot"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "14" "Restore Users" "19" "Cache Cleaner"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "15" "DNS Domain" "20" "Traffic Monitor"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "16" "⚡ Speed Optimization" "21" "Block Torrent"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "17" "🎨 SSH Banner" "22" "🌐 Web Panel"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "23" "🖥️ VPS Dashboard" "24" "V2Ray Management"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s\n" "25" "🚀 DT Proxy"

        echo ""
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    🔥 DANGER ZONE${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_RED}%2s${C_RESET}) %-28s  ${C_RED}%2s${C_RESET}) %-25s\n" "99" "Uninstall Script" "0" "Exit"

        echo ""
        local choice
        safe_read "👉 Select an option: " choice

        case $choice in
            1) _create_user ;;
            2) _delete_user ;;
            3) _edit_user ;;
            4) _lock_user ;;
            5) _bulk_create_users ;;
            6) _unlock_user ;;
            7) _list_users ;;
            8) _renew_user ;;
            9) _cleanup_expired ;;
            10) _view_user_bandwidth ;;
            11) client_config_menu ;;
            12) protocol_menu ;;

            13) backup_user_data ;;
            14) restore_user_data ;;
            15) dns_menu ;;
            16) speed_optimization_menu ;;
            17) ssh_banner_menu ;;
            18) auto_reboot_menu ;;
            19) cache_cleaner_menu ;;
            20) traffic_monitor_menu ;;
            21) torrent_block_menu ;;
            22) web_panel_menu ;;
            23) show_vps_dashboard ;;
            24) v2ray_main_menu ;;
            25) dt_proxy_menu ;;

            99) uninstall_script ;;
            0) echo -e "\n${C_BLUE}👋 Goodbye!${C_RESET}"; exit 0 ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ========== START ==========
if [[ $EUID -ne 0 ]]; then
    echo -e "${C_RED}❌ This script must be run as root!${C_RESET}"
    exit 1
fi

if [[ "$1" == "--install-setup" ]]; then
    initial_setup
    exit 0
fi

main_menu
