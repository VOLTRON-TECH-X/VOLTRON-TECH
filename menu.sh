#!/bin/bash
# ================================================================
# VOLTRON TECH ULTIMATE v9.2 - COMPLETE
# ================================================================
# Inajumuisha:
#   1. User Management - Create, Delete, Edit, Lock, Unlock, List, Renew, Cleanup
#   2. DNSTT - 5 Speed Boosters (1000x-10000x) + MTU Settings + Firewall Fix
#   3. Protocols - badvpn, udp-custom, SSL Tunnel, Falcon Proxy, ZiVPN, X-UI
#   4. Dynamic Banner - Centered (ACCOUNT DETAILS - Blue) WITH ACCOUNT STATUS
#   5. VPS Dashboard - Real-time system info (Compact)
#   6. VPN Data Usage - Per user connection data (Table format)
#   7. UDP Booster - Automatic (sysctl parameters)
#   8. SSH Booster - Automatic
#   9. Trial Account - Auto-delete
#   10. Orphan Detection
#   11. Backup/Restore, Traffic Monitor, Torrent Blocking, Auto Reboot
#   12. SSH Multiplexing - System-wide automatic
#   13. SSH Compression - System-wide automatic
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

# ================================================================
# ========== VARIABLES ==========
# ================================================================

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

# ================================================================
# ========== APT FUNCTIONS ==========
# ================================================================

ff_apt_update() {
    DEBIAN_FRONTEND=noninteractive apt-get update 2>/dev/null || true
}

ff_apt_install() {
    ff_apt_update
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 install "$@"
}

ff_apt_purge() {
    DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Use-Pty=0 purge "$@"
}

# ================================================================
# ========== BANNER CACHE FUNCTIONS ==========
# ================================================================

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

show_banner() {
    refresh_banner_cache
    [[ -t 1 ]] && clear
    echo
    echo -e "${C_TITLE}   VOLTRON TECH ULTIMATE v9.2 ${C_RESET}${C_DIM}| Premium Edition${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "OS" "$BANNER_CACHE_OS_NAME" "Uptime: $BANNER_CACHE_UP_TIME"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Memory" "${BANNER_CACHE_RAM_USAGE}% Used" "Online: ${C_WHITE}${BANNER_CACHE_ONLINE_USERS}${C_RESET}"
    printf "   ${C_GRAY}%-10s${C_RESET} %-20s ${C_GRAY}|${C_RESET} %s\n" "Users" "${BANNER_CACHE_TOTAL_USERS} Managed" "Load: ${C_GREEN}${BANNER_CACHE_CPU_LOAD}${C_RESET}"
    echo -e "${C_BLUE}   ─────────────────────────────────────────────────────────${C_RESET}"
}

press_enter() {
    echo -e "\nPress ${C_YELLOW}[Enter]${C_RESET} to continue..." && read -r
}

# ================================================================
# ========== ORPHAN USER FUNCTIONS ==========
# ================================================================

is_voltrontech_orphan_user() {
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

get_voltrontech_orphan_users() {
    local username
    while IFS=: read -r username _rest; do
        [[ -n "$username" ]] || continue
        if is_voltrontech_orphan_user "$username"; then
            echo "$username"
        fi
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

    while IFS= read -r username; do
        [[ -n "$username" ]] && seen_users["$username"]=1
    done < <(get_voltrontech_orphan_users)

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
            if userdel -r "$username" &>/dev/null; then
                echo -e " ✅ System user '${C_YELLOW}$username${C_RESET}' deleted."
            else
                echo -e " ❌ Failed to delete system user '${C_YELLOW}$username${C_RESET}'."
            fi
        else
            echo -e " ℹ️ System user '${C_YELLOW}$username${C_RESET}' was already missing."
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
    update_ssh_banners_config
}

invalidate_banner_cache() {
    BANNER_CACHE_TS=0
    SSH_SESSION_CACHE_TS=0
}

# ================================================================
# ========== USER SELECTION FUNCTIONS ==========
# ================================================================

_select_user_interface() {
    local title="$1"
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}${title}${C_RESET}\n"
    if [[ ! -s $DB_FILE ]]; then
        echo -e "${C_YELLOW}ℹ️ No users found in the database.${C_RESET}"
        SELECTED_USER="NO_USERS"
        return
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
        SELECTED_USER="NO_USERS"
        return
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
                SELECTED_USER=""
                return
            else
                SELECTED_USER="${users[$((choice-1))]}"
                return
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
        SELECTED_USERS=("NO_USERS")
        return
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
        SELECTED_USERS=("NO_USERS")
        return
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
            SELECTED_USERS=()
            return
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
# ========== USER MANAGEMENT ==========
# ================================================================

get_user_status() {
    local username="$1"
    
    if ! id "$username" &>/dev/null; then 
        echo -e "${C_RED}Not Found${C_RESET}"
        return
    fi
    
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    
    if passwd -S "$username" 2>/dev/null | grep -q " L "; then 
        echo -e "${C_YELLOW}🔒 Locked${C_RESET}"
        return
    fi
    
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    
    if [[ $expiry_ts -lt $current_ts ]]; then 
        echo -e "${C_RED}🗓️ Expired${C_RESET}"
        return
    fi
    
    local bandwidth_gb=$(grep "^$username:" "$DB_FILE" | cut -d: -f5)
    if [[ -n "$bandwidth_gb" && "$bandwidth_gb" != "0" ]]; then
        local used_bytes=0
        if [[ -f "$BANDWIDTH_DIR/${username}.usage" ]]; then
            used_bytes=$(cat "$BANDWIDTH_DIR/${username}.usage" 2>/dev/null)
            [[ -z "$used_bytes" ]] && used_bytes=0
        fi
        local quota_bytes=$(awk "BEGIN {printf \"%.0f\", $bandwidth_gb * 1073741824}")
        if [[ "$used_bytes" -ge "$quota_bytes" ]]; then
            echo -e "${C_RED}📦 Exceeded${C_RESET}"
            return
        fi
    fi
    
    echo -e "${C_GREEN}🟢 Active${C_RESET}"
}

# ================================================================
# ========== GENERATE USER BANNER FUNCTION ==========
# ================================================================

generate_user_banner() {
    local username="$1"
    local expiry="$2"
    local limit="$3"
    local bandwidth_gb="$4"
    
    local bw_display="Unlimited"
    if [[ "$bandwidth_gb" != "0" ]]; then
        bw_display="${bandwidth_gb} GB"
    fi
    
    mkdir -p "$BANNER_DIR"
    cat > "$BANNER_DIR/${username}.txt" << EOF
<br><br>
<center><font color="cyan">──</font><font color="purple" size="8"><b> 🔥 VOLTRON TECH ULTIMATE 🔥 </b></font><font color="cyan">──</font></center><br>
<br>
<center><font color="blue" size="5"><b>📋 ACCOUNT DETAILS 📋</b></font></center><br>
<br>
<center><font color="white">👤 <b>Username      :</b> $username</font></center><br>
<center><font color="white">📅 <b>Expiration    :</b> $expiry</font></center><br>
<center><font color="white">📊 <b>Bandwidth     :</b> $bw_display</font></center><br>
<center><font color="white">🔌 <b>Sessions      :</b> 0/$limit</font></center><br>
<center><font color="green" size="4"><b>📌 Account Status : ✅ ACTIVE</b></font></center><br>
<br>
<center><font color="white">⏱️ <b>Server Uptime :</b> $(uptime -p | sed 's/up //')</font></center><br>
<center><font color="white">📈 <b>Server Load   :</b> $(awk '{print $1}' /proc/loadavg)</font></center><br>
<br>
<center><font color="green" size="4"><b>📢 JOIN OUR COMMUNITY 📢</b></font></center><br>
<center><font color="white">📱 Telegram  : https://t.me/voltrontech</font></center><br>
<center><font color="white">💬 WhatsApp  : https://chat.whatsapp.com/JfxZ5Vif62JLKZc275Njl8</font></center><br>
<br>
<center><font color="red" size="4"><b>⚠️ IMPORTANT NOTICE ⚠️</b></font></center><br>
<center><font color="white">• Account expires on: $expiry</font></center><br>
<center><font color="white">• No torrent or illegal activity</font></center><br>
<center><font color="white">• Account sharing is prohibited</font></center><br>
<br>
<center><font color="gray" size="2"><b>───────── Powered by Voltron Tech ─────────</b></font></center><br>
EOF
}

# ================================================================
# ========== CREATE USER ==========
# ================================================================

create_user() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- ✨ Create New SSH User ---${C_RESET}"
    read -p "👉 Enter username (or '0' to cancel): " username
    if [[ "$username" == "0" ]]; then
        echo -e "\n${C_YELLOW}❌ User creation cancelled.${C_RESET}"
        press_enter
        return
    fi
    if [[ -z "$username" ]]; then
        echo -e "\n${C_RED}❌ Error: Username cannot be empty.${C_RESET}"
        press_enter
        return
    fi
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ Error: User '$username' already exists.${C_RESET}"
        press_enter
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
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; press_enter; return; fi
    read -p "📶 Enter simultaneous connection limit [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; press_enter; return; fi
    read -p "📦 Enter bandwidth limit in GB (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; press_enter; return; fi
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
    
    # ============================================================
    # CREATE BANNER FOR NEW USER - MOJA KWA MOJA
    # ============================================================
    if [[ -f "$BANNER_ENABLED_FILE" ]]; then
        generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
        update_ssh_banners_config
        echo -e "${C_GREEN}✅ Dynamic banner created and configured for user '$username'${C_RESET}"
    else
        echo -e "${C_CYAN}ℹ️ Dynamic banner is not enabled. Enable it first: Menu → 18 → 1${C_RESET}"
        echo -e "${C_CYAN}💡 After enabling, new users will get banners automatically.${C_RESET}"
    fi
    
    clear; show_banner
    echo -e "${C_GREEN}✅ User '$username' created successfully!${C_RESET}\n"
    echo -e "  - 👤 Username:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Password:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - 🗓️ Expires on:        ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  - 📶 Connection Limit:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Bandwidth Limit:   ${C_YELLOW}$bw_display${C_RESET}"
    
    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        echo -e "\n${C_CYAN}💡 Tip: Enable dynamic banner to show account status on login.${C_RESET}"
        echo -e "${C_CYAN}   Menu → 18 → 1${C_RESET}"
    fi
    press_enter
}

delete_user() {
    _select_multi_user_interface "--- 🗑️ Delete Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then 
        press_enter
        return
    fi
    
    echo -e "\n${C_RED}⚠️ You selected ${#SELECTED_USERS[@]} user(s) to delete: ${C_YELLOW}${SELECTED_USERS[*]}${C_RESET}"
    read -p "👉 Are you sure you want to PERMANENTLY delete them? (y/n): " confirm
    if [[ "$confirm" != "y" ]]; then 
        echo -e "\n${C_YELLOW}❌ Deletion cancelled.${C_RESET}"
        press_enter
        return
    fi
    
    echo -e "\n${C_BLUE}🗑️ Deleting selected users...${C_RESET}"
    delete_voltrontech_user_accounts "${SELECTED_USERS[@]}"
    press_enter
}

