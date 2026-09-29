#!/bin/bash
# ================================================================
# VOLTRON TECH ULTIMATE v10.13 — COMPLETE SCRIPT
# ================================================================

# ========== COLOR CODES ==========
C_RESET=$'\033[0m'
C_BOLD=$'\033[1m'
C_DIM=$'\033[2m'
C_UL=$'\033[4m'
C_RED=$'\033[38;5;196m'
C_GREEN=$'\033[38;5;46m'
C_YELLOW=$'\033[38;5;226m'
C_BLUE=$'\033[38;5;39m'
C_PURPLE=$'\033[38;5;135m'
C_CYAN=$'\033[38;5;51m'
C_WHITE=$'\033[38;5;255m'
C_GRAY=$'\033[38;5;245m'
C_ORANGE=$'\033[38;5;208m'
C_GOLD=$'\033[38;5;220m'
C_TEAL=$'\033[38;5;38m'
C_PINK=$'\033[38;5;205m'
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

# ========== DESEC DNS ==========
DESEC_TOKEN="3WxD4Hkiu5VYBLWVizVhf1rzyKbz"
DESEC_DOMAIN="voltrontechtx.shop"

# ========== DIRECTORY STRUCTURE ==========
DB_DIR="/etc/voltrontech"
DB_FILE="$DB_DIR/users.db"
INSTALL_FLAG_FILE="$DB_DIR/.install"
LOGS_DIR="$DB_DIR/logs"
CONFIG_DIR="$DB_DIR/config"
BANDWIDTH_DIR="$DB_DIR/bandwidth"
BANNER_DIR="$DB_DIR/banners"
DNSTT_KEYS_DIR="$DB_DIR/dnstt"
SSL_CERT_DIR="$DB_DIR/ssl"
SSL_CERT_FILE="$SSL_CERT_DIR/voltrontech.pem"
TRAFFIC_DIR="$DB_DIR/traffic"
BACKUP_DIR="$DB_DIR/backups"
DNS_INFO_FILE="$DB_DIR/dns_info.conf"
MTU_CONFIG="$CONFIG_DIR/mtu"
BANNER_ENABLED_FILE="$DB_DIR/banners_enabled"
SSHD_FF_CONFIG="/etc/ssh/sshd_config.d/voltron-auto-banner.conf"
TRIAL_CLEANUP_SCRIPT="/usr/local/bin/voltrontech-trial-cleanup.sh"
FF_USERS_GROUP="ffusers"

# ========== SERVICE FILES ==========
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
ZIVPN_DIR="/etc/zivpn"
ZIVPN_BIN="/usr/local/bin/zivpn"
ZIVPN_SERVICE_FILE="/etc/systemd/system/zivpn.service"
ZIVPN_CONFIG_FILE="$ZIVPN_DIR/config.json"
LIMITER_SCRIPT="/usr/local/bin/voltrontech-limiter.sh"
LIMITER_SERVICE="/etc/systemd/system/voltrontech-limiter.service"
TRAFFIC_SCRIPT="/usr/local/bin/voltron-traffic.sh"
TRAFFIC_SERVICE="/etc/systemd/system/voltron-traffic.service"
CACHE_CRON_FILE="/etc/cron.d/voltron-cache-clean"
CACHE_SCRIPT="/usr/local/bin/voltron-cache-clean"

# ========== WEB PANEL VARIABLES ==========
API_DIR="/opt/voltrontech-api"
API_PORT="5000"
API_KEY_FILE="$DB_DIR/api_key.txt"
API_INFO_FILE="$DB_DIR/api_info.txt"
WEB_PANEL_API_DOMAIN="api.voltrontechtx.shop"
WEB_PANEL_NGINX_CONFIG="/etc/nginx/sites-available/voltrontech-api"
WEB_PANEL_NGINX_LINK="/etc/nginx/sites-enabled/voltrontech-api"
WEB_PANEL_SSL_EMAIL_FILE="$DB_DIR/ssl_email.txt"

SELECTED_USER=""
SELECTED_USERS=()

# ========== APT FUNCTIONS ==========
ff_apt_update() { DEBIAN_FRONTEND=noninteractive apt-get update 2>/dev/null || true; }
ff_apt_install() { ff_apt_update; DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 install "$@"; }
ff_apt_purge() { DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 purge "$@"; }

# ========== CACHE ==========
BANNER_CACHE_TTL=15
BANNER_CACHE_TS=0
BANNER_CACHE_OS_NAME=""
BANNER_CACHE_UP_TIME=""
BANNER_CACHE_RAM_USAGE=""
BANNER_CACHE_CPU_LOAD=""
BANNER_CACHE_ONLINE_USERS=0
BANNER_CACHE_TOTAL_USERS=0

refresh_banner_cache() {
    local now=$(date +%s)
    if (( BANNER_CACHE_TS > 0 && now - BANNER_CACHE_TS < BANNER_CACHE_TTL )); then return; fi
    BANNER_CACHE_OS_NAME=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Linux")
    BANNER_CACHE_UP_TIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    BANNER_CACHE_RAM_USAGE=$(free -m | awk '/^Mem:/{if($2>0){printf "%.2f", $3*100/$2}else{print "0.00"}}')
    BANNER_CACHE_CPU_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    if [[ -s "$DB_FILE" ]]; then BANNER_CACHE_TOTAL_USERS=$(grep -c . "$DB_FILE"); else BANNER_CACHE_TOTAL_USERS=0; fi
    BANNER_CACHE_ONLINE_USERS=$(pgrep -c -u root sshd 2>/dev/null || echo 0)
    BANNER_CACHE_TS=$now
}

show_banner() {
    refresh_banner_cache
    [[ -t 1 ]] && clear
    echo
    echo -e "${C_TITLE}   VOLTRON TECH ULTIMATE v10.13 ${C_RESET}${C_DIM}| Premium Edition${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "OS" "$BANNER_CACHE_OS_NAME" "Uptime: $BANNER_CACHE_UP_TIME"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Memory" "${BANNER_CACHE_RAM_USAGE}% Used" "Online: ${C_WHITE}${BANNER_CACHE_ONLINE_USERS}${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Users" "${BANNER_CACHE_TOTAL_USERS} Managed" "Load: ${C_GREEN}${BANNER_CACHE_CPU_LOAD}${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
}

