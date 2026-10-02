```markdown
<div align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=32&duration=3000&pause=1000&color=F70000&center=true&vCenter=true&width=800&lines=WELCOME+TO+VOLTRON+TECH+ULTIMATE;Powered+By+Voltron+Tech" alt="Typing SVG" />
</div>

<br/>

<div align="center">
  <img src="https://img.shields.io/badge/Version-10.18-blue?style=for-the-badge&logo=version&color=purple" alt="Version 10.18"/>
  <img src="https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge" alt="Status"/>
  <img src="https://img.shields.io/badge/Platform-Linux-cyan?style=for-the-badge&logo=linux" alt="Platform"/>
  <img src="https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge" alt="License"/>
  <img src="https://img.shields.io/badge/API-REST-orange?style=for-the-badge&logo=flask" alt="REST API"/>
  <img src="https://img.shields.io/badge/WebPanel-Lovable-pink?style=for-the-badge" alt="Web Panel"/>
</div>

<br/>

<div align="center">
  <img src="https://readme-typing-svg.demolab.com?font=Fira+Code&weight=600&size=24&pause=1000&color=F70000&center=true&vCenter=true&width=700&lines=🔥+ULTIMATE+VPN+MANAGER+%F0%9F%94%A5;SSH+%7C+DNSTT+%7C+BADVPN+%7C+SSL+TUNNEL;TCP+FAST+OPEN+%2B+BBR+%2B+fq;Dynamic+Banner+%2B+Live+Bandwidth+Tracker" alt="Subtitle" />
</div>

<br/>

---

## 📌 Table of Contents

- [🔥 Overview](#-overview)
- [🆕 What's New in v10.18](#-whats-new-in-v1018)
- [✨ Features](#-features)
- [📦 Installation](#-installation)
- [⚡ Quick Start](#-quick-start)
- [🌐 Protocols Supported](#-protocols-supported)
- [⚡ Speed Boosters](#-speed-boosters)
- [🎨 Dynamic SSH Banner](#-dynamic-ssh-banner)
- [📊 Bandwidth Tracking](#-bandwidth-tracking)
- [🌐 REST API](#-rest-api)
- [🎛️ Web Panel (Lovable)](#️-web-panel-lovable)
- [📸 Screenshots](#-screenshots)
- [📝 Commands](#-commands)
- [📱 Contact & Support](#-contact--support)
- [📊 Project Status](#-project-status)
- [📜 License](#-license)
- [⚠️ Disclaimer](#-disclaimer)

---

## 🔥 Overview

**VOLTRON TECH ULTIMATE v10.18** is a comprehensive VPN/SSH management script designed for Linux servers. It provides a complete solution for managing user accounts, multiple VPN protocols, bandwidth control, dynamic SSH banners, and a full REST API for web integration.

> ⚡ **Features TCP Fast Open + BBR + fq** for maximum speed and low latency!

> 🎨 **Dynamic SSH Banners** with live bandwidth progress bars (KB/MB/GB smart formatting)!

> 🌐 **Full REST API** with custom domain support and **Lovable Web Panel** integration!

---

## 🆕 What's New in v10.18

| Feature | Description |
|---------|-------------|
| 🎯 **Smart Bandwidth Tracker** | Counts ALL user PIDs (sshd + bash + wget + curl) — accurate data usage |
| 📊 **Progress Bar** | `[████░░░░░░] 40.2%` with color-coded blocks (green/yellow/orange/red) |
| 📏 **Smart Size Formatter** | Auto-shows KB / MB / GB based on usage size |
| ⏰ **Expiry Warnings** | EXPIRING SOON (3-7 days) / EXPIRING (1-2 days) / EXPIRES TODAY |
| 🔴 **Critical Warning** | Alerts when data >= 95% |
| 🌐 **Custom API Domain** | Change API domain from menu (auto DNS setup) |
| 🎛️ **Dynamic Banner API** | Enable/disable banner via REST API |
| ⚡ **TCP Fast Open** | 0-RTT handshake on all 7 speed boosters |
| 🚀 **BBR + fq** | Google's congestion control on every booster |

---

## ✨ Features

<details>
<summary><b>👤 User Management</b></summary>

- ✅ Create/Delete/Edit users
- ✅ Lock/Unlock accounts
- ✅ Bulk user creation (1-100 users)
- ✅ Trial accounts with auto-deletion (1h to 3 days)
- ✅ User expiration management
- ✅ Connection limit per user
- ✅ Bandwidth quota management
- ✅ **Live bandwidth tracking** (KB/MB/GB)
- ✅ **Dynamic SSH banners** with progress bars
- ✅ Password generator
- ✅ Multi-user selection (ranges, `all`)
</details>

<details>
<summary><b>🌐 VPN Protocols</b></summary>

- ✅ **DNSTT** (DNS Tunnel) with MTU control (512-1500)
- ✅ **BadVPN** UDP Gateway (Port 7300)
- ✅ **UDP-Custom**
- ✅ **SSL/TLS Tunnel** via HAProxy (Port 444)
- ✅ **Falcon Proxy**
- ✅ **ZiVPN** (UDP 5667)
- ✅ **X-UI Panel**
</details>

<details>
<summary><b>⚡ Performance Boosters</b></summary>

- ✅ Standard (1000x) — buffer 512
- ✅ Medium (2000x) — buffer 5120
- ✅ High (3000x) — buffer 51200
- ✅ **Ultra (5000x)** — buffer 512000 ⭐
- ✅ Extreme (10000x) — buffer 5120000
- ✅ Ultra Plus (768MB) — buffer 6291456
- ✅ Extreme Plus (1GB) — buffer 12582912
- ✅ **All boosters use TCP Fast Open + BBR + fq**
</details>

<details>
<summary><b>🎨 Dynamic SSH Banner</b></summary>

- ✅ **Live bandwidth progress bar** with color blocks
- ✅ **Smart KB/MB/GB formatter**
- ✅ Live session count
- ✅ Account status (ACTIVE / LOCKED / EXPIRED / CRITICAL / EXHAUSTED)
- ✅ Expiry warnings with days left
- ✅ Server uptime + load
- ✅ Auto-update every 15 seconds
- ✅ Different banners per user (via sshd Match User)
- ✅ Enable/disable from CLI or API
</details>

<details>
<summary><b>🌐 REST API + Web Panel</b></summary>

- ✅ Full Flask + Gunicorn REST API
- ✅ API key authentication
- ✅ **Custom API domain** (configurable from menu)
- ✅ Auto SSL via Let's Encrypt
- ✅ Nginx reverse proxy
- ✅ Nginx CORS headers
- ✅ **Lovable web panel integration**
- ✅ 15+ endpoints (trial, users, protocols, banner, dashboard)
- ✅ Dynamic Banner control via API
</details>

<details>
<summary><b>📊 Monitoring & Management</b></summary>

- ✅ VPS Dashboard (real-time stats)
- ✅ Per-user bandwidth tracking (bytes → GB)
- ✅ Network traffic monitor
- ✅ **Progress bar display**
- ✅ Auto-reboot scheduler
- ✅ Backup & Restore
- ✅ Orphan user detection
- ✅ Cache cleaner (cron)
- ✅ **irqbalance** + CPU performance tuning
</details>

---

## 📦 Installation

### 🚀 One-Line Installation

```bash
bash <(curl -sL https://raw.githubusercontent.com/VOLTRON-TECH-X/VOLTRON-TECH/refs/heads/main/install.sh)
```

📝 Manual Installation

```bash
# 1. Clone the repository
git clone https://github.com/VOLTRON-TECH-X/VOLTRON-TECH.git

# 2. Enter directory
cd VOLTRON-TECH

# 3. Make executable
chmod +x voltron.sh

# 4. Run as root
sudo ./voltron.sh
```

✅ Requirements

Component Requirement
OS Ubuntu 20.04+ / Debian 11+
RAM 1 GB minimum (2 GB recommended)
Disk 5 GB minimum
Root Access Required
Architecture x86_64 / arm64

---

⚡ Quick Start

```bash
# 1. Run script
sudo ./voltron.sh

# 2. Initial setup happens automatically
#    → Creates directories
#    → Installs limiter service
#    → Installs traffic monitor
#    → Enables atd (for trial cleanup)

# 3. Main menu will appear
```

🎯 First Steps

1. Create a user → Main Menu → 1) Create User
2. Setup DNSTT → Main Menu → 14) DNSTT Manage
3. Setup Web Panel → Main Menu → 19) Web Panel → 1) Full Setup
4. Enable Dynamic Banner → Main Menu → 17) Dynamic Banner → 1) Enable

---

🌐 Protocols Supported

# Protocol Port Service Status
1 SSH 22 sshd ✅ Built-in
2 DNSTT 53 / 5300 dnstt.service ✅ Optional
3 BadVPN 7300 badvpn.service ✅ Optional
4 UDP-Custom 1-65535 udp-custom.service ✅ Optional
5 SSL/TLS 444 haproxy ✅ Optional
6 Falcon Proxy 8080 falconproxy.service ✅ Optional
7 ZiVPN 5667 zivpn.service ✅ Optional
8 X-UI Panel 54321 x-ui ✅ Optional

---

⚡ Speed Boosters

All boosters include TCP Fast Open + BBR + fq for maximum performance:

# Name Buffer Speed Target Best For
1 Standard 512 10-15 Mbps Low-end VPS
2 Medium 5120 15-20 Mbps Balanced
3 High 51200 20-25 Mbps High RAM
4 Ultra ⭐ 512000 25-35 Mbps Recommended
5 Extreme 5120000 35-50 Mbps 8GB+ RAM
6 Ultra Plus 6291456 40-60 Mbps 16GB+ RAM
7 Extreme Plus 12582912 60-100 Mbps Max RAM

🎯 Modern Optimizations Applied

```bash
✅ TCP Fast Open (0-RTT handshake)
✅ BBR congestion control (Google)
✅ fq (Fair Queue) qdisc
✅ TCP window scaling
✅ TCP SACK / DSACK
✅ TCP ECN
✅ TCP keepalive tuning
✅ TCP Fast Open (client + server)
✅ MTU probing
✅ Multi-core RPS/XPS
✅ IRQ affinity
✅ CPU performance governor
✅ irqbalance
✅ conntrack tuning
✅ File descriptor limits
```

---

🎨 Dynamic SSH Banner

📸 Banner Preview

```
📋 ACCOUNT DETAILS 📋

👤 Username      : ahmed01
📅 Expiration    : 2026-10-15
📊 Bandwidth     : ████████░░ 84.5% | 42.25 GB/50 GB (7.75 GB left)
🔌 Sessions      : 3/999
📌 Account Status : ✅ ACTIVE

⏱️ Server Uptime : 3 days, 4 hours
📈 Server Load   : 0.24

📢 JOIN OUR COMMUNITY 📢
📱 Telegram  : https://t.me/voltrontech
💬 WhatsApp  : https://chat.whatsapp.com/...
```

🎨 Color-Coded Progress Bar

Used % Color Emoji Description
0-59% 🟢 Green ✅ Safe
60-79% 🟡 Yellow ⚠️ Warning
80-94% 🟠 Orange 🔶 High
95-100% 🔴 Red 🔥 Critical
100%+ 🔴 Red ⚠️ Exhausted

📏 Smart Size Formatter

The banner automatically chooses the right unit:

```
< 1 KB       → "512 B"
1 KB - 1 MB  → "500.00 KB"
1 MB - 1 GB  → "50.25 MB"
> 1 GB       → "2.50 GB"
```

⏰ Expiry Warnings

Days Left Status Color
> 7 days ✅ ACTIVE Green
3-7 days ⏰ EXPIRING SOON - X DAYS LEFT Yellow
1-2 days 🔴 EXPIRING - X DAYS LEFT Orange
0 (today) ⚠️ EXPIRES TODAY Red
< 0 🗓️ EXPIRED Orange

---

📊 Bandwidth Tracking

🔬 How It Works

```
1. Limiter runs every 15 seconds
2. For each user, it finds ALL PIDs:
   - sshd processes
   - bash sessions
   - wget/curl subprocesses
3. Reads /proc/$pid/io for rchar + wchar
4. Calculates delta from last scan
5. Updates .usage file + DB
6. Regenerates banner with progress bar
```

📁 File Locations

```bash
/etc/voltrontech/
├── users.db                    # User database (colon-separated)
├── bandwidth/
│   ├── username.usage          # Per-user bytes used
│   └── pidtrack/
│       └── username__PID.last  # Last IO reading per PID
├── banners/
│   └── username.txt            # Generated HTML banner
└── banners_enabled             # Flag: banner on/off
```

📋 Users Database Format

```
username:password:expiry:limit:bandwidth:traffic:status
   │        │        │     │       │        │       │
   │        │        │     │       │        │       └─ ACTIVE/LOCKED
   │        │        │     │       │        └─ GB used (for API)
   │        │        │     │       └─ Bandwidth limit GB (0=unlimited)
   │        │        │     └─ Session limit (999 = unlimited)
   │        │        └─ Expiry date (YYYY-MM-DD)
   │        └─ Password
   └─ Username
```

---

🌐 REST API

🔧 Setup

```bash
# Main Menu → 19) Web Panel → 1) Full Setup
# → API + DNS + Nginx + SSL automatically
```

🔑 Authentication

All requests require X-API-Key header:

```bash
curl -H "X-API-Key: voltron_YOUR_KEY_HERE" \
     https://api.yourdomain.com/api/health
```

📋 Endpoints

🩺 Health & Config

```http
GET  /api/health              # API status
GET  /api/config/domain       # API domain info
```

🎁 Trial Accounts

```http
POST /api/trial/check         # { username }
POST /api/trial/create        # { username, password, days }
GET  /api/trial/status/<u>    # Trial status
```

👥 User Management

```http
GET  /api/users/list          # All users with bandwidth
POST /api/users/create        # { username, password, days, limit, bandwidth }
POST /api/users/delete        # { username }
POST /api/users/lock          # { username }
POST /api/users/unlock        # { username }
POST /api/users/edit          # { username, password?, days?, limit?, bandwidth? }
POST /api/users/renew         # { username, days }
POST /api/users/reset_bandwidth { username }
POST /api/cleanup/expired     # Delete all expired users
```

🔌 Protocols & Dashboard

```http
GET  /api/protocols/status    # Active protocols
GET  /api/dashboard/info      # Server stats
```

🎨 Dynamic Banner

```http
GET  /api/banner/status       # Banner status
POST /api/banner/enable       # Enable banner
POST /api/banner/disable      # Disable banner
POST /api/banner/refresh      # Regenerate banners
```

📊 Sample Response

```json
{
  "success": true,
  "users": [
    {
      "username": "ahmed01",
      "expiry": "2026-10-15",
      "days_left": 13,
      "expiry_status": "active",
      "limit": 999,
      "bandwidth_limit": 50,
      "bandwidth_used_gb": 42.25,
      "bandwidth_pct": 84.5,
      "bandwidth_remaining_gb": 7.75,
      "bandwidth_status": "warning",
      "bandwidth_bar_color": "#FF9F43",
      "status": "active",
      "online": 3
    }
  ],
  "total": 1
}
```

---

🎛️ Web Panel (Lovable)

🚀 Setup Steps

1. Setup API on VPS:
   ```
   Main Menu → 19) Web Panel → 1) Full Setup
   ```
2. Copy for Lovable:
   ```
   Main Menu → 19) Web Panel → 10) Copy for Lovable
   ```
3. Paste to Lovable:
   · Get the API URL + API Key
   · Use with Lovable for building the dashboard

📱 Example Frontend (React)

```typescript
const API_URL = "https://api.yourdomain.com";
const API_KEY = "voltron_XXXXX";

