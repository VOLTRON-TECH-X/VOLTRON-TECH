#!/bin/bash
# ================================================================
# VOLTRON TECH ULTIMATE v10.18 FINAL
# ================================================================
# Changelog v10.18:
#   + FIXED: Limiter now counts ALL user PIDs (sshd + bash + wget)
#   + FIXED: Bandwidth progress bar with smart KB/MB/GB formatter
#   + FIXED: Percentage and used bytes now match perfectly
#   + FIXED: ONLINE counter no longer duplicates (0\n0)
#   + FIXED: DB traffic field updates correctly
#   + CRITICAL warning (data >= 95%)
#   + EXPIRING SOON / EXPIRING / EXPIRES TODAY warnings
#   + Generator & Limiter produce IDENTICAL HTML
#   + Custom API domain (configurable)
#   + API Dynamic Banner endpoints
#   + Speed Boosters: TCP Fast Open + BBR + fq
# ================================================================

C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_DIM=$'\033[2m'; C_UL=$'\033[4m'
C_RED=$'\033[38;5;196m'; C_GREEN=$'\033[38;5;46m'; C_YELLOW=$'\033[38;5;226m'
C_BLUE=$'\033[38;5;39m'; C_PURPLE=$'\033[38;5;135m'; C_CYAN=$'\033[38;5;51m'
C_WHITE=$'\033[38;5;255m'; C_GRAY=$'\033[38;5;245m'; C_ORANGE=$'\033[38;5;208m'

DESEC_TOKEN="3WxD4Hkiu5VYBLWVizVhf1rzyKbz"
DESEC_DOMAIN="voltrontechtx.shop"

DB_DIR="/etc/voltrontech"; DB_FILE="$DB_DIR/users.db"; INSTALL_FLAG_FILE="$DB_DIR/.install"
LOGS_DIR="$DB_DIR/logs"; CONFIG_DIR="$DB_DIR/config"; BANDWIDTH_DIR="$DB_DIR/bandwidth"
BANNER_DIR="$DB_DIR/banners"; DNSTT_KEYS_DIR="$DB_DIR/dnstt"; SSL_CERT_DIR="$DB_DIR/ssl"
SSL_CERT_FILE="$SSL_CERT_DIR/voltrontech.pem"; TRAFFIC_DIR="$DB_DIR/traffic"
BACKUP_DIR="$DB_DIR/backups"; DNS_INFO_FILE="$DB_DIR/dns_info.conf"
MTU_CONFIG="$CONFIG_DIR/mtu"; BANNER_ENABLED_FILE="$DB_DIR/banners_enabled"
SSHD_FF_CONFIG="/etc/ssh/sshd_config.d/voltron-auto-banner.conf"
TRIAL_CLEANUP_SCRIPT="/usr/local/bin/voltrontech-trial-cleanup.sh"
FF_USERS_GROUP="ffusers"

DNSTT_SERVICE_FILE="/etc/systemd/system/dnstt.service"
DNSTT_BINARY="/usr/local/bin/dnstt-server"
DNSTT_CLIENT="/usr/local/bin/dnstt-client"
DNSTT_CONFIG_FILE="$DB_DIR/dnstt_info.conf"
BADVPN_SERVICE_FILE="/etc/systemd/system/badvpn.service"
BADVPN_BIN="/usr/local/bin/badvpn-udpgw"
UDP_CUSTOM_SERVICE_FILE="/etc/systemd/system/udp-custom.service"
UDP_CUSTOM_BIN="/usr/local/bin/udp-custom"
HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"
FALCONPROXY_SERVICE_FILE="/etc/systemd/system/falconproxy.service"
FALCONPROXY_BINARY="/usr/local/bin/falconproxy"
ZIVPN_DIR="/etc/zivpn"; ZIVPN_BIN="/usr/local/bin/zivpn"
ZIVPN_SERVICE_FILE="/etc/systemd/system/zivpn.service"
ZIVPN_CONFIG_FILE="$ZIVPN_DIR/config.json"
LIMITER_SCRIPT="/usr/local/bin/voltrontech-limiter.sh"
LIMITER_SERVICE="/etc/systemd/system/voltrontech-limiter.service"
TRAFFIC_SCRIPT="/usr/local/bin/voltron-traffic.sh"
TRAFFIC_SERVICE="/etc/systemd/system/voltron-traffic.service"
CACHE_CRON_FILE="/etc/cron.d/voltron-cache-clean"
CACHE_SCRIPT="/usr/local/bin/voltron-cache-clean"
BANNER_BUILDER="/usr/local/bin/voltrontech-banner-build.sh"

API_DIR="/opt/voltrontech-api"; API_PORT="5000"
API_KEY_FILE="$DB_DIR/api_key.txt"; API_INFO_FILE="$DB_DIR/api_info.txt"
WEB_PANEL_DOMAIN_FILE="$DB_DIR/web_panel_domain.txt"
WEB_PANEL_NGINX_CONFIG="/etc/nginx/sites-available/voltrontech-api"
WEB_PANEL_NGINX_LINK="/etc/nginx/sites-enabled/voltrontech-api"
WEB_PANEL_SSL_EMAIL_FILE="$DB_DIR/ssl_email.txt"

if [[ -f "$WEB_PANEL_DOMAIN_FILE" ]]; then
    WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")
else
    WEB_PANEL_API_DOMAIN="api.voltrontechtx.shop"
fi

SELECTED_USER=""; SELECTED_USERS=()

_APT_UPDATED=0
ff_apt_update() {
    (( _APT_UPDATED )) && return
    DEBIAN_FRONTEND=noninteractive apt-get update 2>/dev/null || true
    _APT_UPDATED=1
}
ff_apt_install() { ff_apt_update; DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 install "$@"; }
ff_apt_purge() { DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 purge "$@"; }

BANNER_CACHE_TTL=15; BANNER_CACHE_TS=0
BANNER_CACHE_OS_NAME=""; BANNER_CACHE_UP_TIME=""; BANNER_CACHE_RAM_USAGE=""
BANNER_CACHE_CPU_LOAD=""; BANNER_CACHE_ONLINE_USERS=0; BANNER_CACHE_TOTAL_USERS=0

refresh_banner_cache() {
    local now=$(date +%s)
    if (( BANNER_CACHE_TS > 0 && now - BANNER_CACHE_TS < BANNER_CACHE_TTL )); then return; fi
    BANNER_CACHE_OS_NAME=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Linux")
    BANNER_CACHE_UP_TIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    BANNER_CACHE_RAM_USAGE=$(free -m | awk '/^Mem:/{if($2>0){printf "%.2f", $3*100/$2}else{print "0.00"}}')
    BANNER_CACHE_CPU_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    if [[ -s "$DB_FILE" ]]; then BANNER_CACHE_TOTAL_USERS=$(grep -c . "$DB_FILE"); else BANNER_CACHE_TOTAL_USERS=0; fi
    BANNER_CACHE_ONLINE_USERS=$(pgrep -c -u root sshd 2>/dev/null); BANNER_CACHE_ONLINE_USERS=${BANNER_CACHE_ONLINE_USERS:-0}
    BANNER_CACHE_TS=$now
}

show_banner() {
    refresh_banner_cache
    [[ -t 1 ]] && clear
    echo
    echo -e "${C_PURPLE}   VOLTRON TECH ULTIMATE v10.18 ${C_RESET}${C_DIM}| Premium Edition${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "OS" "$BANNER_CACHE_OS_NAME" "Uptime: $BANNER_CACHE_UP_TIME"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Memory" "${BANNER_CACHE_RAM_USAGE}% Used" "Online: ${C_WHITE}${BANNER_CACHE_ONLINE_USERS}${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Users" "${BANNER_CACHE_TOTAL_USERS} Managed" "Load: ${C_GREEN}${BANNER_CACHE_CPU_LOAD}${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
}

press_enter() { echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to continue..." && read -r; }
invalidate_banner_cache() { BANNER_CACHE_TS=0; }
get_current_mtu() { [ -f "$MTU_CONFIG" ] && cat "$MTU_CONFIG" || echo "512"; }

# ============================================================
# SMART SIZE FORMATTER — KB / MB / GB
# ============================================================
format_size() {
    local bytes=$1
    [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
    if (( bytes >= 1073741824 )); then
        awk "BEGIN{printf \"%.2f GB\", $bytes/1073741824}"
    elif (( bytes >= 1048576 )); then
        awk "BEGIN{printf \"%.2f MB\", $bytes/1048576}"
    elif (( bytes >= 1024 )); then
        awk "BEGIN{printf \"%.2f KB\", $bytes/1024}"
    else
        echo "${bytes} B"
    fi
}

# ============================================================
# BANDWIDTH PROGRESS BAR — for generate_user_banner()
# ============================================================
build_bandwidth_bar() {
    local used_bytes="$1"
    local limit_gb="$2"

    if [[ "$limit_gb" == "0" || -z "$limit_gb" ]]; then
        echo '<font color="#6BCB77">Unlimited ∞</font>'
        return
    fi

    local limit_bytes=$(awk "BEGIN{printf \"%.0f\", $limit_gb*1073741824}")
    [[ "$limit_bytes" -le 0 ]] && limit_bytes=1

    local pct=$(awk "BEGIN{printf \"%.1f\", ($used_bytes/$limit_bytes)*100}")
    local pct_int=$(awk "BEGIN{printf \"%d\", ($used_bytes/$limit_bytes)*100}")
    [[ "$pct_int" -gt 100 ]] && pct_int=100
    [[ "$pct_int" -lt 0 ]] && pct_int=0

    local remaining_bytes=$((limit_bytes - used_bytes))
    [[ $remaining_bytes -lt 0 ]] && remaining_bytes=0

    local used_display=$(format_size "$used_bytes")
    local limit_display=$(format_size "$limit_bytes")
    local remaining_display=$(format_size "$remaining_bytes")

    local bar_color="#6BCB77"
    local text_color="#6BCB77"

    if (( $(echo "$pct >= 95" | bc -l) )); then
        bar_color="#FF6B6B"; text_color="#FF6B6B"
    elif (( $(echo "$pct >= 80" | bc -l) )); then
        bar_color="#FF9F43"; text_color="#FF9F43"
    elif (( $(echo "$pct >= 60" | bc -l) )); then
        bar_color="#FFD93D"; text_color="#FFD93D"
    fi

    local total_blocks=10
    local filled=$((pct_int * total_blocks / 100))
    [[ $filled -gt $total_blocks ]] && filled=$total_blocks
    [[ $filled -lt 0 ]] && filled=0
    local empty=$((total_blocks - filled))

    local bar=""
    local i
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    echo "<font color=\"$bar_color\">$bar</font> <font color=\"$text_color\"><b>${pct}%</b></font> <font color=\"#9B59B6\">|</font> <font color=\"#000000\">${used_display}/${limit_display}</font> <font color=\"#6BCB77\">(${remaining_display} left)</font>"
}

# ============================================================
# GENERATOR BANNER — LIVE DATA + SMART FORMATTER
# ============================================================
generate_user_banner() {
    local username="$1" expiry="$2" limit="$3" bandwidth_gb="$4"
    mkdir -p "$BANNER_DIR"

    # ============ BANDWIDTH INFO ============
    local ub=0
    if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
        [[ -f "$BANDWIDTH_DIR/${username}.usage" ]] && ub=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null | tr -d '[:space:]')
        [[ ! "$ub" =~ ^[0-9]+$ ]] && ub=0
    fi
    local bw_display=$(build_bandwidth_bar "$ub" "$bandwidth_gb")

    # ============ SESSIONS (live) ============
    local sessions=$(pgrep -c -u "$username" 2>/dev/null)
    [[ -z "$sessions" || ! "$sessions" =~ ^[0-9]+$ ]] && sessions=0

    # ============ ACCOUNT STATUS ============
    local acct_status="✅ ACTIVE"
    local status_color="#6BCB77"

    local passwd_flag=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
    if [[ "$passwd_flag" == "L" ]]; then
        acct_status="🔒 LOCKED"
        status_color="#FF6B6B"
    else
        local expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        local now_ts=$(date +%s)
        local days_left=0
        local skip_bw=false

        if [[ "$expiry_ts" -gt 0 ]]; then
            days_left=$(( (expiry_ts - now_ts) / 86400 ))

            if [[ "$days_left" -lt 0 ]]; then
                acct_status="🗓️ EXPIRED"; status_color="#FF9F43"; skip_bw=true
            elif [[ "$days_left" -eq 0 ]]; then
                acct_status="⚠️ EXPIRES TODAY"; status_color="#FF6B6B"; skip_bw=true
            elif [[ "$days_left" -le 2 ]]; then
                acct_status="🔴 EXPIRING - ${days_left} DAY$( [[ $days_left -eq 1 ]] && echo '' || echo 'S' ) LEFT"; status_color="#FF9F43"; skip_bw=true
            elif [[ "$days_left" -le 7 ]]; then
                acct_status="⏰ EXPIRING SOON - ${days_left} DAYS LEFT"; status_color="#FFD93D"; skip_bw=true
            fi
        fi

        if ! $skip_bw; then
            if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" && "$ub" -gt 0 ]]; then
                local qb=$(awk "BEGIN{printf \"%.0f\", $bandwidth_gb*1073741824}")
                local pct=$(awk "BEGIN{printf \"%.1f\", ($ub/$qb)*100}")
                local rem=$(format_size $(awk "BEGIN{r=$qb - $ub; if(r<0)r=0; printf \"%.0f\", r}"))

                if (( $(echo "$pct >= 100" | bc -l) )); then
                    acct_status="⚠️ DATA EXHAUSTED"; status_color="#FF6B6B"
                elif (( $(echo "$pct >= 95" | bc -l) )); then
                    acct_status="🔴 CRITICAL - ${rem} LEFT"; status_color="#FF9F43"
                fi
            fi
        fi
    fi

    local uptime_str=$(uptime -p | sed 's/up //')
    local load_str=$(awk '{print $1}' /proc/loadavg)

    # ============ BUILD BANNER (bc= + bc+=) ============
    local bc=""
    bc+="<br><br>"
    bc+="<center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b> 🌍VOLTRON VPN🌍</b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"
    bc+="<br>"
    bc+="<center><font color=\"#4D96FF\" size=\"5\"><b>📋 ACCOUNT DETAILS 📋</b></font></center><br>"
    bc+="<br>"
    bc+="<center><font color=\"#000000\">👤 <b>Username      :</b> $username</font></center><br>"
    bc+="<center><font color=\"#000000\">📅 <b>Expiration    :</b> $expiry</font></center><br>"
    bc+="<center>📊 <b>Bandwidth     :</b> $bw_display</center><br>"
    bc+="<center><font color=\"#000000\">🔌 <b>Sessions      :</b> $sessions/$limit</font></center><br>"
    bc+="<center><font color=\"$status_color\" size=\"4\"><b>📌 Account Status : $acct_status</b></font></center><br>"
    bc+="<br>"
    bc+="<center><font color=\"#000000\">⏱️ <b>Server Uptime :</b> $uptime_str</font></center><br>"
    bc+="<center><font color=\"#000000\">📈 <b>Server Load   :</b> $load_str</font></center><br>"
    bc+="<br>"
    bc+="<center><font color=\"#6BCB77\" size=\"4\"><b>📢 JOIN OUR COMMUNITY 📢</b></font></center><br>"
    bc+="<center><font color=\"#000000\">📱 Telegram  : https://t.me/voltrontech</font></center><br>"
    bc+="<center><font color=\"#000000\">💬 WhatsApp  : https://chat.whatsapp.com/EZtAFt9dmS5DVKbNN5iSPz</font></center><br>"
    bc+="<br>"
    bc+="<center><font color=\"#FF6B6B\" size=\"4\"><b>⚠️ IMPORTANT NOTICE ⚠️</b></font></center><br>"
    bc+="<center><font color=\"#000000\">• Account expires on: $expiry</font></center><br>"
    bc+="<center><font color=\"#000000\">• No torrent or illegal activity</font></center><br>"
    bc+="<center><font color=\"#000000\">• Account sharing is prohibited</font></center><br>"
    bc+="<br>"
    bc+="<center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b>  🌍VOLTRON VPN🌍 </b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"

    printf "%s" "$bc" > "$BANNER_DIR/${username}.txt"
    chmod 644 "$BANNER_DIR/${username}.txt" 2>/dev/null
}

# ============ USER STATUS ============
get_user_status() {
    local username="$1"
    if ! id "$username" &>/dev/null; then echo -e "${C_RED}Not Found${C_RESET}"; return; fi
    local passwd_flag=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
    if [[ "$passwd_flag" == "L" ]]; then echo -e "${C_YELLOW}🔒 Locked${C_RESET}"; return; fi
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    if [[ $expiry_ts -lt $(date +%s) && $expiry_ts -ne 0 ]]; then echo -e "${C_RED}🗓️ Expired${C_RESET}"; return; fi
    local bw=$(grep "^$username:" "$DB_FILE" | cut -d: -f5)
    if [[ -n "$bw" && "$bw" != "0" ]]; then
        local ub=0
        [[ -f "$BANDWIDTH_DIR/${username}.usage" ]] && ub=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null)
        [[ -z "$ub" ]] && ub=0
        local qb=$(awk "BEGIN {printf \"%.0f\", $bw * 1073741824}")
        if [[ "$ub" -ge "$qb" ]]; then echo -e "${C_RED}📦 Exceeded${C_RESET}"; return; fi
    fi
    echo -e "${C_GREEN}🟢 Active${C_RESET}"
}