press_enter() { echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to continue..." && read -r; }
invalidate_banner_cache() { BANNER_CACHE_TS=0; }
get_current_mtu() { [ -f "$MTU_CONFIG" ] && cat "$MTU_CONFIG" || echo "512"; }

# ========== USER STATUS ==========
get_user_status() {
    local username="$1"
    if ! id "$username" &>/dev/null; then echo -e "${C_RED}Not Found${C_RESET}"; return; fi
    local passwd_flag=$(passwd -S "$username" 2>/dev/null | awk '{print $2}')
    if [[ "$passwd_flag" == "L" ]]; then echo -e "${C_YELLOW}🔒 Locked${C_RESET}"; return; fi
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    if [[ $expiry_ts -lt $current_ts && $expiry_ts -ne 0 ]]; then echo -e "${C_RED}🗓️ Expired${C_RESET}"; return; fi
    local bandwidth_gb=$(grep "^$username:" "$DB_FILE" | cut -d: -f5)
    if [[ -n "$bandwidth_gb" && "$bandwidth_gb" != "0" ]]; then
        local used_bytes=0
        if [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then used_bytes=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null); [[ -z "$used_bytes" ]] && used_bytes=0; fi
        local quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        if [[ "$used_bytes" -ge "$quota_bytes" ]]; then echo -e "${C_RED}📦 Exceeded${C_RESET}"; return; fi
    fi
    echo -e "${C_GREEN}🟢 Active${C_RESET}"
}

# ========== ORPHAN USER ==========
delete_voltrontech_user_accounts() {
    local -a users_to_delete=("$@")
    local username
    [[ ${#users_to_delete[@]} -gt 0 ]] || return 0
    for username in "${users_to_delete[@]}"; do
        [[ -n "$username" ]] || continue
        killall -u "$username" -9 &>/dev/null
        if id "$username" &>/dev/null; then
            if userdel -r "$username" &>/dev/null; then echo -e " ✅ '${C_YELLOW}$username${C_RESET}' deleted."
            else echo -e " ❌ Failed '${C_YELLOW}$username${C_RESET}'."; fi
        else echo -e " ℹ️ '${C_YELLOW}$username${C_RESET}' missing."; fi
        rm -f "$BANDWIDTH_DIR/${username}.usage"
        rm -rf "$BANDWIDTH_DIR/pidtrack/${username}"
    done
    if [[ -f "$DB_FILE" ]]; then
        local db_tmp=$(mktemp)
        awk -F: 'NR==FNR { drop[$1]=1; next } !($1 in drop)' <(printf "%s\n" "${users_to_delete[@]}") "$DB_FILE" > "$db_tmp" && mv "$db_tmp" "$DB_FILE"
        rm -f "$db_tmp" 2>/dev/null
    fi
    invalidate_banner_cache
    update_ssh_banners_config
}

# ========== USER SELECTION ==========
_select_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    if [[ ! -s $DB_FILE ]]; then echo -e "${C_YELLOW}ℹ️ No users.${C_RESET}"; SELECTED_USER="NO_USERS"; return; fi
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Search: " search_term
        if [[ -n "$search_term" ]]; then mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term"); else users=("${all_users[@]}"); fi
    else users=("${all_users[@]}"); fi
    if [ ${#users[@]} -eq 0 ]; then echo -e "\n${C_YELLOW}ℹ️ None.${C_RESET}"; SELECTED_USER="NO_USERS"; return; fi
    echo -e "\nSelect user:\n"
    for i in "${!users[@]}"; do printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"; done
    echo -e "\n  ${C_RED} [ 0]${C_RESET} Cancel"
    local choice
    while true; do
        read -p "👉 Number: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 0 ] && [ "$choice" -le "${#users[@]}" ]; then
            if [ "$choice" -eq 0 ]; then SELECTED_USER=""; return; else SELECTED_USER="${users[$((choice-1))]}"; return; fi
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
        read -p "👉 Search: " search_term
        if [[ -n "$search_term" ]]; then mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term"); else users=("${all_users[@]}"); fi
    else users=("${all_users[@]}"); fi
    if [ ${#users[@]} -eq 0 ]; then echo -e "\n${C_YELLOW}ℹ️ None.${C_RESET}"; SELECTED_USERS=("NO_USERS"); return; fi
    echo -e "\nSelect users:\n"
    for i in "${!users[@]}"; do printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"; done
    echo -e "\n  ${C_GREEN}[all]${C_RESET} Select ALL"
    echo -e "  ${C_RED} [ 0]${C_RESET} Cancel"
    local choice
    while true; do
        read -p "👉 Numbers: " choice
        choice=$(echo "$choice" | tr ',' ' ')
        if [[ -z "$choice" ]]; then echo -e "${C_RED}❌ Invalid.${C_RESET}"; continue; fi
        if [[ "$choice" == "0" ]]; then SELECTED_USERS=(); return; fi
        if [[ "${choice,,}" == "all" ]]; then SELECTED_USERS=("${users[@]}"); return; fi
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
        else echo -e "${C_RED}❌ Invalid.${C_RESET}"; fi
    done
}

# ========== GENERATE BANNER ==========
generate_user_banner() {
    local username="$1"
    local expiry="$2"
    local limit="$3"
    local bandwidth_gb="$4"
    local bw_display="Unlimited"
    if [[ "$bandwidth_gb" != "0" ]]; then bw_display="${bandwidth_gb} GB"; fi
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

# ========== USER MANAGEMENT ==========
create_user() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Create New SSH User ---${C_RESET}"
    read -p "👉 Username (or '0' cancel): " username
    [[ "$username" == "0" ]] && { echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; press_enter; return; }
    [[ -z "$username" ]] && { echo -e "\n${C_RED}❌ Empty.${C_RESET}"; press_enter; return; }
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
    local bw_display="Unlimited"; [[ "$bandwidth_gb" != "0" ]] && bw_display="${bandwidth_gb} GB"
    if [[ -f "$BANNER_ENABLED_FILE" ]]; then
        generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
        update_ssh_banners_config
    fi
    clear; show_banner
    echo -e "${C_GREEN}✅ User '$username' created!${C_RESET}\n"
    echo -e "  👤 Username: ${C_YELLOW}$username${C_RESET}"
    echo -e "  🔑 Password: ${C_YELLOW}$password${C_RESET}"
    echo -e "  🗓️ Expires:  ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  📶 Limit:    ${C_YELLOW}$limit${C_RESET}"
    echo -e "  📦 BW:       ${C_YELLOW}$bw_display${C_RESET}"
    press_enter
}

delete_user() {
    _select_multi_user_interface "--- 🗑️ Delete Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    echo -e "\n${C_RED}⚠️ Delete ${#SELECTED_USERS[@]} user(s)?${C_RESET}"
    read -p "👉 Confirm (y/n): " confirm
    [[ "$confirm" != "y" ]] && { echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; press_enter; return; }
    delete_voltrontech_user_accounts "${SELECTED_USERS[@]}"
    press_enter
}

edit_user() {
    _select_user_interface "--- ✏️ Edit User ---"
    local username=$SELECTED_USER
    [[ "$username" == "NO_USERS" || -z "$username" ]] && { press_enter; return; }
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- Editing: ${C_YELLOW}$username${C_RESET}"
        local line=$(grep "^$username:" "$DB_FILE")
        local cur_pass=$(echo "$line" | cut -d: -f2)
        local cur_expiry=$(echo "$line" | cut -d: -f3)
        local cur_limit=$(echo "$line" | cut -d: -f4)
        local cur_bw=$(echo "$line" | cut -d: -f5)
        [[ -z "$cur_bw" ]] && cur_bw="0"
        local cur_bw_display="Unlimited"; [[ "$cur_bw" != "0" ]] && cur_bw_display="${cur_bw} GB"
        echo -e "\n  Current: Pass=${C_YELLOW}$cur_pass${C_RESET} Exp=${C_YELLOW}$cur_expiry${C_RESET} Conn=${C_YELLOW}$cur_limit${C_RESET} BW=${C_YELLOW}$cur_bw_display${C_RESET}"
        echo -e "\n  1) 🔑 Change Password"
        echo -e "  2) 🗓️ Change Expiration"
        echo -e "  3) 📶 Change Limit"
        echo -e "  4) 📦 Change Bandwidth"
        echo -e "  5) 🔄 Reset Bandwidth"
        echo -e "  0) ✅ Finish"
        echo
        read -p "👉 Choice: " edit_choice
        case $edit_choice in
            1) read -p "New password: " new_pass; [[ -z "$new_pass" ]] && new_pass=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8); echo "$username:$new_pass" | chpasswd; sed -i "s/^$username:.*/$username:$new_pass:$cur_expiry:$cur_limit:$cur_bw:0:ACTIVE/" "$DB_FILE"; echo -e "${C_GREEN}✅ Pass: $new_pass${C_RESET}"; press_enter ;;
            2) read -p "New days: " days; if [[ "$days" =~ ^[0-9]+$ ]]; then new_exp=$(date -d "+$days days" +%Y-%m-%d); chage -E "$new_exp" "$username"; sed -i "s/^$username:.*/$username:$cur_pass:$new_exp:$cur_limit:$cur_bw:0:ACTIVE/" "$DB_FILE"; echo -e "${C_GREEN}✅ $new_exp${C_RESET}"; fi; press_enter ;;
            3) read -p "New limit: " nl; [[ "$nl" =~ ^[0-9]+$ ]] && { sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$nl:$cur_bw:0:ACTIVE/" "$DB_FILE"; echo -e "${C_GREEN}✅ $nl${C_RESET}"; }; press_enter ;;
            4) read -p "New BW: " nb; [[ "$nb" =~ ^[0-9]+\.?[0-9]*$ ]] && { sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$nb:0:ACTIVE/" "$DB_FILE"; echo -e "${C_GREEN}✅ $nb${C_RESET}"; }; press_enter ;;
            5) echo "0" > "$BANDWIDTH_DIR/${username}.usage"; usermod -U "$username" &>/dev/null; echo -e "${C_GREEN}✅ Reset${C_RESET}"; press_enter ;;
            0) return ;;
        esac
    done
}

lock_user() {
    _select_multi_user_interface "--- 🔒 Lock Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then echo -e " ❌ $u missing"; continue; fi
        usermod -L "$u" && killall -u "$u" -9 &>/dev/null && echo -e " ✅ ${C_YELLOW}$u${C_RESET} locked"
    done
    press_enter
}

unlock_user() {
    _select_multi_user_interface "--- 🔓 Unlock Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then echo -e " ❌ $u missing"; continue; fi
        usermod -U "$u" && echo -e " ✅ ${C_YELLOW}$u${C_RESET} unlocked"
    done
    press_enter
}

list_users() {
    clear; show_banner
    [[ ! -s "$DB_FILE" ]] && { echo -e "\n${C_YELLOW}ℹ️ No users.${C_RESET}"; press_enter; return; }
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}                      📋 MANAGED USERS${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" ]] && continue
        bandwidth_gb=${bandwidth_gb:-0}
        local online_count=$(pgrep -c -u "$user" sshd 2>/dev/null || echo 0)
        local bw_string="Unlimited"
        if [[ "$bandwidth_gb" != "0" ]]; then
            local used_bytes=0
            [[ -f "$BANDWIDTH_DIR/${user}.usage" ]] && used_bytes=$(cat "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null)
            [[ -z "$used_bytes" ]] && used_bytes=0
            local used_gb=$(awk "BEGIN {printf \"%.2f\", $used_bytes / 1073741824}")
            local remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}")
            bw_string="${used_gb}/${bandwidth_gb} GB | ${remain_gb} GB left"
        fi
        local status_text=$(get_user_status "$user")
        local plain_status=$(echo -e "$status_text" | sed 's/\x1b\[[0-9;]*m//g')
        echo -e "${C_CYAN}┌─────────────────────────────────────────────────────────────┐${C_RESET}"
        printf "${C_CYAN}│${C_RESET} ${C_YELLOW}USER${C_RESET}: ${C_WHITE}%-53s${C_CYAN}│${C_RESET}\n" "$user"
        printf "${C_CYAN}│${C_RESET} ${C_YELLOW}EXPIRY${C_RESET}: ${C_WHITE}%-51s${C_CYAN}│${C_RESET}\n" "$expiry"
        printf "${C_CYAN}│${C_RESET} ${C_YELLOW}BW${C_RESET}: ${C_WHITE}%-55s${C_CYAN}│${C_RESET}\n" "$bw_string"
        printf "${C_CYAN}│${C_RESET} ${C_YELLOW}ONLINE${C_RESET}: ${C_WHITE}%-51s${C_CYAN}│${C_RESET}\n" "${online_count}/${limit}"
        printf "${C_CYAN}│${C_RESET} ${C_YELLOW}STATUS${C_RESET}: %-51s${C_CYAN}│${C_RESET}\n" "$plain_status"
        echo -e "${C_CYAN}└─────────────────────────────────────────────────────────────┘${C_RESET}"
        echo ""
    done < <(sort "$DB_FILE")
    echo -e "${C_DIM}Total: ${C_WHITE}$(grep -c . "$DB_FILE")${C_RESET}"
    press_enter
}

renew_user() {
    _select_multi_user_interface "--- 🔄 Renew Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    read -p "👉 Days to extend: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${C_RED}❌ Invalid.${C_RESET}"; press_enter; return; }
    local new_expire_date=$(date -d "+$days days" +%Y-%m-%d)
    for u in "${SELECTED_USERS[@]}"; do
        chage -E "$new_expire_date" "$u"
        local line=$(grep "^$u:" "$DB_FILE")
        local pass=$(echo "$line"|cut -d: -f2); local limit=$(echo "$line"|cut -d: -f4); local bw=$(echo "$line"|cut -d: -f5)
        [[ -z "$bw" ]] && bw="0"
        sed -i "s/^$u:.*/$u:$pass:$new_expire_date:$limit:$bw:0:ACTIVE/" "$DB_FILE"
        usermod -U "$u" &>/dev/null
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} → ${C_GREEN}$new_expire_date${C_RESET}"
    done
    press_enter
}

cleanup_expired() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🧹 Cleanup Expired ---${C_RESET}"
    local expired_users=(); local current_ts=$(date +%s)
    [[ ! -s "$DB_FILE" ]] && { echo -e "\n${C_GREEN}✅ Empty DB.${C_RESET}"; press_enter; return; }
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        local expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        [[ $expiry_ts -lt $current_ts && $expiry_ts -ne 0 ]] && expired_users+=("$user")
    done < "$DB_FILE"
    [[ ${#expired_users[@]} -eq 0 ]] && { echo -e "\n${C_GREEN}✅ No expired.${C_RESET}"; press_enter; return; }
    echo -e "\nExpired: ${C_RED}${expired_users[*]}${C_RESET}"
    read -p "👉 Delete all? (y/n): " confirm
    if [[ "$confirm" == "y" ]]; then
        delete_voltrontech_user_accounts "${expired_users[@]}"
        echo -e "\n${C_GREEN}✅ Cleaned.${C_RESET}"
    else echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; fi
    press_enter
}

bulk_create_users() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👥 Bulk Create Users ---${C_RESET}"
    read -p "👉 Prefix: " prefix
    [[ -z "$prefix" ]] && { echo -e "${C_RED}❌ Empty.${C_RESET}"; press_enter; return; }
    read -p "🔢 Count: " count
    [[ ! "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]] || [[ "$count" -gt 100 ]] && { echo -e "${C_RED}❌ 1-100.${C_RESET}"; press_enter; return; }
    read -p "🗓️ Days [30]: " days; days=${days:-30}
    read -p "📶 Limit [999]: " limit; limit=${limit:-999}
    read -p "📦 BW GB [0]: " bandwidth_gb; bandwidth_gb=${bandwidth_gb:-0}
    local expire_date=$(date -d "+$days days" +%Y-%m-%d)
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    echo ""
    printf "  ${C_BOLD}%-20s | %-15s | %-12s${C_RESET}\n" "USERNAME" "PASSWORD" "EXPIRES"
    echo -e "${C_YELLOW}────────────────────────────────────────────────────────────${C_RESET}"
    local created=0
    for ((i=1; i<=count; i++)); do
        local username="${prefix}${i}"
        if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then echo -e "  ${C_RED}⚠️ Skip $username${C_RESET}"; continue; fi
        local password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
        useradd -m -s /usr/sbin/nologin "$username"
        usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
        echo "$username:$password" | chpasswd
        chage -E "$expire_date" "$username"
        echo "$username:$password:$expire_date:$limit:$bandwidth_gb:0:ACTIVE" >> "$DB_FILE"
        [[ -f "$BANNER_ENABLED_FILE" ]] && generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$username" "$password" "$expire_date"
        ((created++))
    done
    [[ -f "$BANNER_ENABLED_FILE" ]] && update_ssh_banners_config
    echo -e "\n${C_GREEN}✅ Created $created users.${C_RESET}"
    invalidate_banner_cache
    press_enter
}

view_user_bandwidth() {
    _select_user_interface "--- 📊 View Bandwidth ---"
    local u=$SELECTED_USER
    [[ "$u" == "NO_USERS" || -z "$u" ]] && { press_enter; return; }
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📊 Bandwidth: $u ---${C_RESET}\n"
    local line=$(grep "^$u:" "$DB_FILE")
    local bandwidth_gb=$(echo "$line" | cut -d: -f5)
    [[ -z "$bandwidth_gb" ]] && bandwidth_gb="0"
    local used_bytes=0
    [[ -f "$BANDWIDTH_DIR/${u}.usage" ]] && used_bytes=$(cat "$BANDWIDTH_DIR/${u}.usage" 2>/dev/null)
    [[ -z "$used_bytes" ]] && used_bytes=0
    local used_gb=$(awk "BEGIN {printf \"%.3f\", $used_bytes / 1073741824}")
    echo -e "  ${C_CYAN}Used:${C_RESET} ${C_WHITE}${used_gb} GB${C_RESET}"
    if [[ "$bandwidth_gb" == "0" ]]; then
        echo -e "  ${C_CYAN}Limit:${C_RESET} ${C_GREEN}Unlimited${C_RESET}"
    else
        local quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        local percentage=$(awk "BEGIN {printf \"%.1f\", ($used_bytes / $quota_bytes) * 100}")
        local remaining_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.3f\", r}")
        echo -e "  ${C_CYAN}Limit:${C_RESET} ${C_YELLOW}${bandwidth_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Remaining:${C_RESET} ${C_WHITE}${remaining_gb} GB${C_RESET}"
        echo -e "  ${C_CYAN}Usage:${C_RESET} ${C_WHITE}${percentage}%${C_RESET}"
    fi
    press_enter
}

# ========== TRIAL ==========
setup_trial_cleanup_script() {
    cat > "$TRIAL_CLEANUP_SCRIPT" << 'TREOF'
#!/bin/bash
username="$1"
[[ -z "$username" ]] && exit 1
killall -u "$username" -9 &>/dev/null
userdel -r "$username" &>/dev/null
sed -i "/^${username}:/d" /etc/voltrontech/users.db
rm -f /etc/voltrontech/bandwidth/${username}.usage
rm -rf /etc/voltrontech/bandwidth/pidtrack/${username}
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
    echo "$TRIAL_CLEANUP_SCRIPT $username" | at now + ${duration_hours} hours 2>/dev/null
    [[ -f "$BANNER_ENABLED_FILE" ]] && { generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"; update_ssh_banners_config; }
    clear; show_banner
    echo -e "${C_GREEN}✅ Trial created!${C_RESET}\n"
    echo -e "  👤 ${C_YELLOW}$username${C_RESET}"
    echo -e "  🔑 ${C_YELLOW}$password${C_RESET}"
    echo -e "  ⏱️ ${C_CYAN}$duration_label${C_RESET}"
    echo -e "  🕐 ${C_RED}$expiry_timestamp${C_RESET}"
    press_enter
}

# ========== DNSTT ==========
download_dnstt_binary() {
    local arch=$(uname -m)
    local url=""
    if [[ "$arch" == "x86_64" ]]; then url="https://dnstt.network/dnstt-server-linux-amd64"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then url="https://dnstt.network/dnstt-server-linux-arm64"
    else echo -e "${C_RED}❌ Unsupported: $arch${C_RESET}"; return 1; fi
    curl -sL "$url" -o "$DNSTT_BINARY"; chmod +x "$DNSTT_BINARY"
    if [[ "$arch" == "x86_64" ]]; then curl -sL "https://dnstt.network/dnstt-client-linux-amd64" -o "$DNSTT_CLIENT"
    else curl -sL "https://dnstt.network/dnstt-client-linux-arm64" -o "$DNSTT_CLIENT"; fi
    chmod +x "$DNSTT_CLIENT"
    echo -e "${C_GREEN}✅ Binaries downloaded${C_RESET}"
}

apply_booster_standard_ultimate() {
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=512 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=512 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=1000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=524288 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    ulimit -n 10485760 2>/dev/null
    echo -e "${C_GREEN}✅ 1000x applied${C_RESET}"
}

apply_booster_medium_ultimate() {
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null; modprobe sch_fq 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=5120 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=5120 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=2147483648 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=2147483648 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=2000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=1048576 >/dev/null 2>&1
    ulimit -n 20971520 2>/dev/null
    echo -e "${C_GREEN}✅ 2000x applied${C_RESET}"
}

apply_booster_high_ultimate() {
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null; modprobe sch_fq 2>/dev/null; modprobe sch_htb 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=51200 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=51200 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=4294967296 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=4294967296 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=4000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=2097152 >/dev/null 2>&1
    sysctl -w net.core.dev_weight=1024 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=160000000 >/dev/null 2>&1
    ulimit -n 41943040 2>/dev/null
    echo -e "${C_GREEN}✅ 3000x applied${C_RESET}"
}

apply_booster_ultra_ultimate() {
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null; modprobe sch_fq 2>/dev/null; modprobe sch_htb 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=512000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=512000 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=8589934592 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=8589934592 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=6000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=4194304 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=320000000 >/dev/null 2>&1
    ulimit -n 83886080 2>/dev/null
    for i in /sys/class/net/*/queues/*/rps_cpus; do [[ -f "$i" ]] && echo ffffffff > "$i" 2>/dev/null; done
    sysctl -w net.core.busy_read=1000 >/dev/null 2>&1
    sysctl -w net.core.busy_poll=1000 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ 5000x applied${C_RESET}"
}

apply_booster_extreme_ultimate() {
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null; modprobe sch_fq 2>/dev/null; modprobe sch_htb 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=5120000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=5120000 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=17179869184 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=17179869184 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=10000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=8388608 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=640000000 >/dev/null 2>&1
    ulimit -n 167772160 2>/dev/null
    for i in /sys/class/net/*/queues/*/rps_cpus; do [[ -f "$i" ]] && echo ffffffff > "$i" 2>/dev/null; done
    for i in /sys/class/net/*/queues/*/rps_flow_cnt; do [[ -f "$i" ]] && echo 4096 > "$i" 2>/dev/null; done
    sysctl -w net.core.busy_read=1000 >/dev/null 2>&1
    sysctl -w net.core.busy_poll=1000 >/dev/null 2>&1
    command -v irqbalance &>/dev/null && systemctl restart irqbalance 2>/dev/null
    echo -e "${C_GREEN}✅ 10000x applied${C_RESET}"
}

apply_booster_ultra_plus() {
    modprobe tcp_bbr 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=805306368 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=805306368 >/dev/null 2>&1
    ulimit -n 6291456 2>/dev/null
    echo -e "${C_GREEN}✅ Ultra Plus applied${C_RESET}"
}

apply_booster_extreme_plus() {
    modprobe tcp_bbr 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    ulimit -n 12582912 2>/dev/null
    echo -e "${C_GREEN}✅ Extreme Plus applied${C_RESET}"
}

generate_keys() {
    mkdir -p "$DNSTT_KEYS_DIR"; cd "$DNSTT_KEYS_DIR"; rm -f server.key server.pub
    if ! "$DNSTT_BINARY" -gen-key -privkey-file server.key -pubkey-file server.pub 2>/dev/null; then
        openssl rand -hex 32 > server.key
        cat server.key | sha256sum | awk '{print $1}' > server.pub
    fi
    chmod 600 server.key; chmod 644 server.pub
    PUBLIC_KEY=$(cat server.pub)
}

setup_domain() {
    echo -e "\n${C_BLUE}🌐 Domain config...${C_RESET}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} Custom domain"
    echo -e "  ${C_GREEN}2)${C_RESET} Auto-generate with deSEC"
    read -p "👉 Choice [1-2, default=2]: " domain_option
    domain_option=${domain_option:-2}
    if [[ "$domain_option" == "2" ]]; then
        local rand=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 3)
        local ns_sub="ns-$rand"; local tun_sub="tun-$rand"
        local ip=$(curl -s -4 icanhazip.com)
        echo -e "${C_CYAN}IP: $ip${C_RESET}"
        local ns_data="[{\"subname\":\"$ns_sub\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$ip\"]}]"
        curl -s -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$ns_data" >/dev/null 2>&1
        local ns_rec="[{\"subname\":\"$tun_sub\",\"type\":\"NS\",\"ttl\":3600,\"records\":[\"$ns_sub.$DESEC_DOMAIN.\"]}]"
        local resp=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$ns_rec")
        local http=${resp: -3}
        if [[ "$http" -eq 201 ]]; then DOMAIN="$tun_sub.$DESEC_DOMAIN"; echo -e "${C_GREEN}✅ Domain: $DOMAIN${C_RESET}"
        else read -p "👉 Enter domain manually: " DOMAIN; fi
    else read -p "👉 Enter domain: " DOMAIN; fi
    echo "$DOMAIN" > "$DB_DIR/domain.txt"
}

create_dnstt_service() {
    local domain=$1; local mtu=$2; local ssh_port=$3
    [[ -z "$mtu" ]] && mtu=512
    mkdir -p "$LOGS_DIR"
    touch "$LOGS_DIR/dnstt-server.log" 2>/dev/null
    cat > "$DNSTT_SERVICE_FILE" <<EOF
[Unit]
Description=DNSTT Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$DB_DIR
ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_KEYS_DIR/server.key -mtu $mtu $domain 127.0.0.1:$ssh_port
Restart=always
RestartSec=5
LimitNOFILE=2097152

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable dnstt.service > /dev/null 2>&1
}

save_dnstt_info() {
    cat > "$DNSTT_CONFIG_FILE" <<EOF
TUNNEL_DOMAIN="$1"
PUBLIC_KEY="$2"
MTU_VALUE="$3"
SSH_PORT="$4"
EOF
}

show_client_commands() {
    local domain=$1; local mtu=$2; local ssh_port=$3
    local pubkey=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null)
    [[ -z "$mtu" ]] && mtu=512
    echo -e "\n${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}           📱 CLIENT CONNECTION${C_RESET}"
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  - ${C_CYAN}Tunnel Domain:${C_RESET} ${C_YELLOW}$domain${C_RESET}"
    echo -e "  - ${C_CYAN}Public Key:${C_RESET} ${C_YELLOW}$pubkey${C_RESET}"
    echo -e "  - ${C_CYAN}SSH Port:${C_RESET} ${C_YELLOW}$ssh_port${C_RESET}"
    echo -e "  - ${C_CYAN}MTU:${C_RESET} ${C_YELLOW}$mtu${C_RESET}"
}

install_dnstt() {
    clear; show_banner
    [ -f "$DNSTT_SERVICE_FILE" ] && { read -p "Reinstall? (y/n): " r; [[ "$r" != "y" ]] && return; systemctl stop dnstt.service 2>/dev/null; }
    ff_apt_install wget curl openssl bc dnsutils
    download_dnstt_binary
    read -p "👉 MTU [512]: " MTU; MTU=${MTU:-512}
    echo "$MTU" > "$MTU_CONFIG"
    setup_domain
    generate_keys
    read -p "👉 Speed [1-5, default 3]: " b; b=${b:-3}
    case $b in 1) apply_booster_standard_ultimate ;; 2) apply_booster_medium_ultimate ;; 3) apply_booster_high_ultimate ;; 4) apply_booster_ultra_ultimate ;; 5) apply_booster_extreme_ultimate ;; esac
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); SSH_PORT=${SSH_PORT:-22}
    create_dnstt_service "$DOMAIN" "$MTU" "$SSH_PORT"
    save_dnstt_info "$DOMAIN" "$PUBLIC_KEY" "$MTU" "$SSH_PORT"
    configure_dnstt_firewall
    apply_buffer_optimization; apply_bbr; apply_network_tuning; apply_dns_caching
    systemctl start dnstt.service; sleep 2
    systemctl is-active --quiet dnstt.service && echo -e "\n${C_GREEN}✅ Running${C_RESET}" || journalctl -u dnstt.service -n 20 --no-pager
    show_client_commands "$DOMAIN" "$MTU" "$SSH_PORT"
    press_enter
}

