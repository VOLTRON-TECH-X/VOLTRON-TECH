#!/bin/bash
# ================================================================
# VOLTRON TECH ULTIMATE v11.0 - WITH API MANAGEMENT
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

# ========== VARIABLES ==========
DESEC_TOKEN="3WxD4Hkiu5VYBLWVizVhf1rzyKbz"
DESEC_DOMAIN="voltrontechtx.shop"
DB_DIR="/etc/voltrontech"
DB_FILE="$DB_DIR/users.db"
INSTALL_FLAG_FILE="$DB_DIR/.install"
LOGS_DIR="$DB_DIR/logs"
CONFIG_DIR="$DB_DIR/config"
BANDWIDTH_DIR="$DB_DIR/bandwidth"
BANNER_DIR="$DB_DIR/banners"
DNSTT_KEYS_DIR="$DB_DIR/dnstt"
SSL_CERT_DIR="$DB_DIR/ssl"
TRAFFIC_DIR="$DB_DIR/traffic"
BACKUP_DIR="$DB_DIR/backups"
MTU_CONFIG="$CONFIG_DIR/mtu"
DNSTT_SERVICE_FILE="/etc/systemd/system/dnstt.service"
DNSTT_BINARY="/usr/local/bin/dnstt-server"
DNSTT_CLIENT="/usr/local/bin/dnstt-client"
DNSTT_CONFIG_FILE="$DB_DIR/dnstt_info.conf"
DNS_INFO_FILE="$DB_DIR/dns_info.conf"
BADVPN_SERVICE_FILE="/etc/systemd/system/badvpn.service"
BADVPN_BIN="/usr/local/bin/badvpn-udpgw"
BADVPN_BUILD_DIR="/root/badvpn-build"
UDP_CUSTOM_SERVICE_FILE="/etc/systemd/system/udp-custom.service"
UDP_CUSTOM_BIN="/usr/local/bin/udp-custom"
HAPROXY_CONFIG="/etc/haproxy/haproxy.cfg"
SSL_CERT_FILE="$SSL_CERT_DIR/voltrontech.pem"
FALCONPROXY_SERVICE_FILE="/etc/systemd/system/falconproxy.service"
FALCONPROXY_BINARY="/usr/local/bin/falconproxy"
FALCONPROXY_CONFIG_FILE="$DB_DIR/falconproxy_config.conf"
ZIVPN_DIR="/etc/zivpn"
ZIVPN_BIN="/usr/local/bin/zivpn"
ZIVPN_SERVICE_FILE="/etc/systemd/system/zivpn.service"
ZIVPN_CONFIG_FILE="$ZIVPN_DIR/config.json"
LIMITER_SCRIPT="/usr/local/bin/voltrontech-limiter.sh"
LIMITER_SERVICE="/etc/systemd/system/voltrontech-limiter.service"
SSHD_FF_CONFIG="/etc/ssh/sshd_config.d/voltrontech.conf"
SSH_BANNER_FILE="/etc/bannerssh"
BANNER_ENABLED_FILE="$DB_DIR/banners_enabled"
TRIAL_CLEANUP_SCRIPT="/usr/local/bin/voltrontech-trial-cleanup.sh"
FF_USERS_GROUP="ffusers"
SELECTED_USER=""
SELECTED_USERS=()
UNINSTALL_MODE="interactive"
API_PORT="5000"
API_DIR="/opt/voltrontech-api"
API_KEY_FILE="$DB_DIR/api_key.txt"
API_INFO_FILE="$DB_DIR/api_info.txt"

# ========== APT FUNCTIONS ==========
ff_apt_update() { DEBIAN_FRONTEND=noninteractive apt-get update 2>/dev/null || true; }
ff_apt_install() { ff_apt_update; DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 install "$@"; }
ff_apt_purge() { DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 purge "$@"; }

# ========== BANNER CACHE ==========
BANNER_CACHE_TTL=15
BANNER_CACHE_TS=0
BANNER_CACHE_OS_NAME=""
BANNER_CACHE_UP_TIME=""
BANNER_CACHE_RAM_USAGE=""
BANNER_CACHE_CPU_LOAD=""
BANNER_CACHE_ONLINE_USERS=0
BANNER_CACHE_TOTAL_USERS=0
SSH_SESSION_CACHE_TTL=10
SSH_SESSION_CACHE_TS=0
SSH_SESSION_CACHE_DB_MTIME=0
SSH_SESSION_TOTAL=0
declare -A SSH_SESSION_COUNTS=()
declare -A SSH_SESSION_PIDS=()

