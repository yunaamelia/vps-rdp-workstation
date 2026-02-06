#!/bin/bash
# =============================================================================
# VPS RDP Workstation - Validation Script
# Tests all 30 success criteria for production readiness
# Version: 3.0.0
# =============================================================================

set -euo pipefail

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

# Counters
PASS=0
FAIL=0
WARN=0

# Functions
print_header() {
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD} 🧪 VPS RDP Workstation - Validation Suite${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

check() {
    local category="$1"
    local criteria="$2"
    local test_cmd="$3"

    if eval "$test_cmd" &>/dev/null; then
        echo -e " ${GREEN}✓${RESET} [${category}] ${criteria}"
        ((PASS++))
        return 0
    else
        echo -e " ${RED}✗${RESET} [${category}] ${criteria}"
        ((FAIL++))
        # Don't return 1 to prevent set -e from exiting the script
        return 0
    fi
}

print_section() {
    echo ""
    echo -e "${BOLD}$1${RESET}"
}

print_summary() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD} 📊 Validation Results${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo -e "   ${GREEN}Passed:${RESET}  ${PASS}/30"
    echo -e "   ${RED}Failed:${RESET}  ${FAIL}/30"
    echo -e "   ${YELLOW}Warnings:${RESET} ${WARN}"
    echo ""

    if [[ $FAIL -eq 0 ]]; then
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${GREEN}${BOLD} ✅ ALL SUCCESS CRITERIA MET - PRODUCTION READY!${RESET}"
        echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        exit 0
    else
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        echo -e "${RED}${BOLD} ❌ ${FAIL} CRITERIA FAILED - FIX BEFORE PRODUCTION${RESET}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
        exit 1
    fi
}

# =============================================================================
# MAIN VALIDATION
# =============================================================================

print_header

# -----------------------------------------------------------------------------
# FUNCTIONAL REQUIREMENTS (13 criteria)
# -----------------------------------------------------------------------------
print_section "FUNCTIONAL REQUIREMENTS (FR-1 to FR-13)"

check "FR-1"  "Setup script exists and executable"     "test -x ./setup.sh"
check "FR-2"  "XRDP service running"                   "systemctl is-active xrdp"
check "FR-3"  "Nordic theme installed"                 "test -d /usr/share/plasma/desktoptheme/Nordic || test -d /usr/share/themes/Nordic"
check "FR-4"  "Zsh shell available"                    "command -v zsh"
check "FR-5"  "Oh My Zsh installed"                    "test -d /home/*/\.oh-my-zsh || test -d ~/.oh-my-zsh"
check "FR-6"  "Node.js working"                        "node --version"
check "FR-7"  "Python 3 working"                       "python3 --version"
check "FR-8"  "Docker working"                         "docker --version"
check "FR-9"  "VS Code installed"                      "command -v code || dpkg -l | grep -q code"
check "FR-10" "lazygit installed"                      "command -v lazygit"
check "FR-11" "JetBrains Mono font installed"          "fc-list | grep -qi jetbrains"
check "FR-12" "KDE Plasma installed"                   "dpkg -l | grep -q kde-plasma-desktop"
check "FR-13" "Essential services running"             "systemctl is-active ssh docker"

# -----------------------------------------------------------------------------
# SECURITY REQUIREMENTS (7 criteria)
# -----------------------------------------------------------------------------
print_section "SECURITY REQUIREMENTS (SR-1 to SR-7)"

check "SR-1"  "UFW firewall active"                    "systemctl is-active ufw"
check "SR-2"  "SSH root login disabled"                "grep -qE '^PermitRootLogin\s+no' /etc/ssh/sshd_config"
check "SR-3"  "Port 22 allowed in firewall"            "sudo ufw status | grep -q '22/tcp'"
check "SR-4"  "Port 3389 allowed in firewall"          "sudo ufw status | grep -q '3389/tcp'"
check "SR-5"  "Fail2ban active"                        "systemctl is-active fail2ban"
check "SR-6"  "No plain-text passwords in logs"        "! grep -rE 'password\s*=' /var/log/vps-setup*.log 2>/dev/null"
check "SR-7"  "No password hashes in logs"             "! grep '\$6\$' /var/log/vps-setup*.log 2>/dev/null"

# -----------------------------------------------------------------------------
# QUALITY REQUIREMENTS (5 criteria)
# -----------------------------------------------------------------------------
print_section "QUALITY REQUIREMENTS (QR-1 to QR-5)"

check "QR-1"  "Ansible playbook exists"                "test -f playbooks/main.yml"
check "QR-2"  "Rollback playbook exists"               "test -f playbooks/rollback.yml"
check "QR-3"  "Callback plugin exists"                 "test -f plugins/callback/clean_progress.py"
check "QR-4"  "All roles have meta files"              "test \$(find roles -name 'meta' -type d | wc -l) -ge 15"
check "QR-5"  "Summary template exists"                "test -f templates/summary-log.j2"

# -----------------------------------------------------------------------------
# DOCUMENTATION REQUIREMENTS (5 criteria)
# -----------------------------------------------------------------------------
print_section "DOCUMENTATION REQUIREMENTS (DR-1 to DR-5)"

check "DR-1"  "README.md exists and substantial"       "test -f README.md && wc -l README.md | awk '{exit (\$1 > 100) ? 0 : 1}'"
check "DR-2"  "TROUBLESHOOTING.md exists"              "test -f docs/TROUBLESHOOTING.md"
check "DR-3"  "CONFIGURATION.md exists"                "test -f docs/CONFIGURATION.md"
check "DR-4"  "ARCHITECTURE.md exists"                 "test -f docs/ARCHITECTURE.md"
check "DR-5"  "Role documentation present"             "grep -r '^#' roles/*/tasks/*.yml | wc -l | awk '{exit (\$1 > 30) ? 0 : 1}'"

# -----------------------------------------------------------------------------
# SUMMARY
# -----------------------------------------------------------------------------
print_summary