uninstall_dnstt() {
    systemctl stop dnstt.service 2>/dev/null; systemctl disable dnstt.service 2>/dev/null
    rm -f "$DNSTT_SERVICE_FILE" "$DNSTT_BINARY" "$DNSTT_CLIENT"
    rm -f "$DNSTT_KEYS_DIR/server.key" "$DNSTT_KEYS_DIR/server.pub"
    rm -f "$DB_DIR/domain.txt" "$DNSTT_CONFIG_FILE" "$MTU_CONFIG"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ DNSTT uninstalled${C_RESET}"; press_enter
}

dnstt_main_menu() {
    while true; do
        clear; show_banner
        [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ DNSTT not installed!${C_RESET}"; press_enter; return; }
        local st=""; systemctl is-active --quiet dnstt 2>/dev/null && st="${C_GREEN}● RUNNING${C_RESET}" || st="${C_RED}● STOPPED${C_RESET}"
        local cd=$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo "Not set")
        local cm=$(get_current_mtu)
        local cp=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null || echo "Not set")
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    📡 DNSTT MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_CYAN}Status:${C_RESET} $st"
        echo -e "  ${C_CYAN}Domain:${C_RESET} ${C_YELLOW}$cd${C_RESET}"
        echo -e "  ${C_CYAN}MTU:${C_RESET} ${C_YELLOW}$cm${C_RESET}"
        echo -e "  ${C_CYAN}Key:${C_RESET} ${C_GREEN}${cp:0:35}...${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Domain Management"
        echo -e "  ${C_GREEN}2)${C_RESET} Public Key Management"
        echo -e "  ${C_GREEN}3)${C_RESET} MTU Settings"
        echo -e "  ${C_GREEN}4)${C_RESET} Speed Boosters"
        echo -e "  ${C_GREEN}5)${C_RESET} View Details"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) dnstt_domain_menu ;;
            2) dnstt_key_menu ;;
            3) dnstt_mtu_menu ;;
            4) dnstt_speed_menu ;;
            5) show_dnstt_full_details ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

dnstt_domain_menu() {
    while true; do
        clear; show_banner
        local cd=$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo "Not set")
        echo -e "${C_BOLD}${C_PURPLE}═══ 🌐 DOMAIN MANAGEMENT ═══${C_RESET}\n"
        echo -e "  Current: ${C_YELLOW}$cd${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Set Custom Domain"
        echo -e "  ${C_GREEN}2)${C_RESET} Auto-Generate"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) set_custom_dnstt_domain ;;
            2) change_dnstt_domain ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

dnstt_key_menu() {
    while true; do
        clear; show_banner
        local cp=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null || echo "Not set")
        echo -e "${C_BOLD}${C_PURPLE}═══ 🔑 PUBLIC KEY MANAGEMENT ═══${C_RESET}\n"
        echo -e "  Current:\n  ${C_GREEN}$cp${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Set Custom Public Key"
        echo -e "  ${C_GREEN}2)${C_RESET} Regenerate Keys"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) set_custom_dnstt_public_key ;;
            2) regenerate_dnstt_keys ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

dnstt_mtu_menu() {
    while true; do
        clear; show_banner
        local cm=$(get_current_mtu)
        echo -e "${C_BOLD}${C_PURPLE}═══ 📡 MTU CONFIG ═══${C_RESET}\n"
        echo -e "  Current: ${C_YELLOW}$cm${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} 512  ${C_GREEN}4)${C_RESET} 1400"
        echo -e "  ${C_GREEN}2)${C_RESET} 900  ${C_GREEN}5)${C_RESET} 1500"
        echo -e "  ${C_GREEN}3)${C_RESET} 1200 ${C_GREEN}6)${C_RESET} Custom"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) set_dnstt_mtu "512"; press_enter ;;
            2) set_dnstt_mtu "900"; press_enter ;;
            3) set_dnstt_mtu "1200"; press_enter ;;
            4) set_dnstt_mtu "1400"; press_enter ;;
            5) set_dnstt_mtu "1500"; press_enter ;;
            6) read -p "MTU (512-1500): " cm2; set_dnstt_mtu "$cm2"; press_enter ;;
            0) return ;;
        esac
    done
}

set_dnstt_mtu() {
    local new_mtu="$1"
    [[ ! "$new_mtu" =~ ^[0-9]+$ ]] || [ "$new_mtu" -lt 512 ] || [ "$new_mtu" -gt 1500 ] && { echo -e "${C_RED}❌ 512-1500.${C_RESET}"; return 1; }
    echo "$new_mtu" > "$MTU_CONFIG"
    if [ -f "$DNSTT_SERVICE_FILE" ]; then
        sed -i "s/-mtu [0-9]*/-mtu $new_mtu/g" "$DNSTT_SERVICE_FILE"
        systemctl daemon-reload; systemctl restart dnstt.service 2>/dev/null
        echo -e "${C_GREEN}✅ MTU: $new_mtu${C_RESET}"
    fi
}

dnstt_speed_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══ ⚡ SPEED BOOSTERS ═══${C_RESET}\n"
        echo -e "  ${C_GREEN}[1]${C_RESET} Standard (1000x)"
        echo -e "  ${C_GREEN}[2]${C_RESET} Medium (2000x)"
        echo -e "  ${C_GREEN}[3]${C_RESET} High (3000x)"
        echo -e "  ${C_GREEN}[4]${C_RESET} Ultra (5000x)"
        echo -e "  ${C_GREEN}[5]${C_RESET} Extreme (10000x)"
        echo -e "  ${C_GREEN}[6]${C_RESET} Ultra Plus"
        echo -e "  ${C_GREEN}[7]${C_RESET} Extreme Plus"
        echo -e "\n  ${C_RED}[0]${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) apply_booster_standard_ultimate; press_enter ;;
            2) apply_booster_medium_ultimate; press_enter ;;
            3) apply_booster_high_ultimate; press_enter ;;
            4) apply_booster_ultra_ultimate; press_enter ;;
            5) apply_booster_extreme_ultimate; press_enter ;;
            6) apply_booster_ultra_plus; press_enter ;;
            7) apply_booster_extreme_plus; press_enter ;;
            0) return ;;
        esac
    done
}

set_custom_dnstt_domain() {
    clear; show_banner
    [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ DNSTT not installed.${C_RESET}"; press_enter; return; }
    local cd=$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo "Not set")
    echo -e "\n${C_CYAN}Current: ${C_YELLOW}$cd${C_RESET}\n"
    read -p "👉 New domain: " new_domain
    [[ -z "$new_domain" ]] && return
    [[ ! "$new_domain" =~ ^[a-zA-Z0-9.-]+$ ]] && { echo -e "${C_RED}❌ Invalid.${C_RESET}"; press_enter; return; }
    read -p "👉 Confirm? (y/n): " confirm
    [[ "$confirm" != "y" ]] && return
    echo "$new_domain" > "$DB_DIR/domain.txt"
    local mtu=$(get_current_mtu)
    local ssh_port=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    ssh_port=${ssh_port:-22}
    systemctl stop dnstt.service 2>/dev/null
    sed -i "s|ExecStart=.*|ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_KEYS_DIR/server.key -mtu $mtu $new_domain 127.0.0.1:$ssh_port|" "$DNSTT_SERVICE_FILE"
    [ -f "$DNSTT_CONFIG_FILE" ] && sed -i "s|TUNNEL_DOMAIN=.*|TUNNEL_DOMAIN=\"$new_domain\"|" "$DNSTT_CONFIG_FILE"
    systemctl daemon-reload; systemctl restart dnstt.service
    sleep 2
    systemctl is-active --quiet dnstt.service && echo -e "\n${C_GREEN}✅ $new_domain${C_RESET}" || echo -e "\n${C_RED}❌ Failed${C_RESET}"
    press_enter
}

