#!/bin/bash
# ================================================================
# VOLTRON TECH ULTIMATE v10.14 — COMPLETE (FINAL)
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

API_DIR="/opt/voltrontech-api"; API_PORT="5000"
API_KEY_FILE="$DB_DIR/api_key.txt"; API_INFO_FILE="$DB_DIR/api_info.txt"
WEB_PANEL_API_DOMAIN="api.voltrontechtx.shop"
WEB_PANEL_NGINX_CONFIG="/etc/nginx/sites-available/voltrontech-api"
WEB_PANEL_NGINX_LINK="/etc/nginx/sites-enabled/voltrontech-api"
WEB_PANEL_SSL_EMAIL_FILE="$DB_DIR/ssl_email.txt"

SELECTED_USER=""; SELECTED_USERS=()

ff_apt_update() { DEBIAN_FRONTEND=noninteractive apt-get update 2>/dev/null || true; }
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
    BANNER_CACHE_ONLINE_USERS=$(pgrep -c -u root sshd 2>/dev/null || echo 0)
    BANNER_CACHE_TS=$now
}

show_banner() {
    refresh_banner_cache
    [[ -t 1 ]] && clear
    echo
    echo -e "${C_PURPLE}   VOLTRON TECH ULTIMATE v10.14 ${C_RESET}${C_DIM}| Premium Edition${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "OS" "$BANNER_CACHE_OS_NAME" "Uptime: $BANNER_CACHE_UP_TIME"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Memory" "${BANNER_CACHE_RAM_USAGE}% Used" "Online: ${C_WHITE}${BANNER_CACHE_ONLINE_USERS}${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Users" "${BANNER_CACHE_TOTAL_USERS} Managed" "Load: ${C_GREEN}${BANNER_CACHE_CPU_LOAD}${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
}

press_enter() { echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to continue..." && read -r; }
invalidate_banner_cache() { BANNER_CACHE_TS=0; }
get_current_mtu() { [ -f "$MTU_CONFIG" ] && cat "$MTU_CONFIG" || echo "512"; }

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
    echo -e "\n  ${C_RED} [ 0]${C_RESET} Cancel"
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

generate_user_banner() {
    local username="$1" expiry="$2" limit="$3" bandwidth_gb="$4"
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
    chmod 644 "$BANNER_DIR/${username}.txt" 2>/dev/null
}

sync_all_banners() {
    mkdir -p "$BANNER_DIR"
    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r user pass expiry limit bw _rest; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            [[ ! -f "$BANNER_DIR/${user}.txt" ]] && generate_user_banner "$user" "$expiry" "$limit" "$bw"
            chmod 644 "$BANNER_DIR/${user}.txt" 2>/dev/null
        done < "$DB_FILE"
    fi
}

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
    local bw_display="Unlimited"; [[ "$bandwidth_gb" != "0" ]] && bw_display="${bandwidth_gb} GB"

    generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
    sync_all_banners
    update_ssh_banners_config

    clear; show_banner
    echo -e "${C_GREEN}✅ User '$username' created!${C_RESET}\n"
    echo -e "  👤 Username: ${C_YELLOW}$username${C_RESET}"
    echo -e "  🔑 Password: ${C_YELLOW}$password${C_RESET}"
    echo -e "  🗓️ Expires:  ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  📶 Limit:    ${C_YELLOW}$limit${C_RESET}"
    echo -e "  📦 BW:       ${C_YELLOW}$bw_display${C_RESET}"

    if [[ -f "$BANNER_ENABLED_FILE" ]]; then
        echo -e "\n${C_CYAN}📌 Banner: ✅ Auto-created${C_RESET}"
    fi
    press_enter
}

delete_user() {
    _select_multi_user_interface "--- 🗑️ Delete Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    echo -e "\n${C_RED}⚠️ Delete ${#SELECTED_USERS[@]} user(s)?${C_RESET}"
    read -p "👉 Confirm (y/n): " confirm
    [[ "$confirm" != "y" ]] && { press_enter; return; }
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
        local cp=$(echo "$line"|cut -d: -f2); local ce=$(echo "$line"|cut -d: -f3); local cl=$(echo "$line"|cut -d: -f4); local cb=$(echo "$line"|cut -d: -f5)
        [[ -z "$cb" ]] && cb="0"
        local cbd="Unlimited"; [[ "$cb" != "0" ]] && cbd="${cb} GB"
        echo -e "\n  Pass=${C_YELLOW}$cp${C_RESET} Exp=${C_YELLOW}$ce${C_RESET} Limit=${C_YELLOW}$cl${C_RESET} BW=${C_YELLOW}$cbd${C_RESET}"
        echo -e "\n  1) 🔑 Pass   2) 🗓️ Expiry   3) 📶 Limit   4) 📦 BW   5) 🔄 Reset BW   0) Finish"
        read -p "👉 Choice: " ec
        case $ec in
            1) read -p "New password: " np; [[ -z "$np" ]] && np=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8); echo "$username:$np" | chpasswd; sed -i "s/^$username:.*/$username:$np:$ce:$cl:$cb:0:ACTIVE/" "$DB_FILE"; echo -e "${C_GREEN}✅ $np${C_RESET}"; press_enter ;;
            2) read -p "New days: " d; if [[ "$d" =~ ^[0-9]+$ ]]; then ne=$(date -d "+$d days" +%Y-%m-%d); chage -E "$ne" "$username"; sed -i "s/^$username:.*/$username:$cp:$ne:$cl:$cb:0:ACTIVE/" "$DB_FILE"; echo -e "${C_GREEN}✅ $ne${C_RESET}"; fi; press_enter ;;
            3) read -p "New limit: " nl; [[ "$nl" =~ ^[0-9]+$ ]] && { sed -i "s/^$username:.*/$username:$cp:$ce:$nl:$cb:0:ACTIVE/" "$DB_FILE"; echo -e "${C_GREEN}✅ $nl${C_RESET}"; }; press_enter ;;
            4) read -p "New BW: " nb; [[ "$nb" =~ ^[0-9]+\.?[0-9]*$ ]] && { sed -i "s/^$username:.*/$username:$cp:$ce:$cl:$nb:0:ACTIVE/" "$DB_FILE"; echo -e "${C_GREEN}✅ $nb${C_RESET}"; }; press_enter ;;
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
    echo -e "${C_BOLD}${C_PURPLE}═══ 📋 MANAGED USERS ═══${C_RESET}\n"
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" ]] && continue
        bandwidth_gb=${bandwidth_gb:-0}
        local oc=$(pgrep -c -u "$user" sshd 2>/dev/null || echo 0)
        local bws="Unlimited"
        if [[ "$bandwidth_gb" != "0" ]]; then
            local ub=0
            [[ -f "$BANDWIDTH_DIR/${user}.usage" ]] && ub=$(cat "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null)
            [[ -z "$ub" ]] && ub=0
            local ug=$(awk "BEGIN {printf \"%.2f\", $ub / 1073741824}")
            local rg=$(awk "BEGIN {r=$bandwidth_gb - $ug; if(r<0) r=0; printf \"%.2f\", r}")
            bws="${ug}/${bandwidth_gb} GB | ${rg} GB left"
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

renew_user() {
    _select_multi_user_interface "--- 🔄 Renew Users ---"
    [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]] && { press_enter; return; }
    read -p "👉 Days to extend: " days
    [[ ! "$days" =~ ^[0-9]+$ ]] && { press_enter; return; }
    local ne=$(date -d "+$days days" +%Y-%m-%d)
    for u in "${SELECTED_USERS[@]}"; do
        chage -E "$ne" "$u"
        local line=$(grep "^$u:" "$DB_FILE")
        local p=$(echo "$line"|cut -d: -f2); local l=$(echo "$line"|cut -d: -f4); local b=$(echo "$line"|cut -d: -f5)
        [[ -z "$b" ]] && b="0"
        sed -i "s/^$u:.*/$u:$p:$ne:$l:$b:0:ACTIVE/" "$DB_FILE"
        usermod -U "$u" &>/dev/null
        echo -e " ✅ ${C_YELLOW}$u${C_RESET} → ${C_GREEN}$ne${C_RESET}"
    done
    press_enter
}

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
        generate_user_banner "$u" "$ed" "$limit" "$bandwidth_gb"
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$u" "$p" "$ed"
        ((created++))
    done
    sync_all_banners
    update_ssh_banners_config
    echo -e "\n${C_GREEN}✅ Created $created users${C_RESET}"
    press_enter
}