async function apiCall(endpoint, method = "GET", body = null) {
  const opts = {
    method,
    headers: {
      "Content-Type": "application/json",
      "X-API-Key": API_KEY
    }
  };
  if (body) opts.body = JSON.stringify(body);
  const res = await fetch(`${API_URL}${endpoint}`, opts);
  return res.json();
}

// Create trial
apiCall("/api/trial/create", "POST", {
  username: "trial001",
  password: "pass1234",
  days: 3
});

// Toggle banner
apiCall("/api/banner/enable", "POST");
```

🎨 Lovable Prompt (Copy-Paste)

```
Build a premium VPN/SSH management dashboard called "Voltron VPN Panel":

DESIGN:
- Dark theme with purple (#9B59B6) + blue (#4D96FF) accents
- Glassmorphism cards
- Mobile responsive
- Framer Motion animations

PAGES:
1. Landing — Hero with "Get Free Trial" CTA
2. Trial — Signup form
3. Dashboard — Account + protocols + server stats
4. Admin — User management + Dynamic Banner control

API:
- Base URL: https://api.yourdomain.com
- Auth header: X-API-Key
- Endpoints: see /api/health

KEY FEATURES:
- Live username availability check
- Copy-to-clipboard for all details
- QR codes for protocol configs
- Bandwidth progress bars (color-coded)
- Dynamic Banner toggle
- Status badges (Active/Locked/Expired)

TECH: React + Vite + TS + TailwindCSS + React Query + Framer Motion
```

---

📸 Screenshots

🖥️ Main Menu

```
   VOLTRON TECH ULTIMATE v10.18 | Premium Edition
   ─────────────────────────────────────────────────────────
   OS         Ubuntu 24.04.4 LTS   | Uptime: 11 hours, 27 minutes
   Memory     35.74% Used          | Online: 2
   Users      1 Managed            | Load: 0.03
   ─────────────────────────────────────────────────────────
═══════════════════════════════════════════════════════════════════
                    👤 USER MANAGEMENT
═══════════════════════════════════════════════════════════════════
   1) Create User                 7) List Users
   2) Delete User                 8) Renew User
   3) Edit User                   9) Cleanup Expired
   4) Lock User                  10) Bulk Create
   5) Unlock User                11) View Bandwidth
   6) Trial Account              12) 📱 Client Config