refresh_ssh_session_cache() {
    local now db_mtime
    now=$(date +%s)
    db_mtime=$(stat -c %Y "$DB_FILE" 2>/dev/null || echo 0)
    if (( SSH_SESSION_CACHE_TS > 0 && now - SSH_SESSION_CACHE_TS < SSH_SESSION_CACHE_TTL && db_mtime == SSH_SESSION_CACHE_DB_MTIME )); then return; fi
    SSH_SESSION_COUNTS=(); SSH_SESSION_PIDS=(); SSH_SESSION_TOTAL=0
    SSH_SESSION_CACHE_DB_MTIME=$db_mtime
    if [[ ! -s "$DB_FILE" ]]; then SSH_SESSION_CACHE_TS=$now; return; fi
    local -A managed_user_lookup=(); local -A uid_user_lookup=(); local -A seen_sessions=()
    while IFS=: read -r managed_user _rest; do [[ -n "$managed_user" && "$managed_user" != \#* ]] && managed_user_lookup["$managed_user"]=1; done < "$DB_FILE"
    while IFS=: read -r system_user _ system_uid _rest; do [[ -n "$system_user" && "$system_uid" =~ ^[0-9]+$ ]] && uid_user_lookup["$system_uid"]="$system_user"; done < /etc/passwd
    while read -r ssh_pid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue
        candidate_user=""
        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" && -n "${managed_user_lookup[$ssh_owner]+x}" ]]; then candidate_user="$ssh_owner"
        elif [[ -r "/proc/$ssh_pid/loginuid" ]]; then
            local login_uid=""; read -r login_uid < "/proc/$ssh_pid/loginuid" || login_uid=""
            if [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]]; then candidate_user="${uid_user_lookup[$login_uid]}"; fi
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
count_managed_online_sessions() { refresh_ssh_session_cache; echo "$SSH_SESSION_TOTAL"; }
refresh_banner_cache() {
    local now=$(date +%s)
    if (( BANNER_CACHE_TS > 0 && now - BANNER_CACHE_TS < BANNER_CACHE_TTL )); then return; fi
    BANNER_CACHE_OS_NAME=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Linux")
    BANNER_CACHE_UP_TIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    BANNER_CACHE_RAM_USAGE=$(free -m | awk '/^Mem:/{if($2>0){printf "%.2f", $3*100/$2}else{print "0.00"}}')
    BANNER_CACHE_CPU_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null)
    if [[ -s "$DB_FILE" ]]; then BANNER_CACHE_TOTAL_USERS=$(grep -c . "$DB_FILE"); else BANNER_CACHE_TOTAL_USERS=0; fi
    BANNER_CACHE_ONLINE_USERS=$(count_managed_online_sessions)
    BANNER_CACHE_TS=$now
}
show_banner() {
    refresh_banner_cache
    [[ -t 1 ]] && clear
    echo
    echo -e "${C_TITLE}   VOLTRON TECH ULTIMATE v11.0 ${C_RESET}${C_DIM}| Premium Edition${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "OS" "$BANNER_CACHE_OS_NAME" "Uptime: $BANNER_CACHE_UP_TIME"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Memory" "${BANNER_CACHE_RAM_USAGE}% Used" "Online: ${C_WHITE}${BANNER_CACHE_ONLINE_USERS}${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Users" "${BANNER_CACHE_TOTAL_USERS} Managed" "Load: ${C_GREEN}${BANNER_CACHE_CPU_LOAD}${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
}
press_enter() { echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to continue..." && read -r; }

# ========== ORPHAN USER FUNCTIONS ==========
is_voltrontech_orphan_user() {
    local username="$1"
    local passwd_line system_user _ uid _ home shell
    passwd_line=$(getent passwd "$username" 2>/dev/null) || return 1
    IFS=: read -r system_user _ uid _ _ home shell <<< "$passwd_line"
    [[ "$uid" =~ ^[0-9]+$ ]] || return 1
    grep -q "^$username:" "$DB_FILE" && return 1
    if id -nG "$username" 2>/dev/null | tr ' ' '\n' | grep -Fxq "$FF_USERS_GROUP"; then return 0; fi
    (( uid >= 1000 )) || return 1
    [[ "$home" == "/home/$username" || "$home" == /home/* ]] || return 1
    case "$shell" in /usr/sbin/nologin|/usr/bin/false|/bin/false) return 0 ;; esac
    return 1
}
get_voltrontech_orphan_users() {
    local username
    while IFS=: read -r username _rest; do
        [[ -n "$username" ]] || continue
        if is_voltrontech_orphan_user "$username"; then echo "$username"; fi
    done < /etc/passwd
}
get_voltrontech_known_users() {
    local username
    local -A seen_users=()
    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r username _rest; do
            [[ -n "$username" && "$username" != \#* ]] || continue
            seen_users["$username"]=1
        done < "$DB_FILE"
    fi
    while IFS= read -r username; do [[ -n "$username" ]] && seen_users["$username"]=1; done < <(get_voltrontech_orphan_users)
    (( ${#seen_users[@]} > 0 )) || return 0
    printf "%s\n" "${!seen_users[@]}" | sort
}
delete_voltrontech_user_accounts() {
    local -a users_to_delete=("$@")
    local username
    [[ ${#users_to_delete[@]} -gt 0 ]] || return 0
    for username in "${users_to_delete[@]}"; do
        [[ -n "$username" ]] || continue
        killall -u "$username" -9 &>/dev/null
        if id "$username" &>/dev/null; then
            if userdel -r "$username" &>/dev/null; then echo -e " ✅ System user '${C_YELLOW}$username${C_RESET}' deleted."
            else echo -e " ❌ Failed to delete system user '${C_YELLOW}$username${C_RESET}'."; fi
        else echo -e " ℹ️ System user '${C_YELLOW}$username${C_RESET}' was already missing."; fi
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
invalidate_banner_cache() { BANNER_CACHE_TS=0; SSH_SESSION_CACHE_TS=0; }

# ========== USER SELECTION ==========
_select_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    if [[ ! -s $DB_FILE ]]; then echo -e "${C_YELLOW}ℹ️ No users found.${C_RESET}"; SELECTED_USER="NO_USERS"; return; fi
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Enter search term (or Enter for all): " search_term
        if [[ -n "$search_term" ]]; then mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term"); else users=("${all_users[@]}"); fi
    else users=("${all_users[@]}"); fi
    if [ ${#users[@]} -eq 0 ]; then echo -e "\n${C_YELLOW}ℹ️ No users found.${C_RESET}"; SELECTED_USER="NO_USERS"; return; fi
    echo -e "\nPlease select a user:\n"
    for i in "${!users[@]}"; do printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"; done
    echo -e "\n  ${C_RED} [ 0]${C_RESET} ↩️ Cancel"
    echo
    local choice
    while true; do
        read -p "👉 Enter number: " choice
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
    if [[ ! -s $DB_FILE ]]; then echo -e "${C_YELLOW}ℹ️ No users found.${C_RESET}"; SELECTED_USERS=("NO_USERS"); return; fi
    mapfile -t all_users < <(cut -d: -f1 "$DB_FILE" | sort)
    if [ ${#all_users[@]} -ge 15 ]; then
        read -p "👉 Enter search term (or Enter for all): " search_term
        if [[ -n "$search_term" ]]; then mapfile -t users < <(printf "%s\n" "${all_users[@]}" | grep -i "$search_term"); else users=("${all_users[@]}"); fi
    else users=("${all_users[@]}"); fi
    if [ ${#users[@]} -eq 0 ]; then echo -e "\n${C_YELLOW}ℹ️ No users found.${C_RESET}"; SELECTED_USERS=("NO_USERS"); return; fi
    echo -e "\nPlease select users:\n"
    for i in "${!users[@]}"; do printf "  ${C_GREEN}[%2d]${C_RESET} %s\n" "$((i+1))" "${users[$i]}"; done
    echo -e "\n  ${C_GREEN}[all]${C_RESET} Select ALL"
    echo -e "  ${C_RED}  [0]${C_RESET} ↩️ Cancel"
    echo
    local choice
    while true; do
        read -p "👉 Enter numbers: " choice
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

# ========== USER STATUS ==========
get_user_status() {
    local username="$1"
    if ! id "$username" &>/dev/null; then echo -e "${C_RED}Not Found${C_RESET}"; return; fi
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    if passwd -S "$username" 2>/dev/null | grep -q " L "; then echo -e "${C_YELLOW}🔒 Locked${C_RESET}"; return; fi
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    if [[ $expiry_ts -lt $current_ts ]]; then echo -e "${C_RED}🗓️ Expired${C_RESET}"; return; fi
    local bandwidth_gb=$(grep "^$username:" "$DB_FILE" | cut -d: -f5)
    if [[ -n "$bandwidth_gb" && "$bandwidth_gb" != "0" ]]; then
        local used_bytes=0
        if [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then used_bytes=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null); [[ -z "$used_bytes" ]] && used_bytes=0; fi
        local quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        if [[ "$used_bytes" -ge "$quota_bytes" ]]; then echo -e "${C_RED}📦 Exceeded${C_RESET}"; return; fi
    fi
    echo -e "${C_GREEN}🟢 Active${C_RESET}"
}

# ========== GENERATE BANNER ==========
generate_user_banner() {
    local username="$1"; local expiry="$2"; local limit="$3"; local bandwidth_gb="$4"
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


# ========== CREATE USER ==========
create_user() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Create New SSH User ---${C_RESET}"
    read -p "👉 Username (or '0' to cancel): " username
    [[ "$username" == "0" ]] && { echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; press_enter; return; }
    [[ -z "$username" ]] && { echo -e "\n${C_RED}❌ Empty.${C_RESET}"; press_enter; return; }
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then echo -e "\n${C_RED}❌ Exists.${C_RESET}"; press_enter; return; fi
    local password=""
    while true; do
        read -p "🔑 Password (Enter for auto): " password
        if [[ -z "$password" ]]; then password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8); echo -e "${C_GREEN}🔑 Generated: ${C_YELLOW}$password${C_RESET}"; break; else break; fi
    done
    read -p "🗓️ Duration (days) [30]: " days; days=${days:-30}
    [[ ! "$days" =~ ^[0-9]+$ ]] && { echo -e "${C_RED}❌ Invalid.${C_RESET}"; press_enter; return; }
    read -p "📶 Connection limit [1]: " limit; limit=${limit:-1}
    read -p "📦 Bandwidth GB (0=unlimited) [0]: " bandwidth_gb; bandwidth_gb=${bandwidth_gb:-0}
    local expire_date=$(date -d "+$days days" +%Y-%m-%d)
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb" >> "$DB_FILE"
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

# ========== DELETE USER ==========
delete_user() {
    _select_multi_user_interface "--- 🗑️ Delete Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    echo -e "\n${C_RED}⚠️ Delete ${#SELECTED_USERS[@]} user(s)?${C_RESET}"
    read -p "👉 Confirm (y/n): " confirm
    [[ "$confirm" != "y" ]] && { echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; press_enter; return; }
    delete_voltrontech_user_accounts "${SELECTED_USERS[@]}"
    press_enter
}

# ========== EDIT USER ==========
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
            1) read -p "New password: " new_pass; [[ -z "$new_pass" ]] && new_pass=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8); echo "$username:$new_pass" | chpasswd; sed -i "s/^$username:.*/$username:$new_pass:$cur_expiry:$cur_limit:$cur_bw/" "$DB_FILE"; echo -e "${C_GREEN}✅ Pass: $new_pass${C_RESET}"; press_enter ;;
            2) read -p "New days: " days; if [[ "$days" =~ ^[0-9]+$ ]]; then new_exp=$(date -d "+$days days" +%Y-%m-%d); chage -E "$new_exp" "$username"; sed -i "s/^$username:.*/$username:$cur_pass:$new_exp:$cur_limit:$cur_bw/" "$DB_FILE"; echo -e "${C_GREEN}✅ $new_exp${C_RESET}"; fi; press_enter ;;
            3) read -p "New limit: " nl; [[ "$nl" =~ ^[0-9]+$ ]] && { sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$nl:$cur_bw/" "$DB_FILE"; echo -e "${C_GREEN}✅ $nl${C_RESET}"; }; press_enter ;;
            4) read -p "New BW: " nb; [[ "$nb" =~ ^[0-9]+\.?[0-9]*$ ]] && { sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$nb/" "$DB_FILE"; echo -e "${C_GREEN}✅ $nb${C_RESET}"; }; press_enter ;;
            5) echo "0" > "$BANDWIDTH_DIR/${username}.usage"; usermod -U "$username" &>/dev/null; echo -e "${C_GREEN}✅ Reset${C_RESET}"; press_enter ;;
            0) return ;;
        esac
    done
}

# ========== LOCK USER ==========
lock_user() {
    _select_multi_user_interface "--- 🔒 Lock Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then echo -e " ❌ $u missing"; continue; fi
        usermod -L "$u" && killall -u "$u" -9 &>/dev/null && echo -e " ✅ ${C_YELLOW}$u${C_RESET} locked"
    done
    press_enter
}

# ========== UNLOCK USER ==========
unlock_user() {
    _select_multi_user_interface "--- 🔓 Unlock Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    for u in "${SELECTED_USERS[@]}"; do
        if ! id "$u" &>/dev/null; then echo -e " ❌ $u missing"; continue; fi
        usermod -U "$u" && echo -e " ✅ ${C_YELLOW}$u${C_RESET} unlocked"
    done
    press_enter
}

# ========== LIST USERS ==========
list_users() {
    clear; show_banner
    [[ ! -s "$DB_FILE" ]] && { echo -e "\n${C_YELLOW}ℹ️ No users.${C_RESET}"; press_enter; return; }
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}                      📋 MANAGED USERS${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    local user_count=0
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" ]] && continue
        ((user_count++))
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
    echo -e "${C_DIM}Total: ${C_WHITE}$(grep -c . "$DB_FILE")${C_RESET} | Online: ${C_WHITE}$(count_managed_online_sessions)${C_RESET}"
    press_enter
}

# ========== RENEW USER ==========
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
        sed -i "s/^$u:.*/$u:$pass:$new_expire_date:$limit:$bw/" "$DB_FILE"
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} → ${C_GREEN}$new_expire_date${C_RESET}"
    done
    press_enter
}

# ========== CLEANUP EXPIRED ==========
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
        for user in "${expired_users[@]}"; do
            killall -u "$user" -9 &>/dev/null
            rm -f "$BANDWIDTH_DIR/${user}.usage"
            rm -rf "$BANDWIDTH_DIR/pidtrack/${user}"
            userdel -r "$user" &>/dev/null
            sed -i "/^$user:/d" "$DB_FILE"
        done
        echo -e "\n${C_GREEN}✅ Cleaned.${C_RESET}"
    else echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; fi
    invalidate_banner_cache; update_ssh_banners_config
    press_enter
}

# ========== BULK CREATE ==========
bulk_create_users() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👥 Bulk Create Users ---${C_RESET}"
    read -p "👉 Prefix: " prefix
    [[ -z "$prefix" ]] && { echo -e "${C_RED}❌ Empty.${C_RESET}"; press_enter; return; }
    read -p "🔢 Count: " count
    [[ ! "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]] || [[ "$count" -gt 100 ]] && { echo -e "${C_RED}❌ 1-100.${C_RESET}"; press_enter; return; }
    read -p "🗓️ Days [30]: " days; days=${days:-30}
    read -p "📶 Limit [1]: " limit; limit=${limit:-1}
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
        echo "$username:$password:$expire_date:$limit:$bandwidth_gb" >> "$DB_FILE"
        [[ -f "$BANNER_ENABLED_FILE" ]] && generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$username" "$password" "$expire_date"
        ((created++))
    done
    [[ -f "$BANNER_ENABLED_FILE" ]] && update_ssh_banners_config
    echo -e "\n${C_GREEN}✅ Created $created users.${C_RESET}"
    invalidate_banner_cache
    press_enter
}

# ========== VIEW BANDWIDTH ==========
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

# ========== GENERATE CLIENT CONFIG ==========
generate_client_config() {
    local user=$1; local pass=$2
    local host_ip=$(curl -s -4 icanhazip.com 2>/dev/null || echo "unknown")
    local host_domain="$host_ip"
    [ -f "$DB_DIR/domain.txt" ] && host_domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
    echo -e "\n${C_BOLD}${C_PURPLE}--- 📱 Client Config ---${C_RESET}\n"
    echo -e "${C_YELLOW}========================${C_RESET}"
    echo -e "👤 User: ${C_WHITE}$user${C_RESET}"
    echo -e "🔑 Pass: ${C_WHITE}$pass${C_RESET}"
    echo -e "🌐 Host: ${C_WHITE}$host_domain${C_RESET}"
    echo -e "${C_YELLOW}========================${C_RESET}"
    echo -e "\n🔹 ${C_BOLD}SSH:${C_RESET}"
    echo -e "   Host: $host_domain"
    echo -e "   Port: 22"
    if systemctl is-active --quiet haproxy 2>/dev/null; then
        local hp=$(grep -oP 'bind \*:(\d+)' /etc/haproxy/haproxy.cfg 2>/dev/null | awk -F: '{print $2}' | head -1)
        [[ -n "$hp" ]] && echo -e "\n🔹 ${C_BOLD}SSL:${C_RESET}\n   Host: $host_domain\n   Port: $hp"
    fi
    if systemctl is-active --quiet udp-custom 2>/dev/null; then
        echo -e "\n🔹 ${C_BOLD}UDP Custom:${C_RESET}\n   IP: $host_ip\n   Port: 1-65535 (exclude 53,5300)"
    fi
    if systemctl is-active --quiet dnstt 2>/dev/null; then
        if [ -f "$DNSTT_CONFIG_FILE" ]; then
            source "$DNSTT_CONFIG_FILE"
            echo -e "\n🔹 ${C_BOLD}DNSTT:${C_RESET}\n   Domain: $TUNNEL_DOMAIN\n   PubKey: $PUBLIC_KEY\n   MTU: $MTU_VALUE"
        fi
    fi
    echo -e "${C_YELLOW}========================${C_RESET}"
    press_enter
}
client_config_menu() {
    _select_user_interface "--- 📱 Client Config ---"
    local u=$SELECTED_USER
    [[ "$u" == "NO_USERS" || -z "$u" ]] && { press_enter; return; }
    local pass=$(grep "^$u:" "$DB_FILE" | cut -d: -f2)
    generate_client_config "$u" "$pass"
}


# ========== TRIAL ACCOUNT ==========
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
    read -p "📶 Limit [1]: " limit; limit=${limit:-1}
    read -p "📦 BW GB [0]: " bandwidth_gb; bandwidth_gb=${bandwidth_gb:-0}
    local expire_date
    if [[ "$duration_hours" -ge 24 ]]; then expire_date=$(date -d "+$((duration_hours/24)) days" +%Y-%m-%d); else expire_date=$(date -d "+1 day" +%Y-%m-%d); fi
    local expiry_timestamp=$(date -d "+${duration_hours} hours" '+%Y-%m-%d %H:%M:%S')
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    useradd -m -s /usr/sbin/nologin "$username"
    usermod -aG "$FF_USERS_GROUP" "$username" 2>/dev/null
    echo "$username:$password" | chpasswd
    chage -E "$expire_date" "$username"
    echo "$username:$password:$expire_date:$limit:$bandwidth_gb" >> "$DB_FILE"
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

# ========== DNSTT MTU ==========
get_current_mtu() { [ -f "$MTU_CONFIG" ] && cat "$MTU_CONFIG" || echo "512"; }
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
dnstt_mtu_menu() {
    while true; do
        clear; show_banner
        local cm=$(get_current_mtu)
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           📡 DNSTT MTU CONFIG${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}Current:${C_RESET} ${C_YELLOW}$cm${C_RESET}\n"
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
            6) read -p "MTU: " cm; set_dnstt_mtu "$cm"; press_enter ;;
            0) return ;;
        esac
    done
}