view_user_bandwidth() {
    _select_user_interface "--- 📊 View BW ---"
    local u=$SELECTED_USER
    [[ "$u" == "NO_USERS" || -z "$u" ]] && { press_enter; return; }
    clear; show_banner
    local line=$(grep "^$u:" "$DB_FILE")
    local bw=$(echo "$line"|cut -d: -f5)
    [[ -z "$bw" ]] && bw="0"
    local ub=0
    [[ -f "$BANDWIDTH_DIR/${u}.usage" ]] && ub=$(cat "$BANDWIDTH_DIR/${u}.usage" 2>/dev/null)
    [[ -z "$ub" ]] && ub=0
    local ug=$(awk "BEGIN {printf \"%.3f\", $ub / 1073741824}")
    echo -e "  Used: ${C_WHITE}${ug} GB${C_RESET}"
    if [[ "$bw" == "0" ]]; then
        echo -e "  Limit: ${C_GREEN}Unlimited${C_RESET}"
    else
        local qb=$(awk "BEGIN {printf \"%.0f\", $bw * 1073741824}")
        local pc=$(awk "BEGIN {printf \"%.1f\", ($ub / $qb) * 100}")
        local rg=$(awk "BEGIN {r=$bw - $ug; if(r<0) r=0; printf \"%.3f\", r}")
        echo -e "  Limit: ${C_YELLOW}${bw} GB${C_RESET}"
        echo -e "  Remaining: ${C_WHITE}${rg} GB${C_RESET}"
        echo -e "  Usage: ${C_WHITE}${pc}%${C_RESET}"
    fi
    press_enter
}

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
    echo "$TRIAL_CLEANUP_SCRIPT $username" | at now + ${duration_hours} hours 2>/dev/null
    generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
    sync_all_banners
    update_ssh_banners_config
    clear; show_banner
    echo -e "${C_GREEN}✅ Trial created!${C_RESET}\n"
    echo -e "  👤 ${C_YELLOW}$username${C_RESET}"
    echo -e "  🔑 ${C_YELLOW}$password${C_RESET}"
    echo -e "  ⏱️ ${C_CYAN}$duration_label${C_RESET}"
    echo -e "  🕐 ${C_RED}$expiry_timestamp${C_RESET}"
    press_enter
}

# ========== CLIENT CONFIG ==========
client_config_menu() {
    clear; show_banner
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}              📱 SSH MANAGER CONFIG${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    local ssh_port=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); ssh_port=${ssh_port:-22}
    local domain=""
    [ -f "$DB_DIR/domain.txt" ] && domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
    echo -e "${C_CYAN}═══ Server Info ═══${C_RESET}"
    echo -e "  ${C_YELLOW}IP${C_RESET}       : $ip"
    echo -e "  ${C_YELLOW}SSH Port${C_RESET} : $ssh_port"
    echo -e "  ${C_YELLOW}SNI/Host${C_RESET} : ${domain:-$ip}\n"
    echo -e "  ${C_GREEN} 1)${C_RESET} 📋 Select user — Show config"
    echo -e "  ${C_GREEN} 2)${C_RESET} 📊 List all users — Bulk config"
    echo -e "  ${C_GREEN} 3)${C_RESET} 📄 JSON export (NapsternetV)"
    echo ""
    echo -e "  ${C_RED} 0)${C_RESET} Return"
    echo ""
    read -p "👉 Choice: " c
    case $c in
        1) _select_user_interface "--- Select User ---"; local u=$SELECTED_USER; [[ "$u" == "NO_USERS" || -z "$u" ]] && return; local p=$(grep "^$u:" "$DB_FILE" | cut -d: -f2); generate_client_config "$u" "$p" ;;
        2)
            clear; show_banner
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
        echo -e "  Host : $ip"
        echo -e "  SSL  : 444"
        echo -e "  SNI  : ${domain:-$ip}"
        echo -e "  User : $u"
        echo -e "  Pass : $p\n"
    fi
    if systemctl is-active --quiet dnstt 2>/dev/null && [ -n "$domain" ]; then
        echo -e "${C_GREEN}📡 DNSTT / SLOWDNS${C_RESET}"
        echo -e "  Nameserver : $domain"
        echo -e "  PubKey     : $pubkey"
        echo -e "  DNS IP     : 1.1.1.1"
        echo -e "  MTU        : $mtu"
        echo -e "  User       : $u"
        echo -e "  Pass       : $p\n"
    fi
    if systemctl is-active --quiet badvpn 2>/dev/null; then
        echo -e "${C_GREEN}⚡ BADVPN UDPGW${C_RESET}"
        echo -e "  Host : $ip"
        echo -e "  Port : 7300\n"
    fi
    if systemctl is-active --quiet zivpn 2>/dev/null; then
        echo -e "${C_GREEN}🛡️ ZiVPN${C_RESET}"
        echo -e "  Host : $ip"
        echo -e "  UDP  : 5667\n"
    fi
    press_enter
}

generate_client_json() {
    local u=$1 p=$2
    clear; show_banner
    local line=$(grep "^$u:" "$DB_FILE"); local expiry=$(echo "$line"|cut -d: -f3); local limit=$(echo "$line"|cut -d: -f4)
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null); local domain=""; [ -f "$DB_DIR/domain.txt" ] && domain=$(cat "$DB_DIR/domain.txt" 2>/dev/null)
    local ssh_port=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); ssh_port=${ssh_port:-22}
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}                 📄 JSON EXPORT: $u${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
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

# ========== SPEED BOOSTERS ==========
apply_booster_standard_ultimate() {
    echo -e "\n${C_BLUE}⚡ STANDARD (1000x) — buffer 512${C_RESET}"
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=512 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=512 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=1000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=524288 >/dev/null 2>&1
    ulimit -n 10485760 2>/dev/null
    echo -e "${C_GREEN}✅ 1000x${C_RESET}"
}

apply_booster_medium_ultimate() {
    echo -e "\n${C_BLUE}⚡ MEDIUM (2000x) — buffer 5120${C_RESET}"
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
    echo -e "${C_GREEN}✅ 2000x${C_RESET}"
}

apply_booster_high_ultimate() {
    echo -e "\n${C_BLUE}⚡ HIGH (3000x) — buffer 51200${C_RESET}"
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null; modprobe sch_fq 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=51200 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=51200 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=4294967296 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=4294967296 >/dev/null 2>&1
    sysctl -w net.core.netdev_max_backlog=4000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=2097152 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=160000000 >/dev/null 2>&1
    ulimit -n 41943040 2>/dev/null
    echo -e "${C_GREEN}✅ 3000x${C_RESET}"
}

apply_booster_ultra_ultimate() {
    echo -e "\n${C_BLUE}🚀 ULTRA (5000x) — buffer 512000${C_RESET}"
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null; modprobe sch_fq 2>/dev/null
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
    echo -e "${C_GREEN}✅ 5000x${C_RESET}"
}

apply_booster_extreme_ultimate() {
    echo -e "\n${C_BLUE}💥 EXTREME (10000x) — buffer 5120000${C_RESET}"
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null; modprobe sch_fq 2>/dev/null
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
    command -v irqbalance &>/dev/null && systemctl restart irqbalance 2>/dev/null
    echo -e "${C_GREEN}✅ 10000x${C_RESET}"
}

apply_booster_ultra_plus() {
    echo -e "\n${C_BLUE}🚀 ULTRA PLUS — buffer 6291456${C_RESET}"
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=805306368 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=805306368 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Ultra+${C_RESET}"
}

apply_booster_extreme_plus() {
    echo -e "\n${C_BLUE}💥 EXTREME PLUS — buffer 12582912${C_RESET}"
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Extreme+${C_RESET}"
}

# ========== DNSTT ==========
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
    echo -e "  ${C_GREEN} 1)${C_RESET} 512   ${C_DIM}(default, works everywhere)${C_RESET}"
    echo -e "  ${C_GREEN} 2)${C_RESET} 900   ${C_DIM}(stable)${C_RESET}"
    echo -e "  ${C_GREEN} 3)${C_RESET} 1200  ${C_DIM}(balanced)${C_RESET}"
    echo -e "  ${C_GREEN} 4)${C_RESET} 1400  ${C_DIM}(fast)${C_RESET}"
    echo -e "  ${C_GREEN} 5)${C_RESET} 1500  ${C_DIM}(max)${C_RESET}"
    echo -e "  ${C_GREEN} 6)${C_RESET} Custom ${C_DIM}(512-1500)${C_RESET}"
    echo ""
    read -p "👉 Choice [1]: " mtu_choice; mtu_choice=${mtu_choice:-1}
    case $mtu_choice in
        1) MTU=512 ;; 2) MTU=900 ;; 3) MTU=1200 ;; 4) MTU=1400 ;; 5) MTU=1500 ;;
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
    echo -e "  ${C_GREEN} 1)${C_RESET} Standard   (1000x)   ${C_DIM}buffer 512${C_RESET}"
    echo -e "  ${C_GREEN} 2)${C_RESET} Medium     (2000x)   ${C_DIM}buffer 5120${C_RESET}"
    echo -e "  ${C_GREEN} 3)${C_RESET} High       (3000x)   ${C_DIM}buffer 51200${C_RESET}"
    echo -e "  ${C_GREEN} 4)${C_RESET} Ultra      (5000x)   ${C_DIM}buffer 512000${C_RESET}"
    echo -e "  ${C_GREEN} 5)${C_RESET} Extreme    (10000x)  ${C_DIM}buffer 5120000${C_RESET}"
    echo -e "  ${C_GREEN} 6)${C_RESET} Ultra Plus (768MB)   ${C_DIM}buffer 6291456${C_RESET}"
    echo -e "  ${C_GREEN} 7)${C_RESET} Extreme+   (1GB)     ${C_DIM}buffer 12582912${C_RESET}"
    echo -e "  ${C_GREEN} 8)${C_RESET} Skip"
    echo ""
    read -p "👉 Choice [3]: " b; b=${b:-3}
    case $b in
        1) apply_booster_standard_ultimate ;; 2) apply_booster_medium_ultimate ;;
        3) apply_booster_high_ultimate ;; 4) apply_booster_ultra_ultimate ;;
        5) apply_booster_extreme_ultimate ;; 6) apply_booster_ultra_plus ;;
        7) apply_booster_extreme_plus ;; 8) echo "Skipped" ;;
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
        echo ""
        read -p "👉 Choice: " c
        case $c in
            1) dnstt_domain_menu ;; 2) dnstt_key_menu ;; 3) dnstt_mtu_menu ;;
            4) dnstt_speed_menu ;; 5) show_dnstt_full_details ;;
            0) return ;; *) sleep 2 ;;
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
        echo -e "  ${C_GREEN} 1)${C_RESET} Set Custom Domain"
        echo -e "  ${C_GREEN} 2)${C_RESET} Auto-Generate Domain"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
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
        echo -e "  ${C_GREEN} 1)${C_RESET} Set Custom Public Key"
        echo -e "  ${C_GREEN} 2)${C_RESET} Regenerate Keys"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
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
        echo -e "  ${C_GREEN} 1)${C_RESET} 512"
        echo -e "  ${C_GREEN} 2)${C_RESET} 900"
        echo -e "  ${C_GREEN} 3)${C_RESET} 1200"
        echo -e "  ${C_GREEN} 4)${C_RESET} 1400"
        echo -e "  ${C_GREEN} 5)${C_RESET} 1500"
        echo -e "  ${C_GREEN} 6)${C_RESET} Custom"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
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

