#!/bin/bash
# ================================================================
# VOLTRON TECH ULTIMATE v7.0 - COMPLETE
# ================================================================
# Inajumuisha:
#   1. User Management - Create, Delete, Edit, Lock, Unlock, List, Renew, Cleanup
#   2. DNSTT - 7 Speed Boosters (10-100 Mbps) + MTU Settings
#   3. Protocols - badvpn, udp-custom, SSL Tunnel, Falcon Proxy, ZiVPN, X-UI
#   4. Dynamic Banner - Per-user account info (VOLTRON TECH ULTIMATE)
#   5. VPS Dashboard - Real-time system info
#   6. VPN Data Usage - Per user connection data
#   7. UDP Booster - KCP/smux optimization
#   8. Trial Account - Auto-delete
#   9. Orphan Detection
#   10. Backup/Restore, Traffic Monitor, Torrent Blocking, Auto Reboot
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
# ========== KCP/smux UDP BOOSTER PARAMETERS ==========
# ================================================================

KCP_WINDOW_SIZE="64,64"
KCP_MAX_STREAM_BUFFER="1048576"
KCP_QUEUE_SIZE="128"
KCP_NODELAY="1"
KCP_INTERVAL="10"
KCP_RESEND="2"
KCP_NC="1"

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
    echo -e "${C_TITLE}   VOLTRON TECH ULTIMATE v7.0 ${C_RESET}${C_DIM}| Premium Edition${C_RESET}"
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
    if ! id "$username" &>/dev/null; then echo -e "${C_RED}Not Found${C_RESET}"; return; fi
    local expiry_date=$(grep "^$username:" "$DB_FILE" | cut -d: -f3)
    if passwd -S "$username" 2>/dev/null | grep -q " L "; then echo -e "${C_YELLOW}🔒 Locked${C_RESET}"; return; fi
    local expiry_ts=$(date -d "$expiry_date" +%s 2>/dev/null || echo 0)
    local current_ts=$(date +%s)
    if [[ $expiry_ts -lt $current_ts ]]; then echo -e "${C_RED}🗓️ Expired${C_RESET}"; return; fi
    echo -e "${C_GREEN}🟢 Active${C_RESET}"
}

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
    
    clear; show_banner
    echo -e "${C_GREEN}✅ User '$username' created successfully!${C_RESET}\n"
    echo -e "  - 👤 Username:          ${C_YELLOW}$username${C_RESET}"
    echo -e "  - 🔑 Password:          ${C_YELLOW}$password${C_RESET}"
    echo -e "  - 🗓️ Expires on:        ${C_YELLOW}$expire_date${C_RESET}"
    echo -e "  - 📶 Connection Limit:  ${C_YELLOW}$limit${C_RESET}"
    echo -e "  - 📦 Bandwidth Limit:   ${C_YELLOW}$bw_display${C_RESET}"
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

list_users() {
    clear; show_banner
    if [[ ! -s "$DB_FILE" ]]; then
        echo -e "\n${C_YELLOW}ℹ️ No users are currently being managed.${C_RESET}"
        press_enter
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
        printf "  ${C_GREEN}%-20s${C_RESET} | ${C_YELLOW}%-15s${C_RESET} | ${C_CYAN}%-12s${C_RESET}\n" "$username" "$password" "$expire_date"
        created=$((created + 1))
    done
    
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
# ========== DYNAMIC BANNER FUNCTIONS ==========
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
    tmp_conf="/tmp/voltrontech_banners_new.conf"
    echo "# Voltron Tech - Dynamic per-user SSH banners" > "$tmp_conf"

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

enable_dynamic_banner() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🎨 ENABLING DYNAMIC ACCOUNT BANNER${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    mkdir -p "$BANNER_DIR"
    touch "$BANNER_ENABLED_FILE"
    update_ssh_banners_config
    systemctl restart voltrontech-limiter 2>/dev/null
    
    echo -e "\n${C_GREEN}✅ Dynamic account banner enabled!${C_RESET}"
    echo -e "${C_CYAN}📌 Users will see their account status when connecting via SSH${C_RESET}"
    echo -e "${C_CYAN}📌 Banner updates automatically every 15 seconds${C_RESET}"
    press_enter
}

disable_dynamic_banner() {
    echo -e "\n${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    echo -e "${C_BLUE}           🛑 DISABLING DYNAMIC ACCOUNT BANNER${C_RESET}"
    echo -e "${C_BLUE}═══════════════════════════════════════════════════════════════${C_RESET}"
    
    rm -f "$BANNER_ENABLED_FILE"
    rm -f "$SSHD_FF_CONFIG"
    rm -rf "$BANNER_DIR" 2>/dev/null
    systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
    
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

# ================================================================
# ========== SSH BANNER MENU ==========
# ================================================================

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

select_speed_booster() {
    echo -e "\n${C_BLUE}⚡ Selecting speed booster...${C_RESET}"
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
    read -p "👉 Choose [1-8, default=3]: " booster_choice
    booster_choice=${booster_choice:-3}
    
    case $booster_choice in
        1) apply_booster_standard ;;
        2) apply_booster_medium ;;
        3) apply_booster_high ;;
        4) apply_booster_ultra ;;
        5) apply_booster_extreme ;;
        6) apply_booster_ultra_plus ;;
        7) apply_booster_extreme_plus ;;
        8) echo -e "${C_YELLOW}⚠️ Skipping${C_RESET}" ;;
        *) apply_booster_high ;;
    esac
}