# ========== FIREWALL ==========
configure_dnstt_firewall() {
    echo -e "\n${C_BLUE}🔥 Configuring firewall...${C_RESET}"
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
    echo -e "${C_GREEN}✅ Firewall configured${C_RESET}"
}

# ========== SSH OPTIMIZATIONS ==========
apply_ssh_optimizations() {
    echo -e "\n${C_BLUE}🔧 SSH Optimizations...${C_RESET}"
    mkdir -p /etc/ssh/ssh_config.d
    cat > /etc/ssh/ssh_config.d/voltrontech-ssh.conf << 'EOF'
Host *
    ControlMaster auto
    ControlPath ~/.ssh/control-%r@%h:%p
    ControlPersist 10m
    Compression yes
    CompressionLevel 9
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF
    cat > /etc/ssh/sshd_config.d/voltrontech-sshd.conf << 'EOF'
MaxSessions 100
MaxStartups 100:30:200
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 3
UseDNS no
PrintMotd no
EOF
    for h in /home/*; do
        [[ -d "$h" ]] && { local u=$(basename "$h"); mkdir -p "$h/.ssh"; chown "$u":"$u" "$h/.ssh" 2>/dev/null; chmod 700 "$h/.ssh"; }
    done
    mkdir -p /root/.ssh; chmod 700 /root/.ssh
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    echo -e "${C_GREEN}✅ SSH optimized${C_RESET}"
}

# ========== SPEED BOOSTERS ==========
apply_booster_standard_ultimate() {
    echo -e "\n${C_BLUE}⚡ Standard Booster (1000x)${C_RESET}"
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
    echo -e "\n${C_BLUE}⚡ Medium Booster (2000x)${C_RESET}"
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
    echo -e "\n${C_BLUE}⚡ High Booster (3000x)${C_RESET}"
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
    echo -e "\n${C_BLUE}🚀 Ultra Booster (5000x)${C_RESET}"
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
    echo -e "\n${C_BLUE}💥 Extreme Booster (10000x)${C_RESET}"
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

# ========== DNSTT OPTIMIZATIONS ==========
apply_multiplexing() {
    local num=${1:-3}
    local domain=$(cat /etc/voltrontech/domain.txt 2>/dev/null)
    [[ -z "$domain" ]] && return 1
    pkill -f dnstt-client 2>/dev/null
    ! command -v screen &>/dev/null && apt-get install screen -y 2>/dev/null
    local resolvers=("8.8.8.8:53" "1.1.1.1:53" "9.9.9.9:53")
    for i in $(seq 1 $num); do
        local resolver=${resolvers[$((i-1))]}
        screen -dmS "dnstt_$i" dnstt-client -udp "$resolver" -pubkey-file /etc/voltrontech/dnstt/server.pub -mtu 512 "$domain" 127.0.0.1:22 2>/dev/null
    done
    echo -e "${C_GREEN}✅ Multiplexing started${C_RESET}"
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


# ========== DNSTT DOMAIN ==========
set_custom_dnstt_domain() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Set Custom DNSTT Domain ---${C_RESET}"
    [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ DNSTT not installed.${C_RESET}"; press_enter; return; }
    local cd=$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo "Not set")
    echo -e "\n${C_CYAN}Current: ${C_YELLOW}$cd${C_RESET}\n"
    read -p "👉 New domain: " new_domain
    [[ -z "$new_domain" ]] && { echo -e "${C_RED}❌ Empty.${C_RESET}"; press_enter; return; }
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
    systemctl is-active --quiet dnstt.service && echo -e "\n${C_GREEN}✅ Domain: $new_domain${C_RESET}" || echo -e "\n${C_RED}❌ Failed${C_RESET}"
    press_enter
}
change_dnstt_domain() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 Auto-Generate Domain ---${C_RESET}"
    [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ DNSTT not installed.${C_RESET}"; press_enter; return; }
    [ -f "$DB_DIR/domain.txt" ] && { local old=$(cat "$DB_DIR/domain.txt"); local olds=$(echo "$old" | cut -d. -f1); curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$olds/NS/" -H "Authorization: Token $DESEC_TOKEN" >/dev/null 2>&1; }
    local rand=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 3)
    local ns_sub="ns-$rand"; local tun_sub="tun-$rand"
    local ip=$(curl -s -4 icanhazip.com)
    echo -e "\n${C_BLUE}🔄 Generating...${C_RESET}"
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
        echo -e "\n${C_GREEN}✅ Domain: $new_domain${C_RESET}"
    else echo -e "\n${C_RED}❌ HTTP: $http${C_RESET}"; fi
    press_enter
}

# ========== DNSTT PUBLIC KEY ==========
set_custom_dnstt_public_key() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔑 Set Custom Public Key ---${C_RESET}"
    [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ DNSTT not installed.${C_RESET}"; press_enter; return; }
    local cp=$(cat "$DNSTT_KEYS_DIR/server.pub" 2>/dev/null || echo "Not set")
    echo -e "\n${C_CYAN}Current:${C_RESET}\n${C_YELLOW}$cp${C_RESET}\n"
    read -p "👉 New public key: " custom_pubkey
    [[ -z "$custom_pubkey" ]] && { echo -e "${C_RED}❌ Empty.${C_RESET}"; press_enter; return; }
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
    echo -e "${C_BOLD}${C_PURPLE}--- 🔑 Regenerate Keys ---${C_RESET}"
    [ ! -f "$DNSTT_SERVICE_FILE" ] && { echo -e "\n${C_RED}❌ DNSTT not installed.${C_RESET}"; press_enter; return; }
    [ ! -f "$DNSTT_BINARY" ] && { echo -e "\n${C_RED}❌ Binary missing.${C_RESET}"; press_enter; return; }
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

# ========== DNSTT VIEW DETAILS ==========
show_dnstt_full_details() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📡 DNSTT Details ---${C_RESET}"
    [ ! -f "$DB_DIR/domain.txt" ] && { echo -e "\n${C_YELLOW}DNSTT not installed${C_RESET}"; press_enter; return; }
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

# ========== DNSTT MAIN MENU ==========
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
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}Status:${C_RESET} $st"
        echo -e "  ${C_CYAN}Domain:${C_RESET} ${C_YELLOW}$cd${C_RESET}"
        echo -e "  ${C_CYAN}MTU:${C_RESET} ${C_YELLOW}$cm${C_RESET}"
        echo -e "  ${C_CYAN}Public Key:${C_RESET} ${C_GREEN}${cp:0:35}...${C_RESET}"
        echo ""
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
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    🌐 DOMAIN MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "\n  ${C_CYAN}Current:${C_RESET} ${C_YELLOW}$cd${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Set Custom Domain"
        echo -e "  ${C_GREEN}2)${C_RESET} Auto-Generate Domain"
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
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    🔑 PUBLIC KEY MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "\n  ${C_CYAN}Current:${C_RESET}\n  ${C_GREEN}$cp${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Set Custom Public Key"
        echo -e "  ${C_GREEN}2)${C_RESET} Regenerate Keys (Auto)"
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
dnstt_speed_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    ⚡ SPEED BOOSTERS${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}[1]${C_RESET} Standard (1000x)"
        echo -e "  ${C_GREEN}[2]${C_RESET} Medium (2000x)"
        echo -e "  ${C_GREEN}[3]${C_RESET} High (3000x)"
        echo -e "  ${C_GREEN}[4]${C_RESET} Ultra (5000x)"
        echo -e "  ${C_GREEN}[5]${C_RESET} Extreme (10000x)"
        echo -e "\n  ${C_RED}[0]${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) apply_booster_standard_ultimate; press_enter ;;
            2) apply_booster_medium_ultimate; press_enter ;;
            3) apply_booster_high_ultimate; press_enter ;;
            4) apply_booster_ultra_ultimate; press_enter ;;
            5) apply_booster_extreme_ultimate; press_enter ;;
            0) return ;;
        esac
    done
}

# ========== DNSTT INSTALLATION ==========
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
    echo -e "${C_GREEN}✅ Service created${C_RESET}"
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
uninstall_dnstt() {
    echo -e "\n${C_BLUE}🗑️ Uninstalling DNSTT...${C_RESET}"
    systemctl stop dnstt.service 2>/dev/null; systemctl disable dnstt.service 2>/dev/null
    rm -f "$DNSTT_SERVICE_FILE" "$DNSTT_BINARY" "$DNSTT_CLIENT"
    rm -f "$DNSTT_KEYS_DIR/server.key" "$DNSTT_KEYS_DIR/server.pub"
    rm -f "$DB_DIR/domain.txt" "$DNSTT_CONFIG_FILE" "$MTU_CONFIG"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ DNSTT uninstalled${C_RESET}"
    press_enter
}
install_dnstt() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}           📡 DNSTT INSTALLATION${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    [ -f "$DNSTT_SERVICE_FILE" ] && { read -p "Reinstall? (y/n): " r; [[ "$r" != "y" ]] && return; systemctl stop dnstt.service 2>/dev/null; }
    echo -e "\n${C_BLUE}[1/7] Dependencies...${C_RESET}"
    ff_apt_install wget curl openssl bc dnsutils
    echo -e "\n${C_BLUE}[2/7] Downloading binary...${C_RESET}"
    download_dnstt_binary
    echo -e "\n${C_BLUE}[3/7] MTU...${C_RESET}"
    read -p "👉 MTU [512]: " MTU; MTU=${MTU:-512}
    echo "$MTU" > "$MTU_CONFIG"
    echo -e "\n${C_BLUE}[4/7] Domain...${C_RESET}"
    setup_domain
    echo -e "\n${C_BLUE}[5/7] Generating keys...${C_RESET}"
    generate_keys
    echo -e "\n${C_BLUE}[6/7] Speed Booster...${C_RESET}"
    echo -e "  ${C_GREEN}[1]${C_RESET} 1000x  ${C_GREEN}[2]${C_RESET} 2000x  ${C_GREEN}[3]${C_RESET} 3000x  ${C_GREEN}[4]${C_RESET} 5000x  ${C_GREEN}[5]${C_RESET} 10000x  ${C_GREEN}[6]${C_RESET} Skip"
    read -p "👉 [3]: " b; b=${b:-3}
    case $b in 1) apply_booster_standard_ultimate ;; 2) apply_booster_medium_ultimate ;; 3) apply_booster_high_ultimate ;; 4) apply_booster_ultra_ultimate ;; 5) apply_booster_extreme_ultimate ;; esac
    echo -e "\n${C_BLUE}[7/7] Creating service...${C_RESET}"
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    create_dnstt_service "$DOMAIN" "$MTU" "$SSH_PORT"
    save_dnstt_info "$DOMAIN" "$PUBLIC_KEY" "$MTU" "$SSH_PORT"
    configure_dnstt_firewall
    apply_multiplexing 3
    apply_buffer_optimization; apply_bbr; apply_network_tuning; apply_dns_caching
    systemctl start dnstt.service; sleep 2
    systemctl is-active --quiet dnstt.service && echo -e "\n${C_GREEN}✅ Service running${C_RESET}" || journalctl -u dnstt.service -n 20 --no-pager
    show_client_commands "$DOMAIN" "$MTU" "$SSH_PORT"
    press_enter
}

# ========== PROTOCOLS ==========
install_badvpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing badvpn ---${C_RESET}"
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
    echo -e "${C_GREEN}✅ badvpn on port 7300${C_RESET}"
    press_enter
}
uninstall_badvpn() {
    systemctl stop badvpn.service 2>/dev/null; systemctl disable badvpn.service 2>/dev/null
    rm -f "$BADVPN_SERVICE_FILE" "$BADVPN_BIN"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ badvpn uninstalled${C_RESET}"; press_enter
}
install_udp_custom() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚀 Installing udp-custom ---${C_RESET}"
    mkdir -p /usr/local/bin
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
    echo -e "${C_GREEN}✅ udp-custom installed${C_RESET}"; press_enter
}
uninstall_udp_custom() {
    systemctl stop udp-custom.service 2>/dev/null; systemctl disable udp-custom.service 2>/dev/null
    rm -f "$UDP_CUSTOM_SERVICE_FILE" "$UDP_CUSTOM_BIN"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ udp-custom uninstalled${C_RESET}"; press_enter
}
install_ssl_tunnel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔒 Installing SSL Tunnel ---${C_RESET}"
    ff_apt_install haproxy openssl
    mkdir -p "$SSL_CERT_DIR"
    openssl req -x509 -newkey rsa:2048 -nodes -days 365 -keyout "$SSL_CERT_DIR/voltrontech.key" -out "$SSL_CERT_DIR/voltrontech.crt" -subj "/CN=VOLTRON TECH" 2>/dev/null
    cat "$SSL_CERT_DIR/voltrontech.crt" "$SSL_CERT_DIR/voltrontech.key" > "$SSL_CERT_FILE" 2>/dev/null
    cat > "$HAPROXY_CONFIG" << EOF
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
    bind *:444 ssl crt $SSL_CERT_FILE
    default_backend ssh_backend
backend ssh_backend
    server ssh_server 127.0.0.1:22
EOF
    systemctl restart haproxy
    echo -e "${C_GREEN}✅ SSL Tunnel on port 444${C_RESET}"; press_enter
}
uninstall_ssl_tunnel() {
    systemctl stop haproxy 2>/dev/null
    ff_apt_purge haproxy
    rm -f "$HAPROXY_CONFIG" "$SSL_CERT_FILE"
    echo -e "${C_GREEN}✅ SSL uninstalled${C_RESET}"; press_enter
}
install_falcon_proxy() {
    clear; show_banner    echo -e "${C_BOLD}${C_PURPLE}--- 🦅 Installing Falcon Proxy ---${C_RESET}"
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then curl -sL -o "$FALCONPROXY_BINARY" "https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/latest/download/falconproxy"
    else curl -sL -o "$FALCONPROXY_BINARY" "https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/latest/download/falconproxyarm"; fi
    chmod +x "$FALCONPROXY_BINARY"
    read -p "👉 Port(s) [8080]: " ports; ports=${ports:-8080}
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
    echo -e "${C_GREEN}✅ Falcon Proxy on port $ports${C_RESET}"; press_enter
}
uninstall_falcon_proxy() {
    systemctl stop falconproxy.service 2>/dev/null; systemctl disable falconproxy.service 2>/dev/null
    rm -f "$FALCONPROXY_SERVICE_FILE" "$FALCONPROXY_BINARY"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ Falcon uninstalled${C_RESET}"; press_enter
}
install_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🛡️ Installing ZiVPN ---${C_RESET}"
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then curl -sL -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    else curl -sL -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"; fi
    chmod +x "$ZIVPN_BIN"
    mkdir -p "$ZIVPN_DIR"
    openssl req -x509 -newkey rsa:4096 -nodes -days 365 -keyout "$ZIVPN_DIR/server.key" -out "$ZIVPN_DIR/server.crt" -subj "/CN=ZiVPN" 2>/dev/null
    read -p "Passwords (comma-sep) [user1,user2]: " passwords; passwords=${passwords:-user1,user2}
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
    echo -e "${C_GREEN}✅ ZiVPN on port 5667${C_RESET}"; press_enter
}
uninstall_zivpn() {
    systemctl stop zivpn.service 2>/dev/null; systemctl disable zivpn.service 2>/dev/null
    rm -f "$ZIVPN_SERVICE_FILE" "$ZIVPN_BIN"
    rm -rf "$ZIVPN_DIR"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ ZiVPN uninstalled${C_RESET}"; press_enter
}
install_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💻 Installing X-UI ---${C_RESET}"
    bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh)
    press_enter
}
uninstall_xui_panel() {
    command -v x-ui &>/dev/null && x-ui uninstall
    rm -f /usr/local/bin/x-ui
    rm -rf /etc/x-ui /usr/local/x-ui
    echo -e "${C_GREEN}✅ X-UI uninstalled${C_RESET}"; press_enter
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
    local ONLINE_USERS=$(count_managed_online_sessions 2>/dev/null || echo "0")
    local SSH_STATUS=$(systemctl is-active sshd 2>/dev/null || systemctl is-active ssh 2>/dev/null || echo "inactive")
    local DNSTT_STATUS=$(systemctl is-active dnstt 2>/dev/null || echo "inactive")
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
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}⏱️ Uptime:${C_RESET} ${C_GREEN}%-20s${C_RESET}  ${C_YELLOW}📊 Load:${C_RESET} ${C_GREEN}%-15s${C_RESET}  ${C_YELLOW}👥 Users:${C_RESET} ${C_GREEN}%2s/%2s${C_RESET}  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$UPTIME" "$LOAD" "$ONLINE_USERS" "$TOTAL_USERS"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}🔹 CPU:${C_RESET} ${C_WHITE}%-20s${C_RESET} ${C_CYAN}%2s cores${C_RESET}  ${C_YELLOW}🔹 RAM:${C_RESET} ${C_WHITE}%5s / %5s${C_RESET}  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "CPU" "$CPU_CORES" "$RAM_USED" "$RAM_TOTAL"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}CPU:${C_RESET}  %-28s  ${C_YELLOW}RAM:${C_RESET}  %-28s  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$(make_bar 0)" "$(make_bar $RAM_PERCENT)"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}📀 Disk:${C_RESET} %4s / %4s  %-20s  ${C_YELLOW}📶 Net:${C_RESET} ${C_GREEN}●${C_RESET} Active  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$DISK_USED" "$DISK_TOTAL" "$(make_bar $DISK_PERCENT)"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    local sc=""; [[ "$SSH_STATUS" == "active" ]] && sc="${C_GREEN}● RUNNING${C_RESET}" || sc="${C_RED}● STOPPED${C_RESET}"
    local dc=""; [[ "$DNSTT_STATUS" == "active" ]] && dc="${C_GREEN}● RUNNING${C_RESET}" || dc="${C_RED}● STOPPED${C_RESET}"
    printf "${C_BOLD}${C_CYAN}│${C_RESET}  ${C_YELLOW}🔌 SSH:${C_RESET}  %-15s  ${C_YELLOW}📡 DNSTT:${C_RESET} %-15s  ${C_BOLD}${C_CYAN}│${C_RESET}\n" "$sc" "$dc"
    echo -e "${C_BOLD}${C_CYAN}└─────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    echo -e "${C_DIM}  💡 Press ${C_WHITE}[Enter]${C_DIM} to refresh  |  Press ${C_WHITE}[0]${C_DIM} to return${C_RESET}"
    read -p "👉 " rc
    [[ "$rc" != "0" ]] && show_vps_dashboard
}

# ========== PROTOCOL MENU ==========
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
        local as=""; [ -f "/etc/systemd/system/voltrontech-api.service" ] && { systemctl is-active --quiet voltrontech-api 2>/dev/null && as="${C_GREEN}● RUNNING${C_RESET}" || as="${C_RED}● STOPPED${C_RESET}"; } || as="${C_DIM}● NOT INSTALLED${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}              🔌 PROTOCOL MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}1)${C_RESET} badvpn (UDP 7300)        $bs"
        echo -e "  ${C_GREEN}2)${C_RESET} udp-custom              $us"
        echo -e "  ${C_GREEN}3)${C_RESET} SSL Tunnel (HAProxy)    $hs"
        echo -e "  ${C_GREEN}4)${C_RESET} DNSTT (Port 53)         $ds"
        echo -e "  ${C_GREEN}5)${C_RESET} Falcon Proxy            $fs"
        echo -e "  ${C_GREEN}6)${C_RESET} ZiVPN                   $zs"
        echo -e "  ${C_GREEN}7)${C_RESET} X-UI Panel              $xs"
        echo ""
        echo -e "  ${C_CYAN}8)${C_RESET} 🌐 API Management        $as"
        echo ""
        echo -e "  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Select: " choice
        case $choice in
            1) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_badvpn || uninstall_badvpn ;;
            2) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_udp_custom || uninstall_udp_custom ;;
            3) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_ssl_tunnel || uninstall_ssl_tunnel ;;
            4) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_GREEN}2)${C_RESET} Manage\n  ${C_RED}3)${C_RESET} Uninstall"; read -p "👉 " sub; case $sub in 1) install_dnstt ;; 2) dnstt_main_menu ;; 3) uninstall_dnstt ;; esac ;;
            5) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_falcon_proxy || uninstall_falcon_proxy ;;
            6) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_zivpn || uninstall_zivpn ;;
            7) echo -e "\n  ${C_GREEN}1)${C_RESET} Install\n  ${C_RED}2)${C_RESET} Uninstall"; read -p "👉 " sub; [ "$sub" == "1" ] && install_xui_panel || uninstall_xui_panel ;;
            8) api_management_menu ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

# ========== API MANAGEMENT ==========
api_management_menu() {
    while true; do
        clear; show_banner
        local api_status=""
        if [ -f "/etc/systemd/system/voltrontech-api.service" ]; then
            systemctl is-active --quiet voltrontech-api 2>/dev/null && api_status="${C_GREEN}● RUNNING${C_RESET}" || api_status="${C_RED}● STOPPED${C_RESET}"
        else api_status="${C_DIM}● NOT INSTALLED${C_RESET}"; fi
        local api_url=""; local api_key=""
        if [ -f "$API_INFO_FILE" ]; then
            api_url=$(grep "API_URL=" "$API_INFO_FILE" 2>/dev/null | cut -d= -f2-)
            api_key=$(grep "API_KEY=" "$API_INFO_FILE" 2>/dev/null | cut -d= -f2-)
        fi
        local active_count=0
        for svc in sshd ssh dnstt haproxy badvpn udp-custom zivpn falconproxy; do
            systemctl is-active --quiet "$svc" 2>/dev/null && ((active_count++))
        done
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    🌐 API MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}Status:${C_RESET}           $api_status"
        echo -e "  ${C_CYAN}Active Protocols:${C_RESET} ${C_GREEN}$active_count${C_RESET} running"
        [[ -n "$api_url" ]] && echo -e "  ${C_CYAN}API URL:${C_RESET}          ${C_YELLOW}$api_url${C_RESET}"
        [[ -n "$api_key" ]] && echo -e "  ${C_CYAN}API Key:${C_RESET}          ${C_GREEN}${api_key:0:20}...${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}1)${C_RESET} 📥 Install API Server"
        echo -e "  ${C_GREEN}2)${C_RESET} ▶️  Start API Server"
        echo -e "  ${C_RED}3)${C_RESET} ⏹️  Stop API Server"
        echo -e "  ${C_GREEN}4)${C_RESET} 🔄 Restart API Server"
        echo -e "  ${C_GREEN}5)${C_RESET} 🔑 View API URL + Key"
        echo -e "  ${C_GREEN}6)${C_RESET} 📋 View API Endpoints"
        echo -e "  ${C_GREEN}7)${C_RESET} 📝 Copy for Lovable AI"
        echo -e "  ${C_GREEN}8)${C_RESET} 🧪 Test API"
        echo -e "  ${C_RED}9)${C_RESET} 🗑️  Uninstall API"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Select: " choice
        case $choice in
            1) install_api_server ;;
            2) start_api_server ;;
            3) stop_api_server ;;
            4) restart_api_server ;;
            5) view_api_info ;;
            6) view_api_endpoints ;;
            7) copy_for_lovable_ai ;;
            8) test_api ;;
            9) uninstall_api_server ;;
            0) return ;;
            *) sleep 2 ;;
        esac
    done
}

install_api_server() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}           📥 INSTALLING API SERVER${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    if [ -f "/etc/systemd/system/voltrontech-api.service" ]; then
        read -p "Reinstall? (y/n): " reinstall
        [[ "$reinstall" != "y" ]] && return
        systemctl stop voltrontech-api 2>/dev/null
    fi
    local API_KEY="voltron_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)"
    echo -e "\n${C_BLUE}[1/6] Installing dependencies...${C_RESET}"
    ff_apt_install python3 python3-pip python3-venv curl jq
    echo -e "\n${C_BLUE}[2/6] Creating directory...${C_RESET}"
    mkdir -p "$API_DIR"
    echo -e "\n${C_BLUE}[3/6] Python environment...${C_RESET}"
    cd "$API_DIR"
    [ ! -d "venv" ] && python3 -m venv venv
    source venv/bin/activate
    pip install -q --upgrade pip
    pip install -q flask flask-cors gunicorn
    echo -e "\n${C_BLUE}[4/6] Creating API code...${C_RESET}"
    create_api_code
    echo -e "\n${C_BLUE}[5/6] Systemd service...${C_RESET}"
    local SERVER_HOST=$(cat "$DB_DIR/domain.txt" 2>/dev/null || echo "vpn.voltrontechtx.shop")
    cat > /etc/systemd/system/voltrontech-api.service << EOF
[Unit]
Description=Voltron Tech API Server v11.0
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$API_DIR
Environment="API_KEY=$API_KEY"
Environment="DB_DIR=$DB_DIR"
Environment="SERVER_HOST=$SERVER_HOST"
Environment="PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
ExecStart=$API_DIR/venv/bin/gunicorn --workers 4 --bind 0.0.0.0:$API_PORT --timeout 120 api:app
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
        cat > "$API_INFO_FILE" << EOF
API_URL=http://$SERVER_IP:$API_PORT
API_KEY=$API_KEY
EOF
        echo "$API_KEY" > "$API_KEY_FILE"
        chmod 600 "$API_KEY_FILE"
        echo ""
        echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_GREEN}           ✅ API SERVER INSTALLED!${C_RESET}"
        echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}🌐 API URL:${C_RESET}  ${C_YELLOW}http://$SERVER_IP:$API_PORT${C_RESET}"
        echo -e "  ${C_CYAN}🔑 API Key:${C_RESET}  ${C_GREEN}$API_KEY${C_RESET}"
        echo ""
        echo -e "  ${C_DIM}Saved to: $API_INFO_FILE${C_RESET}"
    else
        echo -e "${C_RED}❌ Failed to start${C_RESET}"
        journalctl -u voltrontech-api -n 20 --no-pager
    fi
    press_enter
}

create_api_code() {
    cat > "$API_DIR/api.py" << 'APIEOF'
#!/usr/bin/env python3
"""Voltron Tech API Server v11.0"""
from flask import Flask, request, jsonify
from flask_cors import CORS
from functools import wraps
import subprocess, os, secrets, string, shutil
from datetime import datetime, timedelta

app = Flask(__name__)
CORS(app, resources={r"/api/*": {"origins": "*"}})

API_KEY = os.environ.get('API_KEY', 'CHANGE_ME')
DB_DIR = os.environ.get('DB_DIR', '/etc/voltrontech')
DB_FILE = f'{DB_DIR}/users.db'
SERVER_HOST = os.environ.get('SERVER_HOST', 'vpn.voltrontechtx.shop')


def require_api_key(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        key = request.headers.get('X-API-Key') or request.args.get('api_key')
        if not key or key != API_KEY:
            return jsonify({'success': False, 'error': 'Invalid API key'}), 401
        return f(*args, **kwargs)
    return decorated


def run(cmd, timeout=30):
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return {'success': r.returncode == 0, 'stdout': r.stdout.strip() if r.stdout else '', 'stderr': r.stderr.strip() if r.stderr else ''}
    except Exception as e:
        return {'success': False, 'stdout': '', 'stderr': str(e)}


def service_active(name):
    if not shutil.which('systemctl'):
        return False
    r = run(f'systemctl is-active {name} 2>/dev/null')
    if r.get('stdout', '').strip() == 'active':
        return True
    r = run(f'systemctl show -p ActiveState --value {name} 2>/dev/null')
    if r.get('stdout', '').strip() == 'active':
        return True
    return False


def ssh_active():
    return service_active('ssh') or service_active('sshd')


def read_users():
    users = []
    if not os.path.exists(DB_FILE):
        return users
    try:
        with open(DB_FILE) as f:
            for line in f:
                line = line.strip()
                if not line or line.startswith('#'):
                    continue
                parts = line.split(':')
                if len(parts) >= 4:
                    users.append({'username': parts[0], 'password': parts[1], 'expiry': parts[2], 'limit': parts[3], 'bandwidth': parts[4] if len(parts) > 4 else '0'})
    except Exception:
        pass
    return users


def user_exists(username):
    r = run(f'id {username} 2>/dev/null')
    return r.get('success', False)


def get_status(username):
    if not user_exists(username):
        return 'not_found'
    r = run(f'passwd -S {username} 2>/dev/null')
    if ' L ' in r.get('stdout', ''):
        return 'locked'
    user = next((u for u in read_users() if u['username'] == username), None)
    if user and user.get('expiry'):
        try:
            if datetime.strptime(user['expiry'], '%Y-%m-%d') < datetime.now():
                return 'expired'
        except Exception:
            pass
    return 'active'


def get_online(username):
    r = run(f'pgrep -c -u {username} sshd 2>/dev/null')
    try:
        return int(r.get('stdout', '0') or '0')
    except ValueError:
        return 0


def get_server_ip():
    for cmd in ['curl -s -4 icanhazip.com', 'hostname -I | awk \'{print $1}\'']:
        r = run(cmd, timeout=5)
        ip = r.get('stdout', '').strip()
        if ip and ip.count('.') == 3:
            return ip
    return 'unknown'


def get_protocols(username=None, password=None):
    protocols = {}
    server_ip = get_server_ip()
    
    if ssh_active():
        protocols['ssh'] = {'id': 'ssh', 'name': 'SSH Direct', 'icon': '🔐', 'color': '#6BCB77', 'host': SERVER_HOST, 'ip': server_ip, 'port': 22, 'username': username, 'password': password, 'info': 'Direct SSH connection', 'type': 'ssh'}
    
    if service_active('haproxy'):
        port = 444
        if os.path.exists('/etc/haproxy/haproxy.cfg'):
            r = run('grep -oP "bind \\*:\\K\\d+" /etc/haproxy/haproxy.cfg 2>/dev/null | head -1')
            try:
                port = int(r.get('stdout', '444'))
            except ValueError:
                port = 444
        protocols['ssl'] = {'id': 'ssl', 'name': 'SSL/TLS Tunnel', 'icon': '🔒', 'color': '#4D96FF', 'host': SERVER_HOST, 'ip': server_ip, 'port': port, 'username': username, 'password': password, 'info': f'SSL tunnel on port {port}', 'type': 'ssl'}
    
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
        protocols['dnstt'] = {'id': 'dnstt', 'name': 'DNSTT (SlowDNS)', 'icon': '📡', 'color': '#9B59B6', 'domain': domain, 'pubkey': pubkey, 'mtu': mtu, 'dns': '8.8.8.8', 'dns_alt': '1.1.1.1', 'username': username, 'password': password, 'info': f'DNSTT with MTU {mtu}', 'type': 'dnstt'}
    
    if service_active('udp-custom'):
        protocols['udp_custom'] = {'id': 'udp_custom', 'name': 'UDP Custom', 'icon': '🚀', 'color': '#FF6B6B', 'host': SERVER_HOST, 'ip': server_ip, 'port_range': '1-65535', 'exclude': '53,5300', 'username': username, 'password': password, 'info': 'UDP any port except 53,5300', 'type': 'udp'}
    
    if service_active('badvpn'):
        protocols['badvpn'] = {'id': 'badvpn', 'name': 'BadVPN UDPGW', 'icon': '⚡', 'color': '#FFD93D', 'host': SERVER_HOST, 'ip': server_ip, 'port': 7300, 'username': username, 'password': password, 'info': 'BadVPN UDP Gateway', 'type': 'badvpn'}
    
    if service_active('zivpn'):
        protocols['zivpn'] = {'id': 'zivpn', 'name': 'ZiVPN', 'icon': '🛡️', 'color': '#6BCB77', 'host': SERVER_HOST, 'ip': server_ip, 'port': 5667, 'username': username, 'password': password, 'info': 'ZiVPN server', 'type': 'zivpn'}
    
    if service_active('falconproxy'):
        protocols['falconproxy'] = {'id': 'falconproxy', 'name': 'Falcon Proxy', 'icon': '🦅', 'color': '#E85555', 'host': SERVER_HOST, 'ip': server_ip, 'port': 8080, 'username': username, 'password': password, 'info': 'Falcon Proxy', 'type': 'falconproxy'}
    
    return protocols


@app.route('/api/health')
def health():
    protocols = get_protocols()
    return jsonify({'success': True, 'status': 'ok', 'service': 'Voltron Tech API', 'version': '11.0', 'protocols_active': len(protocols), 'timestamp': datetime.now().isoformat()})


@app.route('/api/trial/check', methods=['POST'])
@require_api_key
def trial_check():
    data = request.get_json() or {}
    username = data.get('username', '').strip().lower()
    if not username: return jsonify({'available': False, 'error': 'Username required'}), 400
    if not username.replace('-', '').replace('_', '').isalnum(): return jsonify({'available': False, 'error': 'Only letters, numbers, - and _'}), 400
    if len(username) < 3 or len(username) > 20: return jsonify({'available': False, 'error': 'Username must be 3-20 chars'}), 400
    if user_exists(username): return jsonify({'available': False, 'error': 'Username taken'})
    if any(u['username'] == username for u in read_users()): return jsonify({'available': False, 'error': 'Username taken'})
    return jsonify({'available': True, 'username': username})


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
    if user_exists(username): return jsonify({'success': False, 'error': 'Username taken'}), 400
    try:
        run(f'useradd -m -s /usr/sbin/nologin {username}')
        run(f'usermod -aG ffusers {username} 2>/dev/null')
        run(f'echo "{username}:{password}" | chpasswd')
        expire_date = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run(f'chage -E {expire_date} {username}')
        os.makedirs(DB_DIR, exist_ok=True)
        with open(DB_FILE, 'a') as f: f.write(f'{username}:{password}:{expire_date}:1:0\n')
        protocols = get_protocols(username, password)
        server_ip = get_server_ip()
        return jsonify({'success': True, 'message': f'Trial created ({days} days)', 'account': {'username': username, 'password': password, 'expiry': expire_date, 'days': days, 'bandwidth': 'Unlimited', 'server': SERVER_HOST, 'server_ip': server_ip}, 'protocols': protocols, 'protocol_count': len(protocols)})
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
    except Exception:
        days_left = 0
    return jsonify({'success': True, 'account': {'username': username, 'status': get_status(username), 'expiry': user['expiry'], 'days_left': max(0, days_left), 'online': get_online(username)}})


@app.route('/api/dashboard/info')
@require_api_key
def dashboard_info():
    try:
        ip = get_server_ip()
        try:
            with open('/proc/uptime') as f: uptime_sec = float(f.read().split()[0])
            days = int(uptime_sec // 86400); hours = int((uptime_sec % 86400) // 3600); minutes = int((uptime_sec % 3600) // 60)
            uptime_str = f'{days}d {hours}h {minutes}m'
        except Exception: uptime_str = 'unknown'
        try:
            with open('/proc/cpuinfo') as f: cpu_cores = f.read().count('processor')
        except Exception: cpu_cores = 1
        ram_total = ram_used = ram_percent = 0
        try:
            with open('/proc/meminfo') as f:
                mem = {}
                for line in f:
                    parts = line.split(':')
                    if len(parts) == 2:
                        mem[parts[0].strip()] = int(parts[1].split()[0])
                ram_total = mem.get('MemTotal', 0) // 1024
                ram_avail = mem.get('MemAvailable', 0) // 1024
                ram_used = ram_total - ram_avail
                ram_percent = int(ram_used * 100 / ram_total) if ram_total else 0
        except Exception: pass
        disk_total = disk_used = disk_percent = 0
        try:
            r = run('df -k / | tail -1')
            parts = r.get('stdout', '').split()
            if len(parts) >= 4:
                disk_total = int(parts[1]) // 1024
                disk_used = int(parts[2]) // 1024
                disk_percent = int(parts[4].replace('%', ''))
        except Exception: pass
        try:
            with open('/proc/loadavg') as f: load_str = ' '.join(f.read().split()[:3])
        except Exception: load_str = '0.00 0.00 0.00'
        users = read_users()
        online = sum(get_online(u['username']) for u in users)
        return jsonify({'success': True, 'info': {'ip': ip, 'uptime': uptime_str, 'cpu': {'cores': cpu_cores}, 'ram': {'total': ram_total, 'used': ram_used, 'percent': ram_percent}, 'disk': {'total': disk_total, 'used': disk_used, 'percent': disk_percent}, 'load': load_str, 'users': {'total': len(users), 'online': online}, 'services': {'ssh': ssh_active(), 'dnstt': service_active('dnstt'), 'haproxy': service_active('haproxy'), 'badvpn': service_active('badvpn'), 'udp_custom': service_active('udp-custom'), 'zivpn': service_active('zivpn'), 'falconproxy': service_active('falconproxy')}}})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/users/list')
@require_api_key
def users_list():
    users = read_users()
    result = []
    for u in users:
        used_bytes = 0
        usage_file = f'{DB_DIR}/bandwidth/{u["username"]}.usage'
        if os.path.exists(usage_file):
            try:
                with open(usage_file) as f: used_bytes = int(f.read().strip() or 0)
            except Exception: used_bytes = 0
        result.append({'username': u['username'], 'expiry': u['expiry'], 'limit': int(u['limit']), 'bandwidth_limit': float(u['bandwidth']), 'bandwidth_used_gb': round(used_bytes / 1073741824, 2), 'status': get_status(u['username']), 'online': get_online(u['username'])})
    return jsonify({'success': True, 'users': result, 'total': len(result)})


@app.route('/api/users/delete', methods=['POST'])
@require_api_key
def users_delete():
    data = request.get_json() or {}
    username = data.get('username', '').strip()
    run(f'killall -u {username} -9 2>/dev/null')
    run(f'userdel -r {username} 2>/dev/null')
    if os.path.exists(DB_FILE):
        with open(DB_FILE) as f: lines = f.readlines()
        with open(DB_FILE, 'w') as f:
            for line in lines:
                if not line.startswith(f'{username}:'): f.write(line)
    return jsonify({'success': True, 'message': f'User {username} deleted'})


@app.route('/api/users/lock', methods=['POST'])
@require_api_key
def users_lock():
    data = request.get_json() or {}
    username = data.get('username', '').strip()
    run(f'usermod -L {username}')
    run(f'killall -u {username} -9 2>/dev/null')
    return jsonify({'success': True, 'message': f'{username} locked'})


@app.route('/api/users/unlock', methods=['POST'])
@require_api_key
def users_unlock():
    data = request.get_json() or {}
    username = data.get('username', '').strip()
    run(f'usermod -U {username}')
    return jsonify({'success': True, 'message': f'{username} unlocked'})


@app.route('/api/protocols/status')
@require_api_key
def protocols_status():
    protocols = get_protocols()
    return jsonify({'success': True, 'protocols': protocols, 'count': len(protocols), 'active_list': list(protocols.keys())})


@app.route('/api/protocols/start/<service>', methods=['POST'])
@require_api_key
def protocols_start(service):
    allowed = ['badvpn', 'udp-custom', 'haproxy', 'dnstt', 'zivpn', 'falconproxy', 'ssh']
    if service not in allowed: return jsonify({'success': False, 'error': 'Invalid service'}), 400
    r = run(f'systemctl start {service}')
    return jsonify({'success': r['success'], 'message': f'{service} started'})


@app.route('/api/protocols/stop/<service>', methods=['POST'])
@require_api_key
def protocols_stop(service):
    allowed = ['badvpn', 'udp-custom', 'haproxy', 'dnstt', 'zivpn', 'falconproxy']
    if service not in allowed: return jsonify({'success': False, 'error': 'Invalid service'}), 400
    r = run(f'systemctl stop {service}')
    return jsonify({'success': r['success'], 'message': f'{service} stopped'})


@app.route('/api/debug/services')
@require_api_key
def debug_services():
    services = ['ssh', 'sshd', 'haproxy', 'dnstt', 'badvpn', 'udp-custom', 'zivpn', 'falconproxy']
    results = {}
    for svc in services:
        r1 = run(f'systemctl is-active {svc} 2>/dev/null')
        r2 = run(f'systemctl show -p ActiveState --value {svc} 2>/dev/null')
        results[svc] = {'is_active': r1.get('stdout', ''), 'show': r2.get('stdout', ''), 'final': service_active(svc)}
    return jsonify({'success': True, 'debug': results})


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
APIEOF
    chmod +x "$API_DIR/api.py"
}

start_api_server() {
    clear; show_banner
    [ ! -f "/etc/systemd/system/voltrontech-api.service" ] && { echo -e "\n${C_RED}❌ Not installed!${C_RESET}"; press_enter; return; }
    systemctl start voltrontech-api; sleep 2
    systemctl is-active --quiet voltrontech-api && echo -e "\n${C_GREEN}✅ Started${C_RESET}" || echo -e "\n${C_RED}❌ Failed${C_RESET}"
    press_enter
}
stop_api_server() {
    clear; show_banner
    systemctl stop voltrontech-api 2>/dev/null
    echo -e "\n${C_GREEN}✅ Stopped${C_RESET}"; press_enter
}
restart_api_server() {
    clear; show_banner
    systemctl restart voltrontech-api; sleep 2
    systemctl is-active --quiet voltrontech-api && echo -e "\n${C_GREEN}✅ Restarted${C_RESET}" || echo -e "\n${C_RED}❌ Failed${C_RESET}"
    press_enter
}
view_api_info() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🔑 API URL & KEY ---${C_RESET}\n"
    [ ! -f "$API_INFO_FILE" ] && { echo -e "${C_RED}❌ Not installed!${C_RESET}"; press_enter; return; }
    local api_url=$(grep "API_URL=" "$API_INFO_FILE" | cut -d= -f2-)
    local api_key=$(grep "API_KEY=" "$API_INFO_FILE" | cut -d= -f2-)
    echo -e "${C_CYAN}🌐 API URL:${C_RESET} ${C_YELLOW}$api_url${C_RESET}"
    echo -e "${C_CYAN}🔑 API Key:${C_RESET} ${C_GREEN}$api_key${C_RESET}"
    press_enter
}
view_api_endpoints() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📋 API ENDPOINTS ---${C_RESET}\n"
    echo -e "${C_GREEN}🎯 TRIAL:${C_RESET}"
    echo -e "  POST /api/trial/check"
    echo -e "  POST /api/trial/create"
    echo -e "  GET  /api/trial/status/<username>"
    echo -e "\n${C_BLUE}📊 DASHBOARD:${C_RESET}\n  GET /api/dashboard/info"
    echo -e "\n${C_CYAN}👥 USERS:${C_RESET}"
    echo -e "  GET  /api/users/list"
    echo -e "  POST /api/users/delete"
    echo -e "  POST /api/users/lock"
    echo -e "  POST /api/users/unlock"
    echo -e "\n${C_PURPLE}🔌 PROTOCOLS:${C_RESET}\n  GET /api/protocols/status"
    echo -e "\n${C_GREEN}❤️  HEALTH:${C_RESET}\n  GET /api/health"
    echo -e "\n${C_YELLOW}🐛 DEBUG:${C_RESET}\n  GET /api/debug/services"
    press_enter
}
copy_for_lovable_ai() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📝 COPY FOR LOVABLE AI ---${C_RESET}\n"
    [ ! -f "$API_INFO_FILE" ] && { echo -e "${C_RED}❌ Not installed!${C_RESET}"; press_enter; return; }
    local api_url=$(grep "API_URL=" "$API_INFO_FILE" | cut -d= -f2-)
    local api_key=$(grep "API_KEY=" "$API_INFO_FILE" | cut -d= -f2-)
    local active_protocols=""
    for svc in ssh sshd haproxy dnstt udp-custom badvpn zivpn falconproxy; do
        systemctl is-active --quiet "$svc" 2>/dev/null && active_protocols+="$svc "
    done
    echo -e "${C_YELLOW}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_WHITE}COPY HII KWA LOVABLE AI:${C_RESET}"
    echo -e "${C_YELLOW}═══════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "${C_CYAN}API URL:${C_RESET} ${C_YELLOW}$api_url${C_RESET}"
    echo -e "${C_CYAN}API Key:${C_RESET} ${C_GREEN}$api_key${C_RESET}"
    echo -e "\n${C_CYAN}Active Protocols:${C_RESET} ${C_GREEN}$active_protocols${C_RESET}"
    press_enter
}
test_api() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🧪 TESTING API ---${C_RESET}\n"
    local api_key=$(cat "$API_KEY_FILE" 2>/dev/null)
    [ -z "$api_key" ] && { echo -e "${C_RED}❌ Key not found!${C_RESET}"; press_enter; return; }
    echo -e "${C_BLUE}[1/3] Health...${C_RESET}"
    local health=$(curl -s http://localhost:$API_PORT/api/health 2>/dev/null)
    echo "$health" | grep -q "ok" && echo -e "${C_GREEN}✅ OK${C_RESET}" || echo -e "${C_RED}❌ Fail${C_RESET}"
    echo -e "\n${C_BLUE}[2/3] Dashboard...${C_RESET}"
    local dash=$(curl -s -H "X-API-Key: $api_key" http://localhost:$API_PORT/api/dashboard/info 2>/dev/null)
    echo "$dash" | grep -q "success" && echo -e "${C_GREEN}✅ OK${C_RESET}" || echo -e "${C_RED}❌ Fail${C_RESET}"
    echo -e "\n${C_BLUE}[3/3] Protocols...${C_RESET}"
    local prot=$(curl -s -H "X-API-Key: $api_key" http://localhost:$API_PORT/api/protocols/status 2>/dev/null)
    if echo "$prot" | grep -q "success"; then
        local count=$(echo "$prot" | jq -r '.count' 2>/dev/null || echo "?")
        echo -e "${C_GREEN}✅ OK ($count active)${C_RESET}"
    else echo -e "${C_RED}❌ Fail${C_RESET}"; fi
    press_enter
}
uninstall_api_server() {
    clear; show_banner
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_RED}           🗑️ UNINSTALL API SERVER${C_RESET}"
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}\n"
    read -p "Confirm? (y/n): " confirm
    [[ "$confirm" != "y" ]] && return
    systemctl stop voltrontech-api 2>/dev/null
    systemctl disable voltrontech-api 2>/dev/null
    rm -f /etc/systemd/system/voltrontech-api.service
    rm -rf "$API_DIR"
    systemctl daemon-reload
    echo -e "\n${C_GREEN}✅ Uninstalled${C_RESET}"; press_enter
}

# ========== VPN DATA USAGE ==========
show_vpn_data_usage() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}                 📊 VPN DATA USAGE${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}\n"
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

# ========== AUTO REBOOT ==========
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

# ========== TRAFFIC MONITOR ==========
traffic_monitor_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📈 Traffic Monitor ---${C_RESET}\n"
    local iface=$(ip -4 route ls | grep default | grep -Po '(?<=dev )(\S+)' | head -1)
    echo -e "Interface: ${C_CYAN}$iface${C_RESET}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} Live Monitor"
    echo -e "  ${C_GREEN}2)${C_RESET} Total Since Boot"
    echo -e "  ${C_RED}0)${C_RESET} Return"
    read -p "👉 Choice: " c
    case $c in
        1) echo -e "\n${C_BLUE}Live (Ctrl+C to stop)...${C_RESET}\n"
            local rx1=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
            local tx1=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
            while true; do
                sleep 2
                local rx2=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
                local tx2=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
                local rd=$(( (rx2 - rx1) / 1024 / 2 ))
                local td=$(( (tx2 - tx1) / 1024 / 2 ))
                printf "\r⬇️ %6s KB/s | ⬆️ %6s KB/s" "$rd" "$td"
                rx1=$rx2; tx1=$tx2
            done ;;
        2) local rx=$(cat "/sys/class/net/$iface/statistics/rx_bytes")
           local tx=$(cat "/sys/class/net/$iface/statistics/tx_bytes")
           echo -e "\n⬇️ ${C_WHITE}$((rx / 1024 / 1024)) MB${C_RESET}"
           echo -e "⬆️ ${C_WHITE}$((tx / 1024 / 1024)) MB${C_RESET}"
           press_enter ;;
        0) return ;;
    esac
}

# ========== TORRENT BLOCK ==========
torrent_block_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🚫 Torrent Blocking ---${C_RESET}\n"
    local st="${C_RED}Disabled${C_RESET}"
    iptables -L FORWARD 2>/dev/null | grep -q "BitTorrent" && st="${C_GREEN}Enabled${C_RESET}"
    echo -e "Status: ${st}\n"
    echo -e "  ${C_GREEN}1)${C_RESET} Enable"
    echo -e "  ${C_RED}2)${C_RESET} Disable"
    echo -e "  ${C_RED}0)${C_RESET} Return"
    read -p "👉 Choice: " c
    case $c in
        1) iptables -A FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
           iptables -A FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
           iptables -A FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
           iptables -A FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
           echo -e "${C_GREEN}✅ Enabled${C_RESET}"; press_enter ;;
        2) iptables -D FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
           iptables -D FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
           iptables -D FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
           iptables -D FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
           echo -e "${C_GREEN}✅ Disabled${C_RESET}"; press_enter ;;
        0) return ;;
    esac
}

# ========== BACKUP/RESTORE ==========
backup_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💾 Backup User Data ---${C_RESET}\n"
    read -p "Path [/root/voltrontech_backup.tar.gz]: " bp
    bp=${bp:-/root/voltrontech_backup.tar.gz}
    [ ! -d "$DB_DIR" ] || [ ! -s "$DB_FILE" ] && { echo -e "${C_YELLOW}ℹ️ No data.${C_RESET}"; press_enter; return; }
    tar -czf "$bp" -C "$(dirname "$DB_DIR")" "$(basename "$DB_DIR")" 2>/dev/null
    [ $? -eq 0 ] && echo -e "${C_GREEN}✅ Backup: $bp${C_RESET}" || echo -e "${C_RED}❌ Failed${C_RESET}"
    press_enter
}
restore_user_data() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 📥 Restore User Data ---${C_RESET}\n"
    read -p "Backup path: " bp
    [ ! -f "$bp" ] && { echo -e "${C_RED}❌ Not found${C_RESET}"; press_enter; return; }
    read -p "⚠️ Overwrite all? (y/n): " confirm
    [[ "$confirm" == "y" ]] && {
        local td=$(mktemp -d)
        tar -xzf "$bp" -C "$td" 2>/dev/null
        [ -f "$td/voltrontech/users.db" ] && { cp "$td/voltrontech/users.db" "$DB_FILE"; echo -e "${C_GREEN}✅ Restored${C_RESET}"; }
        rm -rf "$td"; invalidate_banner_cache; update_ssh_banners_config
    }
    press_enter
}

# ========== DNS MENU ==========
dns_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS Domain Management ---${C_RESET}\n"
    if [ -f "$DNS_INFO_FILE" ]; then
        source "$DNS_INFO_FILE"
        echo -e "Existing: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
        read -p "Delete? (y/n): " c
        [[ "$c" == "y" || "$c" == "Y" ]] && { curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/A/" -H "Authorization: Token $DESEC_TOKEN" >/dev/null; rm -f "$DNS_INFO_FILE"; echo -e "${C_GREEN}✅ Deleted${C_RESET}"; }
    else
        read -p "Generate new? (y/n): " c
        [[ "$c" == "y" || "$c" == "Y" ]] && generate_dns_record
    fi
    press_enter
}
generate_dns_record() {
    local ip=$(curl -s -4 icanhazip.com)
    [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && { echo -e "${C_RED}❌ Invalid IP${C_RESET}"; return 1; }
    local sub="vps-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    local full="$sub.$DESEC_DOMAIN"
    local data=$(printf '[{"subname": "%s", "type": "A", "ttl": 3600, "records": ["%s"]}]' "$sub" "$ip")
    local resp=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$data")
    local http=${resp: -3}
    [[ "$http" -ne 201 ]] && { echo -e "${C_RED}❌ Failed HTTP $http${C_RESET}"; return 1; }
    cat > "$DNS_INFO_FILE" <<-EOF
SUBDOMAIN="$sub"
FULL_DOMAIN="$full"
EOF
    echo -e "${C_GREEN}✅ Domain: $full${C_RESET}"
}

# ========== SSH BANNERS ==========
update_ssh_banners_config() {
    local tmp_conf
    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        [ -f "$SSHD_FF_CONFIG" ] && { rm -f "$SSHD_FF_CONFIG"; systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null; }
        return
    fi
    mkdir -p "$BANNER_DIR" /etc/ssh/sshd_config.d
    tmp_conf="/tmp/voltrontech_banners_new.conf"
    echo "# Voltron Tech - Dynamic Banners" > "$tmp_conf"
    echo "# Generated: $(date)" >> "$tmp_conf"
    echo "" >> "$tmp_conf"
    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            [[ ! -f "$BANNER_DIR/${user}.txt" ]] && generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"
            echo "Match User $user" >> "$tmp_conf"
            echo "    Banner $BANNER_DIR/${user}.txt" >> "$tmp_conf"
            echo "" >> "$tmp_conf"
        done < "$DB_FILE"
    fi
    if ! cmp -s "$tmp_conf" "$SSHD_FF_CONFIG" 2>/dev/null; then
        mv "$tmp_conf" "$SSHD_FF_CONFIG"
        grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null || echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
        systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    else rm -f "$tmp_conf"; fi
}
enable_dynamic_banner() {
    mkdir -p "$BANNER_DIR"; touch "$BANNER_ENABLED_FILE"
    [[ -f "$DB_FILE" ]] && while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" || "$user" == \#* ]] && continue
        generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"
    done < "$DB_FILE"
    update_ssh_banners_config
    grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null || echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
    systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    systemctl restart voltrontech-limiter 2>/dev/null
    echo -e "${C_GREEN}✅ Dynamic banner enabled${C_RESET}"; press_enter
}
disable_dynamic_banner() {
    rm -f "$BANNER_ENABLED_FILE" "$SSHD_FF_CONFIG"
    rm -rf "$BANNER_DIR"
    systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    echo -e "${C_GREEN}✅ Disabled${C_RESET}"; press_enter
}
preview_dynamic_ssh_banner() {
    [[ ! -f "$BANNER_ENABLED_FILE" ]] && { echo -e "${C_RED}❌ Not enabled${C_RESET}"; press_enter; return; }
    _select_user_interface "--- 📝 Preview Banner ---"
    local u=$SELECTED_USER
    [[ -z "$u" || "$u" == "NO_USERS" ]] && return
    echo -e "\n${C_CYAN}--- Banner for $u ---${C_RESET}\n"
    [[ -f "$BANNER_DIR/${u}.txt" ]] && cat "$BANNER_DIR/${u}.txt" || echo -e "${C_RED}Not found${C_RESET}"
    press_enter
}
ssh_banner_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           🎨 SSH BANNER MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_GREEN}1)${C_RESET} Enable Dynamic Banner"
        echo -e "  ${C_RED}2)${C_RESET} Disable Dynamic Banner"
        echo -e "  ${C_GREEN}3)${C_RESET} Preview Banner"
        echo -e "\n  ${C_RED}0)${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) enable_dynamic_banner ;;
            2) disable_dynamic_banner ;;
            3) preview_dynamic_ssh_banner ;;
            0) return ;;
        esac
    done
}

# ========== SSH BOOSTER AUTO ==========
apply_ssh_booster_auto() {
    cat > /etc/ssh/sshd_config.d/voltrontech-speed.conf << 'EOF'
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
Compression no
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 3
PermitRootLogin yes
EOF
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    echo "net.ipv4.tcp_keepalive_time = 30" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
}

# ========== UDP BOOSTER AUTO ==========
apply_udp_booster_auto() {
    sysctl -w net.core.rmem_max=10737418240 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=10737418240 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=1073741824 >/dev/null 2>&1
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
write_banner_if_changed() {
    local user="$1"; local content="$2"
    local bf="$BANNER_DIR/${user}.txt"; local tf="${bf}.tmp"
    printf "%s" "$content" > "$tf"
    if ! cmp -s "$tf" "$bf" 2>/dev/null; then mv "$tf" "$bf"; else rm -f "$tf"; fi
}
while true; do
    [[ ! -s "$DB_FILE" ]] && { sleep "$SCAN_INTERVAL"; continue; }
    current_ts=$(date +%s)
    declare -A session_pids=(); declare -A locked_users=(); declare -A uid_to_user=(); declare -A loginuid_pids=()
    while IFS=: read -r username _ uid _rest; do
        [[ -n "$username" && "$uid" =~ ^[0-9]+$ ]] && uid_to_user["$uid"]="$username"
    done < /etc/passwd
    while read -r ssh_pid ssh_owner; do
        [[ "$ssh_pid" =~ ^[0-9]+$ ]] || continue
        if [[ -n "$ssh_owner" && "$ssh_owner" != "root" && "$ssh_owner" != "sshd" ]]; then session_pids["$ssh_owner"]+="$ssh_pid "; fi
    done < <(ps -C sshd -o pid=,user= 2>/dev/null)
    for p in /proc/[0-9]*/loginuid; do
        [[ -f "$p" ]] || continue
        login_uid=""; read -r login_uid < "$p" || login_uid=""
        [[ "$login_uid" =~ ^[0-9]+$ && "$login_uid" != "4294967295" ]] || continue
        session_user="${uid_to_user[$login_uid]}"
        [[ -n "$session_user" ]] || continue
        pid_dir=$(dirname "$p"); pid_num=$(basename "$pid_dir")
        comm=""; read -r comm < "$pid_dir/comm" || comm=""
        [[ "$comm" == "sshd" ]] || continue
        loginuid_pids["$session_user"]+="$pid_num "
    done
    while read -r passwd_user _ passwd_status _rest; do
        [[ "$passwd_status" == "L" ]] && locked_users["$passwd_user"]=1
    done < <(passwd -Sa 2>/dev/null)
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" || "$user" == \#* ]] && continue
        declare -A unique_pids=()
        for pid in ${session_pids["$user"]} ${loginuid_pids["$user"]}; do
            [[ "$pid" =~ ^[0-9]+$ ]] && unique_pids["$pid"]=1
        done
        online_count=${#unique_pids[@]}
        user_locked=false; is_expired=false; bw_exhausted=false
        passwd -S "$user" 2>/dev/null | grep -q " L " && user_locked=true
        [[ -n "${locked_users[$user]+x}" ]] && user_locked=true
        expiry_ts=0
        if [[ "$expiry" != "Never" && -n "$expiry" ]]; then
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                is_expired=true
                if ! $user_locked; then usermod -L "$user" &>/dev/null; user_locked=true; fi
            fi
        fi
        [[ "$limit" =~ ^[0-9]+$ ]] || limit=1
        if (( online_count > limit )); then
            if ! $user_locked; then usermod -L "$user" &>/dev/null; killall -u "$user" -9 &>/dev/null; user_locked=true; fi
        fi
        usagefile="$BW_DIR/${user}.usage"
        accum_disp=0
        if [[ -f "$usagefile" ]]; then read -r accum_disp < "$usagefile"; [[ "$accum_disp" =~ ^[0-9]+$ ]] || accum_disp=0; fi
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
                d_l=$(( diff_secs / 86400 )); h_l=$(( (diff_secs % 86400) / 3600 ))
                if (( d_l == 0 )); then days_left="${h_l}h left"; else days_left="${d_l}d ${h_l}h"; fi
            fi
        fi
        bw_info="Unlimited"; bw_display=""
        if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
            used_gb=$(awk "BEGIN {printf \"%.2f\", $accum_disp / 1073741824}")
            remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}")
            bw_info="${used_gb}/${bandwidth_gb} GB | ${remain_gb} GB left"
        fi
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
        banner_content+="<center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b>  🌍VOLTRON VPN🌍 </b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"
        write_banner_if_changed "$user" "$banner_content"
        [[ -z "$bandwidth_gb" || "$bandwidth_gb" == "0" ]] && continue
        accumulated=$accum_disp
        if (( ${#unique_pids[@]} == 0 )); then rm -f "$PID_DIR/${user}__"*.last 2>/dev/null; continue; fi
        delta_total=0
        for pid in "${!unique_pids[@]}"; do
            io_file="/proc/$pid/io"; cur=0
            if [[ -r "$io_file" ]]; then
                rchar=0; wchar=0
                while read -r key value; do
                    case "$key" in rchar:) rchar=${value:-0} ;; wchar:) wchar=${value:-0} ;; esac
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
    done < "$DB_FILE"
    sleep "$SCAN_INTERVAL"
done
LIMEOF
    chmod +x "$LIMITER_SCRIPT"
    cat > "$LIMITER_SERVICE" << EOF
[Unit]
Description=Voltron Tech Limiter
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

# ========== INITIAL SETUP ==========
initial_setup() {
    echo -e "\n${C_BLUE}🔧 Initial setup...${C_RESET}"
    ff_apt_update
    ff_apt_install bc jq curl wget iptables iptables-persistent screen dnsmasq
    mkdir -p "$DB_DIR" "$SSL_CERT_DIR" "$BANDWIDTH_DIR" "$BANNER_DIR" "$DNSTT_KEYS_DIR" "$LOGS_DIR" "$CONFIG_DIR"
    touch "$DB_FILE"
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    create_limiter_service
    apply_ssh_optimizations
    apply_ssh_booster_auto
    apply_udp_booster_auto
    [ ! -f "$INSTALL_FLAG_FILE" ] && touch "$INSTALL_FLAG_FILE"
    echo -e "${C_GREEN}✅ Setup finished${C_RESET}"
}

# ========== SPEED OPTIMIZATION MENU ==========
speed_optimization_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           ⚡ SPEED BOOSTERS${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_GREEN}[1]${C_RESET} Standard (1000x)"
        echo -e "  ${C_GREEN}[2]${C_RESET} Medium (2000x)"
        echo -e "  ${C_GREEN}[3]${C_RESET} High (3000x)"
        echo -e "  ${C_GREEN}[4]${C_RESET} Ultra (5000x)"
        echo -e "  ${C_GREEN}[5]${C_RESET} Extreme (10000x)"
        echo -e "\n  ${C_RED}[0]${C_RESET} Return"
        read -p "👉 Choice: " c
        case $c in
            1) apply_booster_standard_ultimate; press_enter ;;
            2) apply_booster_medium_ultimate; press_enter ;;
            3) apply_booster_high_ultimate; press_enter ;;
            4) apply_booster_ultra_ultimate; press_enter ;;
            5) apply_booster_extreme_ultimate; press_enter ;;
            0) return ;;
        esac
    done
}