dnstt_speed_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                 ⚡ DNSTT SPEED BOOSTERS${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_GREEN} 1)${C_RESET} Standard   (1000x)   → 10-15 Mbps   ${C_DIM}buffer 512${C_RESET}"
        echo -e "  ${C_GREEN} 2)${C_RESET} Medium     (2000x)   → 15-20 Mbps   ${C_DIM}buffer 5120${C_RESET}"
        echo -e "  ${C_GREEN} 3)${C_RESET} High       (3000x)   → 20-25 Mbps   ${C_DIM}buffer 51200${C_RESET}"
        echo -e "  ${C_GREEN} 4)${C_RESET} Ultra      (5000x)   → 25-35 Mbps   ${C_DIM}buffer 512000${C_RESET}"
        echo -e "  ${C_GREEN} 5)${C_RESET} Extreme    (10000x)  → 35-50 Mbps   ${C_DIM}buffer 5120000${C_RESET}"
        echo -e "  ${C_GREEN} 6)${C_RESET} Ultra Plus (768MB)   → 40-60 Mbps   ${C_DIM}buffer 6291456${C_RESET}"
        echo -e "  ${C_GREEN} 7)${C_RESET} Extreme+   (1GB)     → 60-100 Mbps  ${C_DIM}buffer 12582912${C_RESET}"
        echo ""
        echo -e "  ${C_YELLOW} 8)${C_RESET} View Current Settings"
        echo -e "  ${C_RED} 9)${C_RESET} Reset to Default"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
        read -p "👉 Choice: " c
        case $c in
            1) apply_booster_standard_ultimate; press_enter ;;
            2) apply_booster_medium_ultimate; press_enter ;;
            3) apply_booster_high_ultimate; press_enter ;;
            4) apply_booster_ultra_ultimate; press_enter ;;
            5) apply_booster_extreme_ultimate; press_enter ;;
            6) apply_booster_ultra_plus; press_enter ;;
            7) apply_booster_extreme_plus; press_enter ;;
            8) echo -e "\n  TCP: $(sysctl -n net.ipv4.tcp_congestion_control 2>/dev/null)"; echo -e "  UDP rmem: $(sysctl -n net.ipv4.udp_rmem_min 2>/dev/null)"; echo -e "  rmem_max: $(sysctl -n net.core.rmem_max 2>/dev/null)"; press_enter ;;
            9) sysctl -w net.core.rmem_max=212992 >/dev/null 2>&1; sysctl -w net.ipv4.tcp_congestion_control=cubic >/dev/null 2>&1; echo "✅"; press_enter ;;
            0) return ;;
        esac
    done
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
    press_enter
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

# ========== DYNAMIC BANNER (Banner %u — SSH HAIGOMI) ==========
update_ssh_banners_config() {
    grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null || echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
    mkdir -p "$BANNER_DIR" /etc/ssh/sshd_config.d

    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        rm -f "$SSHD_FF_CONFIG" 2>/dev/null
        sshd -t 2>/dev/null && systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        return
    fi

    # Unda banner files kwa users wote kwanza
    sync_all_banners

    # Tumia Banner %u — haiwezi kugoma SSH
    cat > "$SSHD_FF_CONFIG" << 'EOF'
# Voltron Tech - Dynamic Banner
# %u = username — inasoma /etc/voltrontech/banners/<username>.txt
Banner /etc/voltrontech/banners/%u.txt
EOF
    chmod 644 "$SSHD_FF_CONFIG"

    if sshd -t 2>/dev/null; then
        systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    else
        rm -f "$SSHD_FF_CONFIG"
        systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    fi
}

enable_dynamic_banner() {
    mkdir -p "$BANNER_DIR"; touch "$BANNER_ENABLED_FILE"
    sync_all_banners
    update_ssh_banners_config
    if sshd -t 2>/dev/null; then
        systemctl restart voltrontech-limiter 2>/dev/null
        local count=$(grep -c . "$DB_FILE" 2>/dev/null || echo 0)
        echo -e "\n${C_GREEN}✅ Dynamic Banner ENABLED${C_RESET}"
        echo -e "${C_CYAN}📌 Users $count — wote wanaona banner${C_RESET}"
        echo -e "${C_CYAN}📌 Account mpya — banner inaundwa automatic${C_RESET}"
        echo -e "${C_CYAN}📌 Banners zinaupdate kila sekunde 15${C_RESET}"
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
        echo -e "${C_PURPLE}                    🎨 DYNAMIC BANNER${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_CYAN}Status${C_RESET} : $st\n"
        echo -e "  ${C_GREEN} 1)${C_RESET} Enable Dynamic Banner"
        echo -e "  ${C_RED} 2)${C_RESET} Disable Dynamic Banner"
        echo -e "  ${C_GREEN} 3)${C_RESET} Preview Banner"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
        read -p "👉 Choice: " c
        case $c in
            1) enable_dynamic_banner ;;
            2) disable_dynamic_banner ;;
            3) preview_dynamic_ssh_banner ;;
            0) return ;;
        esac
    done
}

