#!/bin/bash
# ================================================================
# VOLTRON TECH ULTIMATE v10.16 — COMPLETE (BANNER FULLY FIXED)
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
    echo -e "${C_PURPLE}   VOLTRON TECH ULTIMATE v10.16 ${C_RESET}${C_DIM}| Premium Edition${C_RESET}"
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
            id "$user" >/dev/null 2>&1 || continue
            [[ ! -f "$BANNER_DIR/${user}.txt" ]] && generate_user_banner "$user" "$expiry" "$limit" "$bw"
            chmod 644 "$BANNER_DIR/${user}.txt" 2>/dev/null
        done < "$DB_FILE"
    fi
}

# ═══════════════════════════════════════════════════════════════════════
# MUHIMU: update_ssh_banners_config (function iliyokosekana v10.14)
# - Inazima Banner /etc/bannerssh
# - Inahamisha Include juu
# - Inaweka PrintMotd yes
# - Inaandika Match User * block HALISI
# ═══════════════════════════════════════════════════════════════════════
update_ssh_banners_config() {
    if [[ ! -f /etc/ssh/sshd_config.voltron.bak ]]; then
        cp /etc/ssh/sshd_config /etc/ssh/sshd_config.voltron.bak 2>/dev/null
    fi

    mkdir -p "$BANNER_DIR" /etc/ssh/sshd_config.d

    # FIX #1: Zima Banner /etc/bannerssh (inashinda dynamic banner)
    if grep -q "^Banner /etc/bannerssh" /etc/ssh/sshd_config 2>/dev/null; then
        sed -i 's|^Banner /etc/bannerssh|#Banner /etc/bannerssh  # Disabled by Voltron|' /etc/ssh/sshd_config
    fi

    # FIX #2: Ondoa DebianBanner (inagongana)
    sed -i 's/^DebianBanner yes/#DebianBanner yes  # Disabled by Voltron/' /etc/ssh/sshd_config 2>/dev/null

    # FIX #3: Enable PrintMotd yes
    sed -i 's/^#*PrintMotd.*/PrintMotd yes/' /etc/ssh/sshd_config 2>/dev/null
    grep -q "^PrintMotd" /etc/ssh/sshd_config || echo "PrintMotd yes" >> /etc/ssh/sshd_config

    # FIX #4: Hamisha Include JUU ya sshd_config
    if grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
        local include_line=$(grep -n "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config | head -1 | cut -d: -f1)
        if [[ "$include_line" -gt 5 ]]; then
            sed -i '/^Include \/etc\/ssh\/sshd_config.d/d' /etc/ssh/sshd_config
            sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config
        fi
    else
        sed -i '1i Include /etc/ssh/sshd_config.d/*.conf' /etc/ssh/sshd_config
    fi

    # FIX #5: Futa config za per-user za zamani
    rm -f /etc/ssh/sshd_config.d/voltron-user-*.conf 2>/dev/null

    # FIX #6: Kama banner haija-enable, futa config na urudi
    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        rm -f "$SSHD_FF_CONFIG" 2>/dev/null
        if sshd -t 2>/dev/null; then
            systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        fi
        return
    fi

    # FIX #7: Generate banners kwa users wote
    sync_all_banners

    # FIX #8: Andika Match User * block HALISI
    cat > "$SSHD_FF_CONFIG" << 'EOF'
# ═══════════════════════════════════════════════════════════════
# VOLTRON TECH — Dynamic Per-User SSH Banner
# sshd inasoma file hii kwa kila login
# ═══════════════════════════════════════════════════════════════
Match User *
    Banner /etc/voltrontech/banners/%u.txt
EOF
    chmod 644 "$SSHD_FF_CONFIG"

    # FIX #9: Validate na reload
    if sshd -t 2>/dev/null; then
        systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    else
        rm -f "$SSHD_FF_CONFIG"
        systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    fi
}

enable_dynamic_banner() {
    clear; show_banner
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}           🎨 ENABLING DYNAMIC BANNER${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"

    mkdir -p "$BANNER_DIR"
    echo "enabled" > "$BANNER_ENABLED_FILE"
    chmod 644 "$BANNER_ENABLED_FILE"

    sync_all_banners
    update_ssh_banners_config
    systemctl restart voltrontech-limiter 2>/dev/null

    local count=$(grep -c . "$DB_FILE" 2>/dev/null || echo 0)
    echo -e "${C_GREEN}✅ Dynamic Banner ENABLED${C_RESET}"
    echo -e "${C_CYAN}📌 Users: $count — wote wanaona banner${C_RESET}"
    echo -e "${C_CYAN}📌 SSH config: $(sshd -T 2>&1 | grep -i banner)${C_RESET}"
    echo -e "${C_CYAN}📌 Banners zinaupdate kila sekunde 15 (limiter)${C_RESET}"
    press_enter
}

disable_dynamic_banner() {
    rm -f "$BANNER_ENABLED_FILE" "$SSHD_FF_CONFIG" /etc/ssh/sshd_config.d/voltron-user-*.conf 2>/dev/null
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

diagnose_banner() {
    clear; show_banner
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_PURPLE}           🔍 BANNER DIAGNOSTIC${C_RESET}"
    echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"

    echo -e "${C_BLUE}[1] SSH version:${C_RESET}"
    echo -e "    $(ssh -V 2>&1)"
    echo ""

    echo -e "${C_BLUE}[2] sshd_config ordering:${C_RESET}"
    grep -n "^Include\|^Banner\|^PrintMotd\|^Match" /etc/ssh/sshd_config 2>/dev/null | sed 's/^/    /'
    echo ""

    echo -e "${C_BLUE}[3] Banner config file:${C_RESET}"
    if [[ -f "$SSHD_FF_CONFIG" ]]; then
        cat "$SSHD_FF_CONFIG" | sed 's/^/    /'
    else
        echo -e "    ${C_RED}❌ HAIPO${C_RESET}"
    fi
    echo ""

    echo -e "${C_BLUE}[4] sshd -T effective config:${C_RESET}"
    sshd -T 2>&1 | grep -iE "banner|printmotd" | sed 's/^/    /'
    echo ""

    echo -e "${C_BLUE}[5] Test kwa user wa kwanza:${C_RESET}"
    local tu=$(cut -d: -f1 "$DB_FILE" 2>/dev/null | head -1)
    if [[ -n "$tu" ]]; then
        echo -e "    User: $tu"
        sshd -T -C user="$tu",host=localhost,addr=127.0.0.1 2>&1 | grep -i banner | sed 's/^/    /'
    else
        echo -e "    ${C_YELLOW}⚠️ Hakuna users${C_RESET}"
    fi
    echo ""

    echo -e "${C_BLUE}[6] Banner files:${C_RESET}"
    ls -la "$BANNER_DIR"/ 2>/dev/null | sed 's/^/    /' || echo -e "    ${C_RED}❌ Folder haipo${C_RESET}"
    echo ""

    echo -e "${C_BLUE}[7] Banners enabled flag:${C_RESET}"
    if [[ -f "$BANNER_ENABLED_FILE" ]]; then
        echo -e "    ${C_GREEN}✅ Ipo${C_RESET} (size: $(stat -c %s "$BANNER_ENABLED_FILE") bytes)"
    else
        echo -e "    ${C_RED}❌ HAIPO${C_RESET}"
    fi
    echo ""

    echo -e "${C_BLUE}[8] Limiter status:${C_RESET}"
    echo -e "    $(systemctl is-active voltrontech-limiter 2>/dev/null)"
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
        echo -e "  ${C_GREEN} 4)${C_RESET} 🔍 Diagnose Banner"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
        read -p "👉 Choice: " c
        case $c in
            1) enable_dynamic_banner ;;
            2) disable_dynamic_banner ;;
            3) preview_dynamic_ssh_banner ;;
            4) diagnose_banner ;;
            0) return ;;
        esac
    done
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
    echo -e "\n${C_BLUE}⚡ STANDARD (1000x)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=512 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=512 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ 1000x${C_RESET}"
}
apply_booster_medium_ultimate() {
    echo -e "\n${C_BLUE}⚡ MEDIUM (2000x)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=5120 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=5120 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=2147483648 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=2147483648 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ 2000x${C_RESET}"
}
apply_booster_high_ultimate() {
    echo -e "\n${C_BLUE}⚡ HIGH (3000x)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=51200 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=51200 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=4294967296 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=4294967296 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ 3000x${C_RESET}"
}
apply_booster_ultra_ultimate() {
    echo -e "\n${C_BLUE}🚀 ULTRA (5000x)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=512000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=512000 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=8589934592 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=8589934592 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ 5000x${C_RESET}"
}
apply_booster_extreme_ultimate() {
    echo -e "\n${C_BLUE}💥 EXTREME (10000x)${C_RESET}"
    modprobe tcp_bbr 2>/dev/null; modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=5120000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=5120000 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=17179869184 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=17179869184 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ 10000x${C_RESET}"
}
apply_booster_ultra_plus() {
    echo -e "\n${C_BLUE}🚀 ULTRA PLUS${C_RESET}"
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=6291456 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=805306368 >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Ultra+${C_RESET}"
}
apply_booster_extreme_plus() {
    echo -e "\n${C_BLUE}💥 EXTREME PLUS${C_RESET}"
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=fq >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=12582912 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
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

configure_dnstt_firewall() {
    echo -e "\n${C_BLUE}🔥 Configuring firewall...${C_RESET}"
    ! command -v iptables &>/dev/null && ff_apt_install iptables iptables-persistent
    iptables -t nat -F 2>/dev/null; iptables -F 2>/dev/null
    iptables -A INPUT -p udp --dport 53 -j ACCEPT
    iptables -A INPUT -p udp --dport 5300 -j ACCEPT
    iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null
    echo -e "${C_GREEN}✅ Firewall configured${C_RESET}"
}

install_dnstt() {
    clear; show_banner
    [ -f "$DNSTT_SERVICE_FILE" ] && { read -p "Reinstall? (y/n): " r; [[ "$r" != "y" ]] && return; systemctl stop dnstt.service 2>/dev/null; }
    ff_apt_install wget curl openssl bc dnsutils
    download_dnstt_binary
    local MTU=512
    mkdir -p "$CONFIG_DIR"; echo "$MTU" > "$MTU_CONFIG"
    setup_domain
    generate_keys
    local SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1); SSH_PORT=${SSH_PORT:-22}
    create_dnstt_service "$DOMAIN" "$MTU" "$SSH_PORT"
    configure_dnstt_firewall
    systemctl start dnstt.service; sleep 2
    systemctl is-active --quiet dnstt.service && echo -e "\n${C_GREEN}✅ DNSTT running${C_RESET}" || journalctl -u dnstt.service -n 20 --no-pager
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
        echo -e "  ${C_CYAN}MTU${C_RESET}        : ${C_YELLOW}$(get_current_mtu)${C_RESET}\n"
        echo -e "  ${C_GREEN} 1)${C_RESET} 📊 View Details"
        echo -e "  ${C_GREEN} 2)${C_RESET} ⚡ Speed Boosters"
        echo ""
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
        read -p "👉 Choice: " c
        case $c in
            1) clear; show_banner; cat "$DNSTT_CONFIG_FILE" 2>/dev/null; press_enter ;;
            2) dnstt_speed_menu ;;
            0) return ;;
        esac
    done
}