change_dnstt_domain() {
    clear; show_banner
    [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ DNSTT not installed.${C_RESET}"; press_enter; return; }
    [ -f "$DB_DIR/domain.txt" ] && { local old=$(cat "$DB_DIR/domain.txt"); local olds=$(echo "$old" | cut -d. -f1); curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$olds/NS/" -H "Authorization: Token $DESEC_TOKEN" >/dev/null 2>&1; }
    local rand=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 3)
    local ns_sub="ns-$rand"; local tun_sub="tun-$rand"
    local ip=$(curl -s -4 icanhazip.com)
    local ns_data="[{\"subname\":\"$ns_sub\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$ip\"]}]"
    curl -s -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$ns_data" >/dev/null 2>&1
    local ns_rec="[{\"subname\":\"$tun_sub\",\"type\":\"NS\",\"ttl\":3600,\"records\":[\"$ns_sub.$DESEC_DOMAIN.\"]}]"
    local resp=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$ns_rec")
    local http=${resp: -3}
    if [[ "$http" -eq 201 ]]; then
        local new_domain="$tun_sub.$DESEC_DOMAIN"
        echo "$new_domain" > "$DB_DIR/domain.txt"
        local mtu=$(get_current_mtu)
        local ssh_port=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
        ssh_port=${ssh_port:-22}
        systemctl stop dnstt.service 2>/dev/null
        sed -i "s|ExecStart=.*|ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_KEYS_DIR/server.key -mtu $mtu $new_domain 127.0.0.1:$ssh_port|" "$DNSTT_SERVICE_FILE"
        [ -f "$DNSTT_CONFIG_FILE" ] && sed -i "s|TUNNEL_DOMAIN=.*|TUNNEL_DOMAIN=\"$new_domain\"|" "$DNSTT_CONFIG_FILE"
        systemctl daemon-reload; systemctl restart dnstt.service
        echo -e "\n${C_GREEN}✅ $new_domain${C_RESET}"
    else echo -e "\n${C_RED}❌ HTTP: $http${C_RESET}"; fi
    press_enter
}

set_custom_dnstt_public_key() {
    clear; show_banner
    [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ DNSTT not installed.${C_RESET}"; press_enter; return; }
    local cp=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null || echo "Not set")
    echo -e "\n${C_CYAN}Current:${C_RESET}\n${C_YELLOW}$cp${C_RESET}\n"
    read -p "👉 New public key: " custom_pubkey
    [[ -z "$custom_pubkey" ]] && return
    [[ ${#custom_pubkey} -lt 30 ]] && { echo -e "${C_RED}❌ Too short.${C_RESET}"; press_enter; return; }
    read -p "👉 Confirm? (y/n): " confirm
    [[ "$confirm" != "y" ]] && return
    [ -f "$DNSTT_KEYS_DIR/server.pub" ] && cp "$DNSTT_KEYS_DIR/server.pub" "$DNSTT_KEYS_DIR/server.pub.bak.$(date +%s)"
    echo "$custom_pubkey" > "$DNSTT_KEYS_DIR/server.pub"
    chmod 644 "$DNSTT_KEYS_DIR/server.pub"
    [ -f "$DNSTT_CONFIG_FILE" ] && sed -i "s|PUBLIC_KEY=.*|PUBLIC_KEY=\"$custom_pubkey\"|" "$DNSTT_CONFIG_FILE"
    systemctl restart dnstt.service 2>/dev/null
    sleep 2
    systemctl is-active --quiet dnstt.service && echo -e "\n${C_GREEN}✅ Key updated!${C_RESET}" || echo -e "\n${C_RED}❌ Failed${C_RESET}"
    press_enter
}

regenerate_dnstt_keys() {
    clear; show_banner
    [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ DNSTT not installed.${C_RESET}"; press_enter; return; }
    read -p "⚠️ Generate NEW keys? (y/n): " confirm
    [[ "$confirm" != "y" ]] && return
    systemctl stop dnstt.service 2>/dev/null
    [ -f "$DNSTT_KEYS_DIR/server.key" ] && { cp "$DNSTT_KEYS_DIR/server.key" "$DNSTT_KEYS_DIR/server.key.bak.$(date +%s)"; cp "$DNSTT_KEYS_DIR/server.pub" "$DNSTT_KEYS_DIR/server.pub.bak.$(date +%s)"; }
    cd "$DNSTT_KEYS_DIR"; rm -f server.key server.pub
    if ! "$DNSTT_BINARY" -gen-key -privkey-file server.key -pubkey-file server.pub 2>/dev/null; then
        openssl rand -hex 32 > server.key
        cat server.key | sha256sum | awk '{print $1}' > server.pub
    fi
    chmod 600 server.key; chmod 644 server.pub
    local new_pubkey=$(cat server.pub 2>/dev/null)
    [ -f "$DNSTT_CONFIG_FILE" ] && sed -i "s|PUBLIC_KEY=.*|PUBLIC_KEY=\"$new_pubkey\"|" "$DNSTT_CONFIG_FILE"
    systemctl restart dnstt.service
    sleep 2
    systemctl is-active --quiet dnstt.service && echo -e "\n${C_GREEN}✅ New keys!${C_RESET}\n${C_CYAN}$new_pubkey${C_RESET}" || echo -e "\n${C_RED}❌ Failed${C_RESET}"
    press_enter
}

show_dnstt_full_details() {
    clear; show_banner
    [ ! -f "$DB_DIR/domain.txt" ] && { echo -e "\n${C_YELLOW}Not installed${C_RESET}"; press_enter; return; }
    local domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
    local mtu=$(get_current_mtu)
    local pubkey=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null)
    local ssh_port=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    ssh_port=${ssh_port:-22}
    local status=""
    systemctl is-active --quiet dnstt.service 2>/dev/null && status="${C_GREEN}● RUNNING${C_RESET}" || status="${C_RED}● STOPPED${C_RESET}"
    echo -e "\n  ${C_YELLOW}Status:${C_RESET} $status"
    echo -e "  ${C_YELLOW}Domain:${C_RESET} ${C_WHITE}$domain${C_RESET}"
    echo -e "  ${C_YELLOW}MTU:${C_RESET} ${C_WHITE}$mtu${C_RESET}"
    echo -e "  ${C_YELLOW}SSH Port:${C_RESET} ${C_WHITE}$ssh_port${C_RESET}"
    echo -e "  ${C_YELLOW}Public Key:${C_RESET} ${C_GREEN}$pubkey${C_RESET}"
    press_enter
}

configure_dnstt_firewall() {
    echo -e "\n${C_BLUE}🔥 Firewall...${C_RESET}"
    ! command -v iptables &>/dev/null && ff_apt_install iptables iptables-persistent
    iptables -t nat -F 2>/dev/null || true
    iptables -F 2>/dev/null || true
    iptables -A INPUT -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
    iptables -A INPUT -p udp --dport 5300 -j ACCEPT
    iptables -A OUTPUT -p udp --sport 5300 -j ACCEPT
    iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    command -v netfilter-persistent &>/dev/null && netfilter-persistent save >/dev/null 2>&1
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    echo -e "${C_GREEN}✅ Firewall${C_RESET}"
}

apply_buffer_optimization() {
    cat >> /etc/sysctl.conf << 'EOF'
net.core.rmem_max=1073741824
net.core.wmem_max=1073741824
net.ipv4.udp_rmem_min=52428800
net.ipv4.udp_wmem_min=52428800
net.core.netdev_max_backlog=1000000
net.core.somaxconn=524288
EOF
    sysctl -p >/dev/null 2>&1
}

apply_bbr() {
    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
    cat >> /etc/sysctl.conf << 'EOF'
net.core.default_qdisc=fq
net.ipv4.tcp_congestion_control=bbr
EOF
    sysctl -p >/dev/null 2>&1
}

apply_network_tuning() {
    for i in /sys/class/net/*/queues/*/rps_cpus; do [[ -f "$i" ]] && echo ffffffff > "$i" 2>/dev/null; done
}

apply_dns_caching() {
    ! command -v dnsmasq &>/dev/null && apt-get install dnsmasq -y 2>/dev/null
    cat > /etc/dnsmasq.conf << 'EOF'
cache-size=10000
server=8.8.8.8
server=1.1.1.1
no-resolv
EOF
    systemctl restart dnsmasq 2>/dev/null
}

# ========== PROTOCOLS ==========
install_badvpn() {
    clear; show_banner
    ff_apt_install cmake make gcc git build-essential libssl-dev
    cd /tmp; rm -rf badvpn
    git clone https://github.com/ambrop72/badvpn.git 2>/dev/null
    cd badvpn; cmake . 2>/dev/null; make 2>/dev/null
    cp badvpn-udpgw "$BADVPN_BIN" 2>/dev/null
    cat > "$BADVPN_SERVICE_FILE" << EOF
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
    echo -e "${C_GREEN}✅ badvpn 7300${C_RESET}"; press_enter
}

uninstall_badvpn() {
    systemctl stop badvpn.service 2>/dev/null; systemctl disable badvpn.service 2>/dev/null
    rm -f "$BADVPN_SERVICE_FILE" "$BADVPN_BIN"
    systemctl daemon-reload; echo -e "${C_GREEN}✅ Removed${C_RESET}"; press_enter
}

install_udp_custom() {
    clear; show_banner
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then curl -sL -o "$UDP_CUSTOM_BIN" "https://github.com/voltrontech/udp-custom/releases/latest/download/udp-custom-linux-amd64"
    else curl -sL -o "$UDP_CUSTOM_BIN" "https://github.com/voltrontech/udp-custom/releases/latest/download/udp-custom-linux-arm64"; fi
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
    systemctl daemon-reload; systemctl enable udp-custom.service 2>/dev/null; systemctl start udp-custom.service
    echo -e "${C_GREEN}✅ udp-custom${C_RESET}"; press_enter
}

uninstall_udp_custom() {
    systemctl stop udp-custom.service 2>/dev/null; systemctl disable udp-custom.service 2>/dev/null
    rm -f "$UDP_CUSTOM_SERVICE_FILE" "$UDP_CUSTOM_BIN"
    systemctl daemon-reload; echo -e "${C_GREEN}✅ Removed${C_RESET}"; press_enter
}

install_ssl_tunnel() {
    clear; show_banner
    ff_apt_install haproxy openssl
    mkdir -p "$SSL_CERT_DIR"
    openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout "$SSL_CERT_DIR/voltrontech.key" -out "$SSL_CERT_DIR/voltrontech.crt" -subj "/CN=VOLTRON TECH" 2>/dev/null
    cat "$SSL_CERT_DIR/voltrontech.crt" "$SSL_CERT_DIR/voltrontech.key" > "$SSL_CERT_FILE" 2>/dev/null
    cat > "$HAPROXY_CONFIG" << EOF
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
    echo -e "${C_GREEN}✅ SSL 444${C_RESET}"; press_enter
}

uninstall_ssl_tunnel() {
    systemctl stop haproxy 2>/dev/null
    ff_apt_purge haproxy
    rm -f "$HAPROXY_CONFIG" "$SSL_CERT_FILE"
    echo -e "${C_GREEN}✅ Removed${C_RESET}"; press_enter
}

install_falcon_proxy() {
    clear; show_banner
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then curl -sL -o "$FALCONPROXY_BINARY" "https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/latest/download/falconproxy"
    else curl -sL -o "$FALCONPROXY_BINARY" "https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/latest/download/falconproxyarm"; fi
    chmod +x "$FALCONPROXY_BINARY"
    read -p "Port [8080]: " ports; ports=${ports:-8080}
    cat > "$FALCONPROXY_SERVICE_FILE" << EOF
[Unit]
Description=Falcon Proxy
After=network.target
[Service]
Type=simple
ExecStart=$FALCONPROXY_BINARY -p $ports
Restart=always
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload; systemctl enable falconproxy.service 2>/dev/null; systemctl start falconproxy.service
    echo -e "${C_GREEN}✅ Falcon $ports${C_RESET}"; press_enter
}

uninstall_falcon_proxy() {
    systemctl stop falconproxy.service 2>/dev/null; systemctl disable falconproxy.service 2>/dev/null
    rm -f "$FALCONPROXY_SERVICE_FILE" "$FALCONPROXY_BINARY"
    systemctl daemon-reload; echo -e "${C_GREEN}✅ Removed${C_RESET}"; press_enter
}

install_zivpn() {
    clear; show_banner
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then curl -sL -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    else curl -sL -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"; fi
    chmod +x "$ZIVPN_BIN"
    mkdir -p "$ZIVPN_DIR"
    openssl req -x509 -newkey rsa:4096 -nodes -days 365 -keyout "$ZIVPN_DIR/server.key" -out "$ZIVPN_DIR/server.crt" -subj "/CN=ZiVPN" 2>/dev/null
    read -p "Passwords [user1,user2]: " passwords; passwords=${passwords:-user1,user2}
    IFS=',' read -ra pass_array <<< "$passwords"
    json_passwords=$(printf '"%s",' "${pass_array[@]}")
    json_passwords="[${json_passwords%,}]"
    cat > "$ZIVPN_CONFIG_FILE" << EOF
{"listen": ":5667", "cert": "$ZIVPN_DIR/server.crt", "key": "$ZIVPN_DIR/server.key", "obfs": "zivpn", "auth": {"mode": "passwords", "config": $json_passwords}}
EOF
    cat > "$ZIVPN_SERVICE_FILE" << EOF
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
    echo -e "${C_GREEN}✅ ZiVPN 5667${C_RESET}"; press_enter
}

uninstall_zivpn() {
    systemctl stop zivpn.service 2>/dev/null; systemctl disable zivpn.service 2>/dev/null
    rm -f "$ZIVPN_SERVICE_FILE" "$ZIVPN_BIN"
    rm -rf "$ZIVPN_DIR"
    systemctl daemon-reload; echo -e "${C_GREEN}✅ Removed${C_RESET}"; press_enter
}

install_xui_panel() {
    clear; show_banner
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
    press_enter
}

uninstall_xui_panel() {
    command -v x-ui &>/dev/null && x-ui uninstall
    rm -f /usr/local/bin/x-ui
    rm -rf /etc/x-ui /usr/local/x-ui
    echo -e "${C_GREEN}✅ Removed${C_RESET}"; press_enter
}

protocol_menu() {
    while true; do
        clear; show_banner
        local bs=""; systemctl is-active --quiet badvpn 2>/dev/null && bs="${C_GREEN}● RUNNING${C_RESET}" || bs="${C_DIM}● STOPPED${C_RESET}"
        local us=""; systemctl is-active --quiet udp-custom 2>/dev/null && us="${C_GREEN}● RUNNING${C_RESET}" || us="${C_DIM}● STOPPED${C_RESET}"
        local hs=""; systemctl is-active --quiet haproxy 2>/dev/null && hs="${C_GREEN}● RUNNING${C_RESET}" || hs="${C_DIM}● STOPPED${C_RESET}"
        local ds=""; systemctl is-active --quiet dnstt 2>/dev/null && ds="${C_GREEN}● RUNNING${C_RESET}" || ds="${C_DIM}● STOPPED${C_RESET}"
        local fs=""; systemctl is-active --quiet falconproxy 2>/dev/null && fs="${C_GREEN}● RUNNING${C_RESET}" || fs="${C_DIM}● STOPPED${C_RESET}"
        local zs=""; systemctl is-active --quiet zivpn 2>/dev/null && zs="${C_GREEN}● RUNNING${C_RESET}" || zs="${C_DIM}● STOPPED${C_RESET}"
        local xs=""; command -v x-ui &>/dev/null && xs="${C_GREEN}● INSTALLED${C_RESET}" || xs="${C_DIM}● NOT INSTALLED${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══ 🔌 PROTOCOL MANAGEMENT ═══${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} badvpn $bs"
        echo -e "  ${C_GREEN}2)${C_RESET} udp-custom $us"
        echo -e "  ${C_GREEN}3)${C_RESET} SSL HAProxy $hs"
        echo -e "  ${C_GREEN}4)${C_RESET} DNSTT $ds"
        echo -e "  ${C_GREEN}5)${C_RESET} Falcon Proxy $fs"
        echo -e "  ${C_GREEN}6)${C_RESET} ZiVPN $zs"
        echo -e "  ${C_GREEN}7)${C_RESET} X-UI $xs"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Select: " choice
        case $choice in
            1) echo "1)Install 2)Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_badvpn || uninstall_badvpn ;;
            2) echo "1)Install 2)Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_udp_custom || uninstall_udp_custom ;;
            3) echo "1)Install 2)Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_ssl_tunnel || uninstall_ssl_tunnel ;;
            4) echo "1)Install 2)Manage 3)Uninstall"; read -p "👉 " sub; case $sub in 1) install_dnstt ;; 2) dnstt_main_menu ;; 3) uninstall_dnstt ;; esac ;;
            5) echo "1)Install 2)Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_falcon_proxy || uninstall_falcon_proxy ;;
            6) echo "1)Install 2)Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_zivpn || uninstall_zivpn ;;
            7) echo "1)Install 2)Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_xui_panel || uninstall_xui_panel ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

# ========== DYNAMIC BANNER (Match User per-user — FIXED) ==========
update_ssh_banners_config() {
    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        rm -f "$SSHD_FF_CONFIG" 2>/dev/null
        systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        return
    fi
    mkdir -p "$BANNER_DIR" /etc/ssh/sshd_config.d
    local tmp="/tmp/voltron-banners.conf"
    echo "# Voltron Tech - Dynamic Banners" > "$tmp"
    echo "# Generated: $(date)" >> "$tmp"
    echo "" >> "$tmp"
    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r user pass expiry limit bandwidth_gb _rest; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            [[ ! -f "$BANNER_DIR/${user}.txt" ]] && generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"
            [[ ! -f "$BANNER_DIR/${user}.txt" ]] && continue
            echo "Match User $user" >> "$tmp"
            echo "    Banner /etc/voltrontech/banners/${user}.txt" >> "$tmp"
            echo "" >> "$tmp"
        done < "$DB_FILE"
    fi
    chmod 644 "$tmp" 2>/dev/null
    if ! cmp -s "$tmp" "$SSHD_FF_CONFIG" 2>/dev/null; then
        mv "$tmp" "$SSHD_FF_CONFIG"
        chmod 644 "$SSHD_FF_CONFIG"
        grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null || \
            echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
        if sshd -t 2>/dev/null; then
            systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        else
            echo -e "${C_RED}⚠️ SSH config test failed, removing${C_RESET}"
            rm -f "$SSHD_FF_CONFIG"
            systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        fi
    else
        rm -f "$tmp"
    fi
}

enable_dynamic_banner() {
    mkdir -p "$BANNER_DIR"
    touch "$BANNER_ENABLED_FILE"
    local count=0
    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r user pass expiry limit bandwidth_gb _rest; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"
            chmod 644 "$BANNER_DIR/${user}.txt" 2>/dev/null
            ((count++))
        done < "$DB_FILE"
    fi
    update_ssh_banners_config
    if sshd -t 2>/dev/null; then
        systemctl restart voltrontech-limiter 2>/dev/null
        echo -e "\n${C_GREEN}✅ Dynamic Banner ENABLED ($count users)${C_RESET}"
        echo -e "${C_CYAN}📌 Banner itaonekana kwenye terminal (PuTTY, Termux, JuiceSSH)${C_RESET}"
        echo -e "${C_CYAN}📌 VPN client apps (HTTP Injector, NapsternetV) hazionyeshi banner${C_RESET}"
    else
        rm -f "$SSHD_FF_CONFIG"
        systemctl restart sshd 2>/dev/null
        echo -e "\n${C_RED}❌ SSH config error${C_RESET}"
    fi
    press_enter
}

disable_dynamic_banner() {
    rm -f "$BANNER_ENABLED_FILE" "$SSHD_FF_CONFIG" /etc/ssh/sshd_config.d/voltron-auto-banner.conf 2>/dev/null
    systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    echo -e "\n${C_GREEN}✅ Dynamic Banner DISABLED${C_RESET}"
    press_enter
}