# ============ USER DELETE ============
delete_voltrontech_user_accounts() {
    local -a users_to_delete=("$@")
    [[ ${#users_to_delete[@]} -gt 0 ]] || return 0
    for username in "${users_to_delete[@]}"; do
        [[ -n "$username" ]] || continue
        killall -u "$username" -9 &>/dev/null
        if id "$username" &>/dev/null; then
            userdel -r "$username" &>/dev/null && echo -e " ✅ ${C_YELLOW}$username${C_RESET} deleted" || echo -e " ❌ Failed"
        else echo -e " ℹ️ missing"; fi
        rm -f "$BANDWIDTH_DIR/${username}.usage"
        rm -rf "$BANDWIDTH_DIR/pidtrack/${username}"
        rm -f "$BANNER_DIR/${username}.txt"
    done
    if [[ -f "$DB_FILE" ]]; then
        local db_tmp=$(mktemp)
        awk -F: 'NR==FNR { drop[$1]=1; next } !($1 in drop)' <(printf "%s\n" "${users_to_delete[@]}") "$DB_FILE" > "$db_tmp" && mv "$db_tmp" "$DB_FILE"
        rm -f "$db_tmp" 2>/dev/null
    fi
    invalidate_banner_cache
    update_ssh_banners_config
}

# ============ USER SELECTION ============
_select_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    if [[ ! -s $DB_FILE ]]; then echo -e "${C_YELLOW}ℹ️ No users.${C_RESET}"; SELECTED_USER="NO_USERS"; return; fi
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Search: " st
        if [[ -n "$st" ]]; then mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$st"); else users=("${all_users[@]}"); fi
    else users=("${all_users[@]}"); fi
    if [ ${#users[@]} -eq 0 ]; then echo -e "\n${C_YELLOW}ℹ️ None.${C_RESET}"; SELECTED_USER="NO_USERS"; return; fi
    echo -e "\nSelect user:\n"
    for i in "${!users[@]}"; do printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"; done
    echo -e "\n  ${C_RED}[ 0]${C_RESET} Cancel"
    while true; do
        read -p "👉 Number: " c
        if [[ "$c" =~ ^[0-9]+$ ]] && [ "$c" -ge 0 ] && [ "$c" -le "${#users[@]}" ]; then
            if [ "$c" -eq 0 ]; then SELECTED_USER=""; return; else SELECTED_USER="${users[$((c-1))]}"; return; fi
        else echo -e "${C_RED}❌ Invalid.${C_RESET}"; fi
    done
}

_select_multi_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    SELECTED_USERS=()
    if [[ ! -s $DB_FILE ]]; then echo -e "${C_YELLOW}ℹ️ No users.${C_RESET}"; SELECTED_USERS=("NO_USERS"); return; fi
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Search: " st
        if [[ -n "$st" ]]; then mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$st"); else users=("${all_users[@]}"); fi
    else users=("${all_users[@]}"); fi
    if [ ${#users[@]} -eq 0 ]; then echo -e "\n${C_YELLOW}ℹ️ None.${C_RESET}"; SELECTED_USERS=("NO_USERS"); return; fi
    echo -e "\nSelect users:\n"
    for i in "${!users[@]}"; do printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"; done
    echo -e "\n  ${C_GREEN}[all]${C_RESET} Select ALL   ${C_RED}[ 0]${C_RESET} Cancel"
    while true; do
        read -p "👉 Numbers: " c
        c=$(echo "$c" | tr ',' ' ')
        if [[ -z "$c" ]]; then echo -e "${C_RED}❌ Invalid.${C_RESET}"; continue; fi
        if [[ "$c" == "0" ]]; then SELECTED_USERS=(); return; fi
        if [[ "${c,,}" == "all" ]]; then SELECTED_USERS=("${users[@]}"); return; fi
        local valid=true; local si=()
        for t in $c; do
            if [[ "$t" =~ ^[0-9]+-[0-9]+$ ]]; then
                local s=${t%-*}; local e=${t#*-}
                if [ "$s" -le "$e" ]; then
                    for (( i=s; i<=e; i++ )); do
                        if [ "$i" -ge 1 ] && [ "$i" -le "${#users[@]}" ]; then si+=($i); else valid=false; break; fi
                    done
                else valid=false; break; fi
            elif [[ "$t" =~ ^[0-9]+$ ]]; then
                if [ "$t" -ge 1 ] && [ "$t" -le "${#users[@]}" ]; then si+=($t); else valid=false; break; fi
            else valid=false; break; fi
        done
        if [[ "$valid" == true && ${#si[@]} -gt 0 ]]; then
            mapfile -t ui < <(printf "%s\n" "${si[@]}" | sort -u -n)
            for i in "${ui[@]}"; do SELECTED_USERS+=("${users[$((i-1))]}"); done
            return
        else echo -e "${C_RED}❌ Invalid.${C_RESET}"; fi
    done
}

# ============ CREATE USER ============
create_user() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Create New SSH User ---${C_RESET}"
    read -p "👉 Username (or '0' cancel): " username
    [[ "$username" == "0" ]] && { press_enter; return; }
    [[ -z "$username" ]] && { echo -e "${C_RED}❌ Empty.${C_RESET}"; press_enter; return; }
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ Exists.${C_RESET}"; press_enter; return
    fi
    local password=""
    read -p "🔑 Password (Enter for auto): " password
    if [[ -z "$password" ]]; then
        password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
        echo -e "${C_GREEN}🔑 Generated: ${C_YELLOW}$password${C_RESET}"
    fi
    read -p "🗓️ Duration (days) [30]: " days; days=${days:-30}
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${C_RED}❌ Invalid.${C_RESET}"; press_enter; return; }
    read -p "📶 Connection limit [999]: " limit; limit=${limit:-999}
    read -p "📦 Bandwidth GB (0=unlimited) [0]: " bandwidth_gb; bandwidth_gb=${bandwidth_gb:-0}
    local expire_date=$(date -d "+$days days" +%Y-%m-%d)
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb:0:ACTIVE" >> "$DB_FILE"
    # Ensure usage file exists
    touch "$BANDWIDTH_DIR/${username}.usage"
    echo "0" > "$BANDWIDTH_DIR/${username}.usage"
    local bw_display="Unlimited"; [[ "$bandwidth_gb" != "0" ]] && bw_display="${bandwidth_gb} GB"
    generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
    [[ -f "$BANNER_ENABLED_FILE" ]] && update_ssh_banners_config
    clear; show_banner
    echo -e "${C_GREEN}✅ User '$username' created!${C_RESET}\n"
    echo -e "  👤 Username: ${C_YELLOW}$username${C_RESET}"
    echo -e "  🔑 Password: ${C_YELLOW}$password${C_RESET}"
    echo -e "  🗓️ Expires:  ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  📶 Limit:    ${C_YELLOW}$limit${C_RESET}"
    echo -e "  📦 BW:       ${C_YELLOW}$bw_display${C_RESET}"
    press_enter
}

# ============ DELETE USER ============
delete_user() {
    _select_multi_user_interface "--- 🗑️ Delete Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    echo -e "\n${C_RED}⚠️ Delete ${#SELECTED_USERS[@]} user(s)?${C_RESET}"
    read -p "👉 Confirm (y/n): " confirm
    [[ "$confirm" != "y" ]] && { press_enter; return; }
    delete_voltrontech_user_accounts "${SELECTED_USERS[@]}"
    press_enter
}

# ============ EDIT USER ============
edit_user() {
    _select_user_interface "--- ✏️ Edit User ---"
    local username=$SELECTED_USER
    [[ "$username" == "NO_USERS" || -z "$username" ]] && { press_enter; return; }
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- Editing: ${C_YELLOW}$username${C_RESET}"
        local line=$(grep "^$username:" "$DB_FILE")
        local cp=$(echo "$line"|cut -d: -f2); local ce=$(echo "$line"|cut -d: -f3); local cl=$(echo "$line"|cut -d: -f4); local cb=$(echo "$line"|cut -d: -f5)
        [[ -z "$cb" ]] && cb="0"
        local cbd="Unlimited"; [[ "$cb" != "0" ]] && cbd="${cb} GB"
        echo -e "\n  Pass=${C_YELLOW}$cp${C_RESET} Exp=${C_YELLOW}$ce${C_RESET} Limit=${C_YELLOW}$cl${C_RESET} BW=${C_YELLOW}$cbd${C_RESET}"
        echo -e "\n  1) 🔑 Pass   2) 🗓️ Expiry   3) 📶 Limit   4) 📦 BW   5) 🔄 Reset BW   0) Finish"
        read -p "👉 Choice: " ec
        case $ec in
            1) read -p "New password: " np; [[ -z "$np" ]] && np=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
               echo "$username:$np" | chpasswd
               awk -F: -v u="$username" -v p="$np" 'BEGIN{OFS=":"} $1==u{$2=p}1' "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
               generate_user_banner "$username" "$ce" "$cl" "$cb"
               echo -e "${C_GREEN}✅ $np${C_RESET}"; press_enter ;;
            2) read -p "New days: " d; if [[ "$d" =~ ^[0-9]+$ ]]; then
                   ne=$(date -d "+$d days" +%Y-%m-%d); chage -E "$ne" "$username"
                   awk -F: -v u="$username" -v e="$ne" 'BEGIN{OFS=":"} $1==u{$3=e;$7="ACTIVE"}1' "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
                   generate_user_banner "$username" "$ne" "$cl" "$cb"
                   echo -e "${C_GREEN}✅ $ne${C_RESET}"; fi; press_enter ;;
            3) read -p "New limit: " nl; [[ "$nl" =~ ^[0-9]+$ ]] && {
                   awk -F: -v u="$username" -v l="$nl" 'BEGIN{OFS=":"} $1==u{$4=l}1' "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
                   generate_user_banner "$username" "$ce" "$nl" "$cb"
                   echo -e "${C_GREEN}✅ $nl${C_RESET}"; }; press_enter ;;
            4) read -p "New BW: " nb; [[ "$nb" =~ ^[0-9]+\.?[0-9]*$ ]] && {
                   awk -F: -v u="$username" -v b="$nb" 'BEGIN{OFS=":"} $1==u{$5=b}1' "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
                   generate_user_banner "$username" "$ce" "$cl" "$nb"
                   echo -e "${C_GREEN}✅ $nb${C_RESET}"; }; press_enter ;;
            5) echo "0" > "$BANDWIDTH_DIR/${username}.usage"; usermod -U "$username" &>/dev/null
               rm -f "$BANDWIDTH_DIR/pidtrack/${username}__"*.last 2>/dev/null
               generate_user_banner "$username" "$ce" "$cl" "$cb"
               echo -e "${C_GREEN}✅ Reset${C_RESET}"; press_enter ;;
            0) return ;;
        esac
    done
}

# ============ LOCK / UNLOCK ============
lock_user() {
    _select_multi_user_interface "--- 🔒 Lock Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then echo -e " ❌ $u missing"; continue; fi
        usermod -L "$u" && killall -u "$u" -9 &>/dev/null
        local line=$(grep "^$u:" "$DB_FILE"); local e=$(echo "$line"|cut -d: -f3); local l=$(echo "$line"|cut -d: -f4); local b=$(echo "$line"|cut -d: -f5)
        generate_user_banner "$u" "$e" "$l" "$b"
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} locked"
    done
    press_enter
}

unlock_user() {
    _select_multi_user_interface "--- 🔓 Unlock Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then echo -e " ❌ $u missing"; continue; fi
        usermod -U "$u"
        local line=$(grep "^$u:" "$DB_FILE"); local e=$(echo "$line"|cut -d: -f3); local l=$(echo "$line"|cut -d: -f4); local b=$(echo "$line"|cut -d: -f5)
        generate_user_banner "$u" "$e" "$l" "$b"
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} unlocked"
    done
    press_enter
}

# ============ LIST USERS — FIXED (Smart formatter) ============
list_users() {
    clear; show_banner
    [[ ! -s "$DB_FILE" ]] && { echo -e "\n${C_YELLOW}ℹ️ No users.${C_RESET}"; press_enter; return; }
    echo -e "${C_BOLD}${C_PURPLE}═══ 📋 MANAGED USERS ═══${C_RESET}\n"
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" ]] && continue
        bandwidth_gb=${bandwidth_gb:-0}
        local oc=$(pgrep -c -u "$user" 2>/dev/null)
        [[ -z "$oc" || ! "$oc" =~ ^[0-9]+$ ]] && oc=0
        
        local bws="Unlimited"
        if [[ "$bandwidth_gb" != "0" ]]; then
            local ub=0
            [[ -f "$BANDWIDTH_DIR/${user}.usage" ]] && ub=$(cat "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null | tr -d '[:space:]')
            [[ ! "$ub" =~ ^[0-9]+$ ]] && ub=0
            
            local limit_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb*1073741824}")
            local rem_bytes=$(awk "BEGIN {r=$limit_bytes - $ub; if(r<0) r=0; printf \"%.0f\", r}")
            local pct=$(awk "BEGIN {printf \"%.1f\", ($ub/$limit_bytes)*100}")
            
            local used_display=$(format_size "$ub")
            local limit_display=$(format_size "$limit_bytes")
            local rem_display=$(format_size "$rem_bytes")
            
            bws="${used_display}/${limit_display} (${pct}%) | ${rem_display} left"
        fi
        local st=$(get_user_status "$user")
        local ps=$(echo -e "$st" | sed 's/\x1b\[[0-9;]*m//g')
        echo -e "${C_CYAN}┌─────────────────────────────────────────────────────────────┐${C_RESET}"
        printf "${C_CYAN}│${C_RESET} USER:   ${C_WHITE}%-51s${C_CYAN}│${C_RESET}\n" "$user"
        printf "${C_CYAN}│${C_RESET} EXPIRY: ${C_WHITE}%-51s${C_CYAN}│${C_RESET}\n" "$expiry"
        printf "${C_CYAN}│${C_RESET} BW:     ${C_WHITE}%-51s${C_CYAN}│${C_RESET}\n" "$bws"
        printf "${C_CYAN}│${C_RESET} ONLINE: ${C_WHITE}%-51s${C_CYAN}│${C_RESET}\n" "${oc}/${limit}"
        printf "${C_CYAN}│${C_RESET} STATUS: %-51s${C_CYAN}│${C_RESET}\n" "$ps"
        echo -e "${C_CYAN}└─────────────────────────────────────────────────────────────┘${C_RESET}"
    done < <(sort "$DB_FILE")
    press_enter
}

# ============ RENEW ============
renew_user() {
    _select_multi_user_interface "--- 🔄 Renew Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    read -p "👉 Days to extend: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { press_enter; return; }
    local ne=$(date -d "+$days days" +%Y-%m-%d)
    for u in "${SELECTED_USERS[@]}"; do
        chage -E "$ne" "$u"
        awk -F: -v u="$u" -v e="$ne" 'BEGIN{OFS=":"} $1==u{$3=e;$7="ACTIVE"}1' "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
        usermod -U "$u" &>/dev/null
        local line=$(grep "^$u:" "$DB_FILE"); local l=$(echo "$line"|cut -d: -f4); local b=$(echo "$line"|cut -d: -f5)
        generate_user_banner "$u" "$ne" "$l" "$b"
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} → ${C_GREEN}$ne${C_RESET}"
    done
    press_enter
}

# ============ CLEANUP EXPIRED ============
cleanup_expired() {
    clear; show_banner
    local exp=(); local ts=$(date +%s)
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        local et=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        [[ $et -lt $ts && $et -ne 0 ]] && exp+=("$user")
    done < "$DB_FILE"
    [[ ${#exp[@]} -eq 0 ]] && { echo -e "${C_GREEN}✅ No expired.${C_RESET}"; press_enter; return; }
    echo -e "Expired: ${C_RED}${exp[*]}${C_RESET}"
    read -p "Delete all? (y/n): " c
    [[ "$c" == "y" ]] && delete_voltrontech_user_accounts "${exp[@]}"
    press_enter
}

# ============ BULK CREATE ============
bulk_create_users() {
    clear; show_banner
    read -p "Prefix: " prefix
    [[ -z "$prefix" ]] && return
    read -p "Count: " count
    [[ ! "$count" =~ ^[0-9]+$ || "$count" -lt 1 || "$count" -gt 100 ]] && return
    read -p "Days [30]: " days; days=${days:-30}
    read -p "Limit [999]: " limit; limit=${limit:-999}
    read -p "BW GB [0]: " bandwidth_gb; bandwidth_gb=${bandwidth_gb:-0}
    local ed=$(date -d "+$days days" +%Y-%m-%d)
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    local created=0
    for ((i=1; i<=count; i++)); do
        local u="${prefix}${i}"
        if id "$u" &>/dev/null || grep -q "^$u:" "$DB_FILE"; then continue; fi
        local p=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
        useradd -m -s /usr/sbin/nologin "$u"
        usermod -aG "$FF_USERS_GROUP" "$u" 2>/dev/null
        echo "$u:$p" | chpasswd
        chage -E "$ed" "$u"
        echo "$u:$p:$ed:$limit:$bandwidth_gb:0:ACTIVE" >> "$DB_FILE"
        echo "0" > "$BANDWIDTH_DIR/${u}.usage"
        generate_user_banner "$u" "$ed" "$limit" "$bandwidth_gb"
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$u" "$p" "$ed"
        ((created++))
    done
    [[ -f "$BANNER_ENABLED_FILE" ]] && update_ssh_banners_config
    echo -e "\n${C_GREEN}✅ Created $created users${C_RESET}"
    press_enter
}

# ============ VIEW BANDWIDTH ============
view_user_bandwidth() {
    _select_user_interface "--- 📊 View BW ---"
    local u=$SELECTED_USER
    [[ "$u" == "NO_USERS" || -z "$u" ]] && { press_enter; return; }
    clear; show_banner
    local line=$(grep "^$u:" "$DB_FILE")
    local bw=$(echo "$line"|cut -d: -f5)
    [[ -z "$bw" ]] && bw="0"
    local ub=0
    [[ -f "$BANDWIDTH_DIR/${u}.usage" ]] && ub=$(cat "$BANDWIDTH_DIR/${u}.usage" 2>/dev/null | tr -d '[:space:]')
    [[ ! "$ub" =~ ^[0-9]+$ ]] && ub=0
    
    local used_display=$(format_size "$ub")
    echo -e "  Used: ${C_WHITE}${used_display}${C_RESET}"
    if [[ "$bw" == "0" ]]; then
        echo -e "  Limit: ${C_GREEN}Unlimited${C_RESET}"
    else
        local limit_bytes=$(awk "BEGIN {printf \"%.0f\", $bw*1073741824}")
        local rem_bytes=$(awk "BEGIN {r=$limit_bytes - $ub; if(r<0) r=0; printf \"%.0f\", r}")
        local pct=$(awk "BEGIN {printf \"%.1f\", ($ub/$limit_bytes)*100}")
        local limit_display=$(format_size "$limit_bytes")
        local rem_display=$(format_size "$rem_bytes")
        
        echo -e "  Limit: ${C_YELLOW}${limit_display}${C_RESET}"
        echo -e "  Remaining: ${C_WHITE}${rem_display}${C_RESET}"
        echo -e "  Usage: ${C_WHITE}${pct}%${C_RESET}"
        echo ""
        echo -e "  ${C_BOLD}Banner Preview:${C_RESET}"
        echo -e "  $(build_bandwidth_bar "$ub" "$bw")"
    fi
    press_enter
}

# ============ TRIAL ============
setup_trial_cleanup_script() {
    cat > "$TRIAL_CLEANUP_SCRIPT" << 'TREOF'
#!/bin/bash
username="$1"
[[ -z "$username" ]] && exit 1
killall -u "$username" -9 &>/dev/null
userdel -r "$username" &>/dev/null
sed -i "/^${username}:/d" /etc/voltrontech/users.db
rm -f /etc/voltrontech/bandwidth/${username}.usage
rm -rf /etc/voltrontech/bandwidth/pidtrack/${username}*
rm -f /etc/voltrontech/banners/${username}.txt
TREOF
    chmod +x "$TRIAL_CLEANUP_SCRIPT"
}

create_trial_account() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ⏱️ Trial Account ---${C_RESET}"
    if ! command -v at &>/dev/null; then
        ff_apt_install at >/dev/null 2>&1
        systemctl enable atd &>/dev/null; systemctl start atd &>/dev/null
    fi
    setup_trial_cleanup_script
    echo -e "\nSelect duration:\n"
    echo -e "  ${C_GREEN}[1]${C_RESET} 1 Hour    ${C_GREEN}[5]${C_RESET} 12 Hours"
    echo -e "  ${C_GREEN}[2]${C_RESET} 2 Hours   ${C_GREEN}[6]${C_RESET} 1 Day"
    echo -e "  ${C_GREEN}[3]${C_RESET} 3 Hours   ${C_GREEN}[7]${C_RESET} 3 Days"
    echo -e "  ${C_GREEN}[4]${C_RESET} 6 Hours   ${C_GREEN}[8]${C_RESET} Custom"
    echo -e "\n  ${C_RED}[0]${C_RESET} Cancel"
    read -p "👉 Choice: " dur_choice
    local duration_hours=0; local duration_label=""
    case $dur_choice in
        1) duration_hours=1; duration_label="1 Hour" ;;
        2) duration_hours=2; duration_label="2 Hours" ;;
        3) duration_hours=3; duration_label="3 Hours" ;;
        4) duration_hours=6; duration_label="6 Hours" ;;
        5) duration_hours=12; duration_label="12 Hours" ;;
        6) duration_hours=24; duration_label="1 Day" ;;
        7) duration_hours=72; duration_label="3 Days" ;;
        8) read -p "Hours: " ch; [[ ! "$ch" =~ ^[0-9]+$ ]] && return; duration_hours=$ch; duration_label="$ch Hours" ;;
        0) return ;;
        *) return ;;
    esac
    local rand_suffix=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 5)
    local default_username="trial_${rand_suffix}"
    read -p "👤 Username [${default_username}]: " username
    username=${username:-$default_username}
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ Exists.${C_RESET}"; press_enter; return
    fi
    local password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
    read -p "🔑 Password [${password}]: " cp; password=${cp:-$password}
    read -p "📶 Limit [999]: " limit; limit=${limit:-999}
    read -p "📦 BW GB [0]: " bandwidth_gb; bandwidth_gb=${bandwidth_gb:-0}
    local expire_date
    if [[ "$duration_hours" -ge 24 ]]; then expire_date=$(date -d "+$((duration_hours/24)) days" +%Y-%m-%d); else expire_date=$(date -d "+1 day" +%Y-%m-%d); fi
    local expiry_timestamp=$(date -d "+${duration_hours} hours" '+%Y-%m-%d %H:%M:%S')
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb:0:ACTIVE" >> "$DB_FILE"
    echo "0" > "$BANDWIDTH_DIR/${username}.usage"
    echo "$TRIAL_CLEANUP_SCRIPT $username" | at now + ${duration_hours} hours 2>/dev/null
    generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
    [[ -f "$BANNER_ENABLED_FILE" ]] && update_ssh_banners_config
    clear; show_banner
    echo -e "${C_GREEN}✅ Trial created!${C_RESET}\n"
    echo -e "  👤 ${C_YELLOW}$username${C_RESET}"
    echo -e "  🔑 ${C_YELLOW}$password${C_RESET}"
    echo -e "  ⏱️ ${C_CYAN}$duration_label${C_RESET}"
    echo -e "  🕐 ${C_RED}$expiry_timestamp${C_RESET}"
    press_enter
}