# ========== UNINSTALL ==========
uninstall_script() {
    clear; show_banner
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_RED}           💥 UNINSTALL SCRIPT${C_RESET}"
    echo -e "${C_RED}═══════════════════════════════════════════════════════════════${C_RESET}\n"
    local -a ru=(); local rmu=false
    mapfile -t ru < <(get_voltrontech_known_users)
    [[ ${#ru[@]} -gt 0 ]] && { echo -e "${C_YELLOW}Users: ${ru[*]}"; read -p "Delete users? (y/n): " ruc; [[ "$ruc" == "y" ]] && rmu=true; }
    read -p "Type 'YES' to confirm: " confirm
    [[ "$confirm" != "YES" ]] && { echo -e "${C_GREEN}✅ Cancelled${C_RESET}"; return; }
    [[ "$rmu" == "true" ]] && delete_voltrontech_user_accounts "${ru[@]}"
    (crontab -l 2>/dev/null | grep -v "reboot") | crontab - 2>/dev/null
    systemctl stop dnstt.service badvpn.service udp-custom.service haproxy falconproxy.service zivpn.service voltrontech-api.service 2>/dev/null
    systemctl disable dnstt.service badvpn.service udp-custom.service falconproxy.service voltrontech-api.service 2>/dev/null
    systemctl stop voltrontech-limiter 2>/dev/null
    systemctl disable voltrontech-limiter 2>/dev/null
    rm -f "$DNSTT_SERVICE_FILE" "$BADVPN_SERVICE_FILE" "$UDP_CUSTOM_SERVICE_FILE" "$FALCONPROXY_SERVICE_FILE"
    rm -f "$LIMITER_SERVICE" "$ZIVPN_SERVICE_FILE" /etc/systemd/system/voltrontech-api.service
    rm -f "$DNSTT_BINARY" "$DNSTT_CLIENT" "$BADVPN_BIN" "$UDP_CUSTOM_BIN"
    rm -f "$FALCONPROXY_BINARY" "$ZIVPN_BIN"
    rm -f "$LIMITER_SCRIPT" "$TRIAL_CLEANUP_SCRIPT"
    rm -rf "$DB_DIR" "$ZIVPN_DIR" "$BADVPN_BUILD_DIR" "$API_DIR"
    rm -f "$SSH_BANNER_FILE" "$0"
    systemctl daemon-reload
    echo -e "\n${C_GREEN}✅ Uninstalled${C_RESET}"
    exit 0
}

# ========== MAIN MENU ==========
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
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "17" "⚡ Speed Optimization" "22" "📊 VPN Data Usage"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s\n" "23" "🖥️ VPS Dashboard"
        echo ""
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}                    🔥 DANGER ZONE${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_RED}%2s${C_RESET}) %-28s  ${C_RED}%2s${C_RESET}) %-25s\n" "99" "Uninstall Script" "0" "Exit"
        echo ""
        read -p "👉 Select: " choice
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
            17) speed_optimization_menu ;;
            18) ssh_banner_menu ;;
            19) auto_reboot_menu ;;
            20) traffic_monitor_menu ;;
            21) torrent_block_menu ;;
            22) show_vpn_data_usage ;;
            23) show_vps_dashboard ;;
            99) uninstall_script ;;
            0) echo -e "\n${C_BLUE}👋 Goodbye!${C_RESET}"; exit 0 ;;
            *) sleep 2 ;;
        esac
    done
}

# ========== START ==========
[[ $EUID -ne 0 ]] && { echo -e "${C_RED}❌ Run as root!${C_RESET}"; exit 1; }
[[ "$1" == "--install-setup" ]] && { initial_setup; exit 0; }
main_menu
