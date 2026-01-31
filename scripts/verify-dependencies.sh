#!/bin/bash
#===============================================================================
# VPS RDP Workstation - Verify External Dependencies
#===============================================================================
# Checks if all external repositories and resources are accessible before
# deployment. Run this from a machine with internet access.
#
# Usage: ./scripts/verify-dependencies.sh
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

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║              VPS RDP Workstation - Dependency Verification                  ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

#-------------------------------------------------------------------------------
# Test Framework
#-------------------------------------------------------------------------------

check_url() {
    local name="$1"
    local url="$2"

    echo -n "Checking $name... "
    if curl -sSfL --connect-timeout 10 --max-time 30 "$url" -o /dev/null 2>/dev/null; then
        echo -e "${GREEN}✅ Accessible${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        ((FAILED++))
        return 1
    fi
}

check_api() {
    local name="$1"
    local url="$2"

    echo -n "Checking $name... "
    local response=$(curl -sSL --connect-timeout 10 --max-time 30 "$url" 2>/dev/null)
    if [ -n "$response" ]; then
        echo -e "${GREEN}✅ Accessible${NC}"
        ((PASSED++))
        return 0
    else
        echo -e "${RED}❌ Failed${NC}"
        ((FAILED++))
        return 1
    fi
}

#-------------------------------------------------------------------------------
# Repository Checks
#-------------------------------------------------------------------------------

echo "Package Repositories"
echo "─────────────────────────────────────"

check_url "Debian Repositories" "http://deb.debian.org/debian/dists/trixie/Release"
check_url "NodeSource Repository" "https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key"
check_url "Docker Repository" "https://download.docker.com/linux/debian/gpg"
check_url "Microsoft VS Code" "https://packages.microsoft.com/keys/microsoft.asc"
check_url "GitHub CLI" "https://cli.github.com/packages/githubcli-archive-keyring.gpg"

echo ""

#-------------------------------------------------------------------------------
# GitHub Release Checks
#-------------------------------------------------------------------------------

echo "GitHub Releases"
echo "─────────────────────────────────────"

check_api "Nerd Fonts (JetBrainsMono)" "https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
check_api "Lazygit" "https://api.github.com/repos/jesseduffield/lazygit/releases/latest"
check_url "Starship Install Script" "https://starship.rs/install.sh"
check_url "Oh My Zsh Install" "https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"

echo ""

#-------------------------------------------------------------------------------
# Zsh Plugin Repos
#-------------------------------------------------------------------------------

echo "Zsh Plugin Repositories"
echo "─────────────────────────────────────"

check_url "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
check_url "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"

echo ""

#-------------------------------------------------------------------------------
# Other URLs
#-------------------------------------------------------------------------------

echo "Other Resources"
echo "─────────────────────────────────────"

check_url "Composer Installer" "https://getcomposer.org/installer"
check_url "PyPI (for pipx)" "https://pypi.org/simple/"
check_url "NPM Registry" "https://registry.npmjs.org/"

echo ""

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------

echo "═══════════════════════════════════════════════════════════════════════════════"
echo ""
echo "Verification Results:"
echo "  ${GREEN}Passed${NC}: $PASSED"
echo "  ${RED}Failed${NC}: $FAILED"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                    ALL DEPENDENCIES ACCESSIBLE!                             ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Your network can reach all required resources."
    echo "You can proceed with deployment."
    exit 0
else
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                    SOME DEPENDENCIES UNAVAILABLE                            ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "Some resources are not accessible. Deployment may fail."
    echo "Check network connectivity or firewall rules."
    exit 1
fi