# ============================================================
# SPEED BOOSTERS — HELPERS
# ============================================================

_detect_ifaces() {
    ip -o -4 route show default 2>/dev/null | awk '{print $5}' | sort -u
}

# ============ MBINU 1 + 2: TCP FAST OPEN + BBR + fq ============
_apply_tfo_bbr() {
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_fq 2>/dev/null

    # ===== MBINU 1: TCP FAST OPEN (0-RTT) =====
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_notsent_lowat=16384 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_ecn=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_window_scaling=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_time=60 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_intvl=10 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fin_timeout=15 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_tw_reuse=1 >/dev/null 2>&1

    # ===== MBINU 2: BBR + fq =====
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
}

# ============ BOOSTER 1: STANDARD (1000x) ============
apply_booster_standard_ultimate() {
    echo -e "\n${C_BLUE}⚡ STANDARD (1000x) — buffer 512${C_RESET}"
    _apply_tfo_bbr
    sysctl -w net.ipv4.udp_rmem_min=512 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=512 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_early_demux=1 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=1000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=524288 >/dev/null 2>&1
    ulimit -n 10485760 2>/dev/null
    echo -e "${C_GREEN}✅ 1000x${C_RESET}"
}

# ============ BOOSTER 2: MEDIUM (2000x) ============
apply_booster_medium_ultimate() {
    echo -e "\n${C_BLUE}⚡ MEDIUM (2000x) — buffer 5120${C_RESET}"
    _apply_tfo_bbr
    sysctl -w net.ipv4.udp_rmem_min=5120 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=5120 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_early_demux=1 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=2147483648 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=2147483648 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=2000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=1048576 >/dev/null 2>&1
    ulimit -n 20971520 2>/dev/null
    echo -e "${C_GREEN}✅ 2000x${C_RESET}"
}

# ============ BOOSTER 3: HIGH (3000x) ============
apply_booster_high_ultimate() {
    echo -e "\n${C_BLUE}⚡ HIGH (3000x) — buffer 51200${C_RESET}"
    _apply_tfo_bbr
    sysctl -w net.ipv4.udp_rmem_min=51200 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=51200 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_early_demux=1 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=4294967296 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=4294967296 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=4000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=2097152 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=160000000 >/dev/null 2>&1
    ulimit -n 41943040 2>/dev/null
    echo -e "${C_GREEN}✅ 3000x${C_RESET}"
}

# ============ BOOSTER 4: ULTRA (5000x) ============
apply_booster_ultra_ultimate() {
    echo -e "\n${C_BLUE}🚀 ULTRA (5000x) — buffer 512000 + modern${C_RESET}"
    _apply_tfo_bbr
    sysctl -w net.ipv4.udp_rmem_min=512000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=512000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_early_demux=1 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=8589934592 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=8589934592 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=6000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=4194304 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=320000000 >/dev/null 2>&1
    ulimit -n 83886080 2>/dev/null
    for i in /sys/class/net/*/queues/*/rps_cpus; do [[ -f "$i" ]] && echo ffffffff > "$i" 2>/dev/null; done
    echo -e "${C_GREEN}✅ 5000x${C_RESET}"
}

# ============ BOOSTER 5: EXTREME (10000x) ============
apply_booster_extreme_ultimate() {
    echo -e "\n${C_BLUE}💥 EXTREME (10000x) — buffer 5120000${C_RESET}"
    _apply_tfo_bbr
    sysctl -w net.ipv4.udp_rmem_min=5120000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=5120000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_early_demux=1 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=17179869184 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=17179869184 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=10000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=8388608 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=640000000 >/dev/null 2>&1
    ulimit -n 167772160 2>/dev/null
    for i in /sys/class/net/*/queues/*/rps_cpus; do [[ -f "$i" ]] && echo ffffffff > "$i" 2>/dev/null; done
    echo -e "${C_GREEN}✅ 10000x${C_RESET}"
}

# ============ BOOSTER 6: ULTRA PLUS (768MB) ============
apply_booster_ultra_plus() {
    echo -e "\n${C_BLUE}🚀 ULTRA PLUS — buffer 6291456${C_RESET}"
    _apply_tfo_bbr
    sysctl -w net.ipv4.udp_rmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_early_demux=1 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=805306368 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=805306368 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Ultra+${C_RESET}"
}

# ============ BOOSTER 7: EXTREME PLUS (1GB) ============
apply_booster_extreme_plus() {
    echo -e "\n${C_BLUE}💥 EXTREME PLUS — buffer 12582912${C_RESET}"
    _apply_tfo_bbr
    sysctl -w net.ipv4.udp_rmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_early_demux=1 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Extreme+${C_RESET}"
}

# ============ SPEED MENU ============
dnstt_speed_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                 ⚡ DNSTT SPEED BOOSTERS v10.18${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_GREEN}[1]${C_RESET} Standard   (1000x)   ${C_DIM}→ buffer 512${C_RESET}"
        echo -e "  ${C_GREEN}[2]${C_RESET} Medium     (2000x)   ${C_DIM}→ buffer 5120${C_RESET}"
        echo -e "  ${C_GREEN}[3]${C_RESET} High       (3000x)   ${C_DIM}→ buffer 51200${C_RESET}"
        echo -e "  ${C_GREEN}[4]${C_RESET} ${C_BOLD}Ultra      (5000x)${C_RESET}   ${C_YELLOW}★ buffer 512000${C_RESET}"
        echo -e "  ${C_GREEN}[5]${C_RESET} Extreme    (10000x)  ${C_DIM}→ buffer 5120000${C_RESET}"
        echo -e "  ${C_GREEN}[6]${C_RESET} Ultra Plus (768MB)   ${C_DIM}→ buffer 6291456${C_RESET}"
        echo -e "  ${C_GREEN}[7]${C_RESET} Extreme+   (1GB)     ${C_DIM}→ buffer 12582912${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}ℹ️  All levels: TCP Fast Open + BBR + fq${C_RESET}"
        echo ""
        echo -e "  ${C_YELLOW}[8]${C_RESET} View Current Settings"
        echo -e "  ${C_RED}[9]${C_RESET} Reset to Default"
        echo ""
        echo -e "  ${C_RED}[0]${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) apply_booster_standard_ultimate; press_enter ;;
            2) apply_booster_medium_ultimate; press_enter ;;
            3) apply_booster_high_ultimate; press_enter ;;
            4) apply_booster_ultra_ultimate; press_enter ;;
            5) apply_booster_extreme_ultimate; press_enter ;;
            6) apply_booster_ultra_plus; press_enter ;;
            7) apply_booster_extreme_plus; press_enter ;;
            8) clear; show_banner
               echo -e "\n  TCP CC:   $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)"
               echo -e "  TFO:      $(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null) (3=on)"
               echo -e "  QDisc:    $(sysctl -n net.core.default_qdisc 2>/dev/null)"
               echo -e "  UDP rmem: $(sysctl -n net.ipv4.udp_rmem_min 2>/dev/null)"
               echo -e "  UDP wmem: $(sysctl -n net.ipv4.udp_wmem_min 2>/dev/null)"
               echo -e "  rmem_max: $(sysctl -n net.core.rmem_max 2>/dev/null)"
               echo -e "  wmem_max: $(sysctl -n net.core.wmem_max 2>/dev/null)"
               press_enter ;;
            9) sysctl -w net.core.rmem_max=212992 >/dev/null 2>&1
               sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1
               sysctl -w net.ipv4.tcp_fastopen=1 >/dev/null 2>&1
               sysctl -w net.core.default_qdisc=fq_codel >/dev/null 2>&1
               echo "✅ Reset"; press_enter ;;
            0) return ;;
        esac
    done
}

# ============ DNSTT HELPERS ============
download_dnstt_binary() {
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        curl -sL "https://dnstt.network/dnstt-server-linux-amd64" -o "$DNSTT_BINARY"
        curl -sL "https://dnstt.network/dnstt-client-linux-amd64" -o "$DNSTT_CLIENT"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        curl -sL "https://dnstt.network/dnstt-server-linux-arm64" -o "$DNSTT_BINARY"
        curl -sL "https://dnstt.network/dnstt-client-linux-arm64" -o "$DNSTT_CLIENT"
    else echo "❌ Unsupported: $arch"; return 1; fi
    chmod +x "$DNSTT_BINARY" "$DNSTT_CLIENT"
    echo -e "${C_GREEN}✅ Binaries${C_RESET}"
}

mtu_selection_during_install() {
    echo -e "\n${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}                 📡 MTU CONFIGURATION${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} 512   ${C_DIM}(default)${C_RESET}"
    echo -e "  ${C_GREEN}2)${C_RESET} 900   ${C_DIM}(stable)${C_RESET}"
    echo -e "  ${C_GREEN}3)${C_RESET} 1200  ${C_DIM}(balanced)${C_RESET}"
    echo -e "  ${C_GREEN}4)${C_RESET} 1400  ${C_DIM}(fast)${C_RESET}"
    echo -e "  ${C_GREEN}5)${C_RESET} 1500  ${C_DIM}(max)${C_RESET}"
    echo -e "  ${C_GREEN}6)${C_RESET} Custom ${C_DIM}(512-1500)${C_RESET}"
    echo ""
    read -p "👉 Choice [1]: " mtu_choice; mtu_choice=${mtu_choice:-1}
    case $mtu_choice in
        1) MTU=512 ;;
        2) MTU=900 ;;
        3) MTU=1200 ;;
        4) MTU=1400 ;;
        5) MTU=1500 ;;
        6) read -p "👉 MTU: " cm; if [[ "$cm" =~ ^[0-9]+$ ]] && [ "$cm" -ge 512 ] && [ "$cm" -le 1500 ]; then MTU=$cm; else MTU=512; fi ;;
        *) MTU=512 ;;
    esac
    mkdir -p "$CONFIG_DIR"; echo "$MTU" > "$MTU_CONFIG"
    echo -e "\n${C_GREEN}✅ MTU set to: $MTU${C_RESET}"
}

generate_keys() {
    mkdir -p "$DNSTT_KEYS_DIR"; cd "$DNSTT_KEYS_DIR"; rm -f server.key server.pub
    "$DNSTT_BINARY" -gen-key -privkey-file server.key -pubkey-file server.pub 2>/dev/null || {
        openssl rand -hex 32 > server.key
        cat server.key | sha256sum | awk '{print $1}' > server.pub
    }
    chmod 600 server.key; chmod 644 server.pub
    PUBLIC_KEY=$(cat server.pub)
}

setup_domain() {
    echo -e "\n${C_BLUE}🌐 Domain config${C_RESET}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} Custom domain"
    echo -e "  ${C_GREEN}2)${C_RESET} Auto-generate with deSEC"
    read -p "👉 [2]: " opt; opt=${opt:-2}
    if [[ "$opt" == "2" ]]; then
        local rand=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 3)
        local ns="ns-$rand"; local tun="tun-$rand"
        local ip=$(curl -s -4 icanhazip.com)
        curl -s -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "[{\"subname\":\"$ns\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$ip\"]}]" >/dev/null 2>&1
        local r=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "[{\"subname\":\"$tun\",\"type\":\"NS\",\"ttl\":3600,\"records\":[\"$ns.$DESEC_DOMAIN.\"]}]")
        [[ "${r: -3}" -eq 201 ]] && { DOMAIN="$tun.$DESEC_DOMAIN"; echo -e "${C_GREEN}✅ $DOMAIN${C_RESET}"; } || read -p "Domain: " DOMAIN
    else read -p "Domain: " DOMAIN; fi
    echo "$DOMAIN" > "$DB_DIR/domain.txt"
}

create_dnstt_service() {
    local domain=$1 mtu=$2 sp=$3
    mkdir -p "$LOGS_DIR"
    cat > "$DNSTT_SERVICE_FILE" <<EOF
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DB_DIR
ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_KEYS_DIR/server.key -mtu $mtu $domain 127.0.0.1:$sp
Restart=always
RestartSec=5
LimitNOFILE=2097152

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable dnstt.service >/dev/null 2>&1
}

save_dnstt_info() {
    printf 'TUNNEL_DOMAIN="%s"\nPUBLIC_KEY="%s"\nMTU_VALUE="%s"\nSSH_PORT="%s"\n' "$1" "$2" "$3" "$4" > "$DNSTT_CONFIG_FILE"
}

show_client_commands() {
    local pk=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null)
    echo -e "\n${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}                 📱 CLIENT CONNECTION${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_CYAN}Tunnel Domain${C_RESET} : ${C_YELLOW}$1${C_RESET}"
    echo -e "  ${C_CYAN}Public Key${C_RESET}    : ${C_YELLOW}$pk${C_RESET}"
    echo -e "  ${C_CYAN}SSH Port${C_RESET}      : ${C_YELLOW}$3${C_RESET}"
    echo -e "  ${C_CYAN}MTU${C_RESET}           : ${C_YELLOW}$2${C_RESET}"
}

configure_dnstt_firewall() {
    echo -e "\n${C_BLUE}🔥 Configuring firewall...${C_RESET}"
    ! command -v iptables &>/dev/null && ff_apt_install iptables iptables-persistent
    iptables -t nat -F 2>/dev/null; iptables -F 2>/dev/null
    iptables -A INPUT -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
    iptables -A INPUT -p udp --dport 5300 -j ACCEPT
    iptables -A OUTPUT -p udp --sport 5300 -j ACCEPT
    iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null
    echo -e "${C_GREEN}✅ Firewall configured${C_RESET}"
}

# ============ DNSTT INSTALL ============
install_dnstt() {
    clear; show_banner
    [ -f "$DNSTT_SERVICE_FILE" ] && { read -p "Reinstall? (y/n): " r; [[ "$r" != "y" ]] && return; systemctl stop dnstt.service 2>/dev/null; }
    echo -e "\n${C_BLUE}[1/7] Dependencies...${C_RESET}"
    ff_apt_install wget curl openssl bc dnsutils
    echo -e "${C_BLUE}[2/7] Downloading binary...${C_RESET}"
    download_dnstt_binary
    echo -e "${C_BLUE}[3/7] MTU selection...${C_RESET}"
    mtu_selection_during_install
    echo -e "${C_BLUE}[4/7] Domain setup...${C_RESET}"
    setup_domain
    echo -e "${C_BLUE}[5/7] Generating keys...${C_RESET}"
    generate_keys
    echo -e "${C_BLUE}[6/7] Speed Booster...${C_RESET}"
    echo -e "\n${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}                 ⚡ SPEED BOOSTERS${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_GREEN}[1]${C_RESET} Standard   (1000x)   ${C_DIM}buffer 512${C_RESET}"
    echo -e "  ${C_GREEN}[2]${C_RESET} Medium     (2000x)   ${C_DIM}buffer 5120${C_RESET}"
    echo -e "  ${C_GREEN}[3]${C_RESET} High       (3000x)   ${C_DIM}buffer 51200${C_RESET}"
    echo -e "  ${C_GREEN}[4]${C_RESET} ${C_BOLD}Ultra      (5000x)${C_RESET}   ${C_YELLOW}★ buffer 512000${C_RESET}"
    echo -e "  ${C_GREEN}[5]${C_RESET} Extreme    (10000x)  ${C_DIM}buffer 5120000${C_RESET}"
    echo -e "  ${C_GREEN}[6]${C_RESET} Ultra Plus (768MB)   ${C_DIM}buffer 6291456${C_RESET}"
    echo -e "  ${C_GREEN}[7]${C_RESET} Extreme+   (1GB)     ${C_DIM}buffer 12582912${C_RESET}"
    echo -e "  ${C_GREEN}[8]${C_RESET} Skip"
    echo -e "\n  ${C_CYAN}ℹ️  All use TCP Fast Open + BBR + fq${C_RESET}\n"
    read -p "👉 Choice [4]: " b; b=${b:-4}
    case $b in
        1) apply_booster_standard_ultimate ;;
        2) apply_booster_medium_ultimate ;;
        3) apply_booster_high_ultimate ;;
        4) apply_booster_ultra_ultimate ;;
        5) apply_booster_extreme_ultimate ;;
        6) apply_booster_ultra_plus ;;
        7) apply_booster_extreme_plus ;;
        8) echo "Skipped" ;;
    esac
    echo -e "\n${C_BLUE}[7/7] Creating service...${C_RESET}"
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); SSH_PORT=${SSH_PORT:-22}
    create_dnstt_service "$DOMAIN" "$MTU" "$SSH_PORT"
    save_dnstt_info "$DOMAIN" "$PUBLIC_KEY" "$MTU" "$SSH_PORT"
    configure_dnstt_firewall
    systemctl start dnstt.service; sleep 2
    systemctl is-active --quiet dnstt.service && echo -e "\n${C_GREEN}✅ Service running${C_RESET}" || journalctl -u dnstt.service -n 20 --no-pager
    show_client_commands "$DOMAIN" "$MTU" "$SSH_PORT"
    press_enter
}

uninstall_dnstt() {
    systemctl stop dnstt.service 2>/dev/null; systemctl disable dnstt.service 2>/dev/null
    rm -f "$DNSTT_SERVICE_FILE" "$DNSTT_BINARY" "$DNSTT_CLIENT" "$DNSTT_KEYS_DIR/server.key" "$DNSTT_KEYS_DIR/server.pub" "$DB_DIR/domain.txt" "$DNSTT_CONFIG_FILE" "$MTU_CONFIG"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ Removed${C_RESET}"; press_enter
}

# ============ DNSTT MAIN MENU ============
dnstt_main_menu() {
    while true; do
        clear; show_banner
        [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ Not installed!${C_RESET}"; press_enter; return; }
        local st=""; systemctl is-active --quiet dnstt 2>/dev/null && st="${C_GREEN}● RUNNING${C_RESET}" || st="${C_RED}● STOPPED${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    📡 DNSTT MANAGEMENT${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_CYAN}Status${C_RESET}     : $st"
        echo -e "  ${C_CYAN}Domain${C_RESET}     : ${C_YELLOW}$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo 'Not set')${C_RESET}"
        echo -e "  ${C_CYAN}MTU${C_RESET}        : ${C_YELLOW}$(get_current_mtu)${C_RESET}"
        echo -e "  ${C_CYAN}Public Key${C_RESET} : ${C_GREEN}$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null | cut -c1-35)...${C_RESET}\n"
        echo -e "  ${C_GREEN} 1)${C_RESET} 🌐 Domain Management"
        echo -e "  ${C_GREEN} 2)${C_RESET} 🔑 Public Key Management"
        echo -e "  ${C_GREEN} 3)${C_RESET} 📡 MTU Settings"
        echo -e "  ${C_GREEN} 4)${C_RESET} ⚡ Speed Boosters"
        echo -e "  ${C_GREEN} 5)${C_RESET} 📊 Full Details"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) dnstt_domain_menu ;;
            2) dnstt_key_menu ;;
            3) dnstt_mtu_menu ;;
            4) dnstt_speed_menu ;;
            5) show_dnstt_full_details ;;
            0) return ;;
        esac
    done
}

dnstt_domain_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    🌐 DOMAIN MANAGEMENT${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_CYAN}Current${C_RESET}: ${C_YELLOW}$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo 'Not set')${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Set Custom Domain"
        echo -e "  ${C_GREEN}2)${C_RESET} Auto-Generate Domain"
        echo -e "  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in 1) set_custom_dnstt_domain ;; 2) change_dnstt_domain ;; 0) return ;; esac
    done
}