preview_dynamic_ssh_banner() {
    [[ ! -f "$BANNER_ENABLED_FILE" ]] && { echo -e "\n${C_RED}❌ Not enabled${C_RESET}"; press_enter; return; }
    _select_user_interface "--- 📝 Preview ---"
    local u=$SELECTED_USER
    [[ -z "$u" || "$u" == "NO_USERS" ]] && return
    echo -e "\n${C_CYAN}--- Banner '$u' ---${C_RESET}\n"
    if [[ -f "$BANNER_DIR/${u}.txt" ]]; then cat "$BANNER_DIR/${u}.txt"
    else
        local line=$(grep "^$u:" "$DB_FILE")
        generate_user_banner "$u" "$(echo "$line"|cut -d: -f3)" "$(echo "$line"|cut -d: -f4)" "$(echo "$line"|cut -d: -f5)"
        cat "$BANNER_DIR/${u}.txt" 2>/dev/null
    fi
    press_enter
}

ssh_banner_menu() {
    while true; do
        clear; show_banner
        local st=""; [[ -f "$BANNER_ENABLED_FILE" ]] && st="${C_GREEN}● ENABLED${C_RESET}" || st="${C_RED}● DISABLED${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══ 🎨 DYNAMIC BANNER ═══${C_RESET}\n"
        echo -e "  Status: $st\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Enable"
        echo -e "  ${C_RED}2)${C_RESET} Disable"
        echo -e "  ${C_GREEN}3)${C_RESET} Preview"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) enable_dynamic_banner ;;
            2) disable_dynamic_banner ;;
            3) preview_dynamic_ssh_banner ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

# ========== WEB PANEL ==========
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
        echo -e "${C_BOLD}${C_PURPLE}═══ 🌐 WEB PANEL MANAGEMENT ═══${C_RESET}\n"
        echo -e "  API Domain:   ${C_YELLOW}$WEB_PANEL_API_DOMAIN${C_RESET}"
        echo -e "  VPS IP:       ${C_YELLOW}$current_ip${C_RESET}\n"
        echo -e "  API:          $api_status"
        echo -e "  Nginx:        $nginx_status"
        echo -e "  SSL:          $ssl_status"
        echo -e "  DNS:          $dns_status\n"
        echo -e "${C_PURPLE}─────────────────────────────────────────${C_RESET}"
        echo -e "  ${C_GREEN}[ 1]${C_RESET} 🚀 Full Setup (API + DNS + Nginx + SSL)"
        echo -e "  ${C_GREEN}[ 2]${C_RESET} 📥 Install API Only"
        echo -e "  ${C_GREEN}[ 3]${C_RESET} 🌐 Setup DNS Only"
        echo -e "  ${C_GREEN}[ 4]${C_RESET} ⚙️  Setup Nginx Only"
        echo -e "  ${C_GREEN}[ 5]${C_RESET} 🔒 Setup SSL Only"
        echo -e "  ${C_GREEN}[ 6]${C_RESET} 🧪 Test Everything"
        echo -e "  ${C_GREEN}[ 7]${C_RESET} 📋 View Logs"
        echo -e "  ${C_GREEN}[ 8]${C_RESET} 🔑 View API Info"
        echo -e "  ${C_GREEN}[ 9]${C_RESET} 🔄 Restart API"
        echo -e "  ${C_GREEN}[10]${C_RESET} 📝 Copy for Lovable AI"
        echo -e "  ${C_RED}[11]${C_RESET} 🗑️  Remove Web Panel"
        echo -e "  ${C_RED}[ 0]${C_RESET} Return"
        read -p "👉 Select: " choice
        case $choice in
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
            11) web_panel_remove ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

web_panel_full_setup() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}       🚀 FULL WEB PANEL SETUP${C_RESET}\n"
    read -p "👉 Continue? (y/n): " confirm
    [[ "$confirm" != "y" ]] && return
    echo -e "\n${C_BLUE}═══ 1/5: API ═══${C_RESET}"; web_panel_install_api; sleep 2
    echo -e "\n${C_BLUE}═══ 2/5: DNS ═══${C_RESET}"; web_panel_dns_setup; sleep 2
    echo -e "\n${C_BLUE}═══ 3/5: NGINX ═══${C_RESET}"; web_panel_nginx_setup; sleep 2
    echo -e "\n${C_BLUE}═══ 4/5: SSL ═══${C_RESET}"; web_panel_ssl_setup; sleep 2
    echo -e "\n${C_BLUE}═══ 5/5: TEST ═══${C_RESET}"; web_panel_test_all
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
        systemctl disable voltrontech-api 2>/dev/null
        rm -f /etc/systemd/system/voltrontech-api.service
        systemctl daemon-reload
    fi

    local API_KEY="voltron_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)"

    echo -e "${C_BLUE}[1/8] Installing dependencies...${C_RESET}"
    ff_apt_update
    DEBIAN_FRONTEND=noninteractive apt-get install -y -o Dpkg::Use-Pty=0 \
        python3 python3-pip python3-venv python3-full curl jq 2>&1 | tail -2

    if ! command -v python3 &>/dev/null; then
        echo -e "${C_RED}❌ python3 install failed!${C_RESET}"
        press_enter; return 1
    fi
    echo -e "${C_GREEN}✅ $(python3 --version)${C_RESET}"

    echo -e "\n${C_BLUE}[2/8] Creating directory...${C_RESET}"
    mkdir -p "$API_DIR"
    cd "$API_DIR" || { echo -e "${C_RED}❌ Cannot cd${C_RESET}"; press_enter; return 1; }

    echo -e "\n${C_BLUE}[3/8] Virtual environment...${C_RESET}"
    rm -rf venv
    if ! python3 -m venv venv; then
        echo -e "${C_RED}❌ venv failed! Install python3-venv python3-full${C_RESET}"
        press_enter; return 1
    fi
    source venv/bin/activate
    pip install --upgrade pip 2>&1 | tail -1
    echo -e "${C_BLUE}Installing Flask + Gunicorn...${C_RESET}"
    if ! pip install flask flask-cors gunicorn 2>&1 | tail -2; then
        echo -e "${C_RED}❌ pip install failed${C_RESET}"
        deactivate; press_enter; return 1
    fi
    deactivate
    echo -e "${C_GREEN}✅ venv ready${C_RESET}"

    echo -e "\n${C_BLUE}[4/8] Writing API code...${C_RESET}"
    web_panel_create_api_code
    if [ ! -f "$API_DIR/api.py" ]; then
        echo -e "${C_RED}❌ api.py not created!${C_RESET}"
        press_enter; return 1
    fi
    if ! python3 -m py_compile "$API_DIR/api.py" 2>/dev/null; then
        echo -e "${C_RED}❌ api.py has syntax error!${C_RESET}"
        python3 -m py_compile "$API_DIR/api.py"
        press_enter; return 1
    fi
    echo -e "${C_GREEN}✅ api.py valid${C_RESET}"

    echo -e "\n${C_BLUE}[5/8] Checking port $API_PORT...${C_RESET}"
    local port_owner=$(ss -tlnp 2>/dev/null | grep ":$API_PORT " | awk '{print $NF}' | head -1)
    if [ -n "$port_owner" ]; then
        echo -e "${C_YELLOW}⚠️ Port $API_PORT in use. Killing...${C_RESET}"
        fuser -k ${API_PORT}/tcp 2>/dev/null
        sleep 1
    fi
    echo -e "${C_GREEN}✅ Port free${C_RESET}"

    echo -e "\n${C_BLUE}[6/8] Systemd service...${C_RESET}"
    local SERVER_HOST=$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo "vpn.voltrontechtx.shop")
    cat > /etc/systemd/system/voltrontech-api.service << EOF
[Unit]
Description=Voltron Tech API Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$API_DIR
Environment="API_KEY=$API_KEY"
Environment="DB_DIR=$DB_DIR"
Environment="SERVER_HOST=$SERVER_HOST"
Environment="PATH=$API_DIR/venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Environment="PYTHONUNBUFFERED=1"
ExecStart=$API_DIR/venv/bin/gunicorn --workers 2 --bind 0.0.0.0:$API_PORT --timeout 120 --access-logfile /var/log/voltrontech-api.log --error-logfile /var/log/voltrontech-api.log api:app
Restart=always
RestartSec=5
StandardOutput=append:/var/log/voltrontech-api.log
StandardError=append:/var/log/voltrontech-api.log

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable voltrontech-api >/dev/null 2>&1

    echo -e "\n${C_BLUE}[7/8] Starting API...${C_RESET}"
    touch /var/log/voltrontech-api.log
    systemctl start voltrontech-api
    sleep 5

    echo -e "\n${C_BLUE}[8/8] Verifying...${C_RESET}"
    if systemctl is-active --quiet voltrontech-api; then
        local test_resp=$(curl -s http://localhost:$API_PORT/api/health 2>/dev/null)
        if echo "$test_resp" | grep -q '"success":true'; then
            local SERVER_IP=$(curl -s -4 icanhazip.com)
            cat > "$API_INFO_FILE" << EOF
API_URL=http://$SERVER_IP:$API_PORT
API_KEY=$API_KEY
EOF
            echo "$API_KEY" > "$API_KEY_FILE"
            chmod 600 "$API_KEY_FILE"
            echo ""
            echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
            echo -e "${C_GREEN}           ✅ API SERVER INSTALLED & RUNNING!${C_RESET}"
            echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}\n"
            echo -e "  ${C_CYAN}🌐 URL:${C_RESET}  ${C_YELLOW}http://$SERVER_IP:$API_PORT${C_RESET}"
            echo -e "  ${C_CYAN}🔑 Key:${C_RESET}  ${C_GREEN}$API_KEY${C_RESET}"
        else
            echo -e "\n${C_YELLOW}⚠️  Service running lakini health check failed${C_RESET}"
            echo -e "${C_CYAN}Response: $test_resp${C_RESET}"
            echo -e "\n${C_BLUE}Last 20 log lines:${C_RESET}"
            tail -20 /var/log/voltrontech-api.log
        fi
    else
        echo -e "\n${C_RED}❌ API failed to start!${C_RESET}"
        echo -e "\n${C_YELLOW}--- systemctl status ---${C_RESET}"
        systemctl status voltrontech-api --no-pager -l 2>&1 | head -20
        echo -e "\n${C_YELLOW}--- Last 30 log lines ---${C_RESET}"
        journalctl -u voltrontech-api -n 30 --no-pager
        echo -e "\n${C_YELLOW}--- API log ---${C_RESET}"
        tail -30 /var/log/voltrontech-api.log 2>/dev/null
        echo -e "\n${C_CYAN}Debug manually:${C_RESET}"
        echo "  cd $API_DIR && source venv/bin/activate && python3 api.py"
    fi
    press_enter
}

web_panel_create_api_code() {
    cat > "$API_DIR/api.py" << 'APIEOF'
#!/usr/bin/env python3
"""Voltron Tech API Server v11.0"""
from flask import Flask, request, jsonify
from flask_cors import CORS
from functools import wraps
from datetime import datetime, timedelta
import subprocess, os, shutil

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}}, supports_credentials=True)

API_KEY = os.environ.get('API_KEY', 'CHANGE_ME')
DB_DIR = os.environ.get('DB_DIR', '/etc/voltrontech')
DB_FILE = f'{DB_DIR}/users.db'
SERVER_HOST = os.environ.get('SERVER_HOST', 'vpn.voltrontechtx.shop')
DEFAULT_LIMIT = 999
BANDWIDTH_DIR = f'{DB_DIR}/bandwidth'

def require_api_key(f):
    @wraps(f)
    def d(*a, **k):
        key = request.headers.get('X-API-Key') or request.args.get('api_key')
        if not key or key != API_KEY:
            return jsonify({'success': False, 'error': 'Invalid API key'}), 401
        return f(*a, **k)
    return d

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

def get_online(u):
    out = run_shell(f'pgrep -c -u {u} sshd 2>/dev/null')
    try: return int(out or '0')
    except ValueError: return 0

def get_server_ip():
    for cmd in ['curl -s -4 icanhazip.com', 'curl -s -4 ifconfig.me', "hostname -I | awk '{print $1}'"]:
        ip = run_shell(cmd, timeout=5).strip()
        if ip and ip.count('.') == 3 and not ip.startswith('127.'): return ip
    return 'unknown'

def get_protocols(username=None, password=None, limit=DEFAULT_LIMIT):
    p = {}
    sip = get_server_ip()
    if ssh_active():
        p['ssh'] = {'id': 'ssh', 'name': 'SSH Direct', 'icon': '🔐', 'color': '#6BCB77', 'host': SERVER_HOST, 'ip': sip, 'port': 22, 'username': username, 'password': password, 'limit': limit, 'type': 'ssh'}
    if service_active('haproxy'):
        p['ssl'] = {'id': 'ssl', 'name': 'SSL/TLS Tunnel', 'icon': '🔒', 'color': '#4D96FF', 'host': SERVER_HOST, 'ip': sip, 'port': 444, 'username': username, 'password': password, 'limit': limit, 'type': 'ssl'}
    if service_active('dnstt'):
        domain = ''; pubkey = ''; mtu = 512
        if os.path.exists(f'{DB_DIR}/domain.txt'):
            try:
                with open(f'{DB_DIR}/domain.txt') as f: domain = f.read().strip()
            except Exception: pass
        if os.path.exists(f'{DB_DIR}/dnstt/server.pub'):
            try:
                with open(f'{DB_DIR}/dnstt/server.pub') as f: pubkey = f.read().strip()
            except Exception: pass
        if os.path.exists(f'{DB_DIR}/config/mtu'):
            try:
                with open(f'{DB_DIR}/config/mtu') as f: mtu = int(f.read().strip())
            except Exception: mtu = 512
        p['dnstt'] = {'id': 'dnstt', 'name': 'DNSTT', 'icon': '📡', 'color': '#9B59B6', 'domain': domain, 'pubkey': pubkey, 'mtu': mtu, 'dns': '8.8.8.8', 'dns_alt': '1.1.1.1', 'username': username, 'password': password, 'limit': limit, 'type': 'dnstt'}
    if service_active('udp-custom'):
        p['udp_custom'] = {'id': 'udp_custom', 'name': 'UDP Custom', 'icon': '🚀', 'color': '#FF6B6B', 'host': SERVER_HOST, 'ip': sip, 'port_range': '1-65535', 'exclude': '53,5300', 'username': username, 'password': password, 'limit': limit, 'type': 'udp'}
    if service_active('badvpn'):
        p['badvpn'] = {'id': 'badvpn', 'name': 'BadVPN UDPGW', 'icon': '⚡', 'color': '#FFD93D', 'host': SERVER_HOST, 'ip': sip, 'port': 7300, 'username': username, 'password': password, 'limit': limit, 'type': 'badvpn'}
    if service_active('zivpn'):
        p['zivpn'] = {'id': 'zivpn', 'name': 'ZiVPN', 'icon': '🛡️', 'color': '#6BCB77', 'host': SERVER_HOST, 'ip': sip, 'port': 5667, 'username': username, 'password': password, 'limit': limit, 'type': 'zivpn'}
    if service_active('falconproxy'):
        p['falconproxy'] = {'id': 'falconproxy', 'name': 'Falcon Proxy', 'icon': '🦅', 'color': '#E85555', 'host': SERVER_HOST, 'ip': sip, 'port': 8080, 'username': username, 'password': password, 'limit': limit, 'type': 'falconproxy'}
    return p

def now_iso(): return datetime.now().isoformat()

@app.route('/api/health')
def health():
    return jsonify({'success': True, 'status': 'ok', 'service': 'Voltron Tech API', 'version': '11.0', 'protocols_active': len(get_protocols()), 'timestamp': now_iso()})