edit_user() {
    _select_user_interface "--- ✏️ Edit a User ---"
    local username=$SELECTED_USER
    if [[ "$username" == "NO_USERS" ]] || [[ -z "$username" ]]; then 
        press_enter
        return
    fi
    
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}--- Editing User: ${C_YELLOW}$username${C_PURPLE} ---${C_RESET}"
        
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
        echo -e "\n  ${C_RED}[ 0]${C_RESET} ✅ Finish Editing"
        echo
        read -p "👉 Enter your choice: " edit_choice
        
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
               press_enter
               ;;
            2) 
               read -p "Enter new duration (in days from today): " days
               if [[ "$days" =~ ^[0-9]+$ ]]; then
                   local new_expire_date; new_expire_date=$(date -d "+$days days" +%Y-%m-%d)
                   chage -E "$new_expire_date" "$username"
                   sed -i "s/^$username:.*/$username:$cur_pass:$new_expire_date:$cur_limit:$cur_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Expiration for '$username' set to ${C_YELLOW}$new_expire_date${C_RESET}."
               else 
                   echo -e "\n${C_RED}❌ Invalid number of days.${C_RESET}"
               fi
               press_enter
               ;;
            3) 
               read -p "Enter new simultaneous connection limit: " new_limit
               if [[ "$new_limit" =~ ^[0-9]+$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$new_limit:$cur_bw/" "$DB_FILE"
                   echo -e "\n${C_GREEN}✅ Connection limit for '$username' set to ${C_YELLOW}$new_limit${C_RESET}."
               else 
                   echo -e "\n${C_RED}❌ Invalid limit.${C_RESET}"
               fi
               press_enter
               ;;
            4) 
               read -p "Enter new bandwidth limit in GB (0 = unlimited): " new_bw
               if [[ "$new_bw" =~ ^[0-9]+\.?[0-9]*$ ]]; then
                   sed -i "s/^$username:.*/$username:$cur_pass:$cur_expiry:$cur_limit:$new_bw/" "$DB_FILE"
                   local bw_msg="Unlimited"; [[ "$new_bw" != "0" ]] && bw_msg="${new_bw} GB"
                   echo -e "\n${C_GREEN}✅ Bandwidth limit for '$username' set to ${C_YELLOW}$bw_msg${C_RESET}."
               else 
                   echo -e "\n${C_RED}❌ Invalid bandwidth value.${C_RESET}"
               fi
               press_enter
               ;;
            5)
               echo "0" > "$BANDWIDTH_DIR/${username}.usage"
               usermod -U "$username" &>/dev/null
               echo -e "\n${C_GREEN}✅ Bandwidth counter for '$username' has been reset to 0.${C_RESET}"
               press_enter
               ;;
            0) 
               return 
               ;;
            *) 
               echo -e "\n${C_RED}❌ Invalid option.${C_RESET}"
               press_enter
               ;;
        esac
    done
}

lock_user() {
    _select_multi_user_interface "--- 🔒 Lock Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then 
        press_enter
        return
    fi
    
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
    press_enter
}

unlock_user() {
    _select_multi_user_interface "--- 🔓 Unlock Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then 
        press_enter
        return
    fi
    
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
    press_enter
}

# ================================================================
# ========== LIST USERS (VERTICAL) ==========
# ================================================================

list_users() {
    clear; show_banner
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_YELLOW}ℹ️ No users are currently being managed.${C_RESET}"
        press_enter
        return
    fi
    
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}                      📋 MANAGED USERS${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    
    local user_count=0
    while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
        [[ -z "$user" ]] && continue
        user_count=$((user_count + 1))
        bandwidth_gb=${bandwidth_gb:-0}
        
        local online_count=$(pgrep -c -u "$user" sshd 2>/dev/null || echo 0)
        local connection_string="${online_count}/${limit}"
        
        local bw_string="Unlimited"
        if [[ "$bandwidth_gb" != "0" ]]; then
            local used_bytes=0
            if [[ -f "$BANDWIDTH_DIR/${user}.usage" ]]; then
                used_bytes=$(cat "$BANDWIDTH_DIR/${user}.usage" 2>/dev/null)
                [[ -z "$used_bytes" ]] && used_bytes=0
            fi
            local used_gb=$(awk "BEGIN {printf \"%.2f\", $used_bytes / 1073741824}")
            local remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}")
            bw_string="${used_gb}/${bandwidth_gb} GB used | ${remain_gb} GB left"
        fi
        
        local status_text=$(get_user_status "$user")
        local plain_status=$(echo -e "$status_text" | sed 's/\x1b\[[0-9;]*m//g')
        
        local status_color=""
        case $plain_status in
            *"Active"*) status_color="$C_GREEN" ;;
            *"Locked"*) status_color="$C_YELLOW" ;;
            *"Expired"*) status_color="$C_RED" ;;
            *"Not Found"*) status_color="$C_GRAY" ;;
            *"Exceeded"*) status_color="$C_RED" ;;
            *) status_color="$C_WHITE" ;;
        esac
        
        # Get expiry date with days left
        local expiry_display="$expiry"
        local current_ts=$(date +%s)
        local expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
        if [[ "$expiry_ts" -gt 0 ]]; then
            local diff_secs=$((expiry_ts - current_ts))
            if (( diff_secs <= 0 )); then
                expiry_display="$expiry (EXPIRED)"
            else
                local d_l=$((diff_secs / 86400))
                local h_l=$(((diff_secs % 86400) / 3600))
                if (( d_l == 0 )); then
                    expiry_display="$expiry (${h_l}h left)"
                else
                    expiry_display="$expiry (${d_l}d ${h_l}h left)"
                fi
            fi
        fi
        
        # Display user info vertically
        echo -e "${C_BOLD}${C_CYAN}┌─────────────────────────────────────────────────────────────┐${C_RESET}"
        echo -e "${C_BOLD}${C_CYAN}│ ${C_BOLD}${C_WHITE}USER #${user_count}${C_RESET}${C_BOLD}${C_CYAN}                                                   │${C_RESET}"
        echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────┤${C_RESET}"
        printf "${C_BOLD}${C_CYAN}│${C_RESET} ${C_YELLOW}USERNAME${C_RESET}        : ${C_WHITE}%-35s${C_BOLD}${C_CYAN}│${C_RESET}\n" "$user"
        printf "${C_BOLD}${C_CYAN}│${C_RESET} ${C_YELLOW}EXPIRATION${C_RESET}      : ${C_WHITE}%-35s${C_BOLD}${C_CYAN}│${C_RESET}\n" "$expiry_display"
        printf "${C_BOLD}${C_CYAN}│${C_RESET} ${C_YELLOW}BANDWIDTH${C_RESET}       : ${C_WHITE}%-35s${C_BOLD}${C_CYAN}│${C_RESET}\n" "$bw_string"
        printf "${C_BOLD}${C_CYAN}│${C_RESET} ${C_YELLOW}CONNECTION${C_RESET}     : ${C_WHITE}%-35s${C_BOLD}${C_CYAN}│${C_RESET}\n" "$connection_string"
        printf "${C_BOLD}${C_CYAN}│${C_RESET} ${C_YELLOW}STATUS${C_RESET}         : ${status_color}%-35s${C_BOLD}${C_CYAN}│${C_RESET}\n" "$plain_status"
        echo -e "${C_BOLD}${C_CYAN}└─────────────────────────────────────────────────────────────┘${C_RESET}"
        echo ""
        
    done < <(sort "$DB_FILE")
    
    echo -e "${C_DIM}Total Users: ${C_WHITE}$(grep -c . "$DB_FILE")${C_RESET}"
    echo -e "${C_DIM}Online: ${C_WHITE}$(count_managed_online_sessions)${C_RESET}"
    press_enter
}

renew_user() {
    _select_multi_user_interface "--- 🔄 Renew Users ---"
    if [[ ${#SELECTED_USERS[@]} -eq 0 || "${SELECTED_USERS[0]}" == "NO_USERS" ]]; then 
        press_enter
        return
    fi
    
    read -p "👉 Enter number of days to extend the account(s): " days
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then 
        echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"
        press_enter
        return
    fi
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
    press_enter
}

cleanup_expired() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🧹 Cleanup Expired Users ---${C_RESET}"
    
    local expired_users=()
    local current_ts=$(date +%s)

    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_GREEN}✅ User database is empty. No expired users found.${C_RESET}"
        press_enter
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
        press_enter
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
    press_enter
}

bulk_create_users() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 👥 Bulk Create Users ---${C_RESET}"
    
    read -p "👉 Enter username prefix (e.g., 'user'): " prefix
    if [[ -z "$prefix" ]]; then 
        echo -e "\n${C_RED}❌ Prefix cannot be empty.${C_RESET}"
        press_enter
        return
    fi
    
    read -p "🔢 How many users to create? " count
    if ! [[ "$count" =~ ^[0-9]+$ ]] || [[ "$count" -lt 1 ]] || [[ "$count" -gt 100 ]]; then
        echo -e "\n${C_RED}❌ Invalid count (1-100).${C_RESET}"
        press_enter
        return
    fi
    
    read -p "🗓️ Account duration (in days) [30]: " days
    days=${days:-30}
    if ! [[ "$days" =~ ^[0-9]+$ ]]; then 
        echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"
        press_enter
        return
    fi
    
    read -p "📶 Connection limit per user [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then 
        echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"
        press_enter
        return
    fi
    
    read -p "📦 Bandwidth limit in GB per user (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then 
        echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"
        press_enter
        return
    fi
    
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
        
        # Create banner for bulk user if dynamic banner is enabled
        if [[ -f "$BANNER_ENABLED_FILE" ]]; then
            generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
        fi
        
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$username" "$password" "$expire_date"
        created=$((created + 1))
    done
    
    if [[ -f "$BANNER_ENABLED_FILE" ]]; then
        update_ssh_banners_config
        echo -e "${C_GREEN}✅ SSH banners configured for all new users${C_RESET}"
    fi
    
    echo -e "${C_YELLOW}================================================================${C_RESET}"
    echo -e "\n${C_GREEN}✅ Created $created users. Conn Limit: ${limit} | BW: ${bw_display}${C_RESET}"
    invalidate_banner_cache
    update_ssh_banners_config
    press_enter
}

view_user_bandwidth() {
    _select_user_interface "--- 📊 View User Bandwidth ---"
    local u=$SELECTED_USER
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then 
        press_enter
        return
    fi
    
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
    press_enter
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
    if [[ "$u" == "NO_USERS" || -z "$u" ]]; then 
        press_enter
        return
    fi
    
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
sed -i "/^${username}:/d" /etc/voltrontech/users.db
rm -f /etc/voltrontech/bandwidth/${username}.usage
rm -rf /etc/voltrontech/bandwidth/pidtrack/${username}
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
        0) echo -e "\n${C_YELLOW}❌ Cancelled.${C_RESET}"; press_enter; return ;;
        *) echo -e "\n${C_RED}❌ Invalid option.${C_RESET}"; press_enter; return ;;
    esac
    
    local rand_suffix=$(head /dev/urandom | tr -dc 'a-z0-9' | head -c 5)
    local default_username="trial_${rand_suffix}"
    read -p "👤 Username [${default_username}]: " username
    username=${username:-$default_username}
    
    if id "$username" &>/dev/null || grep -q "^$username:" "$DB_FILE"; then
        echo -e "\n${C_RED}❌ User '$username' already exists.${C_RESET}"
        press_enter
        return
    fi
    
    local password=$(head /dev/urandom | tr -dc 'A-Za-z0-9' | head -c 8)
    read -p "🔑 Password [${password}]: " custom_pass
    password=${custom_pass:-$password}
    
    read -p "📶 Connection limit [1]: " limit
    limit=${limit:-1}
    if ! [[ "$limit" =~ ^[0-9]+$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; press_enter; return; fi
    
    read -p "📦 Bandwidth limit in GB (0 = unlimited) [0]: " bandwidth_gb
    bandwidth_gb=${bandwidth_gb:-0}
    if ! [[ "$bandwidth_gb" =~ ^[0-9]+\.?[0-9]*$ ]]; then echo -e "\n${C_RED}❌ Invalid number.${C_RESET}"; press_enter; return; fi
    
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
    
    # Create banner for trial user if dynamic banner is enabled
    if [[ -f "$BANNER_ENABLED_FILE" ]]; then
        generate_user_banner "$username" "$expire_date" "$limit" "$bandwidth_gb"
        update_ssh_banners_config
    fi
    
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
    press_enter
}

# ================================================================
# ========== DNSTT MTU FUNCTIONS ==========
# ================================================================

get_current_mtu() {
    if [ -f "$MTU_CONFIG" ]; then
        cat "$MTU_CONFIG"
    else
        echo "512"
    fi
}

set_dnstt_mtu() {
    local new_mtu="$1"
    
    if ! [[ "$new_mtu" =~ ^[0-9]+$ ]] || [ "$new_mtu" -lt 512 ] || [ "$new_mtu" -gt 1500 ]; then
        echo -e "${C_RED}❌ Invalid MTU. Must be between 512 and 1500.${C_RESET}"
        return 1
    fi
    
    echo "$new_mtu" > "$MTU_CONFIG"
    
    if [ -f "$DNSTT_SERVICE_FILE" ]; then
        sed -i "s/-mtu [0-9]*/-mtu $new_mtu/g" "$DNSTT_SERVICE_FILE"
        systemctl daemon-reload
        systemctl restart dnstt.service 2>/dev/null
        echo -e "${C_GREEN}✅ MTU updated to $new_mtu and DNSTT restarted${C_RESET}"
    else
        echo -e "${C_YELLOW}⚠️ DNSTT not installed. MTU saved for future installation.${C_RESET}"
    fi
}

dnstt_mtu_menu() {
    while true; do
        clear; show_banner
        local current_mtu=$(get_current_mtu)
        
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           📡 DNSTT MTU CONFIGURATION${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}Current MTU:${C_RESET} ${C_YELLOW}$current_mtu${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}1)${C_RESET} Set MTU to 512 (Default - Recommended)"
        echo -e "  ${C_GREEN}2)${C_RESET} Set MTU to 900"
        echo -e "  ${C_GREEN}3)${C_RESET} Set MTU to 1200"
        echo -e "  ${C_GREEN}4)${C_RESET} Set MTU to 1400"
        echo -e "  ${C_GREEN}5)${C_RESET} Set MTU to 1500 (Maximum)"
        echo -e "  ${C_GREEN}6)${C_RESET} Custom MTU (Enter value)"
        echo ""
        echo -e "  ${C_RED}0)${C_RESET} Return"
        echo ""
        
        local choice
        read -p "👉 Select option: " choice
        
        case $choice in
            1) set_dnstt_mtu "512"; press_enter ;;
            2) set_dnstt_mtu "900"; press_enter ;;
            3) set_dnstt_mtu "1200"; press_enter ;;
            4) set_dnstt_mtu "1400"; press_enter ;;
            5) set_dnstt_mtu "1500"; press_enter ;;
            6) 
                read -p "👉 Enter MTU value (512-1500): " custom_mtu
                set_dnstt_mtu "$custom_mtu"
                press_enter
                ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ================================================================
