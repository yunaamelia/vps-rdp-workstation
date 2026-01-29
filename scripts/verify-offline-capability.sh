#!/bin/bash
#===============================================================================
# VPS RDP Workstation - Offline Capability Verification
#===============================================================================
# This script identifies which parts of deployment require internet access
# and which can operate offline once packages are cached.
#
# Usage: ./scripts/verify-offline-capability.sh
#===============================================================================

set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}"
echo "╔══════════════════════════════════════════════════════════════════════════════╗"
echo "║            VPS RDP Workstation - Offline Capability Analysis                ║"
echo "╚══════════════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

#-------------------------------------------------------------------------------
# Internet-Required Components
#-------------------------------------------------------------------------------

echo -e "${CYAN}Components Requiring Internet Access:${NC}"
echo "─────────────────────────────────────────"
echo ""

cat << 'EOF'
The following operations REQUIRE internet connectivity:

📥 INITIAL DEPLOYMENT (Internet Required)
├── Phase 1: System Preparation
│   ├── apt update & upgrade
│   └── Install essential packages
│
├── Phase 3: Dependencies
│   ├── Add external repository GPG keys
│   │   ├── NodeSource (Node.js)
│   │   ├── Docker
│   │   ├── Microsoft (VS Code)
│   │   └── GitHub CLI
│   ├── Download from GitHub Releases
│   │   ├── JetBrains Mono Nerd Font
│   │   ├── Lazygit binary
│   │   └── Starship prompt
│   └── Install via package managers
│       ├── npm global packages
│       └── pipx packages
│
├── Phase 4: RDP Packages
│   ├── Install KDE Plasma packages
│   ├── Install XRDP
│   ├── Install Docker
│   ├── Install VS Code
│   ├── Install VS Code extensions
│   ├── Oh My Zsh installation script
│   └── Zsh plugin repositories (git clone)
│
└── Phase 6: Optimization
    └── Unattended-upgrades package

EOF

echo ""

#-------------------------------------------------------------------------------
# Offline-Capable Components
#-------------------------------------------------------------------------------

echo -e "${CYAN}Components That Work Offline After Initial Setup:${NC}"
echo "─────────────────────────────────────────────────────"
echo ""

cat << 'EOF'
The following operations work WITHOUT internet after initial deployment:

🔧 CONFIGURATION (Offline Capable)
├── Phase 2: User Management
│   ├── Create user account
│   ├── Configure sudo permissions
│   └── Set user password
│
├── Phase 5: Validation
│   ├── Service health checks
│   ├── Port verification
│   └── Command verification
│
├── Phase 6: Optimization (Partial)
│   ├── UFW firewall configuration
│   ├── Fail2ban jail configuration
│   ├── SSH hardening
│   ├── Sysctl performance tuning
│   └── KDE compositor settings
│
├── Phase 7: Final Validation
│   ├── All validation checks
│   └── Report generation
│
├── Phase 8: Enhancements
│   ├── VS Code settings (local files)
│   ├── Konsole profile
│   ├── Zsh aliases
│   └── MOTD configuration
│
└── Rollback Operations
    ├── Service stops
    ├── Package removal (cached debs)
    ├── File cleanup
    └── User removal

EOF

echo ""

#-------------------------------------------------------------------------------
# Offline Deployment Strategy
#-------------------------------------------------------------------------------

echo -e "${CYAN}Offline Deployment Strategy:${NC}"
echo "───────────────────────────────"
echo ""

cat << 'EOF'
To deploy in an air-gapped or limited-internet environment:

1. PRE-STAGING (On Internet-Connected Machine)
   ├── Run full deployment on a staging VPS
   ├── Create VPS snapshot after Phase 4
   └── Export all .deb packages from /var/cache/apt/archives/

2. PACKAGE CACHE CREATION
   ├── Copy /var/cache/apt/archives/*.deb to USB/archive
   ├── Download GitHub releases manually:
   │   ├── JetBrainsMono.zip from Nerd Fonts releases
   │   ├── lazygit_*_Linux_x86_64.tar.gz
   │   └── starship binary from releases
   └── Clone git repositories:
       ├── ohmyzsh/ohmyzsh
       ├── zsh-users/zsh-autosuggestions
       └── zsh-users/zsh-syntax-highlighting

3. OFFLINE DEPLOYMENT
   ├── Restore from snapshot, OR
   ├── Transfer cached packages and run with:
   │   └── VPS_OFFLINE=true ./setup.sh
   └── Skip repository additions and use local cache

📌 NOTE: This deployment system is primarily designed for 
   internet-connected environments. Offline support requires 
   significant manual preparation.

EOF

echo ""

#-------------------------------------------------------------------------------
# Summary
#-------------------------------------------------------------------------------

echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${CYAN}Summary:${NC}"
echo ""
echo "  Internet Required:  Phases 1, 3, 4 (initial deployment)"
echo "  Offline Capable:    Phases 2, 5, 6, 7, 8, Rollback"
echo ""
echo "  Estimated Data Download: ~500MB - 1GB (depending on options)"
echo ""
echo -e "${GREEN}Recommendation:${NC}"
echo "  Deploy on internet-connected VPS, then take a snapshot."
echo "  Future instances can be cloned from snapshot for faster deployment."
echo ""
echo -e "${YELLOW}═══════════════════════════════════════════════════════════════════════════════${NC}"
