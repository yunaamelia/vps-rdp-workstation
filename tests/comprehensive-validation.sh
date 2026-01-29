#!/bin/bash
#===============================================================================
# VPS RDP Workstation - Comprehensive Validation Script
#===============================================================================
# Run this after deployment to validate all components are working.
#
# Usage: ./tests/comprehensive-validation.sh
#
# Exit codes:
#   0 - All tests passed
#   1 - One or more tests failed
#===============================================================================

set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

USERNAME="${VPS_USERNAME:-developer}"

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║              VPS RDP Workstation - Comprehensive Validation                 ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

#-------------------------------------------------------------------------------
# Test Framework
#-------------------------------------------------------------------------------

pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAILED++))
}

warn() {
    echo -e "${YELLOW}⚠️  WARN${NC}: $1"
    ((WARNINGS++))
}

#-------------------------------------------------------------------------------
# Service Tests
#-------------------------------------------------------------------------------

echo "Services"
echo "─────────────────────────────────────"

# XRDP
if systemctl is-active --quiet xrdp; then
    pass "XRDP service is running"
else
    fail "XRDP service is not running"
fi

# SDDM
if systemctl is-active --quiet sddm; then
    pass "SDDM service is running"
else
    fail "SDDM service is not running"
fi

# Docker
if systemctl is-active --quiet docker 2>/dev/null; then
    pass "Docker service is running"
else
    warn "Docker service is not running (may be optional)"
fi

# SSH
if systemctl is-active --quiet ssh; then
    pass "SSH service is running"
else
    fail "SSH service is not running"
fi

# Fail2ban
if systemctl is-active --quiet fail2ban 2>/dev/null; then
    pass "Fail2ban service is running"
else
    warn "Fail2ban service is not running"
fi

echo ""

#-------------------------------------------------------------------------------
# Port Tests
#-------------------------------------------------------------------------------

echo "Ports"
echo "─────────────────────────────────────"

# RDP Port
if ss -tuln | grep -q ":3389 "; then
    pass "Port 3389 (RDP) is listening"
else
    fail "Port 3389 (RDP) is not listening"
fi

# SSH Port
if ss -tuln | grep -q ":22 "; then
    pass "Port 22 (SSH) is listening"
else
    fail "Port 22 (SSH) is not listening"
fi

echo ""

#-------------------------------------------------------------------------------
# Development Tools Tests
#-------------------------------------------------------------------------------

echo "Development Tools"
echo "─────────────────────────────────────"

# Node.js
if command -v node &>/dev/null; then
    pass "Node.js: $(node --version)"
else
    fail "Node.js is not installed"
fi

# npm
if command -v npm &>/dev/null; then
    pass "npm: $(npm --version)"
else
    fail "npm is not installed"
fi

# Python
if command -v python3 &>/dev/null; then
    pass "Python: $(python3 --version 2>&1)"
else
    fail "Python 3 is not installed"
fi

# PHP
if command -v php &>/dev/null; then
    pass "PHP: $(php -v | head -n1 | cut -d' ' -f1-2)"
else
    fail "PHP is not installed"
fi

# Composer
if command -v composer &>/dev/null; then
    pass "Composer: $(composer --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')"
else
    fail "Composer is not installed"
fi

# Docker
if command -v docker &>/dev/null; then
    pass "Docker: $(docker --version | cut -d' ' -f3 | tr -d ',')"
else
    warn "Docker is not installed (may be optional)"
fi

# Docker Compose
if docker compose version &>/dev/null 2>&1; then
    pass "Docker Compose: $(docker compose version 2>/dev/null | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+')"
else
    warn "Docker Compose is not available"
fi

# VS Code
if command -v code &>/dev/null; then
    pass "VS Code: $(code --version 2>/dev/null | head -n1)"
else
    fail "VS Code is not installed"
fi

# GitHub CLI
if command -v gh &>/dev/null; then
    pass "GitHub CLI: $(gh --version 2>/dev/null | head -n1 | cut -d' ' -f3)"
else
    warn "GitHub CLI is not installed"
fi

# Lazygit
if command -v lazygit &>/dev/null; then
    pass "Lazygit: installed"
else
    warn "Lazygit is not installed"
fi

echo ""

#-------------------------------------------------------------------------------
# Terminal Tools Tests
#-------------------------------------------------------------------------------

echo "Terminal Tools"
echo "─────────────────────────────────────"

# Zsh
if command -v zsh &>/dev/null; then
    pass "Zsh: $(zsh --version)"
else
    fail "Zsh is not installed"
fi

# Starship
if command -v starship &>/dev/null; then
    pass "Starship: $(starship --version 2>/dev/null | cut -d' ' -f2)"
else
    fail "Starship is not installed"
fi

# Oh My Zsh
if [ -d "/home/$USERNAME/.oh-my-zsh" ]; then
    pass "Oh My Zsh: installed"
else
    fail "Oh My Zsh is not installed"
fi

echo ""

#-------------------------------------------------------------------------------
# User Configuration Tests
#-------------------------------------------------------------------------------

echo "User Configuration"
echo "─────────────────────────────────────"

# User exists
if id "$USERNAME" &>/dev/null; then
    pass "User '$USERNAME' exists"
else
    fail "User '$USERNAME' does not exist"
fi

# User shell
if getent passwd "$USERNAME" | grep -q "/bin/zsh"; then
    pass "User shell is Zsh"
else
    warn "User shell is not Zsh"
fi

# Docker group (if Docker installed)
if command -v docker &>/dev/null; then
    if id -nG "$USERNAME" 2>/dev/null | grep -qw docker; then
        pass "User is in docker group"
    else
        warn "User is not in docker group (logout/login may be required)"
    fi