apply_booster_standard() { echo -e "\n${C_BLUE}⚡ STANDARD BOOSTER (32MB)${C_RESET}"; modprobe tcp_bbr 2>/dev/null; sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1; sysctl -w net.ipv4.udp_rmem_min=524288 >/dev/null 2>&1; sysctl -w net.core.rmem_max=33554432 >/dev/null 2>&1; sysctl -w net.core.wmem_max=33554432 >/dev/null 2>&1; sysctl -w net.core.netdev_max_backlog=100000 >/dev/null 2>&1; sysctl -w net.netfilter.nf_conntrack_max=4000000 >/dev/null 2>&1; ulimit -n 1048576 2>/dev/null; echo -e "${C_GREEN}✅ Standard Booster applied (10-15 Mbps)${C_RESET}"; sleep 1; }
apply_booster_medium() { echo -e "\n${C_BLUE}⚡ MEDIUM BOOSTER (64MB)${C_RESET}"; modprobe tcp_bbr 2>/dev/null; sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1; sysctl -w net.ipv4.udp_rmem_min=1048576 >/dev/null 2>&1; sysctl -w net.core.rmem_max=67108864 >/dev/null 2>&1; sysctl -w net.core.wmem_max=67108864 >/dev/null 2>&1; sysctl -w net.core.netdev_max_backlog=200000 >/dev/null 2>&1; sysctl -w net.netfilter.nf_conntrack_max=8000000 >/dev/null 2>&1; ulimit -n 2097152 2>/dev/null; echo -e "${C_GREEN}✅ Medium Booster applied (15-20 Mbps) 🚀${C_RESET}"; sleep 1; }
apply_booster_high() { echo -e "\n${C_BLUE}⚡ HIGH BOOSTER (128MB)${C_RESET}"; modprobe tcp_bbr 2>/dev/null; sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1; sysctl -w net.ipv4.udp_rmem_min=2097152 >/dev/null 2>&1; sysctl -w net.core.rmem_max=134217728 >/dev/null 2>&1; sysctl -w net.core.wmem_max=134217728 >/dev/null 2>&1; sysctl -w net.core.netdev_max_backlog=400000 >/dev/null 2>&1; sysctl -w net.netfilter.nf_conntrack_max=16000000 >/dev/null 2>&1; ulimit -n 4194304 2>/dev/null; echo -e "${C_GREEN}✅ High Booster applied (20-25 Mbps) 🚀🚀${C_RESET}"; sleep 1; }
apply_booster_ultra() { echo -e "\n${C_BLUE}⚡ ULTRA BOOSTER (256MB)${C_RESET}"; modprobe tcp_bbr 2>/dev/null; sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1; sysctl -w net.ipv4.udp_rmem_min=4194304 >/dev/null 2>&1; sysctl -w net.core.rmem_max=268435456 >/dev/null 2>&1; sysctl -w net.core.wmem_max=268435456 >/dev/null 2>&1; sysctl -w net.core.netdev_max_backlog=600000 >/dev/null 2>&1; sysctl -w net.netfilter.nf_conntrack_max=32000000 >/dev/null 2>&1; ulimit -n 8388608 2>/dev/null; echo -e "${C_GREEN}✅ ULTRA Booster applied (25-35 Mbps) 🚀🚀🚀${C_RESET}"; sleep 1; }
apply_booster_extreme() { echo -e "\n${C_BLUE}⚡ EXTREME BOOSTER (512MB)${C_RESET}"; modprobe tcp_bbr 2>/dev/null; sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1; sysctl -w net.ipv4.udp_rmem_min=8388608 >/dev/null 2>&1; sysctl -w net.core.rmem_max=536870912 >/dev/null 2>&1; sysctl -w net.core.wmem_max=536870912 >/dev/null 2>&1; sysctl -w net.core.netdev_max_backlog=1000000 >/dev/null 2>&1; sysctl -w net.netfilter.nf_conntrack_max=64000000 >/dev/null 2>&1; ulimit -n 16777216 2>/dev/null; echo -e "${C_GREEN}✅ EXTREME Booster applied (35-50 Mbps) 💥💥💥${C_RESET}"; sleep 1; }
apply_booster_ultra_plus() { echo -e "\n${C_BLUE}⚡ ULTRA PLUS BOOSTER (768MB)${C_RESET}"; modprobe tcp_bbr 2>/dev/null; sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1; sysctl -w net.ipv4.udp_rmem_min=6291456 >/dev/null 2>&1; sysctl -w net.core.rmem_max=805306368 >/dev/null 2>&1; sysctl -w net.core.wmem_max=805306368 >/dev/null 2>&1; sysctl -w net.core.netdev_max_backlog=800000 >/dev/null 2>&1; sysctl -w net.netfilter.nf_conntrack_max=48000000 >/dev/null 2>&1; ulimit -n 12582912 2>/dev/null; echo -e "${C_GREEN}✅ ULTRA PLUS Booster applied (40-60 Mbps) 🚀🚀🚀🚀${C_RESET}"; sleep 1; }
apply_booster_extreme_plus() { echo -e "\n${C_BLUE}⚡ EXTREME PLUS BOOSTER (1GB)${C_RESET}"; modprobe tcp_bbr 2>/dev/null; sysctl -w net.ipv4.tcp_congestion_control=bbr >/dev/null 2>&1; sysctl -w net.ipv4.udp_rmem_min=12582912 >/dev/null 2>&1; sysctl -w net.core.rmem_max=1073741824 >/dev/null 2>&1; sysctl -w net.core.wmem_max=1073741824 >/dev/null 2>&1; sysctl -w net.core.netdev_max_backlog=1200000 >/dev/null 2>&1; sysctl -w net.netfilter.nf_conntrack_max=96000000 >/dev/null 2>&1; ulimit -n 25165824 2>/dev/null; echo -e "${C_GREEN}✅ EXTREME PLUS Booster applied (60-100 Mbps) 💥💥💥💥💥${C_RESET}"; sleep 1; }

