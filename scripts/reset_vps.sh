#!/bin/bash
# =============================================================================
#  VPS Hard Reset - Restoration to "Fresh" State
#  Use with EXTREME CAUTION. This script attempts to remove all traces of
#  the vps-rdp-workstation setup.
# =============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║                  ⚠️  DANGER ZONE  ⚠️                         ║${NC}"
echo -e "${RED}║  This script will aggressively purge packages and configs.   ║${NC}"
echo -e "${RED}║  It is intended to reset a VPS to a near-fresh state.        ║${NC}"
echo -e "${RED}║  DATA LOSS IS LIKELY. PROCEED ONLY ON TEST VPS.              ║${NC}"
echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -ne "${YELLOW}Type 'destructive-reset' to confirm: ${NC}"
read -r confirmation

if [[ "$confirmation" != "destructive-reset" ]]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo -e "${YELLOW}[1/6] Stopping services...${NC}"
systemctl stop xrdp fail2ban docker ufw 2>/dev/null || true
systemctl disable xrdp fail2ban docker ufw 2>/dev/null || true

echo -e "${YELLOW}[2/6] Purging installed packages...${NC}"
# Desktop & XRDP
apt-get purge -y -qq xrdp kali-desktop-xfce kde-plasma-desktop plasma-desktop sddm xorg xserver-xorg 2>/dev/null || true
# Dev Tools
apt-get purge -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
apt-get purge -y -qq nodejs php python3-pip python3-venv 2>/dev/null || true
# Security
apt-get purge -y -qq ufw fail2ban unattended-upgrades 2>/dev/null || true
# Utilities
apt-get purge -y -qq zsh ripgrep fd-find neofetch btop 2>/dev/null || true
# Ansible
apt-get purge -y -qq ansible pipx 2>/dev/null || true

echo -e "${YELLOW}[3/6] Cleaning up directories and configs...${NC}"
rm -rf /etc/xrdp /etc/fail2ban /etc/ufw /etc/docker
rm -rf /var/lib/docker /var/lib/vps-setup
rm -rf /var/log/vps-setup*
rm -rf /root/.ansible /root/.local/bin/ansible*
rm -rf /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/nodesource.list
rm -rf /etc/apt/keyrings/docker.asc /usr/share/keyrings/nodesource.gpg

echo -e "${YELLOW}[4/6] Restoring basic networking...${NC}"
# Reset iptables just in case
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

echo -e "${YELLOW}[5/6] Auto-removing dependencies...${NC}"
apt-get autoremove -y -qq
apt-get clean

echo -e "${YELLOW}[6/6] Resetting users (optional warning)...${NC}"
echo -e "${YELLOW}NOTE: Users created by the setup (e.g. VPS_USERNAME) were NOT removed to prevent lockout.${NC}"
echo -e "${YELLOW}You may remove them manually with 'deluser --remove-home <username>'.${NC}"

echo ""
echo -e "${GREEN}✅ Hard reset completed. Please reboot your VPS.${NC}"