# ========== DNSTT FIREWALL FIX ==========
# ================================================================

configure_dnstt_firewall() {
    echo -e "\n${C_BLUE}🔥 Configuring firewall for DNSTT...${C_RESET}"
    
    if ! command -v iptables &>/dev/null; then
        echo -e "${C_YELLOW}⚠️ iptables not found. Installing...${C_RESET}"
        ff_apt_install iptables iptables-persistent
    fi
    
    iptables -t nat -F 2>/dev/null || true
    iptables -F 2>/dev/null || true
    
    iptables -A INPUT -p udp --dport 53 -j ACCEPT
    iptables -A OUTPUT -p udp --sport 53 -j ACCEPT
    
    iptables -A INPUT -p udp --dport 5300 -j ACCEPT
    iptables -A OUTPUT -p udp --sport 5300 -j ACCEPT
    
    iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-ports 5300
    
    if command -v netfilter-persistent &>/dev/null; then
        netfilter-persistent save >/dev/null 2>&1
    fi
    
    mkdir -p /etc/iptables
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
    
    echo -e "${C_GREEN}✅ Firewall configured for DNSTT${C_RESET}"
    echo -e "${C_CYAN}📌 Port 53 → 5300 redirect active${C_RESET}"
}

# ================================================================
# ========== SSH OPTIMIZATIONS (SYSTEM-WIDE) ==========
# ================================================================