fi

# xsession file
if [ -f "/home/$USERNAME/.xsession" ]; then
    pass "xsession file exists"
else
    fail "xsession file missing"
fi

# Starship config
if [ -f "/home/$USERNAME/.config/starship.toml" ]; then
    pass "Starship config exists"
else
    warn "Starship config missing"
fi

echo ""

#-------------------------------------------------------------------------------
# Security Tests
#-------------------------------------------------------------------------------

# Security
echo "Security"
echo "─────────────────────────────────────"

# UFW
if [ "$EUID" -eq 0 ]; then
    if ufw status 2>/dev/null | grep -q "Status: active"; then
        pass "UFW firewall is active"
    else
        warn "UFW firewall is not active"
    fi
else
    # Non-root check
    if systemctl is-active --quiet ufw; then
        pass "UFW service is active"
    else
        warn "UFW service is not active (or permission denied)"
    fi
fi

# Fail2ban jails
if [ "$EUID" -eq 0 ]; then
    if fail2ban-client status 2>/dev/null | grep -q "sshd"; then
        pass "Fail2ban SSH jail is active"
    else
        warn "Fail2ban SSH jail is not active"
    fi
else
    # Non-root check
    if systemctl is-active --quiet fail2ban; then
        pass "Fail2ban service is active"
    else
        warn "Fail2ban service is not active (or permission denied)"
    fi
fi

echo ""

#-------------------------------------------------------------------------------
# Font Tests
#-------------------------------------------------------------------------------

echo "Fonts"
echo "─────────────────────────────────────"

# Check fonts as the target user to ensure user-installed fonts are detected
if [ "$EUID" -eq 0 ]; then
    if su - "$USERNAME" -c "fc-list" | grep -qi "JetBrainsMono"; then
        pass "JetBrains Mono Nerd Font installed"
    else
        warn "JetBrains Mono Nerd Font not found (checked as user $USERNAME)"
    fi
else
    if fc-list | grep -qi "JetBrainsMono"; then
        pass "JetBrains Mono Nerd Font installed"
    else
        warn "JetBrains Mono Nerd Font not found"
    fi
fi

echo ""

#-------------------------------------------------------------------------------
# Konsole Profile Tests
#-------------------------------------------------------------------------------

echo "Konsole Configuration"
echo "─────────────────────────────────────"

# Konsole profile
if [ -f "/home/$USERNAME/.local/share/konsole/Developer.profile" ]; then
    pass "Konsole Developer profile exists"
else
    warn "Konsole Developer profile not found"
fi

# Konsole default config
if [ -f "/home/$USERNAME/.config/konsolerc" ]; then
    pass "Konsole configuration exists"
else
    warn "Konsole configuration not found"
fi

echo ""

#-------------------------------------------------------------------------------
# Firefox Configuration Tests
#-------------------------------------------------------------------------------

echo "Firefox Configuration"
echo "─────────────────────────────────────"

# Firefox installed
if command -v firefox-esr &>/dev/null; then
    pass "Firefox ESR installed"
else
    warn "Firefox ESR not installed"
fi

# Firefox user.js
# Look for developer-default first, then default-release
FIREFOX_PROFILE=$(find "/home/$USERNAME/.mozilla/firefox" -maxdepth 1 -type d -name "*developer-default*" 2>/dev/null | head -1)
if [ -z "$FIREFOX_PROFILE" ]; then
    FIREFOX_PROFILE=$(find "/home/$USERNAME/.mozilla/firefox" -maxdepth 1 -type d -name "*.default-release" 2>/dev/null | head -1)
fi

if [ -n "$FIREFOX_PROFILE" ] && [ -f "$FIREFOX_PROFILE/user.js" ]; then
    pass "Firefox privacy configuration detected"
else
    warn "Firefox privacy configuration not found in $FIREFOX_PROFILE"
fi

# Default browser check
if command -v xdg-settings &>/dev/null; then
    DEFAULT_BROWSER=$(xdg-settings get default-web-browser 2>/dev/null || echo "")
    if echo "$DEFAULT_BROWSER" | grep -qi "firefox"; then
        pass "Firefox is default browser"
    else
        warn "Firefox is not set as default browser"
    fi
fi

echo ""

#-------------------------------------------------------------------------------
# Antigravity IDE Tests
#-------------------------------------------------------------------------------

echo "Antigravity IDE"
echo "─────────────────────────────────────"

# Antigravity installed
if command -v antigravity &>/dev/null; then
    pass "Google Antigravity installed"
else
    if dpkg -l | grep -q antigravity; then
        pass "Google Antigravity package installed"
    else
        warn "Google Antigravity not installed (optional)"
    fi
fi

# Desktop entry
if [ -f "/usr/share/applications/antigravity.desktop" ]; then
    pass "Antigravity desktop entry exists"
else
    warn "Antigravity desktop entry not found"
fi

# Workspace directory
if [ -d "/home/$USERNAME/antigravity-workspace" ]; then
    pass "Antigravity workspace directory exists"
else
    warn "Antigravity workspace directory not found"
fi

echo ""

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------

echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Test Results:"
echo "  ${GREEN}Passed${NC}:   $PASSED"
echo "  ${RED}Failed${NC}:   $FAILED"
echo "  ${YELLOW}Warnings${NC}: $WARNINGS"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    ALL REQUIRED TESTS PASSED!                               ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Your VPS RDP Workstation is ready for use."
    IP=$(hostname -I | awk '{print $1}')
    echo "Connect via RDP: $IP:3389"
    exit 0
else
    echo -e "${RED}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║                    SOME TESTS FAILED                                        ║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Please review the failed tests above and troubleshoot."
    exit 1
fi