```

📊 List Users (with Progress Bar)

```
┌─────────────────────────────────────────────────────────────┐
│ USER:   voltron                                             │
│ EXPIRY: 2026-10-04                                          │
│ BW:     4.12 MB/10.24 MB (40.2%) | 6.12 MB left             │
│ ONLINE: 0/999                                                │
│ STATUS: 🟢 Active                                           │
└─────────────────────────────────────────────────────────────┘
```

🎨 SSH Banner

```
📊 Bandwidth     : ████░░░░░░ 40.2% | 4.12 MB/10.24 MB (6.12 MB left)
📌 Account Status : ✅ ACTIVE
```

---

📝 Commands

🔧 Service Management

```bash
# Limiter
systemctl status voltrontech-limiter
systemctl restart voltrontech-limiter
journalctl -u voltrontech-limiter -f

# Traffic Monitor
systemctl status voltron-traffic

# API
systemctl status voltrontech-api
systemctl restart voltrontech-api
tail -f /var/log/voltrontech-api.log

# DNSTT
systemctl status dnstt
systemctl restart dnstt

# BadVPN
systemctl status badvpn

# ZiVPN
systemctl status zivpn

# HAProxy (SSL Tunnel)
systemctl status haproxy

# Nginx (Web Panel)
systemctl status nginx
nginx -t
```

🔍 Debugging

```bash
# Check user's .usage file
cat /etc/voltrontech/bandwidth/username.usage

