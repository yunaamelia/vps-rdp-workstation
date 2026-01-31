#!/bin/bash
#===============================================================================
# VPS RDP Workstation - Pre-flight Checks
#===============================================================================
# Run this script before deployment to validate system requirements.
#
# Usage: ./scripts/pre-flight-checks.sh
#
# Exit codes:
#   0 - All checks passed
#   1 - One or more checks failed
#===============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║              VPS RDP Workstation - Pre-flight Checks                        ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

#-------------------------------------------------------------------------------
# Check Functions
#-------------------------------------------------------------------------------

check_os() {
    echo -n "Checking OS version... "
    if grep -q "13" /etc/debian_version 2>/dev/null; then
        echo -e "${GREEN}✅ Debian 13 (Trixie)${NC}"
        return 0
    else
        echo -e "${RED}❌ Not Debian 13 (found: $(cat /etc/debian_version 2>/dev/null || echo 'unknown'))${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_architecture() {
    echo -n "Checking architecture... "
    local arch
    arch=$(uname -m)
    if [ "$arch" = "x86_64" ]; then
        echo -e "${GREEN}✅ $arch${NC}"
        return 0
    else
        echo -e "${RED}❌ $arch (x86_64 required)${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_memory() {
    echo -n "Checking memory... "
    local ram_mb
    ram_mb=$(free -m | awk '/^Mem:/{print $2}')
    local ram_gb=$((ram_mb / 1024))

    if [ "$ram_gb" -ge 4 ]; then
        echo -e "${GREEN}✅ ${ram_gb}GB (minimum: 4GB)${NC}"
        return 0
    elif [ "$ram_gb" -ge 3 ]; then
        echo -e "${YELLOW}⚠️  ${ram_gb}GB (recommended: 4GB+)${NC}"
        return 0
    else
        echo -e "${RED}❌ ${ram_gb}GB (minimum: 4GB required)${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_disk() {
    echo -n "Checking disk space... "
    local disk_gb
    disk_gb=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')

    if [ "$disk_gb" -ge 40 ]; then
        echo -e "${GREEN}✅ ${disk_gb}GB free (minimum: 40GB)${NC}"
        return 0
    elif [ "$disk_gb" -ge 30 ]; then
        echo -e "${YELLOW}⚠️  ${disk_gb}GB free (recommended: 40GB+)${NC}"
        return 0
    else
        echo -e "${RED}❌ ${disk_gb}GB free (minimum: 40GB required)${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_cpu() {
    echo -n "Checking CPU cores... "
    local cores
    cores=$(nproc 2>/dev/null || grep -c ^processor /proc/cpuinfo)

    if [ "$cores" -ge 4 ]; then
        echo -e "${GREEN}✅ ${cores} cores (excellent)${NC}"
    elif [ "$cores" -ge 2 ]; then
        echo -e "${GREEN}✅ ${cores} cores (minimum)${NC}"
    else
        echo -e "${YELLOW}⚠️  ${cores} core(s) (recommended: 2+)${NC}"
    fi
    return 0
}

check_privileges() {
    echo -n "Checking privileges... "
    if [ "$(id -u)" -eq 0 ]; then
        echo -e "${GREEN}✅ Running as root${NC}"
        return 0
    elif sudo -n true 2>/dev/null; then
        echo -e "${GREEN}✅ Passwordless sudo available${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Need root or sudo access${NC}"
        return 0
    fi
}

check_internet() {
    echo -n "Checking internet connectivity... "
    if ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
        echo -e "${GREEN}✅ Connected${NC}"
        return 0
    else
        echo -e "${RED}❌ No internet connection${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_dns() {
    echo -n "Checking DNS resolution... "
    if host google.com &>/dev/null || ping -c 1 -W 5 google.com &>/dev/null; then
        echo -e "${GREEN}✅ DNS working${NC}"
        return 0
    else
        echo -e "${RED}❌ DNS resolution failed${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_apt() {
    echo -n "Checking apt... "
    if apt-get update &>/dev/null; then
        echo -e "${GREEN}✅ Package manager working${NC}"
        return 0
    else
        echo -e "${RED}❌ apt-get update failed${NC}"
        ((ERRORS++))
        return 1
    fi
}

check_ports() {
    echo -n "Checking port 3389 availability... "
    if ! netstat -tuln 2>/dev/null | grep -q ":3389 " && \
       ! ss -tuln 2>/dev/null | grep -q ":3389 "; then
        echo -e "${GREEN}✅ Port available${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  Port 3389 in use (will be reconfigured)${NC}"
        return 0
    fi
}

#-------------------------------------------------------------------------------
# Run Checks
#-------------------------------------------------------------------------------

echo ""
echo "System Requirements:"
echo "─────────────────────────────────────"
# shellcheck disable=SC2310
check_os || true
# shellcheck disable=SC2310
check_architecture || true
# shellcheck disable=SC2310
check_cpu || true
# shellcheck disable=SC2310
check_memory || true
# shellcheck disable=SC2310
check_disk || true

echo ""
echo "Access & Connectivity:"
echo "─────────────────────────────────────"
# shellcheck disable=SC2310
check_privileges || true
# shellcheck disable=SC2310
check_internet || true
# shellcheck disable=SC2310
check_dns || true
# shellcheck disable=SC2310
check_apt || true
# shellcheck disable=SC2310
check_ports || true

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------

echo ""
echo "─────────────────────────────────────"
if [ "$ERRORS" -eq 0 ]; then
    echo -e "${GREEN}✅ All pre-flight checks passed!${NC}"
    echo ""
    echo "You can proceed with: sudo ./setup.sh"
    exit 0
else
    echo -e "${RED}❌ $ERRORS check(s) failed${NC}"
    echo ""
    echo "Please resolve the issues above before running setup."
    exit 1
fi