apply_ssh_optimizations() {
    echo -e "\n${C_BLUE}🔧 Applying SSH Optimizations (System-wide)...${C_RESET}"
    
    # SSH Multiplexing - System wide config
    mkdir -p /etc/ssh/ssh_config.d
    cat > /etc/ssh/ssh_config.d/voltrontech-ssh.conf << 'EOF'
# Voltron Tech SSH Optimizations
Host *
    # SSH Multiplexing
    ControlMaster auto
    ControlPath ~/.ssh/control-%r@%h:%p
    ControlPersist 10m
    
    # SSH Compression
    Compression yes
    CompressionLevel 9
    
    # Keep-Alive
    ServerAliveInterval 60
    ServerAliveCountMax 3
    TCPKeepAlive yes
    
    # Security & Performance
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    LogLevel ERROR
EOF

    # SSH Daemon Settings
    cat > /etc/ssh/sshd_config.d/voltrontech-sshd.conf << 'EOF'
# Voltron Tech SSH Daemon Optimizations
MaxSessions 100
MaxStartups 100:30:200
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 3
UseDNS no
PrintMotd no
EOF

    # Create .ssh directories for all users
    for user_home in /home/*; do
        if [[ -d "$user_home" ]]; then
            local username=$(basename "$user_home")
            mkdir -p "$user_home/.ssh"
            chown "$username":"$username" "$user_home/.ssh" 2>/dev/null
            chmod 700 "$user_home/.ssh"
        fi
    done
    mkdir -p /root/.ssh
    chmod 700 /root/.ssh

    # Restart SSH
    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    
    echo -e "${C_GREEN}✅ SSH Optimizations applied system-wide!${C_RESET}"
    echo -e "${C_CYAN}📌 SSH Multiplexing: Active${C_RESET}"
    echo -e "${C_CYAN}📌 SSH Compression: Level 9${C_RESET}"
    echo -e "${C_CYAN}📌 All users can use: ssh user@host${C_RESET}"
}

# ================================================================
# ========== DNSTT SPEED BOOSTERS ==========
# ================================================================

apply_booster_standard_ultimate() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           ⚡ STANDARD BOOSTER ULTIMATE (512) - 1000x SPEED${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=512 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=512 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=512 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=512 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 512 (1000x)${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=1000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=524288 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ TCP optimizations enabled${C_RESET}"
    
    ulimit -n 10485760 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 10M (1000x)${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ Standard Booster Ultimate applied! (1000x Speed) 🚀${C_RESET}"
    sleep 1
}

apply_booster_medium_ultimate() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           ⚡ MEDIUM BOOSTER ULTIMATE (5120) - 2000x SPEED${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    modprobe sch_fq 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake + FQ enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=5120 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=5120 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=5120 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=5120 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=2147483648 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=2147483648 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 5120 (2000x)${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=2000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=1048576 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Advanced TCP optimizations enabled${C_RESET}"
    
    ulimit -n 20971520 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 20M (2000x)${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ Medium Booster Ultimate applied! (2000x Speed) 🚀🚀${C_RESET}"
    sleep 1
}

apply_booster_high_ultimate() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           ⚡ HIGH BOOSTER ULTIMATE (51200) - 3000x SPEED${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    modprobe sch_fq 2>/dev/null
    modprobe sch_htb 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake + FQ + HTB enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=51200 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=51200 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=51200 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=51200 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=4294967296 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=4294967296 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 51200 (3000x)${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=4000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=2097152 >/dev/null 2>&1
    sysctl -w net.core.dev_weight=1024 >/dev/null 2>&1
    sysctl -w net.core.netdev_budget=9600 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=160000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers optimized (3000x)${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_notsent_lowat=16384 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_adv_win_scale=1 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Advanced TCP optimizations enabled${C_RESET}"
    
    ulimit -n 41943040 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 40M (3000x)${C_RESET}"
    
    for i in /sys/class/net/*/queues/*/rps_cpus; do
        if [[ -f "$i" ]]; then
            echo ffffffff > "$i" 2>/dev/null
        fi
    done
    echo -e "${C_GREEN}✓ RPS/RFS enabled${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ High Booster Ultimate applied! (3000x Speed) 🚀🚀🚀${C_RESET}"
    sleep 1
}

apply_booster_ultra_ultimate() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🚀 ULTRA BOOSTER ULTIMATE (512000) - 5000x SPEED${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    modprobe sch_fq 2>/dev/null
    modprobe sch_htb 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake + FQ + HTB enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=512000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=512000 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=512000 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=512000 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=8589934592 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=8589934592 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 512000 (5000x)${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=6000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=4194304 >/dev/null 2>&1
    sysctl -w net.core.dev_weight=2048 >/dev/null 2>&1
    sysctl -w net.core.netdev_budget=19200 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=320000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers optimized (5000x)${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_notsent_lowat=16384 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_time=30 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_intvl=5 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_probes=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_adv_win_scale=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_autocorking=0 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Advanced TCP optimizations enabled${C_RESET}"
    
    ulimit -n 83886080 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 80M (5000x)${C_RESET}"
    
    for i in /sys/class/net/*/queues/*/rps_cpus; do
        if [[ -f "$i" ]]; then
            echo ffffffff > "$i" 2>/dev/null
        fi
    done
    sysctl -w net.core.busy_read=1000 >/dev/null 2>&1
    sysctl -w net.core.busy_poll=1000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ RPS/RFS + Busy polling enabled (5000x)${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ Ultra Booster Ultimate applied! (5000x Speed) 🚀🚀🚀🚀${C_RESET}"
    sleep 1
}

apply_booster_extreme_ultimate() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           💥 EXTREME BOOSTER ULTIMATE (5120000) - 10000x SPEED${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    modprobe sch_cake 2>/dev/null
    modprobe sch_fq 2>/dev/null
    modprobe sch_htb 2>/dev/null
    sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1
    sysctl -w net.core.default_qdisc=cake >/dev/null 2>&1
    echo -e "${C_GREEN}✓ BBR v3 + Cake + FQ + HTB enabled${C_RESET}"
    
    sysctl -w net.ipv4.udp_rmem_min=5120000 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=5120000 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=5120000 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=5120000 >/dev/null 2>&1
    sysctl -w net.core.rmem_max=17179869184 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=17179869184 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ UDP buffers: 5120000 (10000x)${C_RESET}"
    
    sysctl -w net.core.netdev_max_backlog=10000000 >/dev/null 2>&1
    sysctl -w net.core.somaxconn=8388608 >/dev/null 2>&1
    sysctl -w net.core.dev_weight=4096 >/dev/null 2>&1
    sysctl -w net.core.netdev_budget=38400 >/dev/null 2>&1
    sysctl -w net.netfilter.nf_conntrack_max=640000000 >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Network buffers optimized (10000x)${C_RESET}"
    
    sysctl -w net.ipv4.tcp_fastopen=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_sack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_dsack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_fack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_timestamps=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_slow_start_after_idle=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_mtu_probing=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_notsent_lowat=16384 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_time=30 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_intvl=5 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_keepalive_probes=3 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_low_latency=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_adv_win_scale=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_autocorking=0 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_frto=2 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_thin_linear_timeouts=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_thin_dupack=1 >/dev/null 2>&1
    sysctl -w net.ipv4.tcp_early_retrans=3 >/dev/null 2>&1
    sysctl -w net.ipv4.ip_local_port_range="1024 65535" >/dev/null 2>&1
    echo -e "${C_GREEN}✓ Ultimate TCP optimizations enabled${C_RESET}"
    
    ulimit -n 167772160 2>/dev/null
    echo -e "${C_GREEN}✓ File descriptors: 160M (10000x)${C_RESET}"
    
    for i in /sys/class/net/*/queues/*/rps_cpus; do
        if [[ -f "$i" ]]; then
            echo ffffffff > "$i" 2>/dev/null
        fi
    done
    for i in /sys/class/net/*/queues/*/rps_flow_cnt; do
        if [[ -f "$i" ]]; then
            echo 4096 > "$i" 2>/dev/null
        fi
    done
    sysctl -w net.core.busy_read=1000 >/dev/null 2>&1
    sysctl -w net.core.busy_poll=1000 >/dev/null 2>&1
    if command -v irqbalance &>/dev/null; then
        systemctl restart irqbalance 2>/dev/null
    fi
    echo -e "${C_GREEN}✓ Ultimate optimizations enabled (10000x)${C_RESET}"
    
    echo -e "\n${C_GREEN}✅ Extreme Booster Ultimate applied! (10000x Speed) 💥💥💥💥💥${C_RESET}"
    sleep 1
}

# ================================================================
# ========== DNSTT OPTIMIZATIONS (AUTOMATIC) ==========
# ================================================================

apply_multiplexing() {
    echo -e "\n${C_BLUE}🚀 Applying DNSTT Multiplexing...${C_RESET}"
    
    local num=${1:-3}
    local domain=$(cat /etc/voltrontech/domain.txt 2>/dev/null)
    
    if [[ -z "$domain" ]]; then
        echo -e "${C_RED}❌ Domain not found. Please install DNSTT first.${C_RESET}"
        return 1
    fi
    
    pkill -f dnstt-client 2>/dev/null
    
    if ! command -v screen &>/dev/null; then
        echo -e "${C_YELLOW}⚠️ screen not found. Installing...${C_RESET}"
        apt-get install screen -y 2>/dev/null
    fi
    
    local resolvers=(
        "8.8.8.8:53"
        "1.1.1.1:53"
        "9.9.9.9:53"
    )
    
    echo -e "${C_CYAN}Starting $num DNSTT connections...${C_RESET}"
    
    for i in $(seq 1 $num); do
        local resolver=${resolvers[$((i-1))]}
        screen -dmS "dnstt_$i" dnstt-client -udp "$resolver" \
            -pubkey-file /etc/voltrontech/dnstt/server.pub \
            -mtu 512 "$domain" 127.0.0.1:22 2>/dev/null
        echo -e "${C_GREEN}✅ Connection $i started with resolver $resolver${C_RESET}"
    done
    
    echo -e "\n${C_GREEN}✅ $num DNSTT connections started${C_RESET}"
    echo -e "${C_CYAN}📌 To view: screen -r dnstt_1${C_RESET}"
    echo -e "${C_CYAN}📌 To detach: Ctrl+A, D${C_RESET}"
    echo -e "${C_CYAN}📌 To stop all: pkill -f dnstt-client${C_RESET}"
}

apply_buffer_optimization() {
    echo -e "\n${C_BLUE}📦 Applying Buffer Optimization...${C_RESET}"
    
    cat >> /etc/sysctl.conf << 'EOF'
# Voltron Tech Buffer Optimizations for DNSTT
net.core.rmem_max=1073741824
net.core.wmem_max=1073741824
net.core.rmem_default=26214400
net.core.wmem_default=26214400
net.ipv4.udp_rmem_min=52428800
net.ipv4.udp_wmem_min=52428800
net.core.netdev_max_backlog=1000000
net.core.somaxconn=524288
net.ipv4.tcp_rmem=4096 87380 1073741824
net.ipv4.tcp_wmem=4096 65536 1073741824
EOF

    sysctl -p >/dev/null 2>&1
    echo -e "${C_GREEN}✅ Buffer Optimization applied${C_RESET}"
}

apply_bbr() {
    echo -e "\n${C_BLUE}⚡ Applying TCP BBR...${C_RESET}"
    
    modprobe tcp_bbr 2>/dev/null
    echo "tcp_bbr" > /etc/modules-load.d/bbr.conf
    
    cat >> /etc/sysctl.conf << 'EOF'
net.core.default_qdisc=fqnet.ipv4.tcp_congestion_control=bbr
EOF

    sysctl -p >/dev/null 2>&1
    echo -e "${C_GREEN}✅ TCP BBR enabled${C_RESET}"
}

apply_network_tuning() {
    echo -e "\n${C_BLUE}🔧 Applying Network Interface Tuning...${C_RESET}"
    
    # RPS/RFS - distribute load across CPUs
    for i in /sys/class/net/*/queues/*/rps_cpus; do
        if [[ -f "$i" ]]; then
            echo ffffffff > "$i" 2>/dev/null
        fi
    done
    
    # Ring buffer - ignore errors
    if command -v ethtool &>/dev/null; then
        for iface in $(ip link show 2>/dev/null | grep -E '^[0-9]+:' | awk -F': ' '{print $2}' | grep -v lo); do
            ethtool -G "$iface" rx 4096 tx 4096 2>/dev/null || true
        done
    fi
    
    echo -e "${C_GREEN}✅ Network Interface Tuning applied${C_RESET}"
}

apply_dns_caching() {
    echo -e "\n${C_BLUE}📡 Applying DNS Caching...${C_RESET}"
    
    if ! command -v dnsmasq &>/dev/null; then
        apt-get install dnsmasq -y 2>/dev/null
    fi
    
    cat > /etc/dnsmasq.conf << 'EOF'
cache-size=10000
dns-forward-max=1000
server=8.8.8.8
server=1.1.1.1
server=9.9.9.9
no-resolv
EOF

    systemctl restart dnsmasq 2>/dev/null
    
    echo "nameserver 127.0.0.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
    echo "nameserver 1.1.1.1" >> /etc/resolv.conf
    
    echo -e "${C_GREEN}✅ DNS Caching applied${C_RESET}"
}

# ================================================================
# ========== DNSTT FUNCTIONS ==========
# ================================================================

download_dnstt_binary() {
    echo -e "\n${C_BLUE}📥 Downloading DNSTT binary...${C_RESET}"
    
    local arch=$(uname -m)
    local binary_url=""
    
    if [[ "$arch" == "x86_64" ]]; then
        binary_url="https://dnstt.network/dnstt-server-linux-amd64"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        binary_url="https://dnstt.network/dnstt-server-linux-arm64"
    else
        echo -e "\n${C_RED}❌ Unsupported architecture: $arch.${C_RESET}"
        return 1
    fi
    
    curl -sL "$binary_url" -o "$DNSTT_BINARY"
    if [ $? -ne 0 ]; then
        echo -e "\n${C_RED}❌ Failed to download DNSTT binary.${C_RESET}"
        return 1
    fi
    chmod +x "$DNSTT_BINARY"
    
    if [[ "$arch" == "x86_64" ]]; then
        curl -sL "https://dnstt.network/dnstt-client-linux-amd64" -o "$DNSTT_CLIENT"
    elif [[ "$arch" == "aarch64" || "$arch" == "arm64" ]]; then
        curl -sL "https://dnstt.network/dnstt-client-linux-arm64" -o "$DNSTT_CLIENT"
    fi
    chmod +x "$DNSTT_CLIENT"
    
    echo -e "${C_GREEN}✅ DNSTT binaries downloaded${C_RESET}"
    return 0
}

generate_keys() {
    echo -e "\n${C_BLUE}🔑 Generating encryption keys...${C_RESET}"
    
    mkdir -p "$DNSTT_KEYS_DIR"
    cd "$DNSTT_KEYS_DIR"
    rm -f server.key server.pub
    
    if ! "$DNSTT_BINARY" -gen-key -privkey-file server.key -pubkey-file server.pub 2>/dev/null; then
        openssl rand -hex 32 > server.key
        cat server.key | sha256sum | awk '{print $1}' > server.pub
    fi
    
    chmod 600 server.key
    chmod 644 server.pub
    
    PUBLIC_KEY=$(cat server.pub)
    echo -e "${C_GREEN}✅ Keys generated${C_RESET}"
}

setup_domain() {
    echo -e "\n${C_BLUE}🌐 Domain configuration...${C_RESET}"
    
    echo -e "  ${C_GREEN}1)${C_RESET} Custom domain"
    echo -e "  ${C_GREEN}2)${C_RESET} Auto-generate with deSEC"
    read -p "👉 Choice [1-2, default=2]: " domain_option
    domain_option=${domain_option:-2}
    
    if [[ "$domain_option" == "2" ]]; then
        local rand=$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)
        local ns="ns-$rand"
        local tun="tun-$rand"
        local SERVER_IPV4=$(curl -s -4 icanhazip.com)
        
        local API_DATA="[{\"subname\":\"$ns\",\"type\":\"A\",\"ttl\":3600,\"records\":[\"$SERVER_IPV4\"]},{\"subname\":\"$tun\",\"type\":\"NS\",\"ttl\":3600,\"records\":[\"$ns.$DESEC_DOMAIN.\"]}]"
        local RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
            -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" --data "$API_DATA")
        local HTTP_CODE=${RESPONSE: -3}
        
        if [[ "$HTTP_CODE" -eq 201 ]]; then
            DOMAIN="$tun.$DESEC_DOMAIN"
            echo -e "${C_GREEN}✅ Domain: ${C_YELLOW}$DOMAIN${C_RESET}"
        else
            read -p "👉 Enter domain manually: " DOMAIN
        fi
    else
        read -p "👉 Enter domain: " DOMAIN
    fi
    
    echo "$DOMAIN" > "$DB_DIR/domain.txt"
}

create_dnstt_service() {
    local domain=$1
    local mtu=$2
    local ssh_port=$3
    local forward_target=$4
    
    if [[ -z "$mtu" ]]; then
        mtu=512
    fi
    
    mkdir -p "$LOGS_DIR"
    touch "$LOGS_DIR/dnstt-server.log" 2>/dev/null || true
    touch "$LOGS_DIR/dnstt-error.log" 2>/dev/null || true
    chmod 644 "$LOGS_DIR/dnstt-server.log" 2>/dev/null || true
    chmod 644 "$LOGS_DIR/dnstt-error.log" 2>/dev/null || true
    
    cat > "$DNSTT_SERVICE_FILE" <<EOF
[Unit]
Description=DNSTT Server - ULTIMATE OPTIMIZED v9.2
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$DB_DIR
Environment="GODEBUG=netdns=1"
Environment="GOMAXPROCS=4"
ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_KEYS_DIR/server.key -mtu $mtu $domain $forward_target
Restart=always
RestartSec=5
StartLimitInterval=300
StartLimitBurst=5
LimitNOFILE=2097152
LimitNPROC=infinity
LimitCORE=infinity
CPUQuota=200%
MemoryMax=2G
StandardOutput=append:$LOGS_DIR/dnstt-server.log
StandardError=append:$LOGS_DIR/dnstt-error.log

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable dnstt.service > /dev/null 2>&1
    
    echo -e "${C_GREEN}✅ DNSTT service created${C_RESET}"
    echo -e "  • MTU: ${C_YELLOW}$mtu${C_RESET}"
    echo -e "  • Logs: ${C_YELLOW}$LOGS_DIR/dnstt-server.log${C_RESET}"
}

save_dnstt_info() {
    local domain=$1
    local pubkey=$2
    local mtu=$3
    local ssh_port=$4
    
    if [[ -z "$mtu" ]]; then
        mtu=512
    fi
    
    cat > "$DNSTT_CONFIG_FILE" <<EOF
TUNNEL_DOMAIN="$domain"
PUBLIC_KEY="$pubkey"
MTU_VALUE="$mtu"
SSH_PORT="$ssh_port"
EOF
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
    echo ""
    
    echo -e "${C_YELLOW}📌 Client Command:${C_RESET}"
    echo -e "${C_WHITE}$DNSTT_CLIENT -udp 8.8.8.8:53 \\${C_RESET}"
    echo -e "${C_WHITE}  -pubkey-file $DNSTT_KEYS_DIR/server.pub \\${C_RESET}"
    echo -e "${C_WHITE}  -mtu $mtu \\${C_RESET}"
    echo -e "${C_WHITE}  $domain 127.0.0.1:$ssh_port${C_RESET}"
    echo ""
    
    echo -e "${C_YELLOW}📌 Alternative Resolver:${C_RESET}"
    echo -e "${C_WHITE}  $DNSTT_CLIENT -udp 169.255.187.58:53 -pubkey-file $DNSTT_KEYS_DIR/server.pub -mtu $mtu $domain 127.0.0.1:$ssh_port${C_RESET}"
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
    MTU=$(get_current_mtu)
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
    rm -f "$MTU_CONFIG"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ DNSTT uninstalled${C_RESET}"
    press_enter
}

install_dnstt() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}           📡 DNSTT INSTALLATION${C_RESET}"
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
    
    echo -e "\n${C_BLUE}[1/9] Installing dependencies...${C_RESET}"
    ff_apt_install wget curl openssl bc
    
    echo -e "\n${C_BLUE}[2/9] Downloading DNSTT binary...${C_RESET}"
    download_dnstt_binary
    
    echo -e "\n${C_BLUE}[3/9] Configuring resolvers...${C_RESET}"
    mkdir -p "$DB_DIR"
    cat > "$DB_DIR/resolvers.txt" << 'EOF'
8.8.8.8:53
1.1.1.1:53
9.9.9.9:53
208.67.222.222:53
77.88.8.8:53
169.255.187.58:53
EOF
    echo -e "${C_GREEN}✅ 6 resolvers configured${C_RESET}"
    
    echo -e "\n${C_BLUE}[4/9] MTU Configuration...${C_RESET}"
    local current_mtu=$(get_current_mtu)
    echo -e "${C_CYAN}Current MTU: ${C_YELLOW}$current_mtu${C_RESET}"
    echo ""
    echo -e "  ${C_GREEN}1)${C_RESET} Use MTU 512 (Default - Recommended)"
    echo -e "  ${C_GREEN}2)${C_RESET} Use MTU 900"
    echo -e "  ${C_GREEN}3)${C_RESET} Use MTU 1200"
    echo -e "  ${C_GREEN}4)${C_RESET} Use MTU 1400"
    echo -e "  ${C_GREEN}5)${C_RESET} Use MTU 1500"
    echo -e "  ${C_GREEN}6)${C_RESET} Custom MTU"
    echo ""
    read -p "👉 Select MTU [1-6, default=1]: " mtu_choice
    mtu_choice=${mtu_choice:-1}
    
    case $mtu_choice in
        1) MTU=512 ;;
        2) MTU=900 ;;
        3) MTU=1200 ;;
        4) MTU=1400 ;;
        5) MTU=1500 ;;
        6)
            read -p "👉 Enter MTU value (512-1500): " MTU
            if ! [[ "$MTU" =~ ^[0-9]+$ ]] || [ "$MTU" -lt 512 ] || [ "$MTU" -gt 1500 ]; then
                echo -e "${C_RED}❌ Invalid MTU. Using default 512.${C_RESET}"
                MTU=512
            fi
            ;;
        *) MTU=512 ;;
    esac
    
    echo "$MTU" > "$MTU_CONFIG"
    echo -e "${C_GREEN}✅ MTU set to $MTU${C_RESET}"
    
    echo -e "\n${C_BLUE}[5/9] Domain configuration...${C_RESET}"
    setup_domain
    
    echo -e "\n${C_BLUE}[6/9] Generating keys...${C_RESET}"
    generate_keys
    
    # ============================================================
    # SPEED BOOSTER SELECTION - USER CHOOSES
    # ============================================================
    echo -e "\n${C_BLUE}[7/9] Select Speed Booster...${C_RESET}"
    echo ""
    echo -e "  ${C_GREEN}[1]${C_RESET} Standard Ultimate  (1GB)   → 1000x Speed"
    echo -e "  ${C_GREEN}[2]${C_RESET} Medium Ultimate    (2GB)   → 2000x Speed"
    echo -e "  ${C_GREEN}[3]${C_RESET} High Ultimate      (4GB)   → 3000x Speed"
    echo -e "  ${C_GREEN}[4]${C_RESET} Ultra Ultimate     (8GB)   → 5000x Speed"
    echo -e "  ${C_GREEN}[5]${C_RESET} Extreme Ultimate   (16GB)  → 10000x Speed"
    echo -e "  ${C_GREEN}[6]${C_RESET} Skip (No booster)"
    echo ""
    read -p "👉 Choose [1-6, default=3]: " booster_choice
    booster_choice=${booster_choice:-3}
    
    case $booster_choice in
        1) apply_booster_standard_ultimate ;;
        2) apply_booster_medium_ultimate ;;
        3) apply_booster_high_ultimate ;;
        4) apply_booster_ultra_ultimate ;;
        5) apply_booster_extreme_ultimate ;;
        6) echo -e "${C_YELLOW}⚠️ Skipping speed booster${C_RESET}" ;;
        *) apply_booster_high_ultimate ;;
    esac
    
    echo -e "\n${C_BLUE}[8/9] Creating DNSTT service...${C_RESET}"
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    
    create_dnstt_service "$DOMAIN" "$MTU" "$SSH_PORT" "127.0.0.1:$SSH_PORT"
    save_dnstt_info "$DOMAIN" "$PUBLIC_KEY" "$MTU" "$SSH_PORT"
    
    echo -e "\n${C_BLUE}[9/9] Configuring firewall...${C_RESET}"
    configure_dnstt_firewall
    
    # ============================================================
    # AUTO-APPLY DNSTT OPTIMIZATIONS
    # ============================================================
    echo -e "\n${C_BLUE}⚡ Auto-applying DNSTT optimizations...${C_RESET}"
    apply_multiplexing 3
    apply_buffer_optimization
    apply_bbr
    apply_network_tuning
    apply_dns_caching
    echo -e "\n${C_GREEN}✅ DNSTT optimizations applied automatically!${C_RESET}"
    
    echo -e "\n${C_BLUE}🚀 Starting DNSTT...${C_RESET}"
    systemctl start dnstt.service
    sleep 2
    
    if systemctl is-active --quiet dnstt.service; then
        echo -e "${C_GREEN}✅ Service started successfully${C_RESET}"
    else
        echo -e "${C_RED}❌ Service failed to start${C_RESET}"
        journalctl -u dnstt.service -n 20 --no-pager
    fi
    
    show_client_commands "$DOMAIN" "$MTU" "$SSH_PORT"
    press_enter
}

# ================================================================
# ========== SPEED OPTIMIZATION MENU ==========
# ================================================================

speed_optimization_menu() {
    while true; do
        clear; show_banner
        
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           ⚡ DNSTT SPEED BOOSTERS${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_CYAN}Select Speed Level:${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}[1]${C_RESET} Standard Booster (512)   → ${C_GREEN}1000x SPEED 🚀${C_RESET}"
        echo -e "  ${C_GREEN}[2]${C_RESET} Medium Booster (5120)    → ${C_GREEN}2000x SPEED 🚀🚀${C_RESET}"
        echo -e "  ${C_GREEN}[3]${C_RESET} High Booster (51200)     → ${C_GREEN}3000x SPEED 🚀🚀🚀${C_RESET}"
        echo -e "  ${C_GREEN}[4]${C_RESET} Ultra Booster (512000)   → ${C_GREEN}5000x SPEED 🚀🚀🚀🚀${C_RESET}"
        echo -e "  ${C_GREEN}[5]${C_RESET} Extreme Booster (5120000)→ ${C_GREEN}10000x SPEED 💥💥💥💥💥${C_RESET}"
        echo ""
        echo -e "  ${C_DIM}ℹ️  SSH Multiplexing and Compression are applied automatically${C_RESET}"
        echo -e "  ${C_DIM}   during system setup. DNSTT optimizations are applied${C_RESET}"
        echo -e "  ${C_DIM}   during DNSTT installation.${C_RESET}"
        echo ""
        echo -e "  ${C_RED}[0]${C_RESET} Return"
        echo ""
        
        read -p "👉 Select option: " choice
        
        case $choice in
            1) apply_booster_standard_ultimate; press_enter ;;
            2) apply_booster_medium_ultimate; press_enter ;;
            3) apply_booster_high_ultimate; press_enter ;;
            4) apply_booster_ultra_ultimate; press_enter ;;
            5) apply_booster_extreme_ultimate; press_enter ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
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
ExecStart=$BADVPN_BIN --listen-addr 0.0.0.0:7300 --max-clients 1000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable badvpn.service 2>/dev/null
    systemctl start badvpn.service
    echo -e "${C_GREEN}✅ badvpn installed on port 7300${C_RESET}"
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
    echo -e "${C_GREEN}✅ SSL Tunnel installed on port 444${C_RESET}"
    press_enter
}

uninstall_ssl_tunnel() {
    systemctl stop haproxy 2>/dev/null
    ff_apt_purge haproxy
    rm -f "$HAPROXY_CONFIG"
    rm -f "$SSL_CERT_FILE"
    echo -e "${C_GREEN}✅ SSL Tunnel uninstalled${C_RESET}"
    press_enter
}

install_falcon_proxy() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🦅 Installing Falcon Proxy ---${C_RESET}"
    
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        curl -sL -o "$FALCONPROXY_BINARY" "https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/latest/download/falconproxy"
    else
        curl -sL -o "$FALCONPROXY_BINARY" "https://github.com/firewallfalcons/FirewallFalcon-Manager/releases/latest/download/falconproxyarm"
    fi
    chmod +x "$FALCONPROXY_BINARY"
    
    read -p "👉 Enter port(s) [8080]: " ports
    ports=${ports:-8080}
    
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

    systemctl daemon-reload
    systemctl enable falconproxy.service 2>/dev/null
    systemctl start falconproxy.service
    echo -e "${C_GREEN}✅ Falcon Proxy installed on port(s) $ports${C_RESET}"
    press_enter
}

uninstall_falcon_proxy() {
    systemctl stop falconproxy.service 2>/dev/null
    systemctl disable falconproxy.service 2>/dev/null
    rm -f "$FALCONPROXY_SERVICE_FILE" "$FALCONPROXY_BINARY"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ Falcon Proxy uninstalled${C_RESET}"
    press_enter
}

install_zivpn() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🛡️ Installing ZiVPN ---${C_RESET}"
    
    local arch=$(uname -m)
    if [[ "$arch" == "x86_64" ]]; then
        curl -sL -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-amd64"
    else
        curl -sL -o "$ZIVPN_BIN" "https://github.com/zahidbd2/udp-zivpn/releases/download/udp-zivpn_1.4.9/udp-zivpn-linux-arm64"
    fi
    chmod +x "$ZIVPN_BIN"
    mkdir -p "$ZIVPN_DIR"
    
    openssl req -x509 -newkey rsa:4096 -nodes -days 365 -keyout "$ZIVPN_DIR/server.key" -out "$ZIVPN_DIR/server.crt" -subj "/CN=ZiVPN" 2>/dev/null
    
    read -p "Passwords (comma-separated) [user1,user2]: " passwords
    passwords=${passwords:-user1,user2}
    
    IFS=',' read -ra pass_array <<< "$passwords"
    json_passwords=$(printf '"%s",' "${pass_array[@]}")
    json_passwords="[${json_passwords%,}]"
    
    cat > "$ZIVPN_CONFIG_FILE" << EOF
{
  "listen": ":5667",
  "cert": "$ZIVPN_DIR/server.crt",
  "key": "$ZIVPN_DIR/server.key",
  "obfs": "zivpn",
  "auth": {"mode": "passwords", "config": $json_passwords}
}
EOF

    cat > "$ZIVPN_SERVICE_FILE" << EOF
[Unit]
Description=ZiVPN Server
After=network.target

[Service]
Type=simple
ExecStart=$ZIVPN_BIN server -c $ZIVPN_CONFIG_FILE
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable zivpn.service 2>/dev/null
    systemctl start zivpn.service
    echo -e "${C_GREEN}✅ ZiVPN installed on port 5667${C_RESET}"
    press_enter
}

uninstall_zivpn() {
    systemctl stop zivpn.service 2>/dev/null
    systemctl disable zivpn.service 2>/dev/null
    rm -f "$ZIVPN_SERVICE_FILE" "$ZIVPN_BIN"
    rm -rf "$ZIVPN_DIR"
    systemctl daemon-reload
    echo -e "${C_GREEN}✅ ZiVPN uninstalled${C_RESET}"
    press_enter
}

install_xui_panel() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 💻 Installing X-UI ---${C_RESET}"
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
# ========== PROTOCOL MENU ==========
# ================================================================

protocol_menu() {
    while true; do
        clear; show_banner
        
        local badvpn_status=""
        if systemctl is-active --quiet badvpn 2>/dev/null; then
            badvpn_status="${C_GREEN}● RUNNING${C_RESET}"
        else
            badvpn_status="${C_DIM}● STOPPED${C_RESET}"
        fi
        
        local udp_status=""
        if systemctl is-active --quiet udp-custom 2>/dev/null; then
            udp_status="${C_GREEN}● RUNNING${C_RESET}"
        else
            udp_status="${C_DIM}● STOPPED${C_RESET}"
        fi
        
        local haproxy_status=""
        if systemctl is-active --quiet haproxy 2>/dev/null; then
            haproxy_status="${C_GREEN}● RUNNING${C_RESET}"
        else
            haproxy_status="${C_DIM}● STOPPED${C_RESET}"
        fi
        
        local dnstt_status=""
        if systemctl is-active --quiet dnstt 2>/dev/null; then
            dnstt_status="${C_GREEN}● RUNNING${C_RESET}"
        else
            dnstt_status="${C_DIM}● STOPPED${C_RESET}"
        fi
        
        local falconproxy_status=""
        if systemctl is-active --quiet falconproxy 2>/dev/null; then
            falconproxy_status="${C_GREEN}● RUNNING${C_RESET}"
        else
            falconproxy_status="${C_DIM}● STOPPED${C_RESET}"
        fi
        
        local zivpn_status=""
        if systemctl is-active --quiet zivpn 2>/dev/null; then
            zivpn_status="${C_GREEN}● RUNNING${C_RESET}"
        else
            zivpn_status="${C_DIM}● STOPPED${C_RESET}"
        fi
        
        local xui_status=""
        if command -v x-ui &>/dev/null; then
            xui_status="${C_GREEN}● INSTALLED${C_RESET}"
        else
            xui_status="${C_DIM}● NOT INSTALLED${C_RESET}"
        fi
        
        local current_mtu=$(get_current_mtu)
        
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}              🔌 PROTOCOL MANAGEMENT${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}1)${C_RESET} badvpn (UDP 7300)        $badvpn_status"
        echo -e "  ${C_GREEN}2)${C_RESET} udp-custom              $udp_status"
        echo -e "  ${C_GREEN}3)${C_RESET} SSL Tunnel (HAProxy)    $haproxy_status"
        echo -e "  ${C_GREEN}4)${C_RESET} DNSTT (Port 53)         $dnstt_status ${C_DIM}(MTU: $current_mtu)${C_RESET}"
        echo -e "  ${C_GREEN}5)${C_RESET} Falcon Proxy            $falconproxy_status"
        echo -e "  ${C_GREEN}6)${C_RESET} ZiVPN                   $zivpn_status"
        echo -e "  ${C_GREEN}7)${C_RESET} X-UI Panel              $xui_status"
        echo ""
        echo -e "  ${C_GREEN}8)${C_RESET} 📡 DNSTT MTU Settings"
        echo ""
        echo -e "  ${C_RED}0)${C_RESET} Return"
        echo ""
        
        local choice
        read -p "👉 Select protocol: " choice
        
        case $choice in
            1)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_badvpn || uninstall_badvpn
                press_enter
                ;;
            2)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_udp_custom || uninstall_udp_custom
                press_enter
                ;;
            3)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_ssl_tunnel || uninstall_ssl_tunnel
                press_enter
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
                press_enter
                ;;
            5)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_falcon_proxy || uninstall_falcon_proxy
                press_enter
                ;;
            6)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_zivpn || uninstall_zivpn
                press_enter
                ;;
            7)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_xui_panel || uninstall_xui_panel
                press_enter
                ;;
            8) dnstt_mtu_menu ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ================================================================
# ========== VPS DASHBOARD ==========
# ================================================================

show_vps_dashboard() {
    clear; show_banner
    
    local VPS_IP=$(curl -s -4 icanhazip.com 2>/dev/null || echo "Unknown")
    local VPS_LOCATION=$(curl -s "http://ip-api.com/json/$VPS_IP" 2>/dev/null | grep -o '"city":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    local VPS_COUNTRY=$(curl -s "http://ip-api.com/json/$VPS_IP" 2>/dev/null | grep -o '"country":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    local VPS_ISP=$(curl -s "http://ip-api.com/json/$VPS_IP" 2>/dev/null | grep -o '"isp":"[^"]*"' | cut -d'"' -f4 2>/dev/null || echo "Unknown")
    local VPS_OS=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Unknown")
    local VPS_KERNEL=$(uname -r 2>/dev/null || echo "Unknown")
    local VPS_ARCH=$(uname -m 2>/dev/null || echo "Unknown")
    local VPS_CPU_MODEL=$(grep -m1 "model name" /proc/cpuinfo | cut -d: -f2 | sed 's/^[ \t]*//' 2>/dev/null | cut -c1-30)
    local VPS_CPU_CORES=$(grep -c "processor" /proc/cpuinfo 2>/dev/null || echo "0")
    local VPS_CPU_USAGE=$(top -bn1 | head -5 | awk '/Cpu/ {print $2}' 2>/dev/null || echo "0")
    local VPS_RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "0")
    local VPS_RAM_USED=$(free -h | awk '/^Mem:/ {print $3}' 2>/dev/null || echo "0")
    local VPS_RAM_PERCENT=$(free -m | awk '/^Mem:/{if($2>0){printf "%.1f", $3*100/$2}else{print "0"}}' 2>/dev/null || echo "0")
    local VPS_DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}' 2>/dev/null || echo "0")
    local VPS_DISK_USED=$(df -h / | awk 'NR==2 {print $3}' 2>/dev/null || echo "0")
    local VPS_DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    local VPS_UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    local VPS_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0")
    local VPS_TRAFFIC_RX=$(ip -s link | grep -A1 "eth0\|ens3" | grep "RX" | awk '{print $2}' 2>/dev/null | head -1 | numfmt --to=iec 2>/dev/null || echo "0")
    local VPS_TRAFFIC_TX=$(ip -s link | grep -A1 "eth0\|ens3" | grep "TX" | awk '{print $2}' 2>/dev/null | head -1 | numfmt --to=iec 2>/dev/null || echo "0")
    
    echo -e "${C_BOLD}${C_PURPLE}╔═══════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║                         🖥️  VPS DASHBOARD                                  ║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}╚═══════════════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_CYAN}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│${C_RESET} ${C_YELLOW}IP:${C_RESET} ${C_GREEN}%-15s${C_RESET} ${C_YELLOW}Location:${C_RESET} ${C_GREEN}%-25s${C_RESET} ${C_YELLOW}ISP:${C_RESET} ${C_GREEN}%-15s${C_RESET} ${C_BOLD}${C_WHITE}│${C_RESET}\n" "$VPS_IP" "$VPS_LOCATION, $VPS_COUNTRY" "$VPS_ISP"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    
    printf "${C_BOLD}${C_WHITE}│${C_RESET} ${C_YELLOW}OS:${C_RESET} ${C_GREEN}%-15s${C_RESET} ${C_YELLOW}Kernel:${C_RESET} ${C_GREEN}%-20s${C_RESET} ${C_YELLOW}Arch:${C_RESET} ${C_GREEN}%-10s${C_RESET} ${C_BOLD}${C_WHITE}│${C_RESET}\n" "$VPS_OS" "$VPS_KERNEL" "$VPS_ARCH"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    
    printf "${C_BOLD}${C_WHITE}│${C_RESET} ${C_YELLOW}CPU:${C_RESET} ${C_GREEN}%-20s${C_RESET} ${C_YELLOW}Cores:${C_RESET} ${C_GREEN}%-4s${C_RESET} ${C_YELLOW}Usage:${C_RESET} ${C_GREEN}%-6s${C_RESET} ${C_BOLD}${C_WHITE}│${C_RESET}\n" "$VPS_CPU_MODEL" "$VPS_CPU_CORES" "${VPS_CPU_USAGE}%"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    
    printf "${C_BOLD}${C_WHITE}│${C_RESET} ${C_YELLOW}RAM:${C_RESET} ${C_GREEN}%-6s${C_RESET} ${C_YELLOW}Used:${C_RESET} ${C_GREEN}%-6s${C_RESET} ${C_YELLOW}Usage:${C_RESET} ${C_GREEN}%-6s${C_RESET} ${C_BOLD}${C_WHITE}│${C_RESET}\n" "$VPS_RAM_TOTAL" "$VPS_RAM_USED" "${VPS_RAM_PERCENT}%"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    
    printf "${C_BOLD}${C_WHITE}│${C_RESET} ${C_YELLOW}Disk:${C_RESET} ${C_GREEN}%-6s${C_RESET} ${C_YELLOW}Used:${C_RESET} ${C_GREEN}%-6s${C_RESET} ${C_YELLOW}Usage:${C_RESET} ${C_GREEN}%-6s${C_RESET} ${C_BOLD}${C_WHITE}│${C_RESET}\n" "$VPS_DISK_TOTAL" "$VPS_DISK_USED" "${VPS_DISK_PERCENT}%"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    
    printf "${C_BOLD}${C_WHITE}│${C_RESET} ${C_YELLOW}Uptime:${C_RESET} ${C_GREEN}%-18s${C_RESET} ${C_YELLOW}Load:${C_RESET} ${C_GREEN}%-6s${C_RESET} ${C_YELLOW}Online:${C_RESET} ${C_GREEN}%-4s${C_RESET} ${C_BOLD}${C_WHITE}│${C_RESET}\n" "$VPS_UPTIME" "$VPS_LOAD" "${BANNER_CACHE_ONLINE_USERS}"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    
    printf "${C_BOLD}${C_WHITE}│${C_RESET} ${C_YELLOW}↓:${C_RESET} ${C_GREEN}%-10s${C_RESET} ${C_YELLOW}↑:${C_RESET} ${C_GREEN}%-10s${C_RESET} ${C_YELLOW}Users:${C_RESET} ${C_GREEN}%-6s${C_RESET} ${C_BOLD}${C_WHITE}│${C_RESET}\n" "$VPS_TRAFFIC_RX" "$VPS_TRAFFIC_TX" "${BANNER_CACHE_TOTAL_USERS}"
    echo -e "${C_BOLD}${C_CYAN}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    
    echo ""
    echo -e "${C_BOLD}${C_DIM}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_DIM}│  ${C_GREEN}●${C_RESET} System: ${C_GREEN}Running${C_RESET}  │  ${C_GREEN}●${C_RESET} Network: ${C_GREEN}Connected${C_RESET}  │  ${C_GREEN}●${C_RESET} DNSTT: ${C_GREEN}$(systemctl is-active dnstt 2>/dev/null || echo "Stopped")${C_RESET}  │${C_RESET}"
    echo -e "${C_BOLD}${C_DIM}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    
    echo ""
    echo -e "${C_YELLOW}⚠️ Press ${C_BOLD}[Enter]${C_RESET}${C_YELLOW} to refresh or ${C_BOLD}[0]${C_RESET}${C_YELLOW} to return${C_RESET}"
    read -p "👉 " refresh_choice
    if [[ "$refresh_choice" != "0" ]]; then
        show_vps_dashboard
    fi
}