# ========== LIMITER ==========
create_limiter_service() {
    cat > "$LIMITER_SCRIPT" << 'LIMEOF'
#!/bin/bash
DB_FILE="/etc/voltrontech/users.db"
BW_DIR="/etc/voltrontech/bandwidth"
PID_DIR="$BW_DIR/pidtrack"
BANNER_DIR="/etc/voltrontech/banners"
BANNER_ENABLED_FILE="/etc/voltrontech/banners_enabled"
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

        oc=$(pgrep -c -u "$user" sshd 2>/dev/null || echo 0)
        [[ "$oc" =~ ^[0-9]+$ ]] || oc=0

        locked=false; expired=false; ex=false
        [[ -n "${lk[$user]+x}" ]] && locked=true

        et=0; dl="N/A"
        if [[ "$expiry" != "Never" && -n "$expiry" ]]; then
            et=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$et" =~ ^[0-9]+$ ]] && (( et > 0 )); then
                df=$((et - ts))
                if (( df <= 0 )); then
                    expired=true; dl="EXPIRED"
                    ! $locked && { usermod -L "$user" &>/dev/null; locked=true; }
                else
                    d=$((df/86400)); h=$(((df%86400)/3600))
                    [[ $d -eq 0 ]] && dl="${h}h left" || dl="${d}d ${h}h"
                fi
            fi
        fi

        (( limit > 0 && oc > limit )) && ! $locked && { usermod -L "$user" &>/dev/null; killall -u "$user" -9 &>/dev/null; locked=true; }

        uf="$BW_DIR/${user}.usage"; ad=0
        [[ -f "$uf" ]] && { read -r ad < "$uf"; [[ "$ad" =~ ^[0-9]+$ ]] || ad=0; }

        if [[ "$bw" != "0" && -n "$bw" ]]; then
            qb=$(awk "BEGIN{printf \"%.0f\", $bw*1073741824}")
            (( qb > 0 && ad >= qb )) && { ex=true; ! $locked && { usermod -L "$user" &>/dev/null; locked=true; }; }
        fi

        if $dyn; then
            if $locked; then acct_status="🔒 LOCKED"; status_color="#FF6B6B"
            elif $expired; then acct_status="🗓️ EXPIRED"; status_color="#FF9F43"
            elif $ex; then acct_status="⚠️ DATA EXHAUSTED"; status_color="#FF6B6B"
            else acct_status="✅ ACTIVE"; status_color="#6BCB77"; fi

            if [[ "$bw" != "0" && -n "$bw" ]]; then
                ug=$(awk "BEGIN{printf \"%.2f\", $ad/1073741824}")
                rg=$(awk "BEGIN{r=$bw-$ug; if(r<0) r=0; printf \"%.2f\", r}")
                bw_info="${ug}/${bw} GB | ${rg} GB left"
            else
                bw_info="Unlimited"
            fi

            UPTIME=$(uptime -p | sed 's/up //')
            LOAD=$(awk '{print $1}' /proc/loadavg)

            bc=""
            bc+="<br><br>"
            bc+="<center><font color=\"#9B59B6\">‎▬▬▬▬▬ஜ۩</font><font color=\"#FF6B6B\" size=\"8\"><b> 🌍VOLTRON VPN🌍</b></font><font color=\"#9B59B6\">‎۩ஜ▬▬▬▬▬</font></center><br>"
            bc+="<br>"
            bc+="<center><font color=\"#4D96FF\" size=\"5\"><b>📋 ACCOUNT DETAILS 📋</b></font></center><br>"
            bc+="<br>"
            bc+="<center><font color=\"#000000\">👤 <b>Username      :</b> $user</font></center><br>"
            bc+="<center><font color=\"#000000\">📅 <b>Expiration    :</b> $expiry ($dl)</font></center><br>"
            bc+="<center><font color=\"#4D96FF\">📊 <b>Bandwidth     :</b> $bw_info</font></center><br>"
            bc+="<center><font color=\"#000000\">🔌 <b>Sessions      :</b> $oc/$limit</font></center><br>"
            bc+="<center><font color=\"$status_color\" size=\"4\"><b>📌 Account Status : $acct_status</b></font></center><br>"
            bc+="<br>"
            bc+="<center><font color=\"#000000\">⏱️ <b>Server Uptime :</b> $UPTIME</font></center><br>"
            bc+="<center><font color=\"#000000\">📈 <b>Server Load   :</b> $LOAD</font></center><br>"
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

            bf="$BANNER_DIR/${user}.txt"; tf="${bf}.tmp"
            printf "%s" "$bc" > "$tf"
            if ! cmp -s "$tf" "$bf" 2>/dev/null; then mv "$tf" "$bf"; else rm -f "$tf"; fi
            chmod 644 "$bf" 2>/dev/null
        fi

        [[ -z "$bw" || "$bw" == "0" ]] && continue
        acc=$ad
        (( oc == 0 )) && { rm -f "$PID_DIR/${user}__"*.last 2>/dev/null; continue; }

        declare -A upids=()
        while read -r sp; do [[ "$sp" =~ ^[0-9]+$ ]] && upids["$sp"]=1; done < <(pgrep -u "$user" sshd 2>/dev/null)

        dt=0
        for pid in "${!upids[@]}"; do
            io="/proc/$pid/io"; cur=0
            [[ -r "$io" ]] && {
                rc=0; wc=0
                while read -r k v; do
                    case "$k" in rchar:) rc=${v:-0};; wchar:) wc=${v:-0};; esac
                done < "$io"
                cur=$((rc+wc))
            }
            pf="$PID_DIR/${user}__${pid}.last"
            [[ -f "$pf" ]] && {
                read -r pv < "$pf"
                [[ "$pv" =~ ^[0-9]+$ ]] || pv=0
                (( cur >= pv )) && d=$((cur-pv)) || d=$cur
                dt=$((dt+d))
            }
            printf "%s\n" "$cur" > "$pf"
        done

        nt=$((acc+dt))
        printf "%s\n" "$nt" > "$uf"
        tg=$(awk "BEGIN{printf \"%.2f\", $nt/1073741824}" 2>/dev/null)
        [[ -n "$tg" ]] && sed -i "s/^$user:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*/$user:$pass:$expiry:$limit:$bw:$tg:$status/" "$DB_FILE" 2>/dev/null
    done < "$DB_FILE"
    sleep $SCAN
done
LIMEOF
    chmod +x "$LIMITER_SCRIPT"
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

# ========== BACKUP ==========
backup_user_data() { clear; show_banner; read -p "Path [/root/vt.tar.gz]: " p; p=${p:-/root/vt.tar.gz}; tar -czf "$p" -C "$(dirname "$DB_DIR")" "$(basename "$DB_DIR")" 2>/dev/null && echo "✅ $p" || echo "❌"; press_enter; }
restore_user_data() { clear; show_banner; read -p "Path: " p; [ ! -f "$p" ] && { echo "❌"; press_enter; return; }; read -p "Confirm? (y/n): " c; [[ "$c" == "y" ]] && { local td=$(mktemp -d); tar -xzf "$p" -C "$td" 2>/dev/null; [ -f "$td/voltrontech/users.db" ] && cp "$td/voltrontech/users.db" "$DB_FILE"; rm -rf "$td"; echo "✅"; }; press_enter; }

# ========== DNS ==========
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

# ========== VPS DASHBOARD ==========
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
        [[ "$st" == "active" ]] && echo -e "    ${C_GREEN}● $s${C_RESET}" || echo -e "    ${C_GRAY}○ $s${C_RESET}"
    done
    echo -e "\n  ${C_GRAY}[Enter] refresh | [0] exit${C_RESET}"
    read -p "👉 " rc
    [[ "$rc" != "0" ]] && show_vps_dashboard
}

show_vpn_data_usage() {
    clear; show_banner
    [[ ! -s "$DB_FILE" ]] && { echo "No users"; press_enter; return; }
    while IFS=: read -r u p e l b _x; do
        [[ -z "$u" ]] && continue
        ub=0; [[ -f "$BANDWIDTH_DIR/${u}.usage" ]] && ub=$(cat "$BANDWIDTH_DIR/${u}.usage")
        [[ -z "$ub" ]] && ub=0
        ug=$(awk "BEGIN{printf \"%.2f\", $ub/1073741824}")
        st=$(get_user_status "$u" | sed 's/\x1b\[[0-9;]*m//g')
        printf "${C_GREEN}%-15s${C_RESET} | ${C_YELLOW}%-10s GB${C_RESET} | %s\n" "$u" "$ug" "$st"
    done < "$DB_FILE"
    press_enter
}

# ========== AUTO REBOOT ==========
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

# ========== CACHE CLEANER ==========
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

# ========== ORPHAN ==========
find_orphan_users() {
    local -a o=()
    while IFS=: read -r u _ uid _ _ h sh; do
        [[ "$uid" =~ ^[0-9]+$ ]] || continue
        (( uid >= 1000 )) || continue
        [[ "$h" == "/home/$u" ]] || continue
        case "$sh" in /usr/sbin/nologin|/usr/bin/false|/bin/false) ;; *) continue ;; esac
        grep -q "^$u:" "$DB_FILE" && continue
        o+=("$u")
    done < /etc/passwd
    printf '%s\n' "${o[@]}"
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

# ========== SYSTEM UTILITIES ==========
system_utilities_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    ⚙️  SYSTEM UTILITIES${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_GREEN} 1)${C_RESET} 💾 Backup User Data"
        echo -e "  ${C_GREEN} 2)${C_RESET} 📥 Restore User Data"
        echo -e "  ${C_GREEN} 3)${C_RESET} 🌐 DNS Manager"
        echo -e "  ${C_GREEN} 4)${C_RESET} 🖥️  VPS Dashboard"
        echo -e "  ${C_GREEN} 5)${C_RESET} 📊 VPN Data Usage"
        echo -e "  ${C_GREEN} 6)${C_RESET} 🔄 Auto Reboot"
        echo -e "  ${C_GREEN} 7)${C_RESET} 🧹 Cache Cleaner"
        echo -e "  ${C_GREEN} 8)${C_RESET} 🔍 Orphan Cleanup"
        echo -e "  ${C_GREEN} 9)${C_RESET} ⚡ Speed Boosters"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
        read -p "👉 Choice: " c
        case $c in
            1) backup_user_data ;; 2) restore_user_data ;; 3) dns_menu ;;
            4) show_vps_dashboard ;; 5) show_vpn_data_usage ;; 6) auto_reboot_menu ;;
            7) cache_cleaner_menu ;; 8) orphan_cleanup_menu ;; 9) dnstt_speed_menu ;;
            0) return ;;
        esac
    done
}