dnstt_key_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    🔑 PUBLIC KEY MANAGEMENT${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_CYAN}Current${C_RESET}: ${C_GREEN}$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null || echo 'Not set')${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Set Custom Public Key"
        echo -e "  ${C_GREEN}2)${C_RESET} Regenerate Keys"
        echo -e "  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in 1) set_custom_dnstt_public_key ;; 2) regenerate_dnstt_keys ;; 0) return ;; esac
    done
}

dnstt_mtu_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    📡 MTU SETTINGS${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_CYAN}Current${C_RESET}: ${C_YELLOW}$(get_current_mtu)${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} 512   ${C_GREEN}4)${C_RESET} 1400"
        echo -e "  ${C_GREEN}2)${C_RESET} 900   ${C_GREEN}5)${C_RESET} 1500"
        echo -e "  ${C_GREEN}3)${C_RESET} 1200  ${C_GREEN}6)${C_RESET} Custom"
        echo -e "  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) set_dnstt_mtu "512"; press_enter ;;
            2) set_dnstt_mtu "900"; press_enter ;;
            3) set_dnstt_mtu "1200"; press_enter ;;
            4) set_dnstt_mtu "1400"; press_enter ;;
            5) set_dnstt_mtu "1500"; press_enter ;;
            6) read -p "MTU (512-1500): " m; set_dnstt_mtu "$m"; press_enter ;;
            0) return ;;
        esac
    done
}

set_dnstt_mtu() {
    local m="$1"
    [[ ! "$m" =~ ^[0-9]+$ || "$m" -lt 512 || "$m" -gt 1500 ]] && { echo -e "${C_RED}❌ 512-1500${C_RESET}"; return 1; }
    echo "$m" > "$MTU_CONFIG"
    [ -f "$DNSTT_SERVICE_FILE" ] && { sed -i "s/-mtu [0-9]*/-mtu $m/g" "$DNSTT_SERVICE_FILE"; systemctl daemon-reload; systemctl restart dnstt.service 2>/dev/null; echo -e "${C_GREEN}✅ MTU: $m${C_RESET}"; }
}

set_custom_dnstt_domain() {
    clear; show_banner
    read -p "New domain: " nd; [[ -z "$nd" ]] && return
    echo "$nd" > "$DB_DIR/domain.txt"
    local m=$(get_current_mtu); local sp=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); sp=${sp:-22}
    systemctl stop dnstt.service 2>/dev/null
    sed -i "s|ExecStart=.*|ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_KEYS_DIR/server.key -mtu $m $nd 127.0.0.1:$sp|" "$DNSTT_SERVICE_FILE"
    [ -f "$DNSTT_CONFIG_FILE" ] && sed -i "s|TUNNEL_DOMAIN=.*|TUNNEL_DOMAIN=\"$nd\"|" "$DNSTT_CONFIG_FILE"
    systemctl daemon-reload; systemctl restart dnstt.service; sleep 2
    echo -e "${C_GREEN}✅ $nd${C_RESET}"; press_enter
}

change_dnstt_domain() {
    clear; show_banner
    [ -f "$DB_DIR/domain.txt" ] && { local o=$(cat "$DB_DIR/domain.txt"); curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$(echo $o|cut -d. -f1)/NS/" -H "Authorization: Token $DESEC_TOKEN" >/dev/null 2>&1; }
    local rand=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 3)
    local ns="ns-$rand"; local tun="tun-$rand"; local ip=$(curl -s -4 icanhazip.com)
    curl -s -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "[{\"subname\":\"$ns\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$ip\"]}]" >/dev/null 2>&1
    local r=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "[{\"subname\":\"$tun\",\"type\":\"NS\",\"ttl\":3600,\"records\":[\"$ns.$DESEC_DOMAIN.\"]}]")
    if [[ "${r: -3}" -eq 201 ]]; then
        local nd="$tun.$DESEC_DOMAIN"
        echo "$nd" > "$DB_DIR/domain.txt"
        local m=$(get_current_mtu); local sp=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); sp=${sp:-22}
        systemctl stop dnstt.service 2>/dev/null
        sed -i "s|ExecStart=.*|ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_KEYS_DIR/server.key -mtu $m $nd 127.0.0.1:$sp|" "$DNSTT_SERVICE_FILE"
        [ -f "$DNSTT_CONFIG_FILE" ] && sed -i "s|TUNNEL_DOMAIN=.*|TUNNEL_DOMAIN=\"$nd\"|" "$DNSTT_CONFIG_FILE"
        systemctl daemon-reload; systemctl restart dnstt.service
        echo -e "${C_GREEN}✅ $nd${C_RESET}"
    else echo -e "${C_RED}❌ HTTP ${r: -3}${C_RESET}"; fi
    press_enter
}

set_custom_dnstt_public_key() {
    clear; show_banner
    read -p "New public key: " cp; [[ ${#cp} -lt 30 ]] && { echo "❌"; press_enter; return; }
    echo "$cp" > "$DNSTT_KEYS_DIR/server.pub"; chmod 644 "$DNSTT_KEYS_DIR/server.pub"
    [ -f "$DNSTT_CONFIG_FILE" ] && sed -i "s|PUBLIC_KEY=.*|PUBLIC_KEY=\"$cp\"|" "$DNSTT_CONFIG_FILE"
    systemctl restart dnstt.service 2>/dev/null
    echo -e "${C_GREEN}✅${C_RESET}"; press_enter
}

regenerate_dnstt_keys() {
    clear; show_banner
    read -p "Regenerate? (y/n): " c; [[ "$c" != "y" ]] && return
    systemctl stop dnstt.service 2>/dev/null
    cd "$DNSTT_KEYS_DIR"; rm -f server.key server.pub
    "$DNSTT_BINARY" -gen-key -privkey-file server.key -pubkey-file server.pub 2>/dev/null || {
        openssl rand -hex 32 > server.key
        cat server.key | sha256sum | awk '{print $1}' > server.pub
    }
    chmod 600 server.key; chmod 644 server.pub
    local np=$(cat server.pub)
    [ -f "$DNSTT_CONFIG_FILE" ] && sed -i "s|PUBLIC_KEY=.*|PUBLIC_KEY=\"$np\"|" "$DNSTT_CONFIG_FILE"
    systemctl restart dnstt.service; sleep 2
    echo -e "${C_GREEN}✅ $np${C_RESET}"; press_enter
}

show_dnstt_full_details() {
    clear; show_banner
    [ ! -f "$DB_DIR/domain.txt" ] && { echo "Not installed"; press_enter; return; }
    local d=$(cat "$DB_DIR/domain.txt") m=$(get_current_mtu) pk=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null)
    local sp=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); sp=${sp:-22}
    local st=""; systemctl is-active --quiet dnstt.service 2>/dev/null && st="${C_GREEN}● RUNNING${C_RESET}" || st="${C_RED}● STOPPED${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}                 📊 DNSTT DETAILS${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_CYAN}Status${C_RESET}     : $st"
    echo -e "  ${C_CYAN}Domain${C_RESET}     : ${C_YELLOW}$d${C_RESET}"
    echo -e "  ${C_CYAN}MTU${C_RESET}        : ${C_YELLOW}$m${C_RESET}"
    echo -e "  ${C_CYAN}SSH Port${C_RESET}   : ${C_YELLOW}$sp${C_RESET}"
    echo -e "  ${C_CYAN}Public Key${C_RESET} : ${C_GREEN}$pk${C_RESET}"
    echo -e "  ${C_CYAN}TCP CC${C_RESET}     : ${C_GREEN}$(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)${C_RESET}"
    echo -e "  ${C_CYAN}TFO${C_RESET}        : ${C_GREEN}$(sysctl -n net.ipv4.tcp_fastopen 2>/dev/null)${C_RESET}"
    press_enter
}

# ============================================================
# LIMITER v10.18 — FIXED: counts ALL user PIDs
# ============================================================
create_limiter_service() {
    # ============ BANNER BUILDER (bc= + bc+=) ============
    cat > "$BANNER_BUILDER" << 'BBEOF'
#!/bin/bash
# Voltron Banner Builder v10.18 — Smart size formatter
user="$1"
expiry="$2"
bandwidth_gb="$3"
sessions="$4"
limit="$5"
status_label="$6"
status_color="$7"

BANDWIDTH_DIR="/etc/voltrontech/bandwidth"

# ============ SMART SIZE FORMATTER ============
format_size() {
    local bytes=$1
    [[ "$bytes" =~ ^[0-9]+$ ]] || bytes=0
    if (( bytes >= 1073741824 )); then
        awk "BEGIN{printf \"%.2f GB\", $bytes/1073741824}"
    elif (( bytes >= 1048576 )); then
        awk "BEGIN{printf \"%.2f MB\", $bytes/1048576}"
    elif (( bytes >= 1024 )); then
        awk "BEGIN{printf \"%.2f KB\", $bytes/1024}"
    else
        echo "${bytes} B"
    fi
}

# ============ BANDWIDTH PROGRESS BAR ============
bw_info=""
if [[ "$bandwidth_gb" == "0" || -z "$bandwidth_gb" ]]; then
    bw_info='<font color="#6BCB77">Unlimited ∞</font>'
else
    ub=0
    usage_file="$BANDWIDTH_DIR/${user}.usage"
    if [[ -f "$usage_file" ]]; then
        ub=$(cat "$usage_file" 2>/dev/null | tr -d '[:space:]')
        [[ ! "$ub" =~ ^[0-9]+$ ]] && ub=0
    fi

    limit_bytes=$(awk "BEGIN{printf \"%.0f\", $bandwidth_gb*1073741824}")
    [[ "$limit_bytes" -le 0 ]] && limit_bytes=1

    pct=$(awk "BEGIN{printf \"%.1f\", ($ub/$limit_bytes)*100}")
    pct_int=$(awk "BEGIN{printf \"%d\", ($ub/$limit_bytes)*100}")
    [[ "$pct_int" -gt 100 ]] && pct_int=100
    [[ "$pct_int" -lt 0 ]] && pct_int=0

    remaining_bytes=$((limit_bytes - ub))
    [[ $remaining_bytes -lt 0 ]] && remaining_bytes=0

    used_display=$(format_size "$ub")
    limit_display=$(format_size "$limit_bytes")
    remaining_display=$(format_size "$remaining_bytes")

    bar_color="#6BCB77"
    text_color="#6BCB77"

    if (( $(echo "$pct >= 95" | bc -l) )); then
        bar_color="#FF6B6B"; text_color="#FF6B6B"
    elif (( $(echo "$pct >= 80" | bc -l) )); then
        bar_color="#FF9F43"; text_color="#FF9F43"
    elif (( $(echo "$pct >= 60" | bc -l) )); then
        bar_color="#FFD93D"; text_color="#FFD93D"
    fi

    total_blocks=10
    filled=$((pct_int * total_blocks / 100))
    [[ $filled -gt $total_blocks ]] && filled=$total_blocks
    [[ $filled -lt 0 ]] && filled=0
    empty=$((total_blocks - filled))

    bar=""
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done

    bw_info="<font color=\"$bar_color\">$bar</font> <font color=\"$text_color\"><b>${pct}%</b></font> <font color=\"#9B59B6\">|</font> <font color=\"#000000\">${used_display}/${limit_display}</font> <font color=\"#6BCB77\">(${remaining_display} left)</font>"
fi

# ============ SYSTEM INFO ============
uptime_str=$(uptime -p | sed 's/up //')
load_str=$(awk '{print $1}' /proc/loadavg)

# ============ BUILD BANNER ============
bc=""
bc+="<br><br>"
bc+="<center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b> 🌍VOLTRON VPN🌍</b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"
bc+="<br>"
bc+="<center><font color=\"#4D96FF\" size=\"5\"><b>📋 ACCOUNT DETAILS 📋</b></font></center><br>"
bc+="<br>"
bc+="<center><font color=\"#000000\">👤 <b>Username      :</b> $user</font></center><br>"
bc+="<center><font color=\"#000000\">📅 <b>Expiration    :</b> $expiry</font></center><br>"
bc+="<center>📊 <b>Bandwidth     :</b> $bw_info</center><br>"
bc+="<center><font color=\"#000000\">🔌 <b>Sessions      :</b> $sessions/$limit</font></center><br>"
bc+="<center><font color=\"$status_color\" size=\"4\"><b>📌 Account Status : $status_label</b></font></center><br>"
bc+="<br>"
bc+="<center><font color=\"#000000\">⏱️ <b>Server Uptime :</b> $uptime_str</font></center><br>"
bc+="<center><font color=\"#000000\">📈 <b>Server Load   :</b> $load_str</font></center><br>"
bc+="<br>"
bc+="<center><font color=\"#6BCB77\" size=\"4\"><b>📢 JOIN OUR COMMUNITY 📢</b></font></center><br>"
bc+="<center><font color=\"#000000\">📱 Telegram  : https://t.me/voltrontech</font></center><br>"
bc+="<center><font color=\"#000000\">💬 WhatsApp  : https://chat.whatsapp.com/EZtAFt9dmS5DVKbNN5iSPz</font></center><br>"
bc+="<br>"
bc+="<center><font color=\"#FF6B6B\" size=\"4\"><b>⚠️ IMPORTANT NOTICE ⚠️</b></font></center><br>"
bc+="<center><font color=\"#000000\">• Account expires on: $expiry</font></center><br>"
bc+="<center><font color=\"#000000\">• No torrent or illegal activity</font></center><br>"
bc+="<center><font color=\"#000000\">• Account sharing is prohibited</font></center><br>"
bc+="<br>"
bc+="<center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b>  🌍VOLTRON VPN🌍 </b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"

printf "%s" "$bc"
BBEOF
    chmod +x "$BANNER_BUILDER"

    # ============ LIMITER SCRIPT — FIXED ============
    cat > "$LIMITER_SCRIPT" << 'LIMEOF'
#!/bin/bash
# ============================================================
# VOLTRON LIMITER v10.18 — counts ALL user PIDs (sshd+bash+wget)
# ============================================================
DB_FILE="/etc/voltrontech/users.db"
BW_DIR="/etc/voltrontech/bandwidth"
PID_DIR="$BW_DIR/pidtrack"
BANNER_DIR="/etc/voltrontech/banners"
BANNER_ENABLED_FILE="/etc/voltrontech/banners_enabled"
BANNER_BUILDER="/usr/local/bin/voltrontech-banner-build.sh"
SCAN=15

mkdir -p "$BW_DIR" "$PID_DIR" "$BANNER_DIR"
shopt -s nullglob

while true; do
    [[ ! -s "$DB_FILE" ]] && { sleep $SCAN; continue; }
    ts=$(date +%s)
    dyn=false
    [[ -f "$BANNER_ENABLED_FILE" ]] && dyn=true

    declare -A lk=()
    while read -r u _ s _; do [[ "$s" == "L" ]] && lk["$u"]=1; done < <(passwd -Sa 2>/dev/null)

    while IFS=: read -r user pass expiry limit bw traffic status; do
        [[ -z "$user" || "$user" == \#* ]] && continue
        [[ -z "$status" ]] && status="ACTIVE"
        [[ "$limit" =~ ^[0-9]+$ ]] || limit=999
        [[ "$bw" =~ ^[0-9]+\.?[0-9]*$ ]] || bw=0

        # ==================================================
        # FIXED: Get ALL PIDs of user (sshd + bash + wget)
        # ==================================================
        declare -A upids=()
        while read -r sp; do
            [[ "$sp" =~ ^[0-9]+$ ]] && upids["$sp"]=1
        done < <(pgrep -u "$user" 2>/dev/null)

        oc=${#upids[@]}
        [[ "$oc" =~ ^[0-9]+$ ]] || oc=0

        # ============ STATUS CHECKS ============
        locked=false; expired=false; ex=false
        [[ -n "${lk[$user]+x}" ]] && locked=true

        et=0; days_left=999
        if [[ "$expiry" != "Never" && -n "$expiry" ]]; then
            et=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$et" =~ ^[0-9]+$ ]] && (( et > 0 )); then
                days_left=$(( (et - ts) / 86400 ))
                if (( days_left < 0 )); then
                    expired=true
                    ! $locked && { usermod -L "$user" &>/dev/null; locked=true; }
                fi
            fi
        fi

        (( limit > 0 && oc > limit )) && ! $locked && {
            usermod -L "$user" &>/dev/null
            killall -u "$user" -9 &>/dev/null
            locked=true
        }

        uf="$BW_DIR/${user}.usage"
        ad=0
        [[ -f "$uf" ]] && { read -r ad < "$uf"; [[ "$ad" =~ ^[0-9]+$ ]] || ad=0; }

        if [[ "$bw" != "0" && -n "$bw" ]]; then
            qb=$(awk "BEGIN{printf \"%.0f\", $bw*1073741824}")
            (( qb > 0 && ad >= qb )) && { ex=true; ! $locked && { usermod -L "$user" &>/dev/null; locked=true; }; }
        fi

        # ==================================================
        # BANDWIDTH CALCULATION
        # ==================================================
        if [[ -z "$bw" || "$bw" == "0" ]]; then
            : # unlimited — skip bandwidth tracking
        elif (( oc == 0 )); then
            # No sessions — reset pidtrack
            rm -f "$PID_DIR/${user}__"*.last 2>/dev/null
        else
            # Calculate delta for each PID
            dt=0
            for pid in "${!upids[@]}"; do
                io="/proc/$pid/io"
                cur=0
                if [[ -r "$io" ]]; then
                    rc=0; wc=0
                    while read -r k v; do
                        case "$k" in
                            rchar:) rc=${v:-0};;
                            wchar:) wc=${v:-0};;
                        esac
                    done < "$io" 2>/dev/null
                    cur=$((rc + wc))
                fi
                pf="$PID_DIR/${user}__${pid}.last"
                if [[ -f "$pf" ]]; then
                    read -r pv < "$pf"
                    [[ "$pv" =~ ^[0-9]+$ ]] || pv=0
                    if (( cur >= pv )); then
                        d=$((cur - pv))
                    else
                        d=$cur
                    fi
                    dt=$((dt + d))
                fi
                printf "%s\n" "$cur" > "$pf"
            done

            if (( dt > 0 )); then
                nt=$((ad + dt))
                printf "%s\n" "$nt" > "$uf"
                tg=$(awk "BEGIN{printf \"%.2f\", $nt/1073741824}" 2>/dev/null)
                # Update DB traffic (field 6) — preserve bw (field 5)
                awk -F: -v u="$user" -v tg="$tg" 'BEGIN{OFS=":"} $1==u{$6=tg}1' "$DB_FILE" > "$DB_FILE.tmp" && mv "$DB_FILE.tmp" "$DB_FILE"
            fi
        fi

        # ==================================================
        # DYNAMIC BANNER
        # ==================================================
        if $dyn; then
            if $locked; then
                acct_status="🔒 LOCKED"; status_color="#FF6B6B"
            else
                skip_bw=false
                if (( days_left < 0 )); then
                    acct_status="🗓️ EXPIRED"; status_color="#FF9F43"; skip_bw=true
                elif (( days_left == 0 )); then
                    acct_status="⚠️ EXPIRES TODAY"; status_color="#FF6B6B"; skip_bw=true
                elif (( days_left <= 2 )); then
                    acct_status="🔴 EXPIRING - ${days_left} DAY$( [[ $days_left -eq 1 ]] && echo '' || echo 'S' ) LEFT"; status_color="#FF9F43"; skip_bw=true
                elif (( days_left <= 7 )); then
                    acct_status="⏰ EXPIRING SOON - ${days_left} DAYS LEFT"; status_color="#FFD93D"; skip_bw=true
                fi

                if ! $skip_bw; then
                    if $ex; then
                        acct_status="⚠️ DATA EXHAUSTED"; status_color="#FF6B6B"
                    else
                        if [[ "$bw" != "0" && -n "$bw" && "$ad" -gt 0 ]]; then
                            qb=$(awk "BEGIN{printf \"%.0f\", $bw*1073741824}")
                            pct=$(awk "BEGIN{printf \"%.1f\", ($ad/$qb)*100}")
                            if (( $(echo "$pct >= 95" | bc -l) )); then
                                rem_disp=$(awk "BEGIN{printf \"%.2f\", $bw - ($ad/1073741824)}")
                                acct_status="🔴 CRITICAL - ${rem_disp} GB LEFT"; status_color="#FF9F43"
                            else
                                acct_status="✅ ACTIVE"; status_color="#6BCB77"
                            fi
                        else
                            acct_status="✅ ACTIVE"; status_color="#6BCB77"
                        fi
                    fi
                fi
            fi

            bf="$BANNER_DIR/${user}.txt"; tf="${bf}.tmp"
            "$BANNER_BUILDER" "$user" "$expiry" "$bw" "$oc" "$limit" "$acct_status" "$status_color" > "$tf" 2>/dev/null
            if ! cmp -s "$tf" "$bf" 2>/dev/null; then mv "$tf" "$bf"; else rm -f "$tf"; fi
            chmod 644 "$bf" 2>/dev/null
        fi
    done < "$DB_FILE"
    sleep $SCAN
done
LIMEOF
    chmod +x "$LIMITER_SCRIPT"

    # ============ LIMITER SERVICE ============
    cat > "$LIMITER_SERVICE" <<EOF
[Unit]
Description=Voltron Limiter
After=network.target
[Service]
Type=simple
ExecStart=$LIMITER_SCRIPT
Restart=always
RestartSec=10
[Install]
WantedBy=multi-user.target
EOF
    pkill -f voltrontech-limiter 2>/dev/null
    systemctl daemon-reload
    systemctl enable voltrontech-limiter &>/dev/null
    systemctl restart voltrontech-limiter --no-block &>/dev/null
}

# ============ TRAFFIC MONITOR ============
create_traffic_monitor() {
    cat > "$TRAFFIC_SCRIPT" <<'EOF'
#!/bin/bash
DB_FILE="/etc/voltrontech/users.db"
TRAFFIC_DIR="/etc/voltrontech/traffic"
mkdir -p "$TRAFFIC_DIR"
while true; do
    [[ -f "$DB_FILE" ]] && while IFS=: read -r u p e l tl tu s; do
        [[ -z "$u" ]] && continue
        id "$u" &>/dev/null || continue
        tf="$TRAFFIC_DIR/$u"
        [[ -f "$tf" ]] && cb=$(cat "$tf" 2>/dev/null || echo 0) && cg=$(echo "scale=3; $cb/1073741824" | bc 2>/dev/null || echo 0) && sed -i "s/^$u:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*/$u:$p:$e:$l:$tl:$cg:$s/" "$DB_FILE" 2>/dev/null
    done < "$DB_FILE"
    sleep 60
done
EOF
    chmod +x "$TRAFFIC_SCRIPT"
    cat > "$TRAFFIC_SERVICE" <<EOF
[Unit]
Description=Voltron Traffic
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

# ============ SSH BANNER CONFIG ============
update_ssh_banners_config() {
    grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null || echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
    mkdir -p "$BANNER_DIR" /etc/ssh/sshd_config.d
    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        rm -f "$SSHD_FF_CONFIG" 2>/dev/null
        sshd -t 2>/dev/null && systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        return
    fi
    local tmp="/tmp/voltron-banners.conf"
    {
        echo "# Voltron Tech - Dynamic Banners"
        if [[ -f "$DB_FILE" ]]; then
            while IFS=: read -r user pass expiry limit bandwidth_gb _rest; do
                [[ -z "$user" || "$user" == \#* ]] && continue
                [[ ! -f "$BANNER_DIR/${user}.txt" ]] && generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"
                chmod 644 "$BANNER_DIR/${user}.txt" 2>/dev/null
                [[ ! -f "$BANNER_DIR/${user}.txt" ]] && continue
                echo "Match User $user"
                echo "    Banner /etc/voltrontech/banners/${user}.txt"
            done < "$DB_FILE"
        fi
    } > "$tmp"
    chmod 644 "$tmp"
    if ! cmp -s "$tmp" "$SSHD_FF_CONFIG" 2>/dev/null; then
        mv "$tmp" "$SSHD_FF_CONFIG"; chmod 644 "$SSHD_FF_CONFIG"
        if sshd -t 2>/dev/null; then
            systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        else
            rm -f "$SSHD_FF_CONFIG"; systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        fi
    else rm -f "$tmp"; fi
}

enable_dynamic_banner() {
    mkdir -p "$BANNER_DIR"; touch "$BANNER_ENABLED_FILE"
    local count=0
    [[ -f "$DB_FILE" ]] && while IFS=: read -r user pass expiry limit bandwidth_gb _rest; do
        [[ -z "$user" || "$user" == \#* ]] && continue
        generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"; ((count++))
    done < "$DB_FILE"
    update_ssh_banners_config
    sshd -t 2>/dev/null && { systemctl restart voltrontech-limiter 2>/dev/null; echo -e "\n${C_GREEN}✅ Enabled ($count)${C_RESET}"; } || { rm -f "$SSHD_FF_CONFIG"; systemctl restart sshd 2>/dev/null; echo -e "\n${C_RED}❌ Error${C_RESET}"; }
    press_enter
}

disable_dynamic_banner() {
    rm -f "$BANNER_ENABLED_FILE" "$SSHD_FF_CONFIG" /etc/ssh/sshd_config.d/voltron-auto-banner.conf 2>/dev/null
    systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    echo -e "\n${C_GREEN}✅ DISABLED${C_RESET}"; press_enter
}

preview_dynamic_ssh_banner() {
    [[ ! -f "$BANNER_ENABLED_FILE" ]] && { echo -e "\n${C_RED}❌ Not enabled${C_RESET}"; press_enter; return; }
    _select_user_interface "--- Preview ---"
    local u=$SELECTED_USER; [[ -z "$u" || "$u" == "NO_USERS" ]] && return
    [[ -f "$BANNER_DIR/${u}.txt" ]] && cat "$BANNER_DIR/${u}.txt" || echo "Not found"
    press_enter
}

ssh_banner_menu() {
    while true; do
        clear; show_banner
        local st=""; [[ -f "$BANNER_ENABLED_FILE" ]] && st="${C_GREEN}● ENABLED${C_RESET}" || st="${C_RED}● DISABLED${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                 🎨 DYNAMIC BANNER${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_CYAN}Status${C_RESET} : $st\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Enable"
        echo -e "  ${C_RED}2)${C_RESET} Disable"
        echo -e "  ${C_GREEN}3)${C_RESET} Preview"
        echo -e "  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in 1) enable_dynamic_banner ;; 2) disable_dynamic_banner ;; 3) preview_dynamic_ssh_banner ;; 0) return ;; esac
    done
}

# ============================================================
# WEB PANEL
# ============================================================
web_panel_menu() {
    while true; do
        clear; show_banner
        [[ -f "$WEB_PANEL_DOMAIN_FILE" ]] && WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")

        local api_st=""; if [ -f "/etc/systemd/system/voltrontech-api.service" ]; then
            systemctl is-active --quiet voltrontech-api 2>/dev/null && api_st="${C_GREEN}● RUNNING${C_RESET}" || api_st="${C_RED}● STOPPED${C_RESET}"
        else api_st="${C_DIM}● NOT INSTALLED${C_RESET}"; fi
        local ng_st=""; command -v nginx &>/dev/null && { systemctl is-active --quiet nginx 2>/dev/null && ng_st="${C_GREEN}● RUNNING${C_RESET}" || ng_st="${C_RED}● STOPPED${C_RESET}"; } || ng_st="${C_DIM}● NOT INSTALLED${C_RESET}"
        local ssl_st=""; [ -d "/etc/letsencrypt/live/$WEB_PANEL_API_DOMAIN" ] && ssl_st="${C_GREEN}● INSTALLED${C_RESET}" || ssl_st="${C_YELLOW}● NOT INSTALLED${C_RESET}"
        local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
        local dip=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
        local dns_st=""; [[ "$dip" == "$ip" ]] && dns_st="${C_GREEN}● OK${C_RESET}" || dns_st="${C_YELLOW}● NOT SET${C_RESET}"
        local ban_st=""; [[ -f "$BANNER_ENABLED_FILE" ]] && ban_st="${C_GREEN}● ENABLED${C_RESET}" || ban_st="${C_RED}● DISABLED${C_RESET}"

        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                 🌐 WEB PANEL v10.18${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_CYAN}Domain${C_RESET} : ${C_YELLOW}$WEB_PANEL_API_DOMAIN${C_RESET}"
        echo -e "  ${C_CYAN}VPS IP${C_RESET} : $ip\n"
        echo -e "  ${C_CYAN}API${C_RESET}      : $api_st"
        echo -e "  ${C_CYAN}Nginx${C_RESET}    : $ng_st"
        echo -e "  ${C_CYAN}SSL${C_RESET}      : $ssl_st"
        echo -e "  ${C_CYAN}DNS${C_RESET}      : $dns_st"
        echo -e "  ${C_CYAN}Banner${C_RESET}   : $ban_st\n"
        echo -e "  ${C_GREEN}[ 1]${C_RESET} 🚀 Full Setup"
        echo -e "  ${C_GREEN}[ 2]${C_RESET} 📥 API Only"
        echo -e "  ${C_GREEN}[ 3]${C_RESET} 🌐 DNS Only"
        echo -e "  ${C_GREEN}[ 4]${C_RESET} ⚙️  Nginx Only"
        echo -e "  ${C_GREEN}[ 5]${C_RESET} 🔒 SSL Only"
        echo -e "  ${C_GREEN}[ 6]${C_RESET} 🧪 Test"
        echo -e "  ${C_GREEN}[ 7]${C_RESET} 📋 Logs"
        echo -e "  ${C_GREEN}[ 8]${C_RESET} 🔑 API Info"
        echo -e "  ${C_GREEN}[ 9]${C_RESET} 🔄 Restart API"
        echo -e "  ${C_GREEN}[10]${C_RESET} 📝 Copy for Lovable"
        echo -e "  ${C_YELLOW}[11]${C_RESET} 🌐 ${C_BOLD}Change API Domain${C_RESET}"
        echo -e "  ${C_YELLOW}[12]${C_RESET} 🎨 ${C_BOLD}Toggle Dynamic Banner${C_RESET}"
        echo -e "  ${C_RED}[13]${C_RESET} 🗑️  Remove"
        echo -e "  ${C_RED}[ 0]${C_RESET} Return"
        read -p "👉 " c
        case $c in
            1) web_panel_full_setup ;;
            2) web_panel_install_api ;;
            3) web_panel_dns_setup ;;
            4) web_panel_nginx_setup ;;
            5) web_panel_ssl_setup ;;
            6) web_panel_test_all ;;
            7) web_panel_view_logs ;;
            8) web_panel_view_api_info ;;
            9) web_panel_restart_api ;;
            10) web_panel_copy_for_lovable ;;
            11) change_api_domain ;;
            12) toggle_dynamic_banner_web ;;
            13) web_panel_remove ;;
            0) return ;;
        esac
    done
}