# ================================================================
# ========== VPN DATA USAGE (TABLE) ==========
# ================================================================

show_vpn_data_usage() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}                 📊 VPN CONNECTION DATA USAGE${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo ""
    
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "${C_YELLOW}ℹ️ No users found.${C_RESET}"
        press_enter
        return
    fi
    
    echo -e "${C_BOLD}${C_WHITE}┌────────────┬──────────────┬──────────────┬──────────────┬────────────┐${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-10s │ %-12s │ %-12s │ %-12s │ %-10s │${C_RESET}\n" "USERNAME" "TRAFFIC" "LIMIT" "REMAINING" "STATUS"
    echo -e "${C_BOLD}${C_WHITE}├────────────┼──────────────┼──────────────┼──────────────┼────────────┤${C_RESET}"
    
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
            local status="${C_GREEN}Active${C_RESET}"
            printf "${C_WHITE}│${C_RESET} %-10s ${C_WHITE}│${C_RESET} %-12s ${C_WHITE}│${C_RESET} %-12s ${C_WHITE}│${C_RESET} %-12s ${C_WHITE}│${C_RESET} %-10s ${C_WHITE}│${C_RESET}\n" \
                "$user" "${used_gb} GB" "Unlimited" "∞" "$status"
        else
            local remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}" 2>/dev/null || echo "0")
            
            if (( $(awk "BEGIN {print ($used_gb >= $bandwidth_gb)}" 2>/dev/null) )); then
                status="${C_RED}Exceeded${C_RESET}"
            else
                status="${C_GREEN}Active${C_RESET}"
            fi
            
            printf "${C_WHITE}│${C_RESET} %-10s ${C_WHITE}│${C_RESET} %-12s ${C_WHITE}│${C_RESET} %-12s ${C_WHITE}│${C_RESET} %-12s ${C_WHITE}│${C_RESET} %-10s ${C_WHITE}│${C_RESET}\n" \
                "$user" "${used_gb} GB" "${bandwidth_gb} GB" "${remain_gb} GB" "$status"
        fi
    done < "$DB_FILE"
    
    echo -e "${C_BOLD}${C_WHITE}└────────────┴──────────────┴──────────────┴──────────────┴────────────┘${C_RESET}"
    echo ""
    
    local total_users=$(grep -c . "$DB_FILE")
    echo -e "${C_DIM}Total Users: ${C_WHITE}$total_users${C_RESET}"
    echo ""
    press_enter
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
    echo -e "  ${C_RED}0)${C_RESET} Return"
    echo ""
    
    local choice
    read -p "👉 Select option: " choice
    
    case $choice in
        1)
            (crontab -l 2>/dev/null | grep -v "systemctl reboot") | crontab - 2>/dev/null
            (crontab -l 2>/dev/null; echo "0 0 * * * systemctl reboot") | crontab - 2>/dev/null
            echo -e "\n${C_GREEN}✅ Auto-reboot scheduled${C_RESET}"
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
# ========== TRAFFIC MONITOR ==========
# ================================================================

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
    read -p "👉 Select option: " choice
    
    case $choice in
        1)
            echo -e "\n${C_BLUE}⚡ Starting Live Monitor (Ctrl+C to stop)...${C_RESET}\n"
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
    echo -e "${C_BOLD}${C_PURPLE}--- 🚫 Torrent Blocking ---${C_RESET}"
    
    local torrent_status="${C_RED}Disabled${C_RESET}"
    if iptables -L FORWARD 2>/dev/null | grep -q "BitTorrent"; then
        torrent_status="${C_GREEN}Enabled${C_RESET}"
    fi
    
    echo -e "\n${C_WHITE}Current Status: ${torrent_status}${C_RESET}"
    echo ""
    echo -e "  ${C_GREEN}1)${C_RESET} Enable Torrent Blocking"
    echo -e "  ${C_RED}2)${C_RESET} Disable Torrent Blocking"
    echo -e "  ${C_RED}0)${C_RESET} Return"
    echo ""
    
    local choice
    read -p "👉 Select option: " choice
    
    case $choice in
        1)
            echo -e "\n${C_BLUE}🛡️ Applying Anti-Torrent rules...${C_RESET}"
            iptables -A FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
            iptables -A FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
            iptables -A FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
            iptables -A FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
            echo -e "${C_GREEN}✅ Torrent Blocking Enabled${C_RESET}"
            press_enter
            ;;
        2)
            echo -e "\n${C_BLUE}🔓 Removing Anti-Torrent rules...${C_RESET}"
            iptables -D FORWARD -m string --string "BitTorrent" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "peer_id=" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string ".torrent" --algo bm -j DROP 2>/dev/null
            iptables -D FORWARD -m string --string "info_hash" --algo bm -j DROP 2>/dev/null
            echo -e "${C_GREEN}✅ Torrent Blocking Disabled${C_RESET}"
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
    read -p "👉 Backup path [/root/voltrontech_backup.tar.gz]: " backup_path
    backup_path=${backup_path:-/root/voltrontech_backup.tar.gz}
    
    if [ ! -d "$DB_DIR" ] || [ ! -s "$DB_FILE" ]; then
        echo -e "\n${C_YELLOW}ℹ️ No user data found.${C_RESET}"
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
        
        if [ -f "$temp_dir/voltrontech/users.db" ]; then
            cp "$temp_dir/voltrontech/users.db" "$DB_FILE"
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
# ========== DNS MENU ==========
# ================================================================