# ========== PROTOCOL MENU (WIMA, RUNNING/STOPPED) ==========
protocol_menu() {
    while true; do
        clear; show_banner
        local bs=$(systemctl is-active badvpn 2>/dev/null); [[ -z "$bs" ]] && bs="inactive"
        local us=$(systemctl is-active udp-custom 2>/dev/null); [[ -z "$us" ]] && us="inactive"
        local hs=$(systemctl is-active haproxy 2>/dev/null); [[ -z "$hs" ]] && hs="inactive"
        local ds=$(systemctl is-active dnstt 2>/dev/null); [[ -z "$ds" ]] && ds="inactive"
        local fs=$(systemctl is-active falconproxy 2>/dev/null); [[ -z "$fs" ]] && fs="inactive"
        local zs=$(systemctl is-active zivpn 2>/dev/null); [[ -z "$zs" ]] && zs="inactive"
        local bs_st=""; [[ "$bs" == "active" ]] && bs_st="${C_GREEN}RUNNING${C_RESET}" || bs_st="${C_GRAY}STOPPED${C_RESET}"
        local us_st=""; [[ "$us" == "active" ]] && us_st="${C_GREEN}RUNNING${C_RESET}" || us_st="${C_GRAY}STOPPED${C_RESET}"
        local hs_st=""; [[ "$hs" == "active" ]] && hs_st="${C_GREEN}RUNNING${C_RESET}" || hs_st="${C_GRAY}STOPPED${C_RESET}"
        local ds_st=""; [[ "$ds" == "active" ]] && ds_st="${C_GREEN}RUNNING${C_RESET}" || ds_st="${C_GRAY}STOPPED${C_RESET}"
        local fs_st=""; [[ "$fs" == "active" ]] && fs_st="${C_GREEN}RUNNING${C_RESET}" || fs_st="${C_GRAY}STOPPED${C_RESET}"
        local zs_st=""; [[ "$zs" == "active" ]] && zs_st="${C_GREEN}RUNNING${C_RESET}" || zs_st="${C_GRAY}STOPPED${C_RESET}"
        local xs=""; command -v x-ui &>/dev/null && xs="${C_GREEN}INSTALLED${C_RESET}" || xs="${C_GRAY}NOT INSTALLED${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}              🔌 PROTOCOL MANAGEMENT${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_GREEN} 1)${C_RESET} badvpn (UDP 7300)       $bs_st"
        echo -e "  ${C_GREEN} 2)${C_RESET} udp-custom              $us_st"
        echo -e "  ${C_GREEN} 3)${C_RESET} SSL Tunnel (HAProxy)    $hs_st"
        echo -e "  ${C_GREEN} 4)${C_RESET} DNSTT (Port 53)         $ds_st"
        echo -e "  ${C_GREEN} 5)${C_RESET} Falcon Proxy            $fs_st"
        echo -e "  ${C_GREEN} 6)${C_RESET} ZiVPN                   $zs_st"
        echo -e "  ${C_GREEN} 7)${C_RESET} X-UI Panel              $xs"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
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

# ========== WEB PANEL MENU (WIMA + CHANGE DOMAIN) ==========
web_panel_menu() {
    while true; do
        clear; show_banner
        local api_st=""
        if [ -f "/etc/systemd/system/voltrontech-api.service" ]; then
            systemctl is-active --quiet voltrontech-api 2>/dev/null && api_st="${C_GREEN}● RUNNING${C_RESET}" || api_st="${C_RED}● STOPPED${C_RESET}"
        else api_st="${C_GRAY}● NOT INSTALLED${C_RESET}"; fi
        local ng_st=""
        command -v nginx &>/dev/null && { systemctl is-active --quiet nginx 2>/dev/null && ng_st="${C_GREEN}● RUNNING${C_RESET}" || ng_st="${C_RED}● STOPPED${C_RESET}"; } || ng_st="${C_GRAY}● NOT INSTALLED${C_RESET}"
        local ssl_st=""
        [ -d "/etc/letsencrypt/live/$WEB_PANEL_API_DOMAIN" ] && ssl_st="${C_GREEN}● INSTALLED${C_RESET}" || ssl_st="${C_YELLOW}● NOT INSTALLED${C_RESET}"
        local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
        local dip=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
        local dns_st=""
        [[ "$dip" == "$ip" ]] && dns_st="${C_GREEN}● OK${C_RESET}" || dns_st="${C_YELLOW}● NOT SET${C_RESET}"

        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    🌐 WEB PANEL${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_CYAN}Domain${C_RESET} : $WEB_PANEL_API_DOMAIN"
        echo -e "  ${C_CYAN}VPS IP${C_RESET} : $ip\n"
        echo -e "  ${C_CYAN}API${C_RESET}    : $api_st"
        echo -e "  ${C_CYAN}Nginx${C_RESET}  : $ng_st"
        echo -e "  ${C_CYAN}SSL${C_RESET}    : $ssl_st"
        echo -e "  ${C_CYAN}DNS${C_RESET}    : $dns_st\n"
        echo -e "  ${C_GREEN} 1)${C_RESET} 🚀 Full Setup (API + DNS + Nginx + SSL)"
        echo -e "  ${C_GREEN} 2)${C_RESET} 📥 Install API Only"
        echo -e "  ${C_GREEN} 3)${C_RESET} 🌐 Setup DNS Only"
        echo -e "  ${C_GREEN} 4)${C_RESET} ⚙️  Setup Nginx Only"
        echo -e "  ${C_GREEN} 5)${C_RESET} 🔒 Setup SSL Only"
        echo -e "  ${C_GREEN} 6)${C_RESET} 🧪 Test Everything"
        echo -e "  ${C_GREEN} 7)${C_RESET} 📋 View Logs"
        echo -e "  ${C_GREEN} 8)${C_RESET} 🔑 View API Info"
        echo -e "  ${C_GREEN} 9)${C_RESET} 🔄 Restart API"
        echo -e "  ${C_GREEN}10)${C_RESET} 📝 Copy for Lovable AI"
        echo -e "  ${C_RED}11)${C_RESET} 🗑️  Remove Web Panel"
        echo -e "  ${C_GREEN}12)${C_RESET} 🌐 Change API Domain"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
        read -p "👉 Select: " c
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
            11) web_panel_remove ;;
            12) web_panel_change_domain ;;
            0) return ;;
        esac
    done
}

# ========== CHANGE API DOMAIN ==========
web_panel_change_domain() {
    clear; show_banner
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}              🌐 CHANGE API DOMAIN${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_CYAN}Current domain${C_RESET} : ${C_YELLOW}$WEB_PANEL_API_DOMAIN${C_RESET}\n"
    echo -e "  ${C_YELLOW}⚠️  Hii itabadilisha:${C_RESET}"
    echo -e "     • API domain kwenye script"
    echo -e "     • Nginx config"
    echo -e "     • DNS record (deSEC)"
    echo -e "     • SSL certificate (Let's Encrypt)"
    echo ""
    read -p "👉 New domain (or '0' cancel): " new_domain
    [[ "$new_domain" == "0" || -z "$new_domain" ]] && return
    [[ ! "$new_domain" =~ ^[a-zA-Z0-9.-]+$ ]] && { echo -e "${C_RED}❌ Invalid domain${C_RESET}"; press_enter; return; }

    read -p "👉 Confirm change to '$new_domain'? (y/n): " confirm
    [[ "$confirm" != "y" ]] && { echo "Cancelled"; press_enter; return; }

    local old_domain="$WEB_PANEL_API_DOMAIN"
    WEB_PANEL_API_DOMAIN="$new_domain"
    sed -i "s|^WEB_PANEL_API_DOMAIN=.*|WEB_PANEL_API_DOMAIN=\"$new_domain\"|" /usr/local/bin/menu

    if [ -f "$WEB_PANEL_NGINX_CONFIG" ]; then
        sed -i "s|server_name $old_domain;|server_name $new_domain;|g" "$WEB_PANEL_NGINX_CONFIG"
        echo -e "${C_GREEN}✅ Nginx config updated${C_RESET}"
    fi

    if [ -d "/etc/letsencrypt/live/$old_domain" ]; then
        certbot delete --cert-name "$old_domain" --non-interactive 2>/dev/null
        echo -e "${C_GREEN}✅ Old SSL removed${C_RESET}"
    fi

    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    local sub=$(echo "$new_domain" | cut -d. -f1)
    local data="[{\"subname\":\"$sub\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$ip\"]}]"
    local r=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$data" 2>/dev/null)
    local hc=$(echo "$r" | tail -1)
    if [[ "$hc" -eq 201 ]] || [[ "$hc" -eq 200 ]]; then
        echo -e "${C_GREEN}✅ DNS created: $new_domain → $ip${C_RESET}"
        sleep 5
    elif [[ "$hc" -eq 409 ]]; then
        curl -s -X PATCH "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$sub/A/" -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "{\"records\":[\"$ip\"],\"ttl\":3600}" >/dev/null 2>&1
        echo -e "${C_GREEN}✅ DNS updated${C_RESET}"
    fi

    nginx -t 2>&1 | grep -q successful && systemctl reload nginx
    systemctl restart voltrontech-api 2>/dev/null

    echo -e "\n${C_GREEN}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}           ✅ DOMAIN CHANGED!${C_RESET}"
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
    echo -e "  ${C_CYAN}New domain${C_RESET} : ${C_YELLOW}$new_domain${C_RESET}"
    echo ""
    echo -e "${C_YELLOW}📌 Hatua zinazofuata:${C_RESET}"
    echo -e "  1) Setup SSL: Web Panel → 5"
    echo -e "  2) Test: Web Panel → 6"
    press_enter
}