change_api_domain() {
    clear; show_banner
    [[ -f "$WEB_PANEL_DOMAIN_FILE" ]] && WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}                 🌐 CHANGE API DOMAIN${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_CYAN}Current Domain${C_RESET} : ${C_YELLOW}$WEB_PANEL_API_DOMAIN${C_RESET}"
    echo -e "  ${C_CYAN}deSEC Base${C_RESET}    : ${C_YELLOW}$DESEC_DOMAIN${C_RESET}\n"
    read -p "👉 New API domain (or '0' cancel): " nd
    [[ "$nd" == "0" || -z "$nd" ]] && return

    if [[ ! "$nd" =~ ^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$ ]]; then
        echo -e "\n${C_RED}❌ Invalid domain format${C_RESET}"; press_enter; return
    fi

    local old_domain="$WEB_PANEL_API_DOMAIN"
    WEB_PANEL_API_DOMAIN="$nd"
    mkdir -p "$DB_DIR"
    echo "$nd" > "$WEB_PANEL_DOMAIN_FILE"

    if [ -f "/etc/systemd/system/voltrontech-api.service" ]; then
        sed -i "s|Environment=\"API_DOMAIN=.*\"|Environment=\"API_DOMAIN=$nd\"|" /etc/systemd/system/voltrontech-api.service
        systemctl daemon-reload
        systemctl restart voltrontech-api 2>/dev/null
        echo -e "  ${C_GREEN}✅ API service updated${C_RESET}"
    fi

    if [ -f "$WEB_PANEL_NGINX_CONFIG" ]; then
        sed -i "s|server_name .*;|server_name $nd;|" "$WEB_PANEL_NGINX_CONFIG"
        nginx -t 2>&1 | grep -q successful && systemctl reload nginx
        echo -e "  ${C_GREEN}✅ Nginx updated${C_RESET}"
    fi

    if [[ "$nd" == *".$DESEC_DOMAIN" ]]; then
        echo -e "\n  ${C_BLUE}🌐 Updating DNS record...${C_RESET}"
        local ip=$(curl -s -4 icanhazip.com)
        local sub=$(echo "$nd" | sed "s|.$DESEC_DOMAIN||")
        curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$sub/A/" \
            -H "Authorization: Token $DESEC_TOKEN" >/dev/null 2>&1
        local data="[{\"subname\":\"$sub\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$ip\"]}]"
        local r=$(curl -s -w "%{http_code}" -X POST \
            "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
            -H "Authorization: Token $DESEC_TOKEN" \
            -H "Content-Type: application/json" --data "$data" 2>/dev/null)
        if [[ "${r: -3}" -eq 201 ]]; then
            echo -e "  ${C_GREEN}✅ DNS record created: $nd → $ip${C_RESET}"
        else
            echo -e "  ${C_YELLOW}⚠️  DNS auto-update failed (HTTP ${r: -3})${C_RESET}"
        fi
    fi

    echo -e "\n${C_GREEN}✅ API domain: $old_domain → $nd${C_RESET}"
    press_enter
}

toggle_dynamic_banner_web() {
    clear; show_banner
    local st="DISABLED"; [[ -f "$BANNER_ENABLED_FILE" ]] && st="ENABLED"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}              🎨 DYNAMIC BANNER CONTROL${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_CYAN}Status${C_RESET} : ${C_YELLOW}$st${C_RESET}"
    echo -e "  ${C_CYAN}Users${C_RESET}  : $(grep -c . "$DB_FILE" 2>/dev/null || echo 0)\n"
    echo -e "  ${C_GREEN}[1]${C_RESET} Enable Dynamic Banner"
    echo -e "  ${C_RED}[2]${C_RESET} Disable Dynamic Banner"
    echo -e "  ${C_CYAN}[3]${C_RESET} Refresh/Regenerate"
    echo -e "  ${C_RED}[0]${C_RESET} Return"
    read -p "👉 Choice: " c
    case $c in
        1) enable_dynamic_banner ;;
        2) disable_dynamic_banner ;;
        3) update_ssh_banners_config; echo -e "\n${C_GREEN}✅ Refreshed${C_RESET}"; press_enter ;;
        0) return ;;
    esac
}

web_panel_full_setup() {
    clear; show_banner
    read -p "Continue full setup? (y/n): " c; [[ "$c" != "y" ]] && return

    web_panel_install_api || { echo -e "${C_RED}❌ API install failed${C_RESET}"; press_enter; return 1; }
    sleep 2
    web_panel_dns_setup
    sleep 2
    web_panel_nginx_setup
    sleep 2

    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    local tries=0
    echo -e "\n${C_BLUE}⏳ Waiting for DNS propagation...${C_RESET}"
    while [[ "$(dig +short $WEB_PANEL_API_DOMAIN 2>/dev/null | tail -1)" != "$ip" ]]; do
        ((tries++))
        if [[ $tries -gt 30 ]]; then
            echo -e "${C_YELLOW}⏳ DNS bado haijapropagate${C_RESET}"
            break
        fi
        echo "  ⏳ Waiting... ($tries/30)"
        sleep 10
    done

    [[ $tries -le 30 ]] && web_panel_ssl_setup
    sleep 2
    web_panel_test_all
    press_enter
}

web_panel_install_api() {
    clear; show_banner
    if [ -f "/etc/systemd/system/voltrontech-api.service" ]; then
        read -p "Reinstall? (y/n): " r; [[ "$r" != "y" ]] && return 1
        systemctl stop voltrontech-api 2>/dev/null; systemctl disable voltrontech-api 2>/dev/null
        rm -f /etc/systemd/system/voltrontech-api.service; systemctl daemon-reload
    fi

    local API_KEY
    if [ -f "$API_KEY_FILE" ]; then
        API_KEY=$(cat "$API_KEY_FILE")
    else
        API_KEY="voltron_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)"
        mkdir -p "$DB_DIR"
        echo "$API_KEY" > "$API_KEY_FILE"
        chmod 600 "$API_KEY_FILE"
    fi

    ff_apt_update
    DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Use-Pty=0 python3 python3-pip python3-venv python3-full curl jq 2>&1 | tail -2
    command -v python3 &>/dev/null || { echo "❌ python3 fail"; press_enter; return 1; }

    mkdir -p "$API_DIR"; cd "$API_DIR"
    rm -rf venv; python3 -m venv venv || { echo "❌ venv fail"; press_enter; return 1; }
    source venv/bin/activate
    pip install --upgrade pip 2>&1 | tail -1
    pip install flask flask-cors gunicorn 2>&1 | tail -2
    deactivate

    web_panel_create_api_code
    python3 -m py_compile "$API_DIR/api.py" 2>/dev/null || { echo "❌ api.py error"; press_enter; return 1; }

    local po=$(ss -tlnp 2>/dev/null | grep ":$API_PORT " | head -1)
    [ -n "$po" ] && { fuser -k ${API_PORT}/tcp 2>/dev/null; sleep 1; }

    local SH=$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo "vpn.voltrontechtx.shop")
    cat > /etc/systemd/system/voltrontech-api.service <<EOF
[Unit]
Description=Voltron Tech API
After=network.target
[Service]
Type=simple
User=root
WorkingDirectory=$API_DIR
Environment="API_KEY=$API_KEY"
Environment="DB_DIR=$DB_DIR"
Environment="SERVER_HOST=$SH"
Environment="API_DOMAIN=$WEB_PANEL_API_DOMAIN"
Environment="PATH=$API_DIR/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$API_DIR/venv/bin/gunicorn --workers 2 --bind 0.0.0.0:$API_PORT --timeout 120 --access-logfile /var/log/voltrontech-api.log --error-logfile /var/log/voltrontech-api.log api:app
Restart=always
RestartSec=5
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable voltrontech-api >/dev/null 2>&1
    touch /var/log/voltrontech-api.log
    systemctl start voltrontech-api; sleep 5

    if systemctl is-active --quiet voltrontech-api; then
        local resp=$(curl -s http://localhost:$API_PORT/api/health 2>/dev/null)
        if echo "$resp" | grep -q '"success":true'; then
            local sip=$(curl -s -4 icanhazip.com)
            printf 'API_URL=http://%s:%s\nAPI_KEY=%s\nAPI_DOMAIN=%s\n' "$sip" "$API_PORT" "$API_KEY" "$WEB_PANEL_API_DOMAIN" > "$API_INFO_FILE"
            echo -e "\n${C_GREEN}✅ API: http://$sip:$API_PORT${C_RESET}"
            echo -e "${C_GREEN}🔑 Key: $API_KEY${C_RESET}"
            press_enter; return 0
        fi
    fi
    echo -e "${C_RED}❌ Failed${C_RESET}"; journalctl -u voltrontech-api -n 20 --no-pager
    press_enter; return 1
}

web_panel_create_api_code() {
    cat > "$API_DIR/api.py" << 'APIEOF'
#!/usr/bin/env python3
from flask import Flask, request, jsonify
from flask_cors import CORS
from functools import wraps
from datetime import datetime, timedelta
import subprocess, os, shutil, re
app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}}, supports_credentials=False)
API_KEY = os.environ.get('API_KEY', 'CHANGE_ME')
DB_DIR = os.environ.get('DB_DIR', '/etc/voltrontech')
DB_FILE = f'{DB_DIR}/users.db'
SERVER_HOST = os.environ.get('SERVER_HOST', 'vpn.voltrontechtx.shop')
API_DOMAIN = os.environ.get('API_DOMAIN', 'api.voltrontechtx.shop')
DEFAULT_LIMIT = 999
BANDWIDTH_DIR = f'{DB_DIR}/bandwidth'
BANNER_DIR = f'{DB_DIR}/banners'
BANNER_ENABLED_FILE = f'{DB_DIR}/banners_enabled'
SSHD_BANNER_CONF = '/etc/ssh/sshd_config.d/voltron-auto-banner.conf'