speed_booster_menu() {
    while true; do
        clear; show_banner
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}           ⚡ DNSTT SPEED BOOSTER MANAGER${C_RESET}"
        echo -e "${C_BOLD}${C_PURPLE}═══════════════════════════════════════════════════════════════${C_RESET}"
        echo ""
        echo -e "  ${C_GREEN}[1]${C_RESET} Standard  (32MB)   → 10-15 Mbps"
        echo -e "  ${C_GREEN}[2]${C_RESET} Medium    (64MB)   → 15-20 Mbps  🚀"
        echo -e "  ${C_GREEN}[3]${C_RESET} High      (128MB)  → 20-25 Mbps  🚀🚀"
        echo -e "  ${C_GREEN}[4]${C_RESET} Ultra     (256MB)  → 25-35 Mbps  🚀🚀🚀"
        echo -e "  ${C_GREEN}[5]${C_RESET} Extreme   (512MB)  → 35-50 Mbps  💥💥💥"
        echo -e "  ${C_GREEN}[6]${C_RESET} Ultra Plus (768MB)  → 40-60 Mbps  🚀🚀🚀🚀"
        echo -e "  ${C_GREEN}[7]${C_RESET} Extreme Plus (1GB)  → 60-100 Mbps 💥💥💥💥💥"
        echo -e "  ${C_RED}[0]${C_RESET} Return"
        echo ""
        read -p "👉 Select booster: " choice
        case $choice in
            1) apply_booster_standard; press_enter ;;
            2) apply_booster_medium; press_enter ;;
            3) apply_booster_high; press_enter ;;
            4) apply_booster_ultra; press_enter ;;
            5) apply_booster_extreme; press_enter ;;
            6) apply_booster_ultra_plus; press_enter ;;
            7) apply_booster_extreme_plus; press_enter ;;
            0) return ;;
            *) echo -e "\n${C_RED}❌ Invalid option${C_RESET}"; sleep 2 ;;
        esac
    done
}