web_panel_full_setup() {
    clear; show_banner
    read -p "Continue? (y/n): " c; [[ "$c" != "y" ]] && return
    web_panel_install_api; sleep 2
    web_panel_dns_setup; sleep 2
    web_panel_nginx_setup; sleep 2
    web_panel_ssl_setup; sleep 2
    web_panel_test_all
    press_enter
}

web_panel_install_api() {
    clear; show_banner
    if [ -f "/etc/systemd/system/voltrontech-api.service" ]; then
        read -p "Reinstall? (y/n): " r; [[ "$r" != "y" ]] && return
        systemctl stop voltrontech-api 2>/dev/null; systemctl disable voltrontech-api 2>/dev/null
        rm -f /etc/systemd/system/voltrontech-api.service; systemctl daemon-reload
    fi
    local API_KEY="voltron_$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 32)"
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
            printf 'API_URL=http://%s:%s\nAPI_KEY=%s\n' "$sip" "$API_PORT" "$API_KEY" > "$API_INFO_FILE"
            echo "$API_KEY" > "$API_KEY_FILE"; chmod 600 "$API_KEY_FILE"
            echo -e "\n${C_GREEN}✅ API: http://$sip:$API_PORT${C_RESET}"
            echo -e "${C_GREEN}🔑 Key: $API_KEY${C_RESET}"
        else echo -e "${C_YELLOW}⚠️ Health fail${C_RESET}"; tail -20 /var/log/voltrontech-api.log; fi
    else echo -e "${C_RED}❌ Failed${C_RESET}"; journalctl -u voltrontech-api -n 20 --no-pager; fi
    press_enter
}