def is_valid_username(u):
    return bool(re.match(r'^[a-z0-9_-]{3,20}$', u))

def is_valid_password(p):
    return bool(re.match(r'^[A-Za-z0-9!@#$%^&*_-]{4,32}$', p))

def require_api_key(f):
    @wraps(f)
    def d(*a, **k):
        key = request.headers.get('X-API-Key') or request.args.get('api_key')
        if not key or key != API_KEY: return jsonify({'success': False, 'error': 'Invalid API key'}), 401
        return f(*a, **k)
    return d

def run_safe(args, timeout=30):
    try:
        if isinstance(args, str): args = args.split()
        r = subprocess.run(args, capture_output=True, text=True, timeout=timeout)
        return {'success': r.returncode == 0, 'stdout': r.stdout.strip() if r.stdout else '', 'stderr': r.stderr.strip() if r.stderr else ''}
    except Exception as e: return {'success': False, 'stdout': '', 'stderr': str(e)}

def run_shell(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return r.stdout.strip() if r.stdout else ''
    except Exception: return ''

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
                    users.append({'username': parts[0], 'password': parts[1], 'expiry': parts[2], 'limit': parts[3], 'bandwidth': parts[4] if len(parts) > 4 else '0', 'traffic': parts[5] if len(parts) > 5 else '0', 'status': parts[6] if len(parts) > 6 else 'ACTIVE'})
    except Exception: pass
    return users

def user_exists(u): return run_safe(['id', u]).get('success', False)

def get_status(u):
    if not user_exists(u): return 'not_found'
    r = run_safe(['passwd', '-S', u])
    parts = r.get('stdout', '').split()
    if len(parts) >= 2 and parts[1] == 'L': return 'locked'
    user = next((x for x in read_users() if x['username'] == u), None)
    if user and user.get('expiry'):
        try:
            if datetime.strptime(user['expiry'], '%Y-%m-%d') < datetime.now(): return 'expired'
        except Exception: pass
    return 'active'

def get_expiry_status(expiry_date_str):
    try:
        expiry = datetime.strptime(expiry_date_str, '%Y-%m-%d')
        now = datetime.now()
        days_left = (expiry - now).days
        if days_left < 0: return {'status': 'expired', 'level': 'danger', 'days_left': 0}
        elif days_left == 0: return {'status': 'expires_today', 'level': 'danger', 'days_left': 0}
        elif days_left <= 2: return {'status': 'expiring_critical', 'level': 'warning', 'days_left': days_left}
        elif days_left <= 7: return {'status': 'expiring_soon', 'level': 'warning', 'days_left': days_left}
        else: return {'status': 'active', 'level': 'success', 'days_left': days_left}
    except Exception:
        return {'status': 'unknown', 'level': 'default', 'days_left': 0}

def get_bandwidth_status(bandwidth_gb, used_bytes):
    try:
        bw = float(bandwidth_gb)
        if bw <= 0: return {'status': 'unlimited', 'level': 'success', 'pct': 0, 'bar_color': '#6BCB77', 'remaining_gb': 0}
        qb = bw * 1073741824
        pct = (used_bytes / qb) * 100
        remaining = bw - (used_bytes / 1073741824)
        if pct >= 95: bc = '#FF6B6B'; level = 'danger'
        elif pct >= 80: bc = '#FF9F43'; level = 'warning'
        elif pct >= 60: bc = '#FFD93D'; level = 'warning'
        else: bc = '#6BCB77'; level = 'success'
        if pct >= 100: return {'status': 'exhausted', 'level': 'danger', 'pct': round(pct, 1), 'remaining_gb': 0, 'bar_color': bc}
        elif pct >= 95: return {'status': 'critical', 'level': level, 'pct': round(pct, 1), 'remaining_gb': round(remaining, 2), 'bar_color': bc}
        else: return {'status': 'active', 'level': level, 'pct': round(pct, 1), 'remaining_gb': round(remaining, 2), 'bar_color': bc}
    except Exception:
        return {'status': 'unknown', 'level': 'default', 'pct': 0, 'bar_color': '#6BCB77', 'remaining_gb': 0}

def get_online(u):
    out = run_shell(f'pgrep -c -u {u} 2>/dev/null')
    try: return int(out or '0')
    except ValueError: return 0

def get_ssh_port():
    out = run_shell("ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1")
    try: return int(out.strip() or 22)
    except: return 22

def get_server_ip():
    for cmd in ['curl -s -4 icanhazip.com', "hostname -I | awk '{print $1}'"]:
        ip = run_shell(cmd, timeout=5).strip()
        if ip and ip.count('.') == 3 and not ip.startswith('127.'): return ip
    return 'unknown'

def get_protocols(username=None, password=None, limit=DEFAULT_LIMIT):
    p = {}
    sip = get_server_ip()
    if ssh_active(): p['ssh'] = {'id': 'ssh', 'name': 'SSH', 'icon': '🔐', 'host': SERVER_HOST, 'ip': sip, 'port': get_ssh_port(), 'username': username, 'password': password, 'limit': limit}
    if service_active('haproxy'): p['ssl'] = {'id': 'ssl', 'name': 'SSL', 'icon': '🔒', 'host': SERVER_HOST, 'ip': sip, 'port': 444, 'username': username, 'password': password, 'limit': limit}
    if service_active('dnstt'):
        d = ''; pk = ''; mtu = 512
        if os.path.exists(f'{DB_DIR}/domain.txt'):
            try:
                with open(f'{DB_DIR}/domain.txt') as f: d = f.read().strip()
            except: pass
        if os.path.exists(f'{DB_DIR}/dnstt/server.pub'):
            try:
                with open(f'{DB_DIR}/dnstt/server.pub') as f: pk = f.read().strip()
            except: pass
        if os.path.exists(f'{DB_DIR}/config/mtu'):
            try:
                with open(f'{DB_DIR}/config/mtu') as f: mtu = int(f.read().strip())
            except: mtu = 512
        p['dnstt'] = {'id': 'dnstt', 'name': 'DNSTT', 'icon': '📡', 'domain': d, 'pubkey': pk, 'mtu': mtu, 'dns': '8.8.8.8', 'username': username, 'password': password, 'limit': limit}
    if service_active('badvpn'): p['badvpn'] = {'id': 'badvpn', 'name': 'BadVPN', 'icon': '⚡', 'host': SERVER_HOST, 'ip': sip, 'port': 7300, 'username': username, 'password': password, 'limit': limit}
    if service_active('zivpn'): p['zivpn'] = {'id': 'zivpn', 'name': 'ZiVPN', 'icon': '🛡️', 'host': SERVER_HOST, 'ip': sip, 'port': 5667, 'username': username, 'password': password, 'limit': limit}
    return p

def now_iso(): return datetime.now().isoformat()

def is_banner_enabled():
    return os.path.exists(BANNER_ENABLED_FILE)

def refresh_ssh_banners():
    if not is_banner_enabled(): return {'success': False, 'error': 'Banner not enabled'}
    try:
        lines = ["# Voltron Tech - Dynamic Banners (auto-generated)"]
        count = 0
        for u in read_users():
            username = u['username']
            bf = f'{BANNER_DIR}/{username}.txt'
            if not os.path.exists(bf): continue
            lines.append(f"Match User {username}")
            lines.append(f"    Banner {bf}")
            count += 1
        tmp = '/tmp/voltron-banners.conf'
        with open(tmp, 'w') as f: f.write('\n'.join(lines) + '\n')
        os.chmod(tmp, 0o644)
        shutil.copy(tmp, SSHD_BANNER_CONF)
        test = run_safe(['sshd', '-t'])
        if not test.get('success'):
            os.remove(SSHD_BANNER_CONF)
            return {'success': False, 'error': 'sshd config test failed', 'details': test.get('stderr')}
        for svc in ['sshd', 'ssh']:
            if run_safe(['systemctl', 'reload', svc]).get('success'): break
        return {'success': True, 'users_configured': count}
    except Exception as ex:
        return {'success': False, 'error': str(ex)}

@app.route('/api/health')
def health(): return jsonify({'success': True, 'status': 'ok', 'version': '14.0', 'api_domain': API_DOMAIN, 'protocols_active': len(get_protocols()), 'timestamp': now_iso()})

@app.route('/api/trial/check', methods=['POST'])
@require_api_key
def tcheck():
    d = request.get_json() or {}
    u = d.get('username', '').strip().lower()
    if not is_valid_username(u): return jsonify({'available': False, 'error': 'Invalid username format'}), 400
    if user_exists(u) or any(x['username'] == u for x in read_users()): return jsonify({'available': False, 'error': 'Taken'})
    return jsonify({'available': True, 'username': u, 'timestamp': now_iso()})

@app.route('/api/trial/create', methods=['POST'])
@require_api_key
def tcreate():
    d = request.get_json() or {}
    u = d.get('username', '').strip().lower(); p = d.get('password', '').strip(); days = int(d.get('days', 1))
    if not is_valid_username(u): return jsonify({'success': False, 'error': 'Invalid username'}), 400
    if not is_valid_password(p): return jsonify({'success': False, 'error': 'Invalid password'}), 400
    if days not in [1, 3, 7]: return jsonify({'success': False, 'error': 'Days 1/3/7 only'}), 400
    if user_exists(u): return jsonify({'success': False, 'error': 'Exists'}), 400
    try:
        run_safe(['useradd', '-m', '-s', '/usr/sbin/nologin', u])
        run_safe(['usermod', '-aG', 'ffusers', u])
        subprocess.run(['chpasswd'], input=f'{u}:{p}', text=True, capture_output=True)
        e = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', e, u])
        with open(DB_FILE, 'a') as f: f.write(f'{u}:{p}:{e}:{DEFAULT_LIMIT}:0:0:ACTIVE\n')
        run_shell(f'echo "0" > {BANDWIDTH_DIR}/{u}.usage')
        return jsonify({'success': True, 'account': {'username': u, 'password': p, 'expiry': e, 'days': days, 'limit': DEFAULT_LIMIT, 'bandwidth': 'Unlimited', 'server': SERVER_HOST, 'server_ip': get_server_ip()}, 'protocols': get_protocols(u, p, DEFAULT_LIMIT)})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/trial/status/<username>')
@require_api_key
def tstatus(username):
    if not is_valid_username(username): return jsonify({'success': False, 'error': 'Invalid'}), 400
    user = next((u for u in read_users() if u['username'] == username), None)
    if not user: return jsonify({'success': False, 'error': 'Not found'}), 404
    expiry_info = get_expiry_status(user['expiry'])
    return jsonify({'success': True, 'account': {'username': username, 'status': get_status(username), 'expiry': user['expiry'], 'expiry_status': expiry_info['status'], 'days_left': expiry_info['days_left'], 'online': get_online(username), 'limit': int(user['limit']), 'bandwidth': user['bandwidth']}})

@app.route('/api/users/list')
@require_api_key
def ulist():
    r = []
    for u in read_users():
        ub = 0; uf = f'{BANDWIDTH_DIR}/{u["username"]}.usage'
        if os.path.exists(uf):
            try:
                with open(uf) as f: ub = int(f.read().strip() or 0)
            except: ub = 0
        expiry_info = get_expiry_status(u['expiry'])
        bw_info = get_bandwidth_status(u['bandwidth'], ub)
        r.append({
            'username': u['username'],
            'expiry': u['expiry'],
            'days_left': expiry_info['days_left'],
            'expiry_status': expiry_info['status'],
            'limit': int(u['limit']),
            'bandwidth_limit': float(u['bandwidth']),
            'bandwidth_used_gb': round(ub / 1073741824, 4),
            'bandwidth_pct': bw_info['pct'],
            'bandwidth_remaining_gb': bw_info.get('remaining_gb', 0),
            'bandwidth_status': bw_info['status'],
            'bandwidth_bar_color': bw_info.get('bar_color', '#6BCB77'),
            'status': get_status(u['username']),
            'online': get_online(u['username'])
        })
    return jsonify({'success': True, 'users': r, 'total': len(r)})

@app.route('/api/users/create', methods=['POST'])
@require_api_key
def ucreate():
    d = request.get_json() or {}
    u = d.get('username', '').strip().lower(); p = d.get('password', '').strip()
    days = int(d.get('days', 30)); limit = int(d.get('limit', DEFAULT_LIMIT)); bw = float(d.get('bandwidth', 0))
    if not is_valid_username(u): return jsonify({'success': False, 'error': 'Invalid username'}), 400
    if not is_valid_password(p): return jsonify({'success': False, 'error': 'Invalid password'}), 400
    if user_exists(u): return jsonify({'success': False, 'error': 'Exists'}), 400
    try:
        run_safe(['useradd', '-m', '-s', '/usr/sbin/nologin', u])
        run_safe(['usermod', '-aG', 'ffusers', u])
        subprocess.run(['chpasswd'], input=f'{u}:{p}', text=True, capture_output=True)
        e = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', e, u])
        with open(DB_FILE, 'a') as f: f.write(f'{u}:{p}:{e}:{limit}:{bw}:0:ACTIVE\n')
        run_shell(f'echo "0" > {BANDWIDTH_DIR}/{u}.usage')
        return jsonify({'success': True, 'account': {'username': u, 'password': p, 'expiry': e, 'limit': limit, 'bandwidth': bw}})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/delete', methods=['POST'])
@require_api_key
def udelete():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not is_valid_username(u): return jsonify({'success': False, 'error': 'Invalid'}), 400
    try:
        run_shell(f'killall -u {u} -9 2>/dev/null'); run_safe(['userdel', '-r', u])
        run_shell(f'rm -f {BANDWIDTH_DIR}/{u}.usage'); run_shell(f"sed -i '/^{u}:/d' {DB_FILE}")
        return jsonify({'success': True, 'message': f'User {u} deleted'})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/lock', methods=['POST'])
@require_api_key
def ulock():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not is_valid_username(u) or not user_exists(u): return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        run_safe(['usermod', '-L', u]); run_shell(f'killall -u {u} -9 2>/dev/null')
        return jsonify({'success': True, 'message': f'{u} locked'})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/unlock', methods=['POST'])
@require_api_key
def uunlock():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not is_valid_username(u) or not user_exists(u): return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        run_safe(['usermod', '-U', u])
        return jsonify({'success': True, 'message': f'{u} unlocked'})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/renew', methods=['POST'])
@require_api_key
def urenew():
    d = request.get_json() or {}
    u = d.get('username', '').strip(); days = int(d.get('days', 30))
    if not is_valid_username(u) or not user_exists(u): return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        ne = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', ne, u]); run_safe(['usermod', '-U', u])
        all_users = read_users(); new_lines = []
        for x in all_users:
            if x['username'] == u:
                new_lines.append(f"{u}:{x['password']}:{ne}:{x['limit']}:{x['bandwidth']}:{x.get('traffic','0')}:ACTIVE")
            else:
                new_lines.append(f"{x['username']}:{x['password']}:{x['expiry']}:{x['limit']}:{x['bandwidth']}:{x.get('traffic','0')}:{x.get('status','ACTIVE')}")
        with open(DB_FILE, 'w') as f: f.write('\n'.join(new_lines) + '\n')
        return jsonify({'success': True, 'expiry': ne})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/reset_bandwidth', methods=['POST'])
@require_api_key
def ursbw():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not is_valid_username(u) or not user_exists(u): return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        run_shell(f'echo "0" > {BANDWIDTH_DIR}/{u}.usage'); run_safe(['usermod', '-U', u])
        return jsonify({'success': True})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/cleanup/expired', methods=['POST'])
@require_api_key
def uclean():
    try:
        deleted = []
        for x in read_users():
            try:
                exp = datetime.strptime(x['expiry'], '%Y-%m-%d')
                if exp < datetime.now():
                    u = x['username']
                    run_shell(f'killall -u {u} -9 2>/dev/null'); run_safe(['userdel', '-r', u])
                    run_shell(f'rm -f {BANDWIDTH_DIR}/{u}.usage'); run_shell(f"sed -i '/^{u}:/d' {DB_FILE}")
                    deleted.append(u)
            except: pass
        return jsonify({'success': True, 'deleted': deleted, 'count': len(deleted)})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/protocols/status')
@require_api_key
def pstat():
    p = get_protocols()
    return jsonify({'success': True, 'protocols': p, 'count': len(p), 'active_list': list(p.keys())})

@app.route('/api/dashboard/info')
@require_api_key
def dinfo():
    try:
        ip = get_server_ip()
        try:
            with open('/proc/uptime') as f: up = float(f.read().split()[0])
            d = int(up // 86400); h = int((up % 86400) // 3600); us = f'{d}d {h}h'
        except: us = 'unknown'
        users = read_users()
        online = sum(get_online(u['username']) for u in users)
        return jsonify({'success': True, 'info': {'ip': ip, 'api_domain': API_DOMAIN, 'uptime': us, 'users': {'total': len(users), 'online': online}, 'banner_enabled': is_banner_enabled(), 'services': {'ssh': ssh_active(), 'dnstt': service_active('dnstt'), 'haproxy': service_active('haproxy'), 'badvpn': service_active('badvpn'), 'udp_custom': service_active('udp-custom'), 'zivpn': service_active('zivpn')}}})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/banner/status')
@require_api_key
def banner_status():
    return jsonify({'success': True, 'enabled': is_banner_enabled(), 'banner_count': len([f for f in os.listdir(BANNER_DIR) if f.endswith('.txt')]) if os.path.exists(BANNER_DIR) else 0, 'config_file': SSHD_BANNER_CONF, 'config_exists': os.path.exists(SSHD_BANNER_CONF), 'timestamp': now_iso()})

@app.route('/api/banner/enable', methods=['POST'])
@require_api_key
def banner_enable():
    try:
        os.makedirs(BANNER_DIR, exist_ok=True)
        open(BANNER_ENABLED_FILE, 'w').close()
        os.chmod(BANNER_ENABLED_FILE, 0o644)
        result = refresh_ssh_banners()
        run_safe(['systemctl', 'restart', 'voltrontech-limiter'])
        return jsonify({'success': True, 'message': 'Dynamic SSH banner enabled', 'details': result})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/banner/disable', methods=['POST'])
@require_api_key
def banner_disable():
    try:
        for f in [BANNER_ENABLED_FILE, SSHD_BANNER_CONF]:
            if os.path.exists(f): os.remove(f)
        for svc in ['sshd', 'ssh']:
            if run_safe(['systemctl', 'reload', svc]).get('success'): break
        return jsonify({'success': True, 'message': 'Dynamic SSH banner disabled'})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/banner/refresh', methods=['POST'])
@require_api_key
def banner_refresh():
    result = refresh_ssh_banners()
    return jsonify({'success': result.get('success', False), 'details': result})

@app.route('/api/config/domain')
@require_api_key
def config_domain():
    return jsonify({'success': True, 'api_domain': API_DOMAIN, 'server_host': SERVER_HOST})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
APIEOF
    chmod +x "$API_DIR/api.py"
}

web_panel_dns_setup() {
    clear; show_banner
    [[ -f "$WEB_PANEL_DOMAIN_FILE" ]] && WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && { echo "❌"; press_enter; return; }
    echo -e "VPS IP: $ip\nDomain: $WEB_PANEL_API_DOMAIN\n"
    local ex=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
    [[ "$ex" == "$ip" ]] && { echo -e "${C_GREEN}✅ OK${C_RESET}"; press_enter; return; }

    if [[ "$WEB_PANEL_API_DOMAIN" != *".$DESEC_DOMAIN" ]]; then
        echo -e "${C_YELLOW}⚠️  Domain sio under $DESEC_DOMAIN${C_RESET}"
        echo -e "  Set A record: $WEB_PANEL_API_DOMAIN → $ip"
        press_enter; return
    fi

    local sub=$(echo "$WEB_PANEL_API_DOMAIN" | sed "s|.$DESEC_DOMAIN||")
    local data="[{\"subname\":\"$sub\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$ip\"]}]"
    local r=$(curl -s -w "\n%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$data" 2>/dev/null)
    local hc=$(echo "$r" | tail -1)
    if [[ "$hc" -eq 201 ]] || [[ "$hc" -eq 200 ]]; then echo "✅"; sleep 5
    elif [[ "$hc" -eq 409 ]]; then curl -s -X PATCH "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$sub/A/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "{\"records\":[\"$ip\"],\"ttl\":3600}" >/dev/null 2>&1; echo "✅ Updated"
    else echo "❌ HTTP $hc"; fi
    press_enter
}

web_panel_nginx_setup() {
    clear; show_banner
    [[ -f "$WEB_PANEL_DOMAIN_FILE" ]] && WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")
    command -v nginx &>/dev/null || ff_apt_install nginx certbot python3-certbot-nginx >/dev/null 2>&1
    cat > "$WEB_PANEL_NGINX_CONFIG" <<EOF
server {
    listen 80;
    server_name $WEB_PANEL_API_DOMAIN;
    location / {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, X-API-Key' always;
        if (\$request_method = 'OPTIONS') { return 204; }
    }
}
EOF
    ln -sf "$WEB_PANEL_NGINX_CONFIG" "$WEB_PANEL_NGINX_LINK"
    rm -f /etc/nginx/sites-enabled/default
    nginx -t 2>&1 | grep -q successful && systemctl reload nginx && echo "✅" || { echo "❌"; nginx -t; }
    press_enter
}

web_panel_ssl_setup() {
    clear; show_banner
    [[ -f "$WEB_PANEL_DOMAIN_FILE" ]] && WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")
    read -p "Email (Enter skip): " em
    [ -n "$em" ] && echo "$em" > "$WEB_PANEL_SSL_EMAIL_FILE"
    if [ -n "$em" ]; then certbot --nginx -d "$WEB_PANEL_API_DOMAIN" --non-interactive --agree-tos -m "$em" --redirect
    else certbot --nginx -d "$WEB_PANEL_API_DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect; fi
    systemctl enable certbot.timer &>/dev/null; systemctl start certbot.timer &>/dev/null
    press_enter
}

web_panel_test_all() {
    clear; show_banner
    [[ -f "$WEB_PANEL_DOMAIN_FILE" ]] && WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")
    local p=0; local f=0
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    local dip=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
    local key=$(cat "$API_KEY_FILE" 2>/dev/null)
    echo -e "${C_BLUE}[1/6] API service...${C_RESET}"
    systemctl is-active --quiet voltrontech-api 2>/dev/null && { echo -e "     ${C_GREEN}✅${C_RESET}"; p=$((p+1)); } || { echo -e "     ${C_RED}❌${C_RESET}"; f=$((f+1)); }
    echo -e "${C_BLUE}[2/6] Nginx...${C_RESET}"
    systemctl is-active --quiet nginx 2>/dev/null && { echo -e "     ${C_GREEN}✅${C_RESET}"; p=$((p+1)); } || { echo -e "     ${C_RED}❌${C_RESET}"; f=$((f+1)); }
    echo -e "${C_BLUE}[3/6] Local API...${C_RESET}"
    curl -s http://localhost:$API_PORT/api/health 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅${C_RESET}"; p=$((p+1)); } || { echo -e "     ${C_RED}❌${C_RESET}"; f=$((f+1)); }
    echo -e "${C_BLUE}[4/6] DNS...${C_RESET}"
    [[ "$dip" == "$ip" ]] && { echo -e "     ${C_GREEN}✅ $dip${C_RESET}"; p=$((p+1)); } || { echo -e "     ${C_YELLOW}⏳ $dip${C_RESET}"; f=$((f+1)); }
    echo -e "${C_BLUE}[5/6] HTTPS...${C_RESET}"
    if [ -d "/etc/letsencrypt/live/$WEB_PANEL_API_DOMAIN" ]; then
        curl -s "https://$WEB_PANEL_API_DOMAIN/api/health" 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅${C_RESET}"; p=$((p+1)); } || { echo -e "     ${C_RED}❌${C_RESET}"; f=$((f+1)); }
    else echo -e "     ${C_YELLOW}⏳ SSL not installed${C_RESET}"; f=$((f+1)); fi
    echo -e "${C_BLUE}[6/6] Banner endpoint...${C_RESET}"
    if [ -n "$key" ]; then
        curl -s -H "X-API-Key: $key" "https://$WEB_PANEL_API_DOMAIN/api/banner/status" 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅${C_RESET}"; p=$((p+1)); } || { echo -e "     ${C_RED}❌${C_RESET}"; f=$((f+1)); }
    else echo -e "     ${C_RED}❌${C_RESET}"; f=$((f+1)); fi
    echo ""
    [[ $f -eq 0 ]] && echo -e "${C_GREEN}✅ ALL PASSED ($p/6)${C_RESET}" || echo -e "${C_YELLOW}⚠️ Passed: $p/6 Failed: $f${C_RESET}"
    press_enter
}

web_panel_view_logs() {
    clear; show_banner
    echo "1) API  2) Nginx  3) Error  4) Certbot  0) Return"
    read -p "👉 " c
    case $c in
        1) tail -30 /var/log/voltrontech-api.log 2>/dev/null; press_enter ;;
        2) tail -20 /var/log/nginx/access.log 2>/dev/null; press_enter ;;
        3) tail -20 /var/log/nginx/error.log 2>/dev/null; press_enter ;;
        4) tail -20 /var/log/letsencrypt/letsencrypt.log 2>/dev/null; press_enter ;;
        0) return ;;
    esac
}