dnstt_speed_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                 ⚡ DNSTT SPEED BOOSTERS${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        echo -e "  ${C_GREEN} 1)${C_RESET} Standard (1000x)"
        echo -e "  ${C_GREEN} 2)${C_RESET} Medium   (2000x)"
        echo -e "  ${C_GREEN} 3)${C_RESET} High     (3000x)"
        echo -e "  ${C_GREEN} 4)${C_RESET} Ultra    (5000x)"
        echo -e "  ${C_GREEN} 5)${C_RESET} Extreme  (10000x)"
        echo -e "  ${C_GREEN} 6)${C_RESET} Ultra Plus"
        echo -e "  ${C_GREEN} 7)${C_RESET} Extreme Plus"
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
            0) return ;;
        esac
    done
}

# ========== PROTOCOL MENU ==========
protocol_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}              🔌 PROTOCOL MANAGEMENT${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}\n"
        for p in badvpn udp-custom haproxy dnstt zivpn falconproxy; do
            local st=$(systemctl is-active "$p" 2>/dev/null); [[ -z "$st" ]] && st="inactive"
            local sst=""; [[ "$st" == "active" ]] && sst="${C_GREEN}RUNNING${C_RESET}" || sst="${C_GRAY}STOPPED${C_RESET}"
            echo -e "  $p: $sst"
        done
        echo ""
        echo -e "  ${C_GREEN} 1)${C_RESET} DNSTT Menu     ${C_GREEN} 2)${C_RESET} Speed Boosters"
        echo -e "  ${C_RED} 0)${C_RESET} Return"
        echo ""
        read -p "👉 Choice: " c
        case $c in
            1) dnstt_main_menu ;;
            2) dnstt_speed_menu ;;
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