web_panel_create_api_code() {
    cat > "$API_DIR/api.py" << 'APIEOF'
#!/usr/bin/env python3
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
BANNER_DIR = f'{DB_DIR}/banners'
BANNER_ENABLED = f'{DB_DIR}/banners_enabled'

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
    for cmd in ['curl -s -4 icanhazip.com', "hostname -I | awk '{print $1}'"]:
        ip = run_shell(cmd, timeout=5).strip()
        if ip and ip.count('.') == 3 and not ip.startswith('127.'): return ip
    return 'unknown'

def create_banner_content(username, expiry, limit, bw):
    bw_display = "Unlimited" if str(bw) == "0" else f"{bw} GB"
    return f"""<br><br>
<center><font color="#9B59B6">‎▬▬▬▬▬ஜ۩</font><font color="#FF6B6B" size="8"><b> 🌍VOLTRON VPN🌍</b></font><font color="#9B59B6">‎۩ஜ▬▬▬▬▬</font></center><br>
<br>
<center><font color="#4D96FF" size="5"><b>📋 ACCOUNT DETAILS 📋</b></font></center><br>
<br>
<center><font color="#000000">👤 <b>Username      :</b> {username}</font></center><br>
<center><font color="#000000">📅 <b>Expiration    :</b> {expiry}</font></center><br>
<center><font color="#4D96FF">📊 <b>Bandwidth     :</b> {bw_display}</font></center><br>
<center><font color="#000000">🔌 <b>Sessions      :</b> 0/{limit}</font></center><br>
<center><font color="#6BCB77" size="4"><b>📌 Account Status : ✅ ACTIVE</b></font></center><br>
<br>
<center><font color="#6BCB77" size="4"><b>📢 JOIN OUR COMMUNITY 📢</b></font></center><br>
<center><font color="#000000">📱 Telegram  : https://t.me/voltrontech</font></center><br>
<center><font color="#000000">💬 WhatsApp  : https://chat.whatsapp.com/EZtAFt9dmS5DVKbNN5iSPz</font></center><br>
<br>
<center><font color="#9B59B6">‎▬▬▬▬▬ஜ۩</font><font color="#FF6B6B" size="8"><b>  🌍VOLTRON VPN🌍 </b></font><font color="#9B59B6">‎۩ஜ▬▬▬▬▬</font></center><br>"""

def create_user_banner(username, expiry, limit, bw):
    try:
        os.makedirs(BANNER_DIR, exist_ok=True)
        content = create_banner_content(username, expiry, limit, bw)
        banner_file = f'{BANNER_DIR}/{username}.txt'
        with open(banner_file, 'w') as f:
            f.write(content)
        os.chmod(banner_file, 0o644)
        return True
    except Exception:
        return False

def sync_all_banners():
    try:
        os.makedirs(BANNER_DIR, exist_ok=True)
        for u in read_users():
            banner_file = f'{BANNER_DIR}/{u["username"]}.txt'
            if not os.path.exists(banner_file):
                create_user_banner(u['username'], u['expiry'], u['limit'], u['bandwidth'])
        return True
    except Exception:
        return False

def setup_sshd_banner_config():
    try:
        os.makedirs('/etc/ssh/sshd_config.d', exist_ok=True)
        with open('/etc/ssh/sshd_config.d/voltron-auto-banner.conf', 'w') as f:
            f.write('# Voltron Tech - Dynamic Banner\n')
            f.write('Banner /etc/voltrontech/banners/%u.txt\n')
        os.chmod('/etc/ssh/sshd_config.d/voltron-auto-banner.conf', 0o644)
        # Ensure Include
        run_shell('grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config || echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config')
        # Test
        test = run_shell('sshd -t 2>&1').strip()
        if test:
            try: os.remove('/etc/ssh/sshd_config.d/voltron-auto-banner.conf')
            except: pass
            return False, test
        # Reload
        run_shell('systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null')
        return True, ''
    except Exception as ex:
        return False, str(ex)

def get_protocols(username=None, password=None, limit=DEFAULT_LIMIT):
    p = {}
    sip = get_server_ip()
    if ssh_active(): p['ssh'] = {'id': 'ssh', 'name': 'SSH', 'icon': '🔐', 'host': SERVER_HOST, 'ip': sip, 'port': 22, 'username': username, 'password': password, 'limit': limit}
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
    if service_active('udp-custom'): p['udp_custom'] = {'id': 'udp_custom', 'name': 'UDP', 'icon': '🚀', 'host': SERVER_HOST, 'ip': sip, 'port_range': '1-65535', 'exclude': '53,5300', 'username': username, 'password': password, 'limit': limit}
    if service_active('badvpn'): p['badvpn'] = {'id': 'badvpn', 'name': 'BadVPN', 'icon': '⚡', 'host': SERVER_HOST, 'ip': sip, 'port': 7300, 'username': username, 'password': password, 'limit': limit}
    if service_active('zivpn'): p['zivpn'] = {'id': 'zivpn', 'name': 'ZiVPN', 'icon': '🛡️', 'host': SERVER_HOST, 'ip': sip, 'port': 5667, 'username': username, 'password': password, 'limit': limit}
    if service_active('falconproxy'): p['falconproxy'] = {'id': 'falconproxy', 'name': 'Falcon', 'icon': '🦅', 'host': SERVER_HOST, 'ip': sip, 'port': 8080, 'username': username, 'password': password, 'limit': limit}
    return p

def now_iso(): return datetime.now().isoformat()

@app.route('/api/health')
def health(): return jsonify({'success': True, 'status': 'ok', 'version': '11.0', 'protocols_active': len(get_protocols()), 'timestamp': now_iso()})

@app.route('/api/trial/check', methods=['POST'])
@require_api_key
def tcheck():
    d = request.get_json() or {}
    u = d.get('username', '').strip().lower()
    if not u or len(u) < 3 or len(u) > 20: return jsonify({'available': False, 'error': 'Invalid'}), 400
    if not u.replace('-', '').replace('_', '').isalnum(): return jsonify({'available': False, 'error': 'Invalid chars'}), 400
    if user_exists(u) or any(x['username'] == u for x in read_users()): return jsonify({'available': False, 'error': 'Taken'})
    return jsonify({'available': True, 'username': u, 'timestamp': now_iso()})

@app.route('/api/trial/create', methods=['POST'])
@require_api_key
def tcreate():
    d = request.get_json() or {}
    u = d.get('username', '').strip().lower(); p = d.get('password', '').strip(); days = int(d.get('days', 1))
    if not u or len(u) < 3 or len(u) > 20: return jsonify({'success': False, 'error': 'Invalid'}), 400
    if not p or len(p) < 4: return jsonify({'success': False, 'error': 'Password too short'}), 400
    if days not in [1, 3, 7]: return jsonify({'success': False, 'error': 'Days 1/3/7'}), 400
    if user_exists(u): return jsonify({'success': False, 'error': 'Exists'}), 400
    try:
        run_safe(['useradd', '-m', '-s', '/usr/sbin/nologin', u])
        run_safe(['usermod', '-aG', 'ffusers', u])
        subprocess.run(['chpasswd'], input=f'{u}:{p}', text=True, capture_output=True)
        e = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', e, u])
        with open(DB_FILE, 'a') as f: f.write(f'{u}:{p}:{e}:{DEFAULT_LIMIT}:0:0:ACTIVE\n')

        # BANNER AUTOMATIC
        banner_enabled = os.path.exists(BANNER_ENABLED)
        banner_created = False
        if banner_enabled:
            banner_created = create_user_banner(u, e, DEFAULT_LIMIT, '0')

        return jsonify({
            'success': True,
            'account': {'username': u, 'password': p, 'expiry': e, 'days': days, 'limit': DEFAULT_LIMIT, 'bandwidth': 'Unlimited', 'server': SERVER_HOST, 'server_ip': get_server_ip()},
            'protocols': get_protocols(u, p, DEFAULT_LIMIT),
            'banner': {'enabled': banner_enabled, 'created': banner_created}
        })
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/trial/status/<username>')
@require_api_key
def tstatus(username):
    user = next((u for u in read_users() if u['username'] == username), None)
    if not user: return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        e = datetime.strptime(user['expiry'], '%Y-%m-%d'); dl = (e - datetime.now()).days
    except: dl = 0
    return jsonify({'success': True, 'account': {'username': username, 'status': get_status(username), 'expiry': user['expiry'], 'days_left': max(0, dl), 'online': get_online(username), 'limit': int(user['limit']), 'bandwidth': user['bandwidth']}})

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
        r.append({'username': u['username'], 'expiry': u['expiry'], 'limit': int(u['limit']), 'bandwidth_limit': float(u['bandwidth']), 'bandwidth_used_gb': round(ub / 1073741824, 2), 'status': get_status(u['username']), 'online': get_online(u['username'])})
    return jsonify({'success': True, 'users': r, 'total': len(r)})

@app.route('/api/users/create', methods=['POST'])
@require_api_key
def ucreate():
    d = request.get_json() or {}
    u = d.get('username', '').strip().lower(); p = d.get('password', '').strip()
    days = int(d.get('days', 30)); limit = int(d.get('limit', DEFAULT_LIMIT)); bw = float(d.get('bandwidth', 0))
    if not u or len(u) < 3 or len(u) > 20: return jsonify({'success': False, 'error': 'Invalid'}), 400
    if not p or len(p) < 4: return jsonify({'success': False, 'error': 'Password too short'}), 400
    if user_exists(u): return jsonify({'success': False, 'error': 'Exists'}), 400
    try:
        run_safe(['useradd', '-m', '-s', '/usr/sbin/nologin', u])
        run_safe(['usermod', '-aG', 'ffusers', u])
        subprocess.run(['chpasswd'], input=f'{u}:{p}', text=True, capture_output=True)
        e = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', e, u])
        with open(DB_FILE, 'a') as f: f.write(f'{u}:{p}:{e}:{limit}:{bw}:0:ACTIVE\n')

        # BANNER AUTOMATIC
        banner_enabled = os.path.exists(BANNER_ENABLED)
        banner_created = False
        if banner_enabled:
            banner_created = create_user_banner(u, e, limit, bw)

        return jsonify({
            'success': True,
            'account': {'username': u, 'password': p, 'expiry': e, 'limit': limit, 'bandwidth': bw},
            'banner': {'enabled': banner_enabled, 'created': banner_created}
        })
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/delete', methods=['POST'])
@require_api_key
def udelete():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u: return jsonify({'success': False, 'error': 'Username required'}), 400
    if not user_exists(u) and not any(x['username'] == u for x in read_users()): return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        run_shell(f'killall -u {u} -9 2>/dev/null'); run_safe(['userdel', '-r', u])
        run_shell(f'rm -f {BANDWIDTH_DIR}/{u}.usage'); run_shell(f"sed -i '/^{u}:/d' {DB_FILE}")
        run_shell(f'rm -f {BANNER_DIR}/{u}.txt')
        return jsonify({'success': True, 'message': f'User {u} deleted'})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/lock', methods=['POST'])
@require_api_key
def ulock():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u or not user_exists(u): return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        run_safe(['usermod', '-L', u]); run_shell(f'killall -u {u} -9 2>/dev/null')
        return jsonify({'success': True, 'message': f'{u} locked'})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/unlock', methods=['POST'])
@require_api_key
def uunlock():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u or not user_exists(u): return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        run_safe(['usermod', '-U', u])
        return jsonify({'success': True, 'message': f'{u} unlocked'})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/edit', methods=['POST'])
@require_api_key
def uedit():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u or not user_exists(u): return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        line = run_shell(f"grep '^{u}:' {DB_FILE}")
        parts = line.split(':')
        cp = parts[1] if len(parts) > 1 else ''; ce = parts[2] if len(parts) > 2 else ''
        cl = parts[3] if len(parts) > 3 else '999'; cb = parts[4] if len(parts) > 4 else '0'
        np = d.get('password', cp); days = d.get('days'); nl = d.get('limit', cl); nb = d.get('bandwidth', cb)
        if np and np != cp: subprocess.run(['chpasswd'], input=f'{u}:{np}', text=True, capture_output=True)
        if days:
            ne = (datetime.now() + timedelta(days=int(days))).strftime('%Y-%m-%d'); run_safe(['chage', '-E', ne, u]); ce = ne
        run_shell(f"sed -i 's|^{u}:.*|{u}:{np}:{ce}:{nl}:{nb}:0:ACTIVE|' {DB_FILE}")
        return jsonify({'success': True, 'account': {'username': u, 'password': np, 'expiry': ce, 'limit': int(nl), 'bandwidth': float(nb)}})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/renew', methods=['POST'])
@require_api_key
def urenew():
    d = request.get_json() or {}
    u = d.get('username', '').strip(); days = int(d.get('days', 30))
    if not u or not user_exists(u): return jsonify({'success': False, 'error': 'Not found'}), 404
    try:
        ne = (datetime.now() + timedelta(days=days)).strftime('%Y-%m-%d')
        run_safe(['chage', '-E', ne, u]); run_safe(['usermod', '-U', u])
        line = run_shell(f"grep '^{u}:' {DB_FILE}"); parts = line.split(':')
        run_shell(f"sed -i 's|^{u}:.*|{u}:{parts[1]}:{ne}:{parts[3]}:{parts[4]}:0:ACTIVE|' {DB_FILE}")
        return jsonify({'success': True, 'expiry': ne})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/users/reset_bandwidth', methods=['POST'])
@require_api_key
def ursbw():
    d = request.get_json() or {}
    u = d.get('username', '').strip()
    if not u or not user_exists(u): return jsonify({'success': False, 'error': 'Not found'}), 404
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
                    run_shell(f'rm -f {BANNER_DIR}/{u}.txt')
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
        return jsonify({'success': True, 'info': {'ip': ip, 'uptime': us, 'users': {'total': len(users), 'online': online}, 'services': {'ssh': ssh_active(), 'dnstt': service_active('dnstt'), 'haproxy': service_active('haproxy'), 'badvpn': service_active('badvpn'), 'udp_custom': service_active('udp-custom'), 'zivpn': service_active('zivpn')}}})
    except Exception as ex: return jsonify({'success': False, 'error': str(ex)}), 500

# ============ BANNER MANAGEMENT ============
@app.route('/api/banner/status')
@require_api_key
def banner_status():
    enabled = os.path.exists(BANNER_ENABLED)
    total_users = len(read_users())
    banner_count = 0
    if os.path.exists(BANNER_DIR):
        banner_count = len([f for f in os.listdir(BANNER_DIR) if f.endswith('.txt')])
    return jsonify({
        'success': True,
        'enabled': enabled,
        'total_users': total_users,
        'banners_created': banner_count,
        'timestamp': now_iso()
    })

@app.route('/api/banner/enable', methods=['POST'])
@require_api_key
def banner_enable():
    try:
        os.makedirs(BANNER_DIR, exist_ok=True)
        # 1. Flag
        with open(BANNER_ENABLED, 'w') as f:
            f.write('enabled')
        # 2. Unda banners zote
        created = 0
        for u in read_users():
            banner_file = f'{BANNER_DIR}/{u["username"]}.txt'
            if not os.path.exists(banner_file):
                if create_user_banner(u['username'], u['expiry'], u['limit'], u['bandwidth']):
                    created += 1
        # 3. SSH config
        ok, err = setup_sshd_banner_config()
        if not ok:
            return jsonify({'success': False, 'error': f'SSH config error: {err}'}), 500
        # 4. Restart limiter
        run_shell('systemctl restart voltrontech-limiter 2>/dev/null')
        return jsonify({
            'success': True,
            'message': 'Dynamic banner enabled',
            'users_total': len(read_users()),
            'banners_created': created,
            'timestamp': now_iso()
        })
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/banner/disable', methods=['POST'])
@require_api_key
def banner_disable():
    try:
        if os.path.exists(BANNER_ENABLED): os.remove(BANNER_ENABLED)
        sshd_conf = '/etc/ssh/sshd_config.d/voltron-auto-banner.conf'
        if os.path.exists(sshd_conf): os.remove(sshd_conf)
        run_shell('systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null')
        return jsonify({'success': True, 'message': 'Dynamic banner disabled', 'timestamp': now_iso()})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

@app.route('/api/banner/user/<username>', methods=['GET'])
@require_api_key
def banner_user(username):
    try:
        banner_file = f'{BANNER_DIR}/{username}.txt'
        if not os.path.exists(banner_file):
            return jsonify({'success': False, 'error': 'Banner not found'}), 404
        with open(banner_file) as f:
            content = f.read()
        return jsonify({'success': True, 'username': username, 'banner': content, 'timestamp': now_iso()})
    except Exception as ex:
        return jsonify({'success': False, 'error': str(ex)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
APIEOF
    chmod +x "$API_DIR/api.py"
}

web_panel_dns_setup() {
    clear; show_banner
    local ip=$(curl -s -4 icanhazip.com 2>/dev/null)
    [[ ! "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]] && { echo "❌"; press_enter; return; }
    echo -e "VPS IP: $ip\nDomain: $WEB_PANEL_API_DOMAIN\n"
    local ex=$(dig +short "$WEB_PANEL_API_DOMAIN" 2>/dev/null | tail -1)
    [[ "$ex" == "$ip" ]] && { echo -e "${C_GREEN}✅ OK${C_RESET}"; press_enter; return; }
    local sub=$(echo "$WEB_PANEL_API_DOMAIN" | cut -d. -f1)
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
    read -p "Email (Enter skip): " em
    [ -n "$em" ] && echo "$em" > "$WEB_PANEL_SSL_EMAIL_FILE"
    if [ -n "$em" ]; then certbot --nginx -d "$WEB_PANEL_API_DOMAIN" --non-interactive --agree-tos -m "$em" --redirect
    else certbot --nginx -d "$WEB_PANEL_API_DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect; fi
    systemctl enable certbot.timer &>/dev/null; systemctl start certbot.timer &>/dev/null
    press_enter
}

web_panel_test_all() {
    clear; show_banner
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
    echo -e "${C_BLUE}[6/6] API key...${C_RESET}"
    if [ -n "$key" ]; then
        curl -s -H "X-API-Key: $key" "https://$WEB_PANEL_API_DOMAIN/api/protocols/status" 2>/dev/null | grep -q '"success":true' && { echo -e "     ${C_GREEN}✅${C_RESET}"; p=$((p+1)); } || { echo -e "     ${C_RED}❌${C_RESET}"; f=$((f+1)); }
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
    [ ! -f "$API_KEY_FILE" ] && { echo "❌ Not installed"; press_enter; return; }
    echo -e "  🌐 https://$WEB_PANEL_API_DOMAIN\n  🔑 $(cat "$API_KEY_FILE")\n"
    echo "Endpoints:"
    echo "  GET  /api/health"
    echo "  POST /api/trial/check"
    echo "  POST /api/trial/create"
    echo "  GET  /api/trial/status/<user>"
    echo "  GET  /api/users/list"
    echo "  POST /api/users/create"
    echo "  POST /api/users/delete"
    echo "  POST /api/users/lock"
    echo "  POST /api/users/unlock"
    echo "  POST /api/users/edit"
    echo "  POST /api/users/renew"
    echo "  POST /api/users/reset_bandwidth"
    echo "  POST /api/cleanup/expired"
    echo "  GET  /api/protocols/status"
    echo "  GET  /api/dashboard/info"
    echo ""
    echo -e "${C_CYAN}🆕 Banner endpoints:${C_RESET}"
    echo "  GET  /api/banner/status          — Angalia hali"
    echo "  POST /api/banner/enable          — Washa banner (kwa wote)"
    echo "  POST /api/banner/disable         — Zima banner"
    echo "  GET  /api/banner/user/<user>     — Angalia banner ya user"
    press_enter
}

web_panel_restart_api() { systemctl restart voltrontech-api; sleep 2; systemctl is-active --quiet voltrontech-api && echo "✅" || echo "❌"; press_enter; }

web_panel_copy_for_lovable() {
    clear; show_banner
    [ ! -f "$API_KEY_FILE" ] && { echo "❌"; press_enter; return; }
    echo "API URL: https://$WEB_PANEL_API_DOMAIN"
    echo "API Key: $(cat "$API_KEY_FILE")"
    echo ""
    echo "Banner Endpoints:"
    echo "  POST /api/banner/enable"
    echo "  POST /api/banner/disable"
    echo "  GET  /api/banner/status"
    press_enter
}

web_panel_remove() {
    clear; show_banner
    read -p "Confirm? (y/n): " c; [[ "$c" != "y" ]] && return
    systemctl stop voltrontech-api 2>/dev/null; systemctl disable voltrontech-api 2>/dev/null
    rm -f /etc/systemd/system/voltrontech-api.service; rm -rf "$API_DIR"
    rm -f "$WEB_PANEL_NGINX_LINK" "$WEB_PANEL_NGINX_CONFIG"
    nginx -t 2>&1 | grep -q successful && systemctl reload nginx
    certbot delete --cert-name "$WEB_PANEL_API_DOMAIN" --non-interactive 2>/dev/null
    systemctl daemon-reload; echo "✅"; press_enter
}

# ========== INITIAL SETUP ==========
initial_setup() {
    echo -e "\n${C_BLUE}🔧 Initial setup...${C_RESET}"
    ff_apt_install curl wget bc iptables openssl dnsutils jq at 2>/dev/null
    mkdir -p "$DB_DIR" "$LOGS_DIR" "$CONFIG_DIR" "$BANDWIDTH_DIR" "$BANNER_DIR" "$DNSTT_KEYS_DIR" "$SSL_CERT_DIR" "$TRAFFIC_DIR" "$BACKUP_DIR"
    touch "$DB_FILE"
    create_limiter_service
    create_traffic_monitor
    systemctl enable atd &>/dev/null; systemctl start atd &>/dev/null
    echo -e "${C_GREEN}✅ Setup complete${C_RESET}"
}

uninstall_script() {
    clear; show_banner
    read -p "Type YES to uninstall: " c
    [[ "$c" != "YES" ]] && { echo "Cancelled"; press_enter; return; }
    systemctl stop dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-api voltrontech-limiter voltron-traffic 2>/dev/null
    systemctl disable dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-api voltrontech-limiter voltron-traffic 2>/dev/null
    rm -f "$DNSTT_SERVICE_FILE" "$BADVPN_SERVICE_FILE" "$UDP_CUSTOM_SERVICE_FILE" "$ZIVPN_SERVICE_FILE" "$FALCONPROXY_SERVICE_FILE" "$LIMITER_SERVICE" "$TRAFFIC_SERVICE" /etc/systemd/system/voltrontech-api.service
    systemctl daemon-reload
    rm -f "$DNSTT_BINARY" "$DNSTT_CLIENT" "$BADVPN_BIN" "$UDP_CUSTOM_BIN" "$ZIVPN_BIN" "$FALCONPROXY_BINARY" "$LIMITER_SCRIPT" "$TRAFFIC_SCRIPT" "$CACHE_SCRIPT" "$TRIAL_CLEANUP_SCRIPT"
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

# ========== MAIN MENU ==========
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

[[ $EUID -ne 0 ]] && { echo -e "${C_RED}❌ Run as root!${C_RESET}"; exit 1; }
[[ "$1" == "--install-setup" ]] && { initial_setup; exit 0; }
[[ ! -f "$INSTALL_FLAG_FILE" ]] && { initial_setup; touch "$INSTALL_FLAG_FILE"; }
main_menu