web_panel_view_api_info() {
    clear; show_banner
    [[ -f "$WEB_PANEL_DOMAIN_FILE" ]] && WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")
    [ ! -f "$API_KEY_FILE" ] && { echo "❌ Not installed"; press_enter; return; }
    echo -e "  🌐 Domain: https://$WEB_PANEL_API_DOMAIN"
    echo -e "  🔑 API Key: $(cat "$API_KEY_FILE")"
    echo -e "  🎨 Banner: $([ -f "$BANNER_ENABLED_FILE" ] && echo 'ENABLED' || echo 'DISABLED')\n"
    echo -e "${C_BOLD}Endpoints:${C_RESET}"
    echo "  GET  /api/health"
    echo "  POST /api/trial/check       { username }"
    echo "  POST /api/trial/create      { username, password, days }"
    echo "  GET  /api/trial/status/<u>"
    echo "  GET  /api/users/list"
    echo "  POST /api/users/create      { username, password, days, limit, bandwidth }"
    echo "  POST /api/users/delete      { username }"
    echo "  POST /api/users/lock        { username }"
    echo "  POST /api/users/unlock      { username }"
    echo "  POST /api/users/renew       { username, days }"
    echo "  POST /api/users/reset_bandwidth { username }"
    echo "  POST /api/cleanup/expired"
    echo "  GET  /api/protocols/status"
    echo "  GET  /api/dashboard/info"
    echo ""
    echo -e "${C_BOLD}${C_YELLOW}Banner Endpoints:${C_RESET}"
    echo "  GET  /api/banner/status"
    echo "  POST /api/banner/enable"
    echo "  POST /api/banner/disable"
    echo "  POST /api/banner/refresh"
    press_enter
}

web_panel_restart_api() { systemctl restart voltrontech-api; sleep 2; systemctl is-active --quiet voltrontech-api && echo "✅" || echo "❌"; press_enter; }