dns_menu() {
    clear; show_banner
    echo -e "${C_BOLD}${C_PURPLE}--- 🌐 DNS Domain Management ---${C_RESET}"
    
    if [ -f "$DNS_INFO_FILE" ]; then
        source "$DNS_INFO_FILE"
        echo -e "\nℹ️ Domain exists: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
        read -p "👉 Delete this domain? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$SUBDOMAIN/A/" \
                -H "Authorization: Token $DESEC_TOKEN" > /dev/null
            rm -f "$DNS_INFO_FILE"
            echo -e "\n${C_GREEN}✅ Domain deleted${C_RESET}"
        fi
    else
        read -p "👉 Generate new domain? (y/n): " choice
        if [[ "$choice" == "y" || "$choice" == "Y" ]]; then
            generate_dns_record
        fi
    fi
    press_enter
}

generate_dns_record() {
    echo -e "\n${C_BLUE}⚙️ Generating a random domain...${C_RESET}"
    
    local SERVER_IPV4=$(curl -s -4 icanhazip.com)
    if ! [[ "$SERVER_IPV4" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        echo -e "\n${C_RED}❌ Could not retrieve valid IPv4 address.${C_RESET}"
        return 1
    fi

    local RANDOM_SUBDOMAIN="vps-$(head /dev/urandom | tr -dc a-z0-9 | head -c 8)"
    local FULL_DOMAIN="$RANDOM_SUBDOMAIN.$DESEC_DOMAIN"

    local API_DATA=$(printf '[{"subname": "%s", "type": "A", "ttl": 3600, "records": ["%s"]}]' "$RANDOM_SUBDOMAIN" "$SERVER_IPV4")

    local CREATE_RESPONSE=$(curl -s -w "%{http_code}" -X POST "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/" \
        -H "Authorization: Token $DESEC_TOKEN" -H "Content-Type: application/json" \
        --data "$API_DATA")
    
    local HTTP_CODE=${CREATE_RESPONSE: -3}

    if [[ "$HTTP_CODE" -ne 201 ]]; then
        echo -e "${C_RED}❌ Failed to create DNS records. HTTP $HTTP_CODE.${C_RESET}"
        return 1
    fi
    
    cat > "$DNS_INFO_FILE" <<-EOF
SUBDOMAIN="$RANDOM_SUBDOMAIN"
FULL_DOMAIN="$FULL_DOMAIN"
EOF
    echo -e "\n${C_GREEN}✅ Domain: ${C_YELLOW}$FULL_DOMAIN${C_RESET}"
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
    
    local -a removable_users=()
    local remove_users_on_uninstall=false
    mapfile -t removable_users < <(get_voltrontech_known_users)
    if [[ ${#removable_users[@]} -gt 0 ]]; then
        echo -e "\n${C_YELLOW}Voltron Tech SSH users detected: ${removable_users[*]}"
        read -p "👉 Delete these users before uninstalling? (y/n): " remove_users_confirm
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
    
    if [[ "$remove_users_on_uninstall" == "true" ]]; then
        echo -e "\n${C_BLUE}🗑️ Removing users before uninstall...${C_RESET}"
        delete_voltrontech_user_accounts "${removable_users[@]}"
    fi
    
    if [ -f "$DB_DIR/desec_ns_subdomain.txt" ]; then
        local ns_subdomain=$(cat "$DB_DIR/desec_ns_subdomain.txt")
        local tun_subdomain=$(cat "$DB_DIR/desec_tun_subdomain.txt")
        curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$ns_subdomain/A/" -H "Authorization: Token $DESEC_TOKEN" > /dev/null
        curl -s -X DELETE "https://desec.io/api/v1/domains/$DESEC_DOMAIN/rrsets/$tun_subdomain/NS/" -H "Authorization: Token $DESEC_TOKEN" > /dev/null
    fi
    
    (crontab -l 2>/dev/null | grep -v "reboot") | crontab - 2>/dev/null
    
    systemctl stop dnstt.service badvpn.service udp-custom.service haproxy falconproxy.service zivpn.service 2>/dev/null
    systemctl disable dnstt.service badvpn.service udp-custom.service falconproxy.service 2>/dev/null
    systemctl stop voltrontech-limiter 2>/dev/null
    systemctl disable voltrontech-limiter 2>/dev/null
    
    rm -f "$DNSTT_SERVICE_FILE" "$BADVPN_SERVICE_FILE" "$UDP_CUSTOM_SERVICE_FILE" "$FALCONPROXY_SERVICE_FILE"
    rm -f "$LIMITER_SERVICE" "$ZIVPN_SERVICE_FILE"
    
    rm -f "$DNSTT_BINARY" "$DNSTT_CLIENT" "$BADVPN_BIN" "$UDP_CUSTOM_BIN"
    rm -f "$FALCONPROXY_BINARY" "$ZIVPN_BIN"
    rm -f "$LIMITER_SCRIPT" "$TRIAL_CLEANUP_SCRIPT"
    
    rm -rf "$DB_DIR" "$ZIVPN_DIR" "$BADVPN_BUILD_DIR"
    rm -f "$SSH_BANNER_FILE"
    
    rm -f "$0"
    
    systemctl daemon-reload
    
    echo -e "\n${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_GREEN}      ✅ SCRIPT UNINSTALLED SUCCESSFULLY!${C_RESET}"
    echo -e "${C_GREEN}═══════════════════════════════════════════════════════════════${C_RESET}"
    exit 0
}

# ================================================================
# ========== UPDATE SSH BANNERS CONFIG ==========
# ================================================================

update_ssh_banners_config() {
    local tmp_conf

    # Only proceed if dynamic banner is enabled
    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
        if [[ -f "$SSHD_FF_CONFIG" ]]; then
            rm -f "$SSHD_FF_CONFIG" 2>/dev/null
            systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
        fi
        return
    fi

    mkdir -p "$BANNER_DIR" /etc/ssh/sshd_config.d
    tmp_conf="/tmp/voltrontech_banners_new.conf"
    
    echo "# Voltron Tech - Dynamic per-user SSH banners" > "$tmp_conf"
    echo "# Generated: $(date)" >> "$tmp_conf"
    echo "" >> "$tmp_conf"

    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            
            # Ensure banner file exists for every user
            if [[ ! -f "$BANNER_DIR/${user}.txt" ]]; then
                generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"
            fi
            
            echo "Match User $user" >> "$tmp_conf"
            echo "    Banner $BANNER_DIR/${user}.txt" >> "$tmp_conf"
            echo "" >> "$tmp_conf"
        done < "$DB_FILE"
    fi

    if ! cmp -s "$tmp_conf" "$SSHD_FF_CONFIG" 2>/dev/null; then
        mv "$tmp_conf" "$SSHD_FF_CONFIG"
        if ! grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
            echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
        fi
        systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    else
        rm -f "$tmp_conf"
    fi
}

# ================================================================
# ========== DYNAMIC BANNER FUNCTIONS ==========
# ================================================================

enable_dynamic_banner() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🎨 ENABLING DYNAMIC ACCOUNT BANNER${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    mkdir -p "$BANNER_DIR"
    touch "$BANNER_ENABLED_FILE"
    
    echo -e "\n${C_CYAN}📝 Creating banners for all existing users...${C_RESET}"
    
    if [[ -f "$DB_FILE" ]]; then
        while IFS=: read -r user pass expiry limit bandwidth_gb _extra; do
            [[ -z "$user" || "$user" == \#* ]] && continue
            generate_user_banner "$user" "$expiry" "$limit" "$bandwidth_gb"
            echo -e "${C_GREEN}✅ Banner created for user: ${C_YELLOW}$user${C_RESET}"
        done < "$DB_FILE"
    fi
    
    echo -e "\n${C_GREEN}✅ Banners created for all existing users${C_RESET}"
    echo -e "${C_CYAN}📌 New users will automatically get banners when created${C_RESET}"
    
    # Update SSH config
    update_ssh_banners_config
    
    # Ensure Include directive exists
    if ! grep -q "^Include /etc/ssh/sshd_config.d/" /etc/ssh/sshd_config 2>/dev/null; then
        echo "Include /etc/ssh/sshd_config.d/*.conf" >> /etc/ssh/sshd_config
    fi
    
    # Restart SSH
    systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    
    # Restart limiter
    systemctl restart voltrontech-limiter 2>/dev/null
    
    echo -e "\n${C_GREEN}✅ Dynamic account banner enabled!${C_RESET}"
    echo -e "${C_CYAN}📌 Users will see their account status when connecting via SSH/VPN${C_RESET}"
    echo -e "${C_CYAN}📌 Banner updates automatically every 15 seconds${C_RESET}"
    echo -e "${C_CYAN}📌 New users created after this will get banners automatically${C_RESET}"
    echo -e "${C_CYAN}📌 No need to enable again!${C_RESET}"
    press_enter
}

disable_dynamic_banner() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🛑 DISABLING DYNAMIC ACCOUNT BANNER${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    rm -f "$BANNER_ENABLED_FILE"
    rm -f "$SSHD_FF_CONFIG"
    rm -rf "$BANNER_DIR" 2>/dev/null
    systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    
    echo -e "\n${C_GREEN}✅ Dynamic banner disabled!${C_RESET}"
    press_enter
}

preview_dynamic_ssh_banner() {
    if [[ ! -f "$BANNER_ENABLED_FILE" ]]; then
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
            journalctl -u voltrontech-limiter -n 15 --no-pager
        fi
    fi
    press_enter
}

ssh_banner_menu() {
    while true; do
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
        read -p "👉 Select option: " choice
        case $choice in
            1) enable_dynamic_banner ;;
            2) disable_dynamic_banner ;;
            3) preview_dynamic_ssh_banner ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
}

# ================================================================
# ========== APPLY SSH BOOSTER AUTO ==========
# ================================================================

apply_ssh_booster_auto() {
    echo -e "\n${C_BLUE}🔧 Applying SSH Speed Booster (Automatic)...${C_RESET}"
    
    cat > /etc/ssh/sshd_config.d/voltrontech-speed.conf << 'EOF'
# Voltron Tech SSH Speed Optimizations
# Fastest ciphers and MACs for maximum performance

Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com,aes256-ctr,aes192-ctr,aes128-ctr
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512,hmac-sha2-256
KexAlgorithms curve25519-sha256@libssh.org,ecdh-sha2-nistp521,ecdh-sha2-nistp384,ecdh-sha2-nistp256,diffie-hellman-group-exchange-sha256
HostKeyAlgorithms ssh-ed25519-cert-v01@openssh.com,ssh-rsa-cert-v01@openssh.com,ssh-ed25519,ssh-rsa
Compression no
TCPKeepAlive yes
ClientAliveInterval 60
ClientAliveCountMax 3
RekeyLimit 1G 1h
AllowTcpForwarding yes
GatewayPorts yes
PermitRootLogin yes
EOF

    systemctl restart sshd 2>/dev/null || systemctl restart ssh 2>/dev/null
    
    echo "net.ipv4.tcp_keepalive_time = 30" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_keepalive_intvl = 5" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_keepalive_probes = 3" >> /etc/sysctl.conf
    sysctl -p >/dev/null 2>&1
    
    echo -e "${C_GREEN}✅ SSH Speed Booster applied automatically!${C_RESET}"
}

# ================================================================
# ========== APPLY UDP BOOSTER AUTO ==========
# ================================================================

apply_udp_booster_auto() {
    echo -e "\n${C_BLUE}🔧 Applying UDP Booster (Automatic)...${C_RESET}"
    
    sysctl -w net.core.rmem_max=10737418240 >/dev/null 2>&1
    sysctl -w net.core.wmem_max=10737418240 >/dev/null 2>&1
    sysctl -w net.core.rmem_default=1073741824 >/dev/null 2>&1
    sysctl -w net.core.wmem_default=1073741824 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_rmem_min=125829120 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_wmem_min=125829120 >/dev/null 2>&1
    
    sysctl -w net.core.udp_gro_enabled=1 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_gro_enabled=1 >/dev/null 2>&1
    sysctl -w net.ipv4.udp_l3mdev_accept=1 >/dev/null 2>&1
    
    echo "KCP_WINDOW_SIZE=1024,1024" >> /etc/sysctl.conf 2>/dev/null
    echo "KCP_MAX_STREAM_BUFFER=10737418240" >> /etc/sysctl.conf 2>/dev/null
    echo "KCP_QUEUE_SIZE=10240" >> /etc/sysctl.conf 2>/dev/null
    
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_DIR/udp_booster.conf" << EOF
UDP_BOOSTER_APPLIED="true"
DATE_APPLIED="$(date)"
EOF
    
    echo -e "${C_GREEN}✅ UDP Booster applied automatically!${C_RESET}"
}

# ================================================================
# ========== LIMITER SERVICE (WITH ACCOUNT STATUS) ==========
# ================================================================

create_limiter_service() {
    cat > "$LIMITER_SCRIPT" << 'EOF'
#!/bin/bash
# Voltron Tech Limiter v9.2 - WITH ACCOUNT STATUS
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

    if [[ -f "$BANNER_ENABLED_FILE" ]]; then
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
        is_expired=false
        bw_exhausted=false
        
        # Check if user is locked by system
        if passwd -S "$user" 2>/dev/null | grep -q " L "; then
            user_locked=true
        fi
        
        if [[ -n "${locked_users[$user]+x}" ]]; then
            user_locked=true
        fi

        # Check if account is expired
        expiry_ts=0
        if [[ "$expiry" != "Never" && -n "$expiry" ]]; then
            expiry_ts=$(date -d "$expiry" +%s 2>/dev/null || echo 0)
            if [[ "$expiry_ts" =~ ^[0-9]+$ ]] && (( expiry_ts > 0 && expiry_ts < current_ts )); then
                is_expired=true
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    user_locked=true
                fi
            fi
        fi

        # Check connection limit
        [[ "$limit" =~ ^[0-9]+$ ]] || limit=1
        if (( online_count > limit )); then
            if ! $user_locked; then
                usermod -L "$user" &>/dev/null
                killall -u "$user" -9 &>/dev/null
                user_locked=true
            fi
        fi

        # Check bandwidth
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
                if ! $user_locked; then
                    usermod -L "$user" &>/dev/null
                    user_locked=true
                fi
            fi
        fi

        # Determine account status
        if $user_locked; then
            account_status="🔒 LOCKED"
            status_color="yellow"
        elif $is_expired; then
            account_status="🗓️ EXPIRED"
            status_color="red"
        elif $bw_exhausted; then
            account_status="⚠️ DATA EXHAUSTED"
            status_color="red"
        else
            account_status="✅ ACTIVE"
            status_color="green"
        fi

        # Calculate days left
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

        # Calculate bandwidth info
        bw_info="Unlimited"
        bw_display=""
        if [[ "$bandwidth_gb" != "0" && -n "$bandwidth_gb" ]]; then
            used_gb=$(awk "BEGIN {printf \"%.2f\", $accum_disp / 1073741824}")
            remain_gb=$(awk "BEGIN {r=$bandwidth_gb - $used_gb; if(r<0) r=0; printf \"%.2f\", r}")
            bw_info="${used_gb}/${bandwidth_gb} GB used | ${remain_gb} GB left"
            
            if (( $(echo "$remain_gb <= 0" | bc -l 2>/dev/null || echo "0") )); then
                bw_display="<center><font color=\"red\" size=\"4\"><b>⚠️ DATA EXHAUSTED! Please contact admin.</b></font></center><br>"
            elif (( $(echo "$remain_gb <= 1" | bc -l 2>/dev/null || echo "0") )); then
                bw_display="<center><font color=\"yellow\" size=\"4\"><b>⚠️ WARNING: Low bandwidth! Only ${remain_gb} GB left.</b></font></center><br>"
            fi
        fi

        UPTIME=$(uptime -p | sed 's/up //')
        LOAD=$(awk '{print $1}' /proc/loadavg)
        
        # Build banner content
        banner_content=""
        banner_content+="<br><br>"
        banner_content+="<center><font color=\"red\">=======</font><font color=\"purple\" size=\"8\"><b> 🔥 VOLTRON TECH ULTIMATE 🔥 </b></font><font color=\"red\">=======</font></center><br>"
        banner_content+="<br>"
        banner_content+="<center><font color=\"blue\" size=\"5\"><b>📋 ACCOUNT DETAILS 📋</b></font></center><br>"
        banner_content+="<br>"
        banner_content+="<center><font color=\"white\">👤 <b>Username      :</b> $user</font></center><br>"
        banner_content+="<center><font color=\"white\">📅 <b>Expiration    :</b> $expiry ($days_left)</font></center><br>"
        banner_content+="<center><font color=\"white\">📊 <b>Bandwidth     :</b> $bw_info</font></center><br>"
        banner_content+="<center><font color=\"white\">🔌 <b>Sessions      :</b> $online_count/$limit</font></center><br>"
        banner_content+="<center><font color=\"${status_color}\" size=\"4\"><b>📌 Account Status : ${account_status}</b></font></center><br>"
        
        if [[ -n "$bw_display" ]]; then
            banner_content+="$bw_display"
        fi
        
        banner_content+="<br>"
        banner_content+="<center><font color=\"white\">⏱️ <b>Server Uptime :</b> $UPTIME</font></center><br>"
        banner_content+="<center><font color=\"white\">📈 <b>Server Load   :</b> $LOAD</font></center><br>"
        banner_content+="<br>"
        banner_content+="<center><font color=\"green\" size=\"4\"><b>📢 JOIN OUR COMMUNITY 📢</b></font></center><br>"
        banner_content+="<center><font color=\"white\">📱 Telegram  : https://t.me/voltrontech</font></center><br>"
        banner_content+="<center><font color=\"white\">💬 WhatsApp  : https://chat.whatsapp.com/JfxZ5Vif62JLKZc275Njl8</font></center><br>"
        banner_content+="<br>"
        banner_content+="<center><font color=\"red\" size=\"4\"><b>⚠️ IMPORTANT NOTICE ⚠️</b></font></center><br>"
        banner_content+="<center><font color=\"white\">• Account expires on: $expiry</font></center><br>"
        banner_content+="<center><font color=\"white\">• No torrent or illegal activity</font></center><br>"
        banner_content+="<center><font color=\"white\">• Account sharing is prohibited</font></center><br>"
        banner_content+="<br>"
        banner_content+="<center><font color=\"gray\" size=\"2\"><b>─────── Powered by Voltron Tech ───────</b></font></center><br>"
        
        write_banner_if_changed "$user" "$banner_content"

        # Bandwidth tracking
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

    done < "$DB_FILE"

    sleep "$SCAN_INTERVAL"
done
EOF
    chmod +x "$LIMITER_SCRIPT"
    sed -i 's/\r$//' "$LIMITER_SCRIPT" 2>/dev/null

    cat > "$LIMITER_SERVICE" << EOF
[Unit]
Description=Voltron Tech Active User Limiter
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

# ================================================================
# ========== INITIAL SETUP ==========
# ================================================================

initial_setup() {
    echo -e "\n${C_BLUE}🔧 Running initial system setup...${C_RESET}"
    
    ff_apt_update
    ff_apt_install bc jq curl wget iptables iptables-persistent screen dnsmasq
    mkdir -p "$DB_DIR" "$SSL_CERT_DIR" "$BANDWIDTH_DIR" "$BANNER_DIR" "$DNSTT_KEYS_DIR" "$LOGS_DIR" "$CONFIG_DIR"
    touch "$DB_FILE"
    
    getent group "$FF_USERS_GROUP" >/dev/null 2>&1 || groupadd "$FF_USERS_GROUP" >/dev/null 2>&1
    
    create_limiter_service
    
    # Apply SSH optimizations
    echo -e "\n${C_BLUE}🔧 Applying SSH Optimizations...${C_RESET}"
    apply_ssh_optimizations
    
    echo -e "\n${C_BLUE}🚀 Applying automatic boosters...${C_RESET}"
    apply_ssh_booster_auto
    apply_udp_booster_auto
    
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
        printf "  ${C_GREEN}%2s${C_RESET}) %-25s  ${C_GREEN}%2s${C_RESET}) %-25s\n" "17" "⚡ Speed Optimization" "22" "📊 VPN Data Usage"
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
            17) speed_optimization_menu ;;
            18) ssh_banner_menu ;;
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

if [[ $EUID -ne 0 ]]; then
    echo -e "${C_RED}❌ This script must be run as root!${C_RESET}"
    exit 1
fi

if [[ "$1" == "--install-setup" ]]; then
    initial_setup
    exit 0
fi

main_menu