# ========== BACKUP ==========
backup_user_data() { clear; show_banner; read -p "Path [/root/vt.tar.gz]: " p; p=${p:-/root/vt.tar.gz}; tar -czf "$p" -C "$(dirname "$DB_DIR")" "$(basename "$DB_DIR")" 2>/dev/null && echo "✅ $p" || echo "❌"; press_enter; }
restore_user_data() { clear; show_banner; read -p "Path: " p; [ ! -f "$p" ] && { echo "❌"; press_enter; return; }; read -p "Confirm? (y/n): " c; [[ "$c" == "y" ]] && { local td=$(mktemp -d); tar -xzf "$p" -C "$td" 2>/dev/null; [ -f "$td/voltrontech/users.db" ] && cp "$td/voltrontech/users.db" "$DB_FILE"; rm -rf "$td"; echo "✅"; update_ssh_banners_config; }; press_enter; }

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
    for s in sshd dnstt haproxy badvpn udp-custom zivpn falconproxy voltrontech-limiter nginx; do
        st=$(systemctl is-active "$s" 2>/dev/null)
        [[ "$st" == "active" ]] && echo -e "    ${C_GREEN}● $s${C_RESET}" || echo -e "    ${C_GRAY}○ $s${C_RESET}"
    done
    echo -e "\n  ${C_GRAY}[Enter] refresh | [0] exit${C_RESET}"
    read -p "👉 " rc
    [[ "$rc" != "0" ]] && show_vps_dashboard
}