@app.route('/api/trial/check', methods=['POST'])
@require_api_key
def tcheck():
    d = request.get_json() or {}
    u = d.get('username', '').strip().lower()
    if not u: return jsonify({'available': False, 'error': 'Username required'}), 400
    if not u.replace('-', '').replace('_', '').isalnum(): return jsonify({'available': False, 'error': 'Only letters, numbers, - and _'}), 400
    if len(u) < 3 or len(u) > 20: return jsonify({'available': False, 'error': 'Username must be 3-20 chars'}), 400
    if user_exists(u) or any(x['username'] == u for x in read_users()):
        return jsonify({'available': False, 'error': 'Username already used'})
    return jsonify({'available': True, 'username': u, 'timestamp': now_iso()})

@app.route('/api/trial/create', methods=['POST'])
@require_api_key
def tcreate():
    d = request.get_json() or {}
    u = d.get('username', '').strip().lower()
    p = d.get('password', '').strip()
    days = int(d.get('days', 1))
    if not u or len(u) < 3 or len(u) > 20: return jsonify({'success': False, 'error': 'Invalid username'}), 400
    if not u.replace('-', '').replace('_', '').isalnum(): return jsonify({'success': False, 'error': 'Invalid chars'}), 400
    if not p or len(p) < 4: return jsonify({'success': False, 'error': 'Password too short'}), 400
    if days not in [1, 3, 7]: return jsonify({'success': False, 'error': 'Days must be 1, 3, or 7'}), 400
    if user_exists(u): return jsonify({'success': False, 'error': 'Username already used'}), 400
    try:
        r = run_safe(['useradd', '-m', '-s', '/usr/sbin/nologin', u])
        if not r['success']: return jsonify({'success': False, 'error': 'Failed to create user'}), 500
        run_safe(['usermod', '-aG', 'ffusers', u])
        try: subprocess.run(['chpasswd'], input=f'{u}:{p}', text=True, capture_output=True, timeout=10)
        except Exception: pass
        e = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', e, u])
        os.makedirs(DB_DIR, exist_ok=True)
        with open(DB_FILE, 'a') as f: f.write(f'{u}:{p}:{e}:{DEFAULT_LIMIT}:0:0:ACTIVE\n')
        return jsonify({'success': True, 'message': f'Trial created ({days} days)', 'timestamp': now_iso(), 'account': {'username': u, 'password': p, 'expiry': e, 'days': days, 'limit': DEFAULT_LIMIT, 'bandwidth': 'Unlimited', 'server': SERVER_HOST, 'server_ip': get_server_ip()}, 'protocols': get_protocols(u, p, DEFAULT_LIMIT), 'protocol_count': len(get_protocols(u, p, DEFAULT_LIMIT))})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/trial/status/<username>')
@require_api_key
def tstatus(username):
    user = next((u for u in read_users() if u['username'] == username), None)
    if not user: return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        e = datetime.strptime(user['expiry'], '%Y-%m-%d')
        dl = (e - datetime.now()).days
    except Exception: dl = 0
    return jsonify({'success': True, 'timestamp': now_iso(), 'account': {'username': username, 'status': get_status(username), 'expiry': user['expiry'], 'days_left': max(0, dl), 'online': get_online(username), 'limit': int(user['limit']), 'bandwidth': user['bandwidth']}})

@app.route('/api/users/list')
@require_api_key
def ulist():
    users = read_users()
    r = []
    for u in users:
        ub = 0
        uf = f'{BANDWIDTH_DIR}/{u["username"]}.usage'
        if os.path.exists(uf):
            try:
                with open(uf) as f: ub = int(f.read().strip() or 0)
            except Exception: ub = 0
        r.append({'username': u['username'], 'expiry': u['expiry'], 'limit': int(u['limit']), 'bandwidth_limit': float(u['bandwidth']), 'bandwidth_used_gb': round(ub / 1073741824, 2), 'status': get_status(u['username']), 'online': get_online(u['username'])})
    return jsonify({'success': True, 'timestamp': now_iso(), 'users': r, 'total': len(r)})

@app.route('/api/users/create', methods=['POST'])
@require_api_key
def users_create():
    d = request.get_json() or {}
    u = d.get('username', '').strip().lower()
    p = d.get('password', '').strip()
    days = int(d.get('days', 30))
    limit = int(d.get('limit', DEFAULT_LIMIT))
    bw = float(d.get('bandwidth', 0))
    if not u or len(u) < 3 or len(u) > 20: return jsonify({'success': False, 'error': 'Username 3-20 chars'}), 400
    if not u.replace('-', '').replace('_', '').isalnum(): return jsonify({'success': False, 'error': 'Invalid chars'}), 400
    if not p or len(p) < 4: return jsonify({'success': False, 'error': 'Password too short'}), 400
    if user_exists(u): return jsonify({'success': False, 'error': 'User exists'}), 400
    try:
        run_safe(['useradd', '-m', '-s', '/usr/sbin/nologin', u])
        run_safe(['usermod', '-aG', 'ffusers', u])
        subprocess.run(['chpasswd'], input=f'{u}:{p}', text=True, capture_output=True)
        e = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', e, u])
        with open(DB_FILE, 'a') as f: f.write(f'{u}:{p}:{e}:{limit}:{bw}:0:ACTIVE\n')
        return jsonify({'success': True, 'message': f'User {u} created', 'account': {'username': u, 'password': p, 'expiry': e, 'limit': limit, 'bandwidth': bw}})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/delete', methods=['POST'])
@require_api_key
def users_delete():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u: return jsonify({'success': False, 'error': 'Username required'}), 400
    if not user_exists(u) and not any(x['username'] == u for x in read_users()):
        return jsonify({'success': False, 'error': 'User not found'}), 404
    try:
        run_shell(f'killall -u {u} -9 2>/dev/null')
        run_safe(['userdel', '-r', u])
        run_shell(f'rm -f {BANDWIDTH_DIR}/{u}.usage')
        run_shell(f'rm -rf {BANDWIDTH_DIR}/pidtrack/{u}')
        run_shell(f"sed -i '/^{u}:/d' {DB_FILE}")
        return jsonify({'success': True, 'message': f'User {u} deleted'})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/lock', methods=['POST'])
@require_api_key
def users_lock():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u: return jsonify({'success': False, 'error': 'Username required'}), 400
    if not user_exists(u): return jsonify({'success': False, 'error': 'User not found'}), 404
    try:
        run_safe(['usermod', '-L', u])
        run_shell(f'killall -u {u} -9 2>/dev/null')
        return jsonify({'success': True, 'message': f'User {u} locked'})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/unlock', methods=['POST'])
@require_api_key
def users_unlock():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u: return jsonify({'success': False, 'error': 'Username required'}), 400
    if not user_exists(u): return jsonify({'success': False, 'error': 'User not found'}), 404
    try:
        run_safe(['usermod', '-U', u])
        return jsonify({'success': True, 'message': f'User {u} unlocked'})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/edit', methods=['POST'])
@require_api_key
def users_edit():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u or not user_exists(u): return jsonify({'success': False, 'error': 'User not found'}), 404
    try:
        line = run_shell(f"grep '^{u}:' {DB_FILE}")
        if not line: return jsonify({'success': False, 'error': 'DB entry missing'}), 404
        parts = line.split(':')
        cur_pass = parts[1] if len(parts) > 1 else ''
        cur_exp = parts[2] if len(parts) > 2 else ''
        cur_limit = parts[3] if len(parts) > 3 else '999'
        cur_bw = parts[4] if len(parts) > 4 else '0'
        new_pass = d.get('password', cur_pass)
        days = d.get('days')
        new_limit = d.get('limit', cur_limit)
        new_bw = d.get('bandwidth', cur_bw)
        if new_pass and new_pass != cur_pass:
            subprocess.run(['chpasswd'], input=f'{u}:{new_pass}', text=True, capture_output=True)
        if days:
            new_exp = (datetime.now() + timedelta(days=int(days))).strftime('%Y-%m-%d')
            run_safe(['chage', '-E', new_exp, u])
            cur_exp = new_exp
        run_shell(f"sed -i 's|^{u}:.*|{u}:{new_pass}:{cur_exp}:{new_limit}:{new_bw}:0:ACTIVE|' {DB_FILE}")
        return jsonify({'success': True, 'message': f'User {u} updated', 'account': {'username': u, 'password': new_pass, 'expiry': cur_exp, 'limit': int(new_limit), 'bandwidth': float(new_bw)}})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/renew', methods=['POST'])
@require_api_key
def users_renew():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    days = int(d.get('days', 30))
    if not u or not user_exists(u): return jsonify({'success': False, 'error': 'User not found'}), 404
    try:
        new_exp = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', new_exp, u])
        run_safe(['usermod', '-U', u])
        line = run_shell(f"grep '^{u}:' {DB_FILE}")
        parts = line.split(':')
        run_shell(f"sed -i 's|^{u}:.*|{u}:{parts[1]}:{new_exp}:{parts[3]}:{parts[4]}:0:ACTIVE|' {DB_FILE}")
        return jsonify({'success': True, 'message': f'User {u} renewed to {new_exp}', 'expiry': new_exp})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/reset_bandwidth', methods=['POST'])
@require_api_key
def users_reset_bw():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u or not user_exists(u): return jsonify({'success': False, 'error': 'User not found'}), 404
    try:
        run_shell(f'echo "0" > {BANDWIDTH_DIR}/{u}.usage')
        run_safe(['usermod', '-U', u])
        return jsonify({'success': True, 'message': f'Bandwidth reset for {u}'})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/cleanup/expired', methods=['POST'])
@require_api_key
def cleanup_expired_api():
    try:
        users = read_users()
        deleted = []
        for x in users:
            try:
                exp = datetime.strptime(x['expiry'], '%Y-%m-%d')
                if exp < datetime.now():
                    u = x['username']
                    run_shell(f'killall -u {u} -9 2>/dev/null')
                    run_safe(['userdel', '-r', u])
                    run_shell(f'rm -f {BANDWIDTH_DIR}/{u}.usage')
                    run_shell(f"sed -i '/^{u}:/d' {DB_FILE}")
                    deleted.append(u)
            except Exception:
                pass
        return jsonify({'success': True, 'deleted': deleted, 'count': len(deleted)})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/protocols/status')
@require_api_key
def pstat():
    p = get_protocols()
    return jsonify({'success': True, 'timestamp': now_iso(), 'protocols': p, 'count': len(p), 'active_list': list(p.keys())})

@app.route('/api/dashboard/info')
@require_api_key
def dinfo():
    try:
        ip = get_server_ip()
        try:
            with open('/proc/uptime') as f: up = float(f.read().split()[0])
            d = int(up // 86400); h = int((up % 86400) // 3600)
            us = f'{d}d {h}h'
        except Exception: us = 'unknown'
        users = read_users()
        online = sum(get_online(u['username']) for u in users)
        return jsonify({'success': True, 'timestamp': now_iso(), 'info': {'ip': ip, 'uptime': us, 'users': {'total': len(users), 'online': online}, 'services': {'ssh': ssh_active(), 'dnstt': service_active('dnstt'), 'haproxy': service_active('haproxy'), 'badvpn': service_active('badvpn'), 'udp_custom': service_active('udp-custom'), 'zivpn': service_active('zivpn'), 'falconproxy': service_active('falconproxy')}}})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
APIEOF
    chmod +x "$API_DIR/api.py"
}

web_panel_dns_setup() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS Setup ---${C_RESET}\n"
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    if [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "${C_RED}❌ Cannot detect IP${C_RESET}"; press_enter; return 1
    fi
    echo -e "  ${C_CYAN}VPS IP:${C_RESET}      ${C_YELLOW}$ip${C_RESET}"
    echo -e "  ${C_CYAN}API Domain:${C_RESET}  ${C_YELLOW}$WEB_PANEL_API_DOMAIN${C_RESET}\n"
    local existing=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
    if [[ "$existing" == "$ip" ]]; then
        echo -e "${C_GREEN}✅ DNS exists${C_RESET}"; press_enter; return 0
    fi
    local api_sub=$(echo "$WEB_PANEL_API_DOMAIN" | cut -d. -f1)
    local api_data="[{\"subname\":\"$api_sub\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$ip\"]}]"
    local resp=$(curl -s -w "\n%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$api_data" 2>/dev/null)
    local http_code=$(echo "$resp" | tail -1)
    if [[ "$http_code" -eq 201 ]] || [[ "$http_code" -eq 200 ]]; then
        echo -e "${C_GREEN}✅ DNS created${C_RESET}"; sleep 5
    elif [[ "$http_code" -eq 409 ]]; then
        curl -s -X PATCH "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$api_sub/A/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "{\"records\":[\"$ip\"],\"ttl\":3600}" >/dev/null 2>&1
        echo -e "${C_GREEN}✅ DNS updated${C_RESET}"
    else
        echo -e "${C_RED}❌ Failed HTTP $http_code${C_RESET}"
    fi
    press_enter
}

web_panel_nginx_setup() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ⚙️ Nginx Setup ---${C_RESET}\n"
    if ! command -v nginx &>/dev/null; then
        ff_apt_install nginx certbot python3-certbot-nginx >/dev/null 2>&1
    fi
    [ -f "$WEB_PANEL_NGINX_CONFIG" ] && cp "$WEB_PANEL_NGINX_CONFIG" "$WEB_PANEL_NGINX_CONFIG.bak.$(date +%s)"
    cat > "$WEB_PANEL_NGINX_CONFIG" << EOF
server {
    listen 80;
    server_name $WEB_PANEL_API_DOMAIN;
    location / {
        proxy_pass http://127.0.0.1:$API_PORT;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, POST, OPTIONS' always;
        add_header 'Access-Control-Allow-Headers' 'Content-Type, X-API-Key' always;
        if (\$request_method = 'OPTIONS') { return 204; }
    }
}
EOF
    ln -sf "$WEB_PANEL_NGINX_CONFIG" "$WEB_PANEL_NGINX_LINK"
    [ -f /etc/nginx/sites-enabled/default ] && rm -f /etc/nginx/sites-enabled/default
    if nginx -t 2>&1 | grep -q "successful"; then
        systemctl reload nginx
        echo -e "${C_GREEN}✅ Nginx reloaded${C_RESET}"
    else
        echo -e "${C_RED}❌ Config error${C_RESET}"; nginx -t
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
        echo -e "${C_RED}❌ DNS not pointing!${C_RESET}"; echo -e "  Expected: $ip"; echo -e "  Got: $dns_ip"; press_enter; return 1
    fi
    ! systemctl is-active --quiet nginx && { echo -e "${C_RED}❌ Nginx not running${C_RESET}"; press_enter; return 1; }
    local ssl_email
    if [ -f "$WEB_PANEL_SSL_EMAIL_FILE" ]; then ssl_email=$(cat "$WEB_PANEL_SSL_EMAIL_FILE")
    else
        read -p "👉 Email (or Enter skip): " ssl_email
        [ -n "$ssl_email" ] && echo "$ssl_email" > "$WEB_PANEL_SSL_EMAIL_FILE"
    fi
    local cmd
    if [ -n "$ssl_email" ]; then cmd="certbot --nginx -d $WEB_PANEL_API_DOMAIN --non-interactive --agree-tos -m $ssl_email --redirect"
    else cmd="certbot --nginx -d $WEB_PANEL_API_DOMAIN --non-interactive --agree-tos --register-unsafely-without-email --redirect"; fi
    if eval "$cmd" 2>&1 | tee /tmp/certbot_webpanel.log | grep -q "Successfully"; then
        echo -e "\n${C_GREEN}✅ SSL! https://$WEB_PANEL_API_DOMAIN${C_RESET}"
        systemctl enable certbot.timer &>/dev/null; systemctl start certbot.timer &>/dev/null
    else
        echo -e "\n${C_RED}❌ SSL failed${C_RESET}"; tail -15 /tmp/certbot_webpanel.log
    fi
    press_enter
}