# Check user's PIDs
pgrep -u username

# Check IO for each PID
for pid in $(pgrep -u username); do
    echo "PID $pid ($(cat /proc/$pid/comm)):"
    cat /proc/$pid/io | head -3
done

# Check banner
cat /etc/voltrontech/banners/username.txt

# Check database
grep "^username:" /etc/voltrontech/users.db

# Test banner-builder manually
/usr/local/bin/voltrontech-banner-build.sh "user" "2026-12-31" "50" "2" "999" "✅ ACTIVE" "#6BCB77"
```

🔄 Restart All Services

```bash
# From menu:
Main Menu → 21) Restart Services

# Or manually:
systemctl restart dnstt badvpn udp-custom haproxy zivpn \
    falconproxy voltrontech-limiter voltron-traffic voltrontech-api
```

📦 Backup & Restore

```bash
# Backup
tar -czf /root/voltron-backup-$(date +%Y%m%d).tar.gz /etc/voltrontech/

# Restore
# Main Menu → 20) System Utilities → 2) Restore
```

---

📱 Contact & Support

<div align="center">

https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white
https://img.shields.io/badge/WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white
https://img.shields.io/badge/GitHub-100000?style=for-the-badge&logo=github&logoColor=white

</div>

Platform Link
📱 Telegram @voltrontech
💬 WhatsApp Join Group
🐙 GitHub VOLTRON-TECH-X

---

📊 Project Status

Component Status Version
👤 User Management ✅ Stable v10.18
🌐 SSH ✅ Stable v10.18
📡 DNSTT ✅ Stable v10.18
⚡ BadVPN ✅ Stable v10.18
🚀 UDP-Custom ✅ Stable v10.18
🔒 SSL Tunnel ✅ Stable v10.18
🛡️ ZiVPN ✅ Stable v10.18
🦅 Falcon Proxy ✅ Stable v10.18
🎨 Dynamic Banner ✅ Stable v10.18
📊 Bandwidth Tracker ✅ FIXED v10.18
🌐 REST API ✅ Stable v10.18
🎛️ Web Panel ✅ Stable v10.18

---

🗺️ Roadmap

☑ ~~Basic SSH user management~~
☑ ~~Multiple protocols (SSH, DNSTT, BadVPN)~~
☑ ~~Speed boosters~~
☑ ~~Dynamic SSH banners~~
☑ ~~REST API~~
☑ ~~Web Panel integration~~
☑ ~~Smart bandwidth tracker~~
☑ ~~Progress bar with colors~~
☑ ~~Custom API domain~~
☐ DNS-over-HTTPS (DoH)
☐ Docker deployment
☐ Multi-language support
☐ Mobile app (React Native)

---

📜 License

This project is licensed under the MIT License — see the LICENSE file for details.

```
MIT License

Copyright (c) 2026 Voltron Tech

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
```