orphan_cleanup_menu() {
    clear; show_banner
    local -a orphans=()
    while IFS=: read -r u _ uid _ _ h sh; do
        [[ "$uid" =~ ^[0-9]+$ ]] || continue
        (( uid >= 1000 )) || continue
        [[ "$h" == "/home/$u" ]] || continue
        case "$sh" in /usr/sbin/nologin|/usr/bin/false|/bin/false) ;; *) continue ;; esac
        grep -q "^$u:" "$DB_FILE" && continue
        orphans+=("$u")
    done < /etc/passwd
    [[ ${#orphans[@]} -eq 0 ]] && { echo -e "${C_GREEN}✅ No orphans${C_RESET}"; press_enter; return; }
    echo -e "Found ${#orphans[@]} orphans: ${C_RED}${orphans[*]}${C_RESET}"
    read -p "Delete all? (y/n): " c
    [[ "$c" == "y" ]] && delete_voltrontech_user_accounts "${orphans[@]}"
    press_enter
}

# ========== INITIAL SETUP ==========
initial_setup() {
    echo -e "\n${C_BLUE}🔧 Initial setup...${C_RESET}"
    ff_apt_install curl wget bc iptables openssl dnsutils jq at 2>/dev/null
    mkdir -p "$DB_DIR" "$LOGS_DIR" "$CONFIG_DIR" "$BANDWIDTH_DIR" "$BANNER_DIR" "$DNSTT_KEYS_DIR" "$SSL_CERT_DIR" "$TRAFFIC_DIR" "$BACKUP_DIR"
    touch "$DB_FILE"
    create_limiter_service
    systemctl enable atd &>/dev/null; systemctl start atd &>/dev/null
    echo -e "${C_GREEN}✅ Setup complete${C_RESET}"
}

uninstall_script() {
    clear; show_banner
    read -p "Type YES to uninstall: " c
    [[ "$c" != "YES" ]] && { echo "Cancelled"; press_enter; return; }
    systemctl stop dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-limiter 2>/dev/null
    systemctl disable dnstt badvpn udp-custom haproxy zivpn falconproxy voltrontech-limiter 2>/dev/null
    rm -f "$DNSTT_SERVICE_FILE" "$BADVPN_SERVICE_FILE" "$UDP_CUSTOM_SERVICE_FILE" "$ZIVPN_SERVICE_FILE" "$FALCONPROXY_SERVICE_FILE" "$LIMITER_SERVICE"
    systemctl daemon-reload
    rm -f "$DNSTT_BINARY" "$DNSTT_CLIENT" "$BADVPN_BIN" "$UDP_CUSTOM_BIN" "$ZIVPN_BIN" "$FALCONPROXY_BINARY" "$LIMITER_SCRIPT" "$TRIAL_CLEANUP_SCRIPT"
    rm -rf "$DB_DIR" "$ZIVPN_DIR"
    rm -f "$SSHD_FF_CONFIG" /etc/ssh/sshd_config.d/voltron-user-*.conf
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
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "6" "Trial Account" "12" "Client Config"
        echo ""
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_PURPLE}                    🔌 PROTOCOLS & SERVICES${C_RESET}"
        echo -e "${C_PURPLE}═══════════════════════════════════════════════════════════════════${C_RESET}"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "13" "Protocols" "17" "Dynamic Banner"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "14" "DNSTT Manage" "18" "Speed Boosters"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s\n" "15" "VPS Dashboard"
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s\n" "16" "Orphan Cleanup"
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
            15) show_vps_dashboard ;;
            16) orphan_cleanup_menu ;;
            17) ssh_banner_menu ;;
            18) dnstt_speed_menu ;;
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