create_dnstt_service_with_booster() {
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
Description=DNSTT Server - ULTIMATE OPTIMIZED v7.0
After=network.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$DB_DIR
Environment="GODEBUG=netdns=1"
ExecStart=$DNSTT_BINARY -udp :5300 -privkey-file $DNSTT_KEYS_DIR/server.key -mtu $mtu $domain $forward_target
Restart=always
RestartSec=5
StartLimitInterval=300
StartLimitBurst=5
LimitNOFILE=2097152
LimitNPROC=infinity
LimitCORE=infinity
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
    
    echo -e "\n${C_BLUE}[1/8] Installing dependencies...${C_RESET}"
    ff_apt_install wget curl openssl bc
    
    echo -e "\n${C_BLUE}[2/8] Downloading DNSTT binary...${C_RESET}"
    download_dnstt_binary
    
    echo -e "\n${C_BLUE}[3/8] Configuring resolvers...${C_RESET}"
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
    
    echo -e "\n${C_BLUE}[4/8] MTU Configuration...${C_RESET}"
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
    
    echo -e "\n${C_BLUE}[5/8] Domain configuration...${C_RESET}"
    setup_domain
    
    echo -e "\n${C_BLUE}[6/8] Generating keys...${C_RESET}"
    generate_keys
    
    echo -e "\n${C_BLUE}[7/8] Speed booster...${C_RESET}"
    select_speed_booster
    
    echo -e "\n${C_BLUE}[8/8] Creating DNSTT service...${C_RESET}"
    SSH_PORT=$(ss -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1)
    SSH_PORT=${SSH_PORT:-22}
    
    create_dnstt_service_with_booster "$DOMAIN" "$MTU" "$SSH_PORT" "127.0.0.1:$SSH_PORT"
    save_dnstt_info "$DOMAIN" "$PUBLIC_KEY" "$MTU" "$SSH_PORT"
    
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
        echo -e "  ${C_GREEN}5)${C_RESET} ⚡ DNSTT Speed Booster"
        echo -e "  ${C_GREEN}6)${C_RESET} 📡 DNSTT MTU Settings"
        echo -e "  ${C_GREEN}7)${C_RESET} Falcon Proxy            $falconproxy_status"
        echo -e "  ${C_GREEN}8)${C_RESET} ZiVPN                   $zivpn_status"
        echo -e "  ${C_GREEN}9)${C_RESET} X-UI Panel              $xui_status"
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
            5) speed_booster_menu ;;
            6) dnstt_mtu_menu ;;
            7)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_falcon_proxy || uninstall_falcon_proxy
                press_enter
                ;;
            8)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_zivpn || uninstall_zivpn
                press_enter
                ;;
            9)
                echo -e "\n  ${C_GREEN}1)${C_RESET} Install"
                echo -e "  ${C_RED}2)${C_RESET} Uninstall"
                read -p "👉 Choose: " sub
                [ "$sub" == "1" ] && install_xui_panel || uninstall_xui_panel
                press_enter
                ;;
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
    local VPS_OS=$(grep -oP 'PRETTY_NAME="\K[^"]+' /etc/os-release 2>/dev/null || echo "Unknown")
    local VPS_KERNEL=$(uname -r 2>/dev/null || echo "Unknown")
    local VPS_ARCH=$(uname -m 2>/dev/null || echo "Unknown")
    local VPS_CPU_CORES=$(grep -c "processor" /proc/cpuinfo 2>/dev/null || echo "0")
    local VPS_CPU_USAGE=$(top -bn1 | head -5 | awk '/Cpu/ {print $2}' 2>/dev/null || echo "0")
    local VPS_RAM_TOTAL=$(free -h | awk '/^Mem:/ {print $2}' 2>/dev/null || echo "0")
    local VPS_RAM_USED=$(free -h | awk '/^Mem:/ {print $3}' 2>/dev/null || echo "0")
    local VPS_RAM_PERCENT=$(free -m | awk '/^Mem:/{if($2>0){printf "%.2f", $3*100/$2}else{print "0"}}' 2>/dev/null || echo "0")
    local VPS_DISK_TOTAL=$(df -h / | awk 'NR==2 {print $2}' 2>/dev/null || echo "0")
    local VPS_DISK_USED=$(df -h / | awk 'NR==2 {print $3}' 2>/dev/null || echo "0")
    local VPS_DISK_PERCENT=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//' 2>/dev/null || echo "0")
    local VPS_UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "unknown")
    local VPS_LOAD=$(awk '{print $1}' /proc/loadavg 2>/dev/null || echo "0")
    
    echo -e "${C_BOLD}${C_PURPLE}╔═══════════════════════════════════════════════════════════════════════════════╗${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}║                    🖥️  VPS DASHBOARD - REAL TIME INFO                        ║${C_RESET}"
    echo -e "${C_BOLD}${C_PURPLE}╚═══════════════════════════════════════════════════════════════════════════════╝${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_CYAN}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}│                        📋 VPS BASIC INFORMATION                            │${C_RESET}"
    echo -e "${C_BOLD}${C_CYAN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "IP Address:" "$VPS_IP"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "OS:" "$VPS_OS"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Kernel:" "$VPS_KERNEL"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Architecture:" "$VPS_ARCH"
    echo -e "${C_BOLD}${C_CYAN}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_YELLOW}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}│                           ⚡ CPU & LOAD INFO                              │${C_RESET}"
    echo -e "${C_BOLD}${C_YELLOW}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "CPU Cores:" "$VPS_CPU_CORES"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "CPU Usage:" "${VPS_CPU_USAGE}%"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Load:" "$VPS_LOAD"
    echo -e "${C_BOLD}${C_YELLOW}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_GREEN}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_GREEN}│                         💾 RAM & DISK INFO                               │${C_RESET}"
    echo -e "${C_BOLD}${C_GREEN}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "RAM Total:" "$VPS_RAM_TOTAL"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "RAM Used:" "$VPS_RAM_USED"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "RAM Usage:" "${VPS_RAM_PERCENT}%"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Disk Total:" "$VPS_DISK_TOTAL"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Disk Used:" "$VPS_DISK_USED"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Disk Usage:" "${VPS_DISK_PERCENT}%"
    echo -e "${C_BOLD}${C_GREEN}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_BLUE}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}│                          ⏱️  UPTIME & STATUS                               │${C_RESET}"
    echo -e "${C_BOLD}${C_BLUE}├─────────────────────────────────────────────────────────────────────────────────┤${C_RESET}"
    printf "${C_BOLD}${C_WHITE}│ %-18s${C_RESET} ${C_GREEN}%-50s${C_RESET}${C_BOLD}${C_WHITE}│${C_RESET}\n" "Uptime:" "$VPS_UPTIME"
    echo -e "${C_BOLD}${C_BLUE}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_BOLD}${C_DIM}┌─────────────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_BOLD}${C_DIM}│  ${C_GREEN}●${C_RESET} System: ${C_GREEN}Running${C_RESET}  │  ${C_GREEN}●${C_RESET} Network: ${C_GREEN}Connected${C_RESET}  │${C_RESET}"
    echo -e "${C_BOLD}${C_DIM}└─────────────────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo ""
    
    echo -e "${C_YELLOW}⚠️ Press ${C_BOLD}[Enter]${C_RESET}${C_YELLOW} to refresh or ${C_BOLD}[0]${C_RESET}${C_YELLOW} to return${C_RESET}"
    read -p "👉 " refresh_choice
    if [[ "$refresh_choice" != "0" ]]; then
        show_vps_dashboard
    fi
}

# ================================================================
# ========== VPN DATA USAGE ==========
# ================================================================

show_vpn_data_usage() {
    clear; show_banner
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
# ========== LIMITER SERVICE ==========
# ================================================================

create_limiter_service() {
    cat > "$LIMITER_SCRIPT" << 'EOF'
#!/bin/bash
# Voltron Tech Limiter v7.0
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

            UPTIME=$(uptime -p | sed 's/up //')
            LOAD=$(awk '{print $1}' /proc/loadavg)
            
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
    ff_apt_install bc jq curl wget
    mkdir -p "$DB_DIR" "$SSL_CERT_DIR" "$BANDWIDTH_DIR" "$BANNER_DIR" "$DNSTT_KEYS_DIR" "$LOGS_DIR" "$CONFIG_DIR"
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