web_panel_test_all() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}       🧪 TESTING WEB PANEL${C_RESET}\n"
    local p=0; local f=0
    echo -e "${C_BLUE}[1/6] API service...${C_RESET}"
    systemctl is-active --quiet voltrontech-api 2>/dev/null && { echo -e "     ${C_GREEN}✅${C_RESET}"; ((p++)); } || { echo -e "     ${C_RED}❌${C_RESET}"; ((f++)); }
    echo -e "${C_BLUE}[2/6] Nginx...${C_RESET}"
    systemctl is-active --quiet nginx 2>/dev/null && { echo -e "     ${C_GREEN}✅${C_RESET}"; ((p++)); } || { echo -e "     ${C_RED}❌${C_RESET}"; ((f++)); }
    echo -e "${C_BLUE}[3/6] Local API...${C_RESET}"
    curl -s http://localhost:$API_PORT/api/health 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅${C_RESET}"; ((p++)); } || { echo -e "     ${C_RED}❌${C_RESET}"; ((f++)); }
    echo -e "${C_BLUE}[4/6] DNS...${C_RESET}"
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    local dip=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
    [[ "$dip" == "$ip" ]] && { echo -e "     ${C_GREEN}✅ $dip${C_RESET}"; ((p++)); } || { echo -e "     ${C_RED}❌ $dip${C_RESET}"; ((f++)); }
    echo -e "${C_BLUE}[5/6] HTTPS...${C_RESET}"
    curl -s "https://$WEB_PANEL_API_DOMAIN/api/health" 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅${C_RESET}"; ((p++)); } || { echo -e "     ${C_RED}❌${C_RESET}"; ((f++)); }
    echo -e "${C_BLUE}[6/6] API key...${C_RESET}"
    local k=$(cat "$API_KEY_FILE" 2>/dev/null)
    if [ -n "$k" ]; then
        curl -s -H "X-API-Key: $k" "https://$WEB_PANEL_API_DOMAIN/api/protocols/status" 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅${C_RESET}"; ((p++)); } || { echo -e "     ${C_RED}❌${C_RESET}"; ((f++)); }
    else echo -e "     ${C_RED}❌ No key${C_RESET}"; ((f++)); fi
    echo ""
    [[ $f -eq 0 ]] && echo -e "${C_GREEN}✅ ALL PASSED ($p/6)${C_RESET}" || echo -e "${C_YELLOW}⚠️  Passed: $p/6 Failed: $f${C_RESET}"
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

web_panel_view_api_info() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔑 API Information ---${C_RESET}\n"
    [ ! -f "$API_INFO_FILE" ] && { echo -e "${C_RED}❌ Not installed${C_RESET}"; press_enter; return; }
    echo -e "  ${C_YELLOW}🌐 HTTPS:${C_RESET}    ${C_GREEN}https://$WEB_PANEL_API_DOMAIN${C_RESET}"
    echo -e "  ${C_YELLOW}🔑 Key:${C_RESET}      ${C_GREEN}$(cat "$API_KEY_FILE" 2>/dev/null)${C_RESET}"
    echo -e "\n  ${C_YELLOW}📋 Endpoints:${C_RESET}"
    echo "    GET  /api/health"
    echo "    POST /api/trial/check"
    echo "    POST /api/trial/create"
    echo "    GET  /api/trial/status/<username>"
    echo "    GET  /api/users/list"
    echo "    POST /api/users/create"
    echo "    POST /api/users/delete"
    echo "    POST /api/users/lock"
    echo "    POST /api/users/unlock"
    echo "    POST /api/users/edit"
    echo "    POST /api/users/renew"
    echo "    POST /api/users/reset_bandwidth"
    echo "    POST /api/cleanup/expired"
    echo "    GET  /api/protocols/status"
    echo "    GET  /api/dashboard/info"
    press_enter
}

web_panel_restart_api() {
    systemctl restart voltrontech-api; sleep 2
    systemctl is-active --quiet voltrontech-api && echo -e "${C_GREEN}✅ Restarted${C_RESET}" || echo -e "${C_RED}❌ Failed${C_RESET}"
    press_enter
}

web_panel_copy_for_lovable() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📝 Copy for Lovable AI ---${C_RESET}\n"
    [ ! -f "$API_KEY_FILE" ] && { echo -e "${C_RED}❌ Not installed${C_RESET}"; press_enter; return; }
    echo -e "${C_CYAN}API URL:${C_RESET} ${C_GREEN}https://$WEB_PANEL_API_DOMAIN${C_RESET}"
    echo -e "${C_CYAN}API Key:${C_RESET} ${C_GREEN}$(cat "$API_KEY_FILE")${C_RESET}"
    echo -e "${C_CYAN}Default Limit:${C_RESET} ${C_GREEN}999${C_RESET}"
    press_enter
}

web_panel_remove() {
    clear; show_banner
    echo -e "${C_RED}       🗑️ REMOVE WEB PANEL${C_RESET}\n"
    read -p "⚠️  Confirm? (y/n): " confirm
    [[ "$confirm" != "y" ]] && return
    systemctl stop voltrontech-api 2>/dev/null
    systemctl disable voltrontech-api 2>/dev/null
    rm -f /etc/systemd/system/voltrontech-api.service
    rm -rf "$API_DIR"
    rm -f "$WEB_PANEL_NGINX_LINK" "$WEB_PANEL_NGINX_CONFIG"
    nginx -t 2>&1 | grep -q "successful" && systemctl reload nginx
    [ -d "/etc/letsencrypt/live/$WEB_PANEL_API_DOMAIN" ] && certbot delete --cert-name "$WEB_PANEL_API_DOMAIN" --non-interactive 2>/dev/null
    systemctl daemon-reload
    echo -e "\n${C_GREEN}✅ Removed${C_RESET}"
    press_enter
}

# ========== LIMITER SERVICE ==========
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

_connect_banner_to_ssh() {
    mkdir -p /etc/ssh/sshd_config.d
    cat > /etc/ssh/sshd_config.d/voltron-auto-banner.conf << 'SSH_CONF'
# Voltron Tech - Dynamic Banners
Match User *
    Banner /etc/voltrontech/banners/%u.txt
SSH_CONF
    if ! grep -q "Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
        echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
    fi
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
}

while true; do
    [[ ! -s "$DB_FILE" ]] && { sleep "$SCAN_INTERVAL"; continue; }
    current_ts=$(date +%s)
    dynamic_banners_enabled=false
    [[ -f "$BANNER_ENABLED_FILE" ]] && dynamic_banners_enabled=true
    declare -A locked_users=()
    while read -r passwd_user _ passwd_status _rest; do
        [[ "$passwd_status" == "L" ]] && locked_users["$passwd_user"]=1
    done < <(passwd -Sa 2>/dev/null)
    while IFS=: read -r user pass expiry limit bandwidth_gb traffic_used status; do
        [[ -z "$user" || "$user" == \#* ]] && continue
        [[ -z "$status" ]] && status="ACTIVE"
        [[ "$limit" =~ ^[0-9]+$ ]] || limit=999
        [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]] || bandwidth_gb=0
        online_count=$(pgrep -c -u "$user" sshd 2>/dev/null || echo 0)
        [[ "$online_count" =~ ^[0-9]+$ ]] || online_count=0
        user_locked=false; is_expired=false; bw_exhausted=false
        [[ -n "${locked_users[$user]+x}" ]] && user_locked=true
        expiry_ts=0; days_left="N/A"
        if [[ "$expiry" != "Never" && -n "$expiry" ]]; then
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 )); then
                diff_secs=$((expiry_ts - current_ts))
                if (( diff_secs <= 0 )); then
                    is_expired=true; days_left="EXPIRED"
                    if ! $user_locked; then usermod -L "$user" &>/dev/null; user_locked=true; fi
                else
                    d_l=$(( diff_secs / 86400 )); h_l=$(( (diff_secs % 86400) / 3600 ))
                    if (( d_l == 0 )); then days_left="${h_l}h left"; else days_left="${d_l}d ${h_l}h"; fi
                fi
            fi
        fi
        if (( limit > 0 && online_count > limit )); then
            if ! $user_locked; then usermod -L "$user" &>/dev/null; killall -u "$user" -9 &>/dev/null; user_locked=true; fi
        fi
        usagefile="$BW_DIR/${user}.usage"
        accum_disp=0
        [[ -f "$usagefile" ]] && { read -r accum_disp < "$usagefile"; [[ "$accum_disp" =~ ^[0-9]+$ ]] || accum_disp=0; }
        if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
            quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
            if (( quota_bytes > 0 && accum_disp >= quota_bytes )); then
                bw_exhausted=true
                if ! $user_locked; then usermod -L "$user" &>/dev/null; user_locked=true; fi
            fi
        fi
        if $dynamic_banners_enabled; then
            if $user_locked; then account_status="🔒 LOCKED"; status_color="#FF6B6B"
            elif $is_expired; then account_status="🗓️ EXPIRED"; status_color="#FF9F43"
            elif $bw_exhausted; then account_status="⚠️ DATA EXHAUSTED"; status_color="#FF6B6B"
            else account_status="✅ ACTIVE"; status_color="#6BCB77"; fi
            bw_info="Unlimited"
            if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
                used_gb=$(awk "BEGIN {printf \"%.2f\", $accum_disp / 1073741824}")
                remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}")
                bw_info="${used_gb}/${bandwidth_gb} GB | ${remain_gb} GB left"
            fi
            UPTIME=$(uptime -p | sed 's/up //')
            LOAD=$(awk '{print $1}' /proc/loadavg)
            banner_content="<br><br><center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b> 🌍VOLTRON VPN🌍</b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"
            banner_content+="<center><font color=\"#4D96FF\" size=\"5\"><b>📋 ACCOUNT DETAILS 📋</b></font></center><br>"
            banner_content+="<center><font color=\"#000000\">👤 <b>Username:</b> $user</font></center><br>"
            banner_content+="<center><font color=\"#000000\">📅 <b>Expiration:</b> $expiry ($days_left)</font></center><br>"
            banner_content+="<center><font color=\"#4D96FF\">📊 <b>Bandwidth:</b> $bw_info</font></center><br>"
            banner_content+="<center><font color=\"#000000\">🔌 <b>Sessions:</b> $online_count/$limit</font></center><br>"
            banner_content+="<center><font color=\"$status_color\" size=\"5\"><b>📌 Status: $account_status</b></font></center><br>"
            banner_content+="<center><font color=\"#000000\">⏱️ Uptime: $UPTIME | 📈 Load: $LOAD</font></center><br>"
            banner_content+="<center>📱 https://t.me/voltrontech</center><br>"
            banner_content+="<center>💬 https://chat.whatsapp.com/EZtAFt9dmS5DVKbNN5iSPz</center><br>"
            banner_content+="<center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b>  🌍VOLTRON VPN🌍 </b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"
            bf="$BANNER_DIR/${user}.txt"; tf="${bf}.tmp"
            printf "%s" "$banner_content" > "$tf"
            if ! cmp -s "$tf" "$bf" 2>/dev/null; then mv "$tf" "$bf"; else rm -f "$tf"; fi
            chmod 644 "$bf" 2>/dev/null
        fi
        [[ -z "$bandwidth_gb" || "$bandwidth_gb" == "0" ]] && continue
        accumulated=$accum_disp
        if (( online_count == 0 )); then rm -f "$PID_DIR/${user}__"*.last 2>/dev/null; continue; fi
        declare -A unique_pids=()
        while read -r ssh_pid; do [[ "$ssh_pid" =~ ^[0-9]+$ ]] && unique_pids["$ssh_pid"]=1; done < <(pgrep -u "$user" sshd 2>/dev/null)
        delta_total=0
        for pid in "${!unique_pids[@]}"; do
            io_file="/proc/$pid/io"; cur=0
            if [[ -r "$io_file" ]]; then
                rchar=0; wchar=0
                while read -r key value; do
                    case "$key" in rchar:) rchar=${value:-0};; wchar:) wchar=${value:-0};; esac
                done < "$io_file"
                cur=$((rchar + wchar))
            fi
            pidfile="$PID_DIR/${user}__${pid}.last"
            if [[ -f "$pidfile" ]]; then
                read -r prev < "$pidfile"; [[ "$prev" =~ ^[0-9]+$ ]] || prev=0
                if (( cur >= prev )); then d=$((cur - prev)); else d=$cur; fi
                delta_total=$((delta_total + d))
            fi
            printf "%s\n" "$cur" > "$pidfile"
        done
        for f in "$PID_DIR/${user}__"*.last; do
            [[ -f "$f" ]] || continue
            fpid=${f##*__}; fpid=${fpid%.last}
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
    cat > "$LIMITER_SERVICE" << EOF
[Unit]
Description=Voltron Connection & Traffic Limiter
After=network.target

[Service]
Type=simple
ExecStart=$LIMITER_SCRIPT
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    pkill -f "voltrontech-limiter" 2>/dev/null
    systemctl daemon-reload
    systemctl enable voltrontech-limiter &>/dev/null
    systemctl restart voltrontech-limiter --no-block &>/dev/null
}

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

# ========== BACKUP ==========
backup_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💾 Backup ---${C_RESET}\n"
    read -p "Path [/root/voltrontech_backup.tar.gz]: " bp
    bp=${bp:-/root/voltrontech_backup.tar.gz}
    tar -czf "$bp" -C "$(dirname "$DB_DIR")" "$(basename "$DB_DIR")" 2>/dev/null
    [ $? -eq 0 ] && echo -e "${C_GREEN}✅ $bp${C_RESET}" || echo -e "${C_RED}❌ Failed${C_RESET}"
    press_enter
}

restore_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📥 Restore ---${C_RESET}\n"
    read -p "Path: " bp
    [ ! -f "$bp" ] && { echo -e "${C_RED}❌ Not found${C_RESET}"; press_enter; return; }
    read -p "⚠️ Overwrite? (y/n): " c
    [[ "$c" == "y" ]] && {
        local td=$(mktemp -d)
        tar -xzf "$bp" -C "$td" 2>/dev/null
        [ -f "$td/voltrontech/users.db" ] && { cp "$td/voltrontech/users.db" "$DB_FILE"; echo -e "${C_GREEN}✅ Restored${C_RESET}"; }
        rm -rf "$td"
    }
    press_enter
}

# ========== DNS MENU ==========
dns_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS ---${C_RESET}\n"
    if [ -f "$DNS_INFO_FILE" ]; then
        source "$DNS_INFO_FILE"
        echo -e "Existing: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
        read -p "Delete? (y/n): " c
        [[ "$c" == "y" ]] && { curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/A/" -H "Authorization: Token $DESEC_TOKEN" >/dev/null; rm -f "$DNS_INFO_FILE"; echo -e "${C_GREEN}✅ Deleted${C_RESET}"; }
    else
        read -p "Generate? (y/n): " c
        [[ "$c" == "y" ]] && generate_dns_record
    fi
    press_enter
}