web_panel_copy_for_lovable() {
    clear; show_banner
    [[ -f "$WEB_PANEL_DOMAIN_FILE" ]] && WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")
    [ ! -f "$API_KEY_FILE" ] && { echo "❌"; press_enter; return; }
    local key=$(cat "$API_KEY_FILE")
    cat << LOVABLEEOF
═══════════════════════════════════════════════════════════════════
         📋 COPY HII KWA LOVABLE
═══════════════════════════════════════════════════════════════════

BASE URL : https://$WEB_PANEL_API_DOMAIN
API KEY  : $key

AUTH HEADER:
  X-API-Key: $key

MFANO WA FETCH (JavaScript):
─────────────────────────────────────────
const API_URL = "https://$WEB_PANEL_API_DOMAIN";
const API_KEY = "$key";

async function apiCall(endpoint, method = "GET", body = null) {
  const opts = {
    method,
    headers: {
      "Content-Type": "application/json",
      "X-API-Key": API_KEY
    }
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(\`\${API_URL}\${endpoint}\`, opts);
  return res.json();
}

// Mfano: Unda trial
apiCall("/api/trial/create", "POST", {
  username: "trial001",
  password: "pass1234",
  days: 3
});

ENDPOINTS:
─────────────────────────────────────────
POST /api/trial/check            { username }
POST /api/trial/create           { username, password, days }
GET  /api/trial/status/:u
GET  /api/users/list
POST /api/users/create           { username, password, days, limit, bandwidth }
POST /api/users/delete           { username }
POST /api/users/lock             { username }
POST /api/users/unlock           { username }
POST /api/users/renew            { username, days }
POST /api/users/reset_bandwidth  { username }
POST /api/cleanup/expired
GET  /api/protocols/status
GET  /api/dashboard/info
GET  /api/banner/status
POST /api/banner/enable
POST /api/banner/disable
POST /api/banner/refresh
GET  /api/config/domain

═══════════════════════════════════════════════════════════════════
LOVABLEEOF
    press_enter
}

web_panel_remove() {
    clear; show_banner
    read -p "Confirm? (y/n): " c; [[ "$c" != "y" ]] && return
    [[ -f "$WEB_PANEL_DOMAIN_FILE" ]] && WEB_PANEL_API_DOMAIN=$(cat "$WEB_PANEL_DOMAIN_FILE")
    systemctl stop voltrontech-api 2>/dev/null; systemctl disable voltrontech-api 2>/dev/null
    rm -f /etc/systemd/system/voltrontech-api.service; rm -rf "$API_DIR"
    rm -f "$WEB_PANEL_NGINX_LINK" "$WEB_PANEL_NGINX_CONFIG"
    nginx -t 2>&1 | grep -q successful && systemctl reload nginx
    certbot delete --cert-name "$WEB_PANEL_API_DOMAIN" --non-interactive 2>/dev/null
    systemctl daemon-reload; echo "✅"; press_enter
}

# ============================================================
# PROTOCOLS
# ============================================================

install_badvpn() {
    clear; show_banner
    ff_apt_install cmake make gcc git build-essential libssl-dev
    cd /tmp; rm -rf badvpn
    git clone https://github.com/ambrop72/badvpn.git 2>/dev/null
    cd badvpn; cmake . 2>/dev/null; make 2>/dev/null
    cp badvpn-udpgw "$BADVPN_BIN" 2>/dev/null
    cat > "$BADVPN_SERVICE_FILE" <<EOF
[Unit]
Description=BadVPN
After=network.target
[Service]
Type=simple
ExecStart=$BADVPN_BIN --listen-addr 0.0.0.0:7300 --max-clients 1000
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable badvpn.service 2>/dev/null; systemctl start badvpn.service
    echo "✅"; press_enter
}
uninstall_badvpn() { systemctl stop badvpn.service 2>/dev/null; systemctl disable badvpn.service 2>/dev/null; rm -f "$BADVPN_SERVICE_FILE" "$BADVPN_BIN"; systemctl daemon-reload; echo "✅"; press_enter; }

install_udp_custom() {
    clear; show_banner
    local a=$(uname -m)
    [[ "$a" == "x86_64" ]] && curl -sL -o "$UDP_CUSTOM_BIN" "https://github.com/voltrontech/udp-custom/releases/latest/download/udp-custom-linux-amd64" || curl -sL -o "$UDP_CUSTOM_BIN" "https://github.com/voltrontech/udp-custom/releases/latest/download/udp-custom-linux-arm64"
    chmod +x "$UDP_CUSTOM_BIN"
    cat > "$UDP_CUSTOM_SERVICE_FILE" <<EOF
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
    systemctl daemon-reload; systemctl enable udp-custom.service 2>/dev/null; systemctl start udp-custom.service
    echo "✅"; press_enter
}
uninstall_udp_custom() { systemctl stop udp-custom.service 2>/dev/null; systemctl disable udp-custom.service 2>/dev/null; rm -f "$UDP_CUSTOM_SERVICE_FILE" "$UDP_CUSTOM_BIN"; systemctl daemon-reload; echo "✅"; press_enter; }

install_ssl_tunnel() {
    clear; show_banner
    ff_apt_install haproxy openssl
    mkdir -p "$SSL_CERT_DIR"
    openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout "$SSL_CERT_DIR/v.key" -out "$SSL_CERT_DIR/v.crt" -subj "/CN=VOLTRON" 2>/dev/null
    cat "$SSL_CERT_DIR/v.crt" "$SSL_CERT_DIR/v.key" > "$SSL_CERT_FILE" 2>/dev/null
    cat > "$HAPROXY_CONFIG" <<EOF
global
    daemon
defaults
    mode tcp
    timeout connect 5000
    timeout client 50000
    timeout server 50000
frontend ssh_ssl_in
    bind *:444 ssl crt $SSL_CERT_FILE
    default_backend ssh_backend
backend ssh_backend
    server ssh_server 127.0.0.1:22
EOF
    systemctl restart haproxy
    echo "✅"; press_enter
}
uninstall_ssl_tunnel() { systemctl stop haproxy 2>/dev/null; ff_apt_purge haproxy; rm -f "$HAPROXY_CONFIG" "$SSL_CERT_FILE"; echo "✅"; press_enter; }

install_falcon_proxy() {
    clear; show_banner
    local a=$(uname -m)
    [[ "$a" == "x86_64" ]] && curl -sL -o "$FALCONPROXY_BINARY" "https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/latest/download/falconproxy" || curl -sL -o "$FALCONPROXY_BINARY" "https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/latest/download/falconproxyarm"
    chmod +x "$FALCONPROXY_BINARY"
    read -p "Port [8080]: " p; p=${p:-8080}
    cat > "$FALCONPROXY_SERVICE_FILE" <<EOF
[Unit]
Description=Falcon Proxy
After=network.target
[Service]
Type=simple
ExecStart=$FALCONPROXY_BINARY -p $p
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable falconproxy.service 2>/dev/null; systemctl start falconproxy.service
    echo "✅"; press_enter
}
uninstall_falcon_proxy() { systemctl stop falconproxy.service 2>/dev/null; systemctl disable falconproxy.service 2>/dev/null; rm -f "$FALCONPROXY_SERVICE_FILE" "$FALCONPROXY_BINARY"; systemctl daemon-reload; echo "✅"; press_enter; }

install_zivpn() {
    clear; show_banner
    local a=$(uname -m)
    [[ "$a" == "x86_64" ]] && curl -sL -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64" || curl -sL -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
    chmod +x "$ZIVPN_BIN"; mkdir -p "$ZIVPN_DIR"
    openssl req -x509 -newkey rsa:4096 -nodes -days 365 -keyout "$ZIVPN_DIR/server.key" -out "$ZIVPN_DIR/server.crt" -subj "/CN=ZiVPN" 2>/dev/null
    read -p "Passwords [user1,user2]: " pw; pw=${pw:-user1,user2}
    IFS=',' read -ra pa <<< "$pw"
    jp=$(printf '"%s",' "${pa[@]}"); jp="[${jp%,}]"
    cat > "$ZIVPN_CONFIG_FILE" <<EOF
{"listen":":5667","cert":"$ZIVPN_DIR/server.crt","key":"$ZIVPN_DIR/server.key","obfs":"zivpn","auth":{"mode":"passwords","config":$jp}}
EOF
    cat > "$ZIVPN_SERVICE_FILE" <<EOF
[Unit]
Description=ZiVPN
After=network.target
[Service]
Type=simple
ExecStart=$ZIVPN_BIN server -c $ZIVPN_CONFIG_FILE
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable zivpn.service 2>/dev/null; systemctl start zivpn.service
    echo "✅"; press_enter
}
uninstall_zivpn() { systemctl stop zivpn.service 2>/dev/null; systemctl disable zivpn.service 2>/dev/null; rm -f "$ZIVPN_SERVICE_FILE" "$ZIVPN_BIN"; rm -rf "$ZIVPN_DIR"; systemctl daemon-reload; echo "✅"; press_enter; }

install_xui_panel() { clear; show_banner; bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh); press_enter; }
uninstall_xui_panel() { command -v x-ui &>/dev/null && x-ui uninstall; rm -f /usr/local/bin/x-ui; rm -rf /etc/x-ui /usr/local/x-ui; echo "✅"; press_enter; }

# ============ PROTOCOL MENU ============
protocol_menu() {
    while true; do
        clear; show_banner
        local bs=$(systemctl is-active badvpn 2>/dev/null); [[ -z "$bs" ]] && bs="inactive"
        local us=$(systemctl is-active udp-custom 2>/dev/null); [[ -z "$us" ]] && us="inactive"
        local hs=$(systemctl is-active haproxy 2>/dev/null); [[ -z "$hs" ]] && hs="inactive"
        local ds=$(systemctl is-active dnstt 2>/dev/null); [[ -z "$ds" ]] && ds="inactive"
        local fs=$(systemctl is-active falconproxy 2>/dev/null); [[ -z "$fs" ]] && fs="inactive"
        local zs=$(systemctl is-active zivpn 2>/dev/null); [[ -z "$zs" ]] && zs="inactive"
        local bs_col="$C_DIM"; [[ "$bs" == "active" ]] && bs_col="$C_GREEN"
        local us_col="$C_DIM"; [[ "$us" == "active" ]] && us_col="$C_GREEN"
        local hs_col="$C_DIM"; [[ "$hs" == "active" ]] && hs_col="$C_GREEN"
        local ds_col="$C_DIM"; [[ "$ds" == "active" ]] && ds_col="$C_GREEN"
        local fs_col="$C_DIM"; [[ "$fs" == "active" ]] && fs_col="$C_GREEN"
        local zs_col="$C_DIM"; [[ "$zs" == "active" ]] && zs_col="$C_GREEN"
        local xs=""; command -v x-ui &>/dev/null && xs="${C_GREEN}● INSTALLED${C_RESET}" || xs="${C_DIM}● NOT INSTALLED${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}              🔌 PROTOCOL MANAGEMENT${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        printf "  ${C_GREEN}%2s${C_RESET}) %-22s [${bs_col}%s${C_RESET}]\n" "1" "badvpn (UDP 7300)" "$bs"
        printf "  ${C_GREEN}%2s${C_RESET}) %-22s [${us_col}%s${C_RESET}]\n" "2" "udp-custom" "$us"
        printf "  ${C_GREEN}%2s${C_RESET}) %-22s [${hs_col}%s${C_RESET}]\n" "3" "SSL Tunnel (HAProxy)" "$hs"
        printf "  ${C_GREEN}%2s${C_RESET}) %-22s [${ds_col}%s${C_RESET}]\n" "4" "DNSTT (Port 53)" "$ds"
        printf "  ${C_GREEN}%2s${C_RESET}) %-22s [${fs_col}%s${C_RESET}]\n" "5" "Falcon Proxy" "$fs"
        printf "  ${C_GREEN}%2s${C_RESET}) %-22s [${zs_col}%s${C_RESET}]\n" "6" "ZiVPN" "$zs"
        printf "  ${C_GREEN}%2s${C_RESET}) %-22s %s\n" "7" "X-UI Panel" "$xs"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        read -p "👉 Select: " choice
        case $choice in
            1) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_badvpn || uninstall_badvpn ;;
            2) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_udp_custom || uninstall_udp_custom ;;
            3) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_ssl_tunnel || uninstall_ssl_tunnel ;;
            4) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_GREEN}2)${C_RESET} Manage\n  ${C_RED}3)${C_RESET} Uninstall"; read -p "👉 " sub
               case $sub in 1) install_dnstt ;; 2) dnstt_main_menu ;; 3) uninstall_dnstt ;; esac ;;
            5) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_falcon_proxy || uninstall_falcon_proxy ;;
            6) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_zivpn || uninstall_zivpn ;;
            7) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_xui_panel || uninstall_xui_panel ;;
            0) return ;;
        esac
    done
}

# ============ CLIENT CONFIG ============
client_config_menu() {
    clear; show_banner
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}              📱 SSH MANAGER CONFIG${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    local ssh_port=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); ssh_port=${ssh_port:-22}
    local domain=""; [ -f "$DB_DIR/domain.txt" ] && domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
    echo -e "${C_CYAN}═══ Server Info ═══${C_RESET}"
    echo -e "  ${C_YELLOW}IP${C_RESET}       : $ip"
    echo -e "  ${C_YELLOW}SSH Port${C_RESET} : $ssh_port"
    echo -e "  ${C_YELLOW}SNI/Host${C_RESET} : ${domain:-$ip}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} 📋 Select user — Show config"
    echo -e "  ${C_GREEN}2)${C_RESET} 📊 List all users — Bulk config"
    echo -e "  ${C_GREEN}3)${C_RESET} 📄 JSON export"
    echo -e "  ${C_RED}0)${C_RESET} Return"
    read -p "👉 Choice: " c
    case $c in
        1) _select_user_interface "--- Select User ---"; local u=$SELECTED_USER; [[ "$u" == "NO_USERS" || -z "$u" ]] && return; local p=$(grep "^$u:" "$DB_FILE" | cut -d: -f2); generate_client_config "$u" "$p" ;;
        2) clear; show_banner
            echo -e "${C_PURPLE}═══ 📋 ALL USERS CONFIG ═══${C_RESET}\n"
            echo -e "${C_CYAN}Server:${C_RESET} $ip:$ssh_port   ${C_CYAN}SNI:${C_RESET} ${domain:-$ip}\n"
            printf "${C_BOLD}%-15s | %-15s | %-12s | %-8s${C_RESET}\n" "USERNAME" "PASSWORD" "EXPIRY" "LIMIT"
            while IFS=: read -r user pass expiry limit bw _extra; do
                [[ -z "$user" ]] && continue
                printf "${C_GREEN}%-15s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET} | ${C_WHITE}%-8s${C_RESET}\n" "$user" "$pass" "$expiry" "$limit"
            done < <(sort "$DB_FILE")
            press_enter ;;
        3) _select_user_interface "--- JSON Export ---"; local u=$SELECTED_USER; [[ "$u" == "NO_USERS" || -z "$u" ]] && return; local p=$(grep "^$u:" "$DB_FILE" | cut -d: -f2); generate_client_json "$u" "$p" ;;
        0) return ;;
    esac
}

generate_client_config() {
    local u=$1 p=$2
    clear; show_banner
    local line=$(grep "^$u:" "$DB_FILE")
    local expiry=$(echo "$line"|cut -d: -f3); local limit=$(echo "$line"|cut -d: -f4)
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    local domain=""; [ -f "$DB_DIR/domain.txt" ] && domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
    local ssh_port=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); ssh_port=${ssh_port:-22}
    local pubkey=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null); local mtu=$(get_current_mtu)
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}                 📱 CLIENT CONFIG: $u${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "${C_GREEN}🔐 SSH DIRECT${C_RESET}"
    echo -e "  Host/Server : $ip"
    echo -e "  Port        : $ssh_port"
    echo -e "  Username    : $u"
    echo -e "  Password    : $p"
    echo -e "  SNI         : ${domain:-$ip}"
    echo -e "  Expiry      : $expiry"
    echo -e "  Limit       : $limit\n"
    if systemctl is-active --quiet haproxy 2>/dev/null; then
        echo -e "${C_GREEN}🔒 SSL/TLS TUNNEL${C_RESET}"
        echo -e "  Host : $ip"; echo -e "  SSL  : 444"; echo -e "  SNI  : ${domain:-$ip}"
        echo -e "  User : $u"; echo -e "  Pass : $p\n"
    fi
    if systemctl is-active --quiet dnstt 2>/dev/null && [ -n "$domain" ]; then
        echo -e "${C_GREEN}📡 DNSTT / SLOWDNS${C_RESET}"
        echo -e "  Nameserver : $domain"; echo -e "  PubKey     : $pubkey"
        echo -e "  DNS IP     : 1.1.1.1"; echo -e "  MTU        : $mtu"
        echo -e "  User       : $u"; echo -e "  Pass       : $p\n"
    fi
    if systemctl is-active --quiet badvpn 2>/dev/null; then
        echo -e "${C_GREEN}⚡ BADVPN UDPGW${C_RESET}"
        echo -e "  Host : $ip"; echo -e "  Port : 7300\n"
    fi
    if systemctl is-active --quiet zivpn 2>/dev/null; then
        echo -e "${C_GREEN}🛡️ ZiVPN${C_RESET}"
        echo -e "  Host : $ip"; echo -e "  UDP  : 5667\n"
    fi
    press_enter
}

generate_client_json() {
    local u=$1 p=$2
    clear; show_banner
    local line=$(grep "^$u:" "$DB_FILE"); local expiry=$(echo "$line"|cut -d: -f3); local limit=$(echo "$line"|cut -d: -f4)
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null); local domain=""; [ -f "$DB_DIR/domain.txt" ] && domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
    local ssh_port=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); ssh_port=${ssh_port:-22}
    cat << JSONEOF
{
  "name": "Voltron_$u",
  "type": "ssh",
  "server": "$ip",
  "server_port": $ssh_port,
  "username": "$u",
  "password": "$p",
  "sni": "${domain:-$ip}",
  "expiry": "$expiry",
  "limit": $limit
}
JSONEOF
    echo ""; press_enter
}

# ============ SYSTEM UTILITIES ============
backup_user_data() { clear; show_banner; read -p "Path [/root/vt.tar.gz]: " p; p=${p:-/root/vt.tar.gz}; tar -czf "$p" -C "$(dirname "$DB_DIR")" "$(basename "$DB_DIR")" 2>/dev/null && echo "✅ $p" || echo "❌"; press_enter; }
restore_user_data() { clear; show_banner; read -p "Path: " p; [ ! -f "$p" ] && { echo "❌"; press_enter; return; }; read -p "Confirm? (y/n): " c; [[ "$c" == "y" ]] && { local td=$(mktemp -d); tar -xzf "$p" -C "$td" 2>/dev/null; [ -f "$td/voltrontech/users.db" ] && cp "$td/voltrontech/users.db" "$DB_FILE"; rm -rf "$td"; echo "✅"; }; press_enter; }

dns_menu() { clear; show_banner; [ -f "$DNS_INFO_FILE" ] && { source "$DNS_INFO_FILE"; echo "Existing: $FULL_DOMAIN"; read -p "Delete? (y/n): " c; [[ "$c" == "y" ]] && { curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/A/" -H "Authorization: Token $DESEC_TOKEN" >/dev/null; rm -f "$DNS_INFO_FILE"; }; } || { read -p "Generate? (y/n): " c; [[ "$c" == "y" ]] && generate_dns_record; }; press_enter; }

generate_dns_record() {
    local ip=$(curl -s -4 icanhazip.com)
    [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && return 1
    local sub="vps-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    local full="$sub.$DESEC_DOMAIN"
    local data=$(printf '[{"subname":"%s","type":"A","ttl":3600,"records":["%s"]}]' "$sub" "$ip")
    local r=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$data")
    [[ "${r: -3}" -ne 201 ]] && return 1
    printf 'SUBDOMAIN="%s"\nFULL_DOMAIN="%s"\n' "$sub" "$full" > "$DNS_INFO_FILE"
    echo "✅ $full"
}

show_vps_dashboard() {
    clear
    local ip=$(curl -s -4 icanhazip.com); local up=$(uptime -p | sed 's/up //')
    local ram=$(free -h | awk '/^Mem:/ {print $3"/"$2}')
    local disk=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")"}')
    local load=$(awk '{print $1}' /proc/loadavg)
    local users=$(grep -c . "$DB_FILE" 2>/dev/null || echo 0)
    echo -e "\n${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}                 🖥️  VPS DASHBOARD${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_CYAN}IP${C_RESET}     : $ip"
    echo -e "  ${C_CYAN}Uptime${C_RESET} : $up"
    echo -e "  ${C_CYAN}RAM${C_RESET}    : $ram"
    echo -e "  ${C_CYAN}Disk${C_RESET}   : $disk"
    echo -e "  ${C_CYAN}Load${C_RESET}   : $load"
    echo -e "  ${C_CYAN}Users${C_RESET}  : $users\n"
    echo -e "  ${C_PURPLE}Services:${C_RESET}"
    for s in sshd dnstt haproxy badvpn udp-custom zivpn falconproxy voltrontech-api voltrontech-limiter voltron-traffic nginx; do
        st=$(systemctl is-active "$s" 2>/dev/null)
        [[ "$st" == "active" ]] && echo -e "    ${C_GREEN}● $s${C_RESET}" || echo -e "    ${C_DIM}○ $s${C_RESET}"
    done
    echo -e "\n  ${C_DIM}[Enter] refresh | [0] exit${C_RESET}"
    read -p "👉 " rc
    [[ "$rc" != "0" ]] && show_vps_dashboard
}

show_vpn_data_usage() {
    clear; show_banner
    [[ ! -s "$DB_FILE" ]] && { echo "No users"; press_enter; return; }
    while IFS=: read -r u p e l b _x; do
        [[ -z "$u" ]] && continue
        ub=0; [[ -f "$BANDWIDTH_DIR/${u}.usage" ]] && ub=$(cat "$BANDWIDTH_DIR/${u}.usage" | tr -d '[:space:]')
        [[ ! "$ub" =~ ^[0-9]+$ ]] && ub=0
        local used_display=$(format_size "$ub")
        st=$(get_user_status "$u" | sed 's/\x1b\[[0-9;]*m//g')
        printf "${C_GREEN}%-15s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | %s\n" "$u" "$used_display" "$st"
    done < "$DB_FILE"
    press_enter
}

auto_reboot_menu() {
    clear; show_banner
    cc=$(crontab -l 2>/dev/null | grep "systemctl reboot")
    st="Disabled"; [[ -n "$cc" ]] && st="Active"
    echo -e "Status: $st\n1) Enable  2) Disable  0) Return"
    read -p "👉 " c
    case $c in
        1) (crontab -l 2>/dev/null | grep -v "systemctl reboot"; echo "0 0 * * * systemctl reboot") | crontab -; echo "✅"; press_enter ;;
        2) (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab -; echo "✅"; press_enter ;;
        0) return ;;
    esac
}

enable_cache_cleaner() {
    touch /var/log/voltron-cache.log
    cat > "$CACHE_SCRIPT" << 'EOF'
#!/bin/bash
LOG="/var/log/voltron-cache.log"
echo "$(date): Clean" >> "$LOG"
apt clean >> "$LOG" 2>&1
apt autoclean >> "$LOG" 2>&1
apt autoremove -y >> "$LOG" 2>&1
journalctl --vacuum-time=3d >> "$LOG" 2>&1
rm -rf /tmp/* /var/tmp/* 2>/dev/null
echo "$(date): Done" >> "$LOG"
EOF
    chmod +x "$CACHE_SCRIPT"
    echo "0 0 * * * root $CACHE_SCRIPT" > "$CACHE_CRON_FILE"
    (crontab -l 2>/dev/null | grep -v "voltron-cache"; echo "0 0 * * * $CACHE_SCRIPT") | crontab -
    echo "✅"; press_enter
}
disable_cache_cleaner() { rm -f "$CACHE_CRON_FILE"; crontab -l 2>/dev/null | grep -v "voltron-cache" | crontab -; echo "✅"; press_enter; }
cache_cleaner_menu() {
    while true; do
        clear; show_banner
        st="DISABLED"; [ -f "$CACHE_CRON_FILE" ] && st="ENABLED"
        echo -e "Cache cleaner: $st\n1) Enable  2) Disable  0) Return"
        read -p "👉 " c
        case $c in 1) enable_cache_cleaner ;; 2) disable_cache_cleaner ;; 0) return ;; esac
    done
}

find_orphan_users() {
    local -a o=()
    while IFS=: read -r u _ uid _ _ h sh; do
        [[ -z "$u" ]] && continue
        [[ "$uid" =~ ^[0-9]+$ ]] || continue
        (( uid >= 1000 )) || continue
        [[ "$h" == "/home/$u" ]] || continue
        case "$sh" in /usr/sbin/nologin|/usr/bin/false|/bin/false) ;; *) continue ;; esac
        grep -q "^$u:" "$DB_FILE" && continue
        o+=("$u")
    done < /etc/passwd
    ((${#o[@]})) && printf '%s\n' "${o[@]}"
}

orphan_cleanup_menu() {
    clear; show_banner
    mapfile -t ol < <(find_orphan_users)
    [ ${#ol[@]} -eq 0 ] && { echo "No orphans"; press_enter; return; }
    echo "Found ${#ol[@]} orphans:"
    for i in "${!ol[@]}"; do printf "  [%d] %s\n" "$((i+1))" "${ol[$i]}"; done
    read -p "Delete ALL? (y/n): " c
    [[ "$c" == "y" ]] && delete_voltrontech_user_accounts "${ol[@]}"
    press_enter
}

system_utilities_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                 ⚙️  SYSTEM UTILITIES${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} 💾 Backup"
        echo -e "  ${C_GREEN}2)${C_RESET} 📥 Restore"
        echo -e "  ${C_GREEN}3)${C_RESET} 🌐 DNS Manager"
        echo -e "  ${C_GREEN}4)${C_RESET} 🖥️  VPS Dashboard"
        echo -e "  ${C_GREEN}5)${C_RESET} 📊 Data Usage"
        echo -e "  ${C_GREEN}6)${C_RESET} 🔄 Auto Reboot"
        echo -e "  ${C_GREEN}7)${C_RESET} 🧹 Cache Cleaner"
        echo -e "  ${C_GREEN}8)${C_RESET} 🔍 Orphan Cleanup"
        echo -e "  ${C_GREEN}9)${C_RESET} ⚡ Speed Boosters"
        echo -e "  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) backup_user_data ;; 2) restore_user_data ;; 3) dns_menu ;;
            4) show_vps_dashboard ;; 5) show_vpn_data_usage ;; 6) auto_reboot_menu ;;
            7) cache_cleaner_menu ;; 8) orphan_cleanup_menu ;; 9) dnstt_speed_menu ;;
            0) return ;;
        esac
    done
}

# ============================================================
# INITIAL SETUP
# ============================================================
initial_setup() {
    echo -e "\n${C_BLUE}🔧 Initial setup...${C_RESET}"
    ff_apt_install curl wget bc iptables openssl dnsutils jq at ethtool 2>/dev/null
    mkdir -p "$DB_DIR" "$LOGS_DIR" "$CONFIG_DIR" "$BANDWIDTH_DIR" "$BANNER_DIR" "$DNSTT_KEYS_DIR" "$SSL_CERT_DIR" "$TRAFFIC_DIR" "$BACKUP_DIR"
    touch "$DB_FILE"
    [ ! -f "$WEB_PANEL_DOMAIN_FILE" ] && echo "$WEB_PANEL_API_DOMAIN" > "$WEB_PANEL_DOMAIN_FILE"
    create_limiter_service
    create_traffic_monitor
    systemctl enable atd &>/dev/null; systemctl start atd &>/dev/null
    echo -e "${C_GREEN}✅ Setup complete${C_RESET}"
}

# ============================================================
# UNINSTALL
# ============================================================
uninstall_script() {
    clear; show_banner
    read -p "Type YES to uninstall: " c
    [[ "$c" != "YES" ]] && { echo "Cancelled"; press_enter; return; }
    systemctl stop dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-api voltrontech-limiter voltron-traffic 2>/dev/null
    systemctl disable dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-api voltrontech-limiter voltron-traffic 2>/dev/null
    rm -f "$DNSTT_SERVICE_FILE" "$BADVPN_SERVICE_FILE" "$UDP_CUSTOM_SERVICE_FILE" "$ZIVPN_SERVICE_FILE" "$FALCONPROXY_SERVICE_FILE" "$LIMITER_SERVICE" "$TRAFFIC_SERVICE" /etc/systemd/system/voltrontech-api.service
    systemctl daemon-reload
    rm -f "$DNSTT_BINARY" "$DNSTT_CLIENT" "$BADVPN_BIN" "$UDP_CUSTOM_BIN" "$ZIVPN_BIN" "$FALCONPROXY_BINARY" "$LIMITER_SCRIPT" "$TRAFFIC_SCRIPT" "$CACHE_SCRIPT" "$TRIAL_CLEANUP_SCRIPT" "$BANNER_BUILDER"
    rm -rf "$API_DIR" "$DB_DIR" "$ZIVPN_DIR"
    rm -f "$WEB_PANEL_NGINX_CONFIG" "$WEB_PANEL_NGINX_LINK"
    certbot delete --cert-name "$WEB_PANEL_API_DOMAIN" --non-interactive 2>/dev/null
    nginx -t 2>&1 | grep -q successful && systemctl reload nginx 2>/dev/null
    rm -f "$SSHD_FF_CONFIG" /etc/ssh/sshd_config.d/voltron-auto-banner.conf
    rm -f "$CACHE_CRON_FILE"
    crontab -l 2>/dev/null | grep -v "voltron" | crontab - 2>/dev/null
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    echo "✅ Uninstalled"; sleep 2; rm -f "$0"; exit 0
}

# ============================================================
# MAIN MENU
# ============================================================
main_menu() {
    while true; do
        show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    👤 USER MANAGEMENT${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "1" "Create User" "7" "List Users"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "2" "Delete User" "8" "Renew User"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "3" "Edit User" "9" "Cleanup Expired"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "4" "Lock User" "10" "Bulk Create"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "5" "Unlock User" "11" "View Bandwidth"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "6" "Trial Account" "12" "📱 Client Config"
        echo ""
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    🔌 PROTOCOLS & SERVICES${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "13" "Protocols" "19" "Web Panel"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "14" "DNSTT Manage" "20" "System Utilities"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "15" "Speed Boosters" "21" "Restart Services"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "16" "VPS Dashboard" "22" "Orphan Cleanup"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s\n" "17" "Dynamic Banner"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s\n" "18" "📱 SSH Manager Config"
        echo ""
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    🔥 DANGER ZONE${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_RED}%2s${C_RESET}) %-28s  ${C_RED}%2s${C_RESET}) %-25s\n" "99" "Uninstall" "0" "Exit"
        echo ""
        read -p "👉 Select: " choice
        case $choice in
            1) create_user ;;
            2) delete_user ;;
            3) edit_user ;;
            4) lock_user ;;
            5) unlock_user ;;
            6) create_trial_account ;;
            7) list_users ;;
            8) renew_user ;;
            9) cleanup_expired ;;
            10) bulk_create_users ;;
            11) view_user_bandwidth ;;
            12) client_config_menu ;;
            13) protocol_menu ;;
            14) dnstt_main_menu ;;
            15) dnstt_speed_menu ;;
            16) show_vps_dashboard ;;
            17) ssh_banner_menu ;;
            18) client_config_menu ;;
            19) web_panel_menu ;;
            20) system_utilities_menu ;;
            21)
                echo -e "\n${C_BLUE}🔄 Restarting all services...${C_RESET}"
                systemctl restart dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-limiter voltron-traffic voltrontech-api 2>/dev/null
                echo -e "${C_GREEN}✅ Done${C_RESET}"
                press_enter ;;
            22) orphan_cleanup_menu ;;
            99) uninstall_script ;;
            0) echo -e "\n${C_GREEN}👋 Goodbye!${C_RESET}\n"; exit 0 ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ============================================================
# ENTRY POINT
# ============================================================
[[ $EUID -ne 0 ]] && { echo -e "${C_RED}❌ Run as root!${C_RESET}"; exit 1; }
[[ "$1" == "--install-setup" ]] && { initial_setup; exit 0; }
[[ ! -f "$INSTALL_FLAG_FILE" ]] && { initial_setup; touch "$INSTALL_FLAG_FILE"; }
main_menu