generate_dns_record() {
    local ip=$(curl -s -4 icanhazip.com)
    [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && return 1
    local sub="vps-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    local full="$sub.$DESEC_DOMAIN"
    local data=$(printf '[{"subname": "%s", "type": "A", "ttl": 3600, "records": ["%s"]}]' "$sub" "$ip")
    local resp=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$data")
    [[ "${resp: -3}" -ne 201 ]] && return 1
    cat > "$DNS_INFO_FILE" <<-EOF
SUBDOMAIN="$sub"
FULL_DOMAIN="$full"
EOF
    echo -e "${C_GREEN}✅ $full${C_RESET}"
}

# ========== VPS DASHBOARD ==========
show_vps_dashboard() {
    clear
    local HOSTNAME=$(hostname)
    local OS=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null | cut -d' ' -f1-2)
    local KERNEL=$(uname -r)
    local UPTIME=$(uptime -p | sed 's/up //')
    local IP=$(curl -s -4 icanhazip.com 2>/dev/null || echo "Unknown")
    local CPU_CORES=$(grep -c "processor" /proc/cpuinfo)
    local RAM_USED=$(free -h | awk '/^Mem:/ {print $3}')
    local RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}')
    local RAM_PERCENT=$(free -m | awk '/^Mem:/ {printf "%.0f", $3*100/$2}')
    local DISK_USED=$(df -h / | awk 'NR==2 {print $3}')
    local DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}')
    local DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
    local LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)
    local TOTAL_USERS=$(grep -c . "$DB_FILE" 2>/dev/null || echo "0")
    local SSH_ST=$(systemctl is-active sshd 2>/dev/null || systemctl is-active ssh 2>/dev/null || echo "inactive")
    local DNSTT_ST=$(systemctl is-active dnstt 2>/dev/null || echo "inactive")
    local API_ST=$(systemctl is-active voltrontech-api 2>/dev/null || echo "inactive")
    make_bar() {
        local p=$1; local w=20
        local f=$((p * w / 100)); [[ $f -gt $w ]] && f=$w
        local e=$((w - f))
        local color=""; [[ $p -lt 50 ]] && color="\033[38;5;46m" || { [[ $p -lt 75 ]] && color="\033[38;5;226m" || color="\033[38;5;196m"; }
        printf "${color}["
        printf "%${f}s" | tr ' ' '█'
        printf "%${e}s" | tr ' ' '░'
        printf "]${C_RESET} ${p}%%"
    }
    echo ""
    echo -e "${C_BOLD}${C_PURPLE}╔═══════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║${C_RESET}  ${C_BOLD}${C_WHITE}🖥️  VPS DASHBOARD${C_RESET}                                                       ${C_BOLD}${C_PURPLE}║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║${C_RESET}  ${C_DIM}${HOSTNAME}${C_RESET}                                                       ${C_BOLD}${C_PURPLE}║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}╚═══════════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    echo -e "${C_CYAN}┌─────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    printf "${C_CYAN}│${C_RESET} ${C_YELLOW}IP:${C_RESET} ${C_GREEN}%-15s${C_RESET} ${C_YELLOW}Uptime:${C_RESET} %-20s ${C_YELLOW}Load:${C_RESET} %-15s ${C_CYAN}│${C_RESET}\n" "$IP" "$UPTIME" "$LOAD"
    echo -e "${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_CYAN}│${C_RESET} ${C_YELLOW}OS:${C_RESET} %-12s ${C_YELLOW}Kernel:${C_RESET} %-18s ${C_YELLOW}Users:${C_RESET} %-15s ${C_CYAN}│${C_RESET}\n" "$OS" "$KERNEL" "$TOTAL_USERS"
    echo -e "${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_CYAN}│${C_RESET} ${C_YELLOW}CPU:${C_RESET} %-2s cores ${C_YELLOW}RAM:${C_RESET} %-6s/%-6s ${C_CYAN}│${C_RESET}\n" "$CPU_CORES" "$RAM_USED" "$RAM_TOTAL"
    echo -e "${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_CYAN}│${C_RESET} RAM:  %-28s  ${C_CYAN}│${C_RESET}\n" "$(make_bar $RAM_PERCENT)"
    echo -e "${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_CYAN}│${C_RESET} Disk: %-6s/%-6s %-28s  ${C_CYAN}│${C_RESET}\n" "$DISK_USED" "$DISK_TOTAL" "$(make_bar $DISK_PERCENT)"
    echo -e "${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    local sc=""; [[ "$SSH_ST" == "active" ]] && sc="${C_GREEN}● RUNNING${C_RESET}" || sc="${C_RED}● STOPPED${C_RESET}"
    local dc=""; [[ "$DNSTT_ST" == "active" ]] && dc="${C_GREEN}● RUNNING${C_RESET}" || dc="${C_RED}● STOPPED${C_RESET}"
    local ac=""; [[ "$API_ST" == "active" ]] && ac="${C_GREEN}● RUNNING${C_RESET}" || ac="${C_RED}● STOPPED${C_RESET}"
    printf "${C_CYAN}│${C_RESET} SSH: %-15s DNSTT: %-15s API: %-15s ${C_CYAN}│${C_RESET}\n" "$sc" "$dc" "$ac"
    echo -e "${C_CYAN}└─────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    echo -e "${C_DIM}  [Enter] refresh | [0] return${C_RESET}"
    read -p "👉 " rc
    [[ "$rc" != "0" ]] && show_vps_dashboard
}

show_vpn_data_usage() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══ 📊 VPN DATA USAGE ═══${C_RESET}\n"
    [[ ! -s "$DB_FILE" ]] && { echo -e "${C_YELLOW}ℹ️ No users.${C_RESET}"; press_enter; return; }
    printf "${C_BOLD}${C_WHITE}%-15s | %-12s | %-10s${C_RESET}\n" "USERNAME" "USED" "STATUS"
    echo -e "${C_WHITE}──────────────────────────────────────────${C_RESET}"
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" ]] && continue
        local used_bytes=0
        [[ -f "$BANDWIDTH_DIR/${user}.usage" ]] && used_bytes=$(cat "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null)
        [[ -z "$used_bytes" ]] && used_bytes=0
        local used_gb=$(awk "BEGIN {printf \"%.2f\", $used_bytes / 1073741824}")
        local st=$(get_user_status "$user" | sed 's/\x1b\[[0-9;]*m//g')
        printf "${C_WHITE}%-15s${C_RESET} | ${C_YELLOW}%-10s GB${C_RESET} | ${C_GREEN}%s${C_RESET}\n" "$user" "$used_gb" "$st"
    done < "$DB_FILE"
    press_enter
}

auto_reboot_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔄 Auto-Reboot ---${C_RESET}\n"
    local cc=$(crontab -l 2>/dev/null | grep "systemctl reboot")
    local st="${C_RED}Disabled${C_RESET}"
    [[ -n "$cc" ]] && st="${C_GREEN}Active (Daily 00:00)${C_RESET}"
    echo -e "${C_WHITE}Status: ${st}${C_RESET}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} Enable"
    echo -e "  ${C_RED}2)${C_RESET} Disable"
    echo -e "  ${C_RED}0)${C_RESET} Return"
    read -p "👉 Choice: " c
    case $c in
        1) (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab - 2>/dev/null; (crontab -l 2>/dev/null; echo "0 0 * * * systemctl reboot") | crontab - 2>/dev/null; echo -e "${C_GREEN}✅ Enabled${C_RESET}"; press_enter ;;
        2) (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab - 2>/dev/null; echo -e "${C_GREEN}✅ Disabled${C_RESET}"; press_enter ;;
        0) return ;;
    esac
}

enable_cache_cleaner() {
    echo -e "\n${C_BLUE}🔧 ENABLING CACHE CLEANER${C_RESET}"
    touch /var/log/voltron-cache.log 2>/dev/null
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
    press_enter
}

disable_cache_cleaner() {
    rm -f "$CACHE_CRON_FILE" 2>/dev/null
    crontab -l 2>/dev/null | grep -v "voltron-cache-clean" | crontab - 2>/dev/null
    echo -e "${C_GREEN}✅ Disabled${C_RESET}"
    press_enter
}

cache_cleaner_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}           🧹 CACHE CLEANER${C_RESET}\n"
        local st="${C_RED}DISABLED${C_RESET}"
        [ -f "$CACHE_CRON_FILE" ] && st="${C_GREEN}ENABLED${C_RESET}"
        echo -e "  Status: $st\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Enable"
        echo -e "  ${C_RED}2)${C_RESET} Disable"
        echo -e "  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) enable_cache_cleaner ;;
            2) disable_cache_cleaner ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

find_orphan_users() {
    local -a orphans=()
    while IFS=: read -r username _ uid _ _ home shell; do
        [[ "$uid" =~ ^[0-9]+$ ]] || continue
        (( uid >= 1000 )) || continue
        [[ "$home" == "/home/$username" || "$home" == /home/* ]] || continue
        case "$shell" in /usr/sbin/nologin|/usr/bin/false|/bin/false) ;; *) continue ;; esac
        grep -q "^$username:" "$DB_FILE" && continue
        orphans+=("$username")
    done < /etc/passwd
    printf '%s\n' "${orphans[@]}"
}

orphan_cleanup_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}           🔍 ORPHAN CLEANUP${C_RESET}\n"
        mapfile -t orphan_list < <(find_orphan_users)
        if [ ${#orphan_list[@]} -eq 0 ]; then
            echo -e "  ${C_GREEN}✅ No orphans.${C_RESET}"
            press_enter; return
        fi
        echo -e "  ${C_YELLOW}Found ${#orphan_list[@]}:${C_RESET}\n"
        for i in "${!orphan_list[@]}"; do
            printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${orphan_list[$i]}"
        done
        echo ""
        echo -e "  ${C_GREEN}1)${C_RESET} Delete ALL"
        echo -e "  ${C_GREEN}2)${C_RESET} Delete selected"
        echo -e "  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) read -p "Confirm? (y/n): " confirm; [[ "$confirm" == "y" ]] && { delete_voltrontech_user_accounts "${orphan_list[@]}"; echo -e "${C_GREEN}✅ Done${C_RESET}"; }; press_enter ;;
            2) read -p "Numbers: " sel; local -a chosen=(); for n in $sel; do [[ "$n" =~ ^[0-9]+$ ]] && [ "$n" -ge 1 ] && [ "$n" -le "${#orphan_list[@]}" ] && chosen+=("${orphan_list[$((n-1))]}"); done; [ ${#chosen[@]} -gt 0 ] && delete_voltrontech_user_accounts "${chosen[@]}"; press_enter ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

system_utilities_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}              ⚙️  SYSTEM UTILITIES${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} 💾 Backup"
        echo -e "  ${C_GREEN}2)${C_RESET} 📥 Restore"
        echo -e "  ${C_GREEN}3)${C_RESET} 🌐 DNS Manager"
        echo -e "  ${C_GREEN}4)${C_RESET} 🖥️  VPS Dashboard"
        echo -e "  ${C_GREEN}5)${C_RESET} 📊 Data Usage"
        echo -e "  ${C_GREEN}6)${C_RESET} 🔄 Auto Reboot"
        echo -e "  ${C_GREEN}7)${C_RESET} 🧹 Cache Cleaner"
        echo -e "  ${C_GREEN}8)${C_RESET} 🔍 Orphan Cleanup"
        echo -e "  ${C_GREEN}9)${C_RESET} ⚡ Speed Boosters"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) backup_user_data ;;
            2) restore_user_data ;;
            3) dns_menu ;;
            4) show_vps_dashboard ;;
            5) show_vpn_data_usage ;;
            6) auto_reboot_menu ;;
            7) cache_cleaner_menu ;;
            8) orphan_cleanup_menu ;;
            9) dnstt_speed_menu ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

initial_setup() {
    echo -e "\n${C_BLUE}🔧 Initial setup...${C_RESET}\n"
    ff_apt_install curl wget bc iptables openssl dnsutils jq at 2>/dev/null
    mkdir -p "$DB_DIR" "$LOGS_DIR" "$CONFIG_DIR" "$BANDWIDTH_DIR" "$BANNER_DIR" "$DNSTT_KEYS_DIR" "$SSL_CERT_DIR" "$TRAFFIC_DIR" "$BACKUP_DIR"
    touch "$DB_FILE"
    create_limiter_service
    create_traffic_monitor
    systemctl enable atd &>/dev/null; systemctl start atd &>/dev/null
    echo -e "${C_GREEN}✅ Initial setup complete${C_RESET}"
}

uninstall_script() {
    clear; show_banner
    echo -e "${C_RED}       💥 UNINSTALL VOLTRON TECH${C_RESET}\n"
    read -p "⚠️  Type 'YES' to confirm: " confirm
    [[ "$confirm" != "YES" ]] && { echo -e "${C_GREEN}✅ Cancelled.${C_RESET}"; press_enter; return; }
    systemctl stop dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-api voltrontech-limiter voltron-traffic 2>/dev/null
    systemctl disable dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-api voltrontech-limiter voltron-traffic 2>/dev/null
    rm -f "$DNSTT_SERVICE_FILE" "$BADVPN_SERVICE_FILE" "$UDP_CUSTOM_SERVICE_FILE" "$ZIVPN_SERVICE_FILE" "$FALCONPROXY_SERVICE_FILE"
    rm -f "$LIMITER_SERVICE" "$TRAFFIC_SERVICE" /etc/systemd/system/voltrontech-api.service
    systemctl daemon-reload
    rm -f "$DNSTT_BINARY" "$DNSTT_CLIENT" "$BADVPN_BIN" "$UDP_CUSTOM_BIN" "$ZIVPN_BIN" "$FALCONPROXY_BINARY"
    rm -f "$LIMITER_SCRIPT" "$TRAFFIC_SCRIPT" "$CACHE_SCRIPT" "$TRIAL_CLEANUP_SCRIPT"
    rm -rf "$API_DIR" "$DB_DIR" "$ZIVPN_DIR"
    rm -f "$WEB_PANEL_NGINX_CONFIG" "$WEB_PANEL_NGINX_LINK"
    certbot delete --cert-name "$WEB_PANEL_API_DOMAIN" --non-interactive 2>/dev/null
    nginx -t 2>&1 | grep -q "successful" && systemctl reload nginx 2>/dev/null
    rm -f "$SSHD_FF_CONFIG" /etc/ssh/sshd_config.d/voltron-auto-banner.conf
    rm -f /etc/cron.d/voltron-cache-clean
    crontab -l 2>/dev/null | grep -v "voltron" | crontab - 2>/dev/null
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    echo -e "\n${C_GREEN}✅ UNINSTALLED${C_RESET}"
    sleep 2
    rm -f "$0"
    exit 0
}

main_menu() {
    while true; do
        show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    👤 USER MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "1" "Create User" "7" "List Users"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "2" "Delete User" "8" "Renew User"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "3" "Edit User" "9" "Cleanup Expired"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "4" "Lock User" "10" "Bulk Create"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "5" "Unlock User" "11" "View Bandwidth"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "6" "Trial Account" "12" "Orphan Cleanup"
        echo ""
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    🔌 PROTOCOLS & SERVICES${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "13" "Protocol Management" "17" "Dynamic Banner"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "14" "DNSTT Management" "18" "Web Panel"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "15" "Speed Boosters" "19" "System Utilities"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "16" "VPS Dashboard" "20" "Restart All Services"
        echo ""
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    🔥 DANGER ZONE${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_RED}%2s${C_RESET}) %-28s  ${C_RED}%2s${C_RESET}) %-25s\n" "99" "Uninstall Script" "0" "Exit"
        echo ""
        read -p "👉 Select option: " choice
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
            12) orphan_cleanup_menu ;;
            13) protocol_menu ;;
            14) dnstt_main_menu ;;
            15) dnstt_speed_menu ;;
            16) show_vps_dashboard ;;
            17) ssh_banner_menu ;;
            18) web_panel_menu ;;
            19) system_utilities_menu ;;
            20) echo -e "\n${C_BLUE}🔄 Restarting...${C_RESET}"; systemctl restart dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-limiter voltron-traffic voltrontech-api 2>/dev/null; echo -e "${C_GREEN}✅ Done${C_RESET}"; press_enter ;;
            99) uninstall_script ;;
            0) echo -e "\n${C_GREEN}👋 Goodbye!${C_RESET}\n"; exit 0 ;;
            *) echo -e "\n${C_RED}❌ Invalid${C_RESET}"; sleep 2 ;;
        esac
    done
}

if [[ $EUID -ne 0 ]]; then
    echo -e "${C_RED}❌ Run as root!${C_RESET}"
    exit 1
fi

if [[ "$1" == "--install-setup" ]]; then
    initial_setup
    exit 0
fi

if [[ ! -f "$INSTALL_FLAG_FILE" ]]; then
    initial_setup
    touch "$INSTALL_FLAG_FILE"
fi

main_menu
