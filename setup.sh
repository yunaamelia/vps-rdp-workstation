#!/bin/bash
#===============================================================================
# VPS RDP Developer Workstation - Setup Script
#===============================================================================
# Version: 1.0.0
# Target: Debian 13 (Trixie)
# Description: Single-command deployment of a fully-configured RDP developer
#              workstation with KDE Plasma, modern dev tools, and Docker.
#
# Usage:
#   Interactive:     ./setup.sh
#   Non-Interactive: VPS_USERNAME=dev VPS_PASSWORD=pass ./setup.sh --non-interactive
#
# Environment Variables:
#   VPS_USERNAME     - Primary workstation user (required)
#   VPS_PASSWORD     - User password (required)
#   VPS_TIMEZONE     - System timezone (default: UTC)
#   VPS_HOSTNAME     - System hostname (default: vps-workstation)
#   VPS_THEME        - Desktop theme: dark/light (default: dark)
#   VPS_LOCALE       - System locale (default: en_US.UTF-8)
#===============================================================================

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Configure apt to be non-interactive
if command -v debconf-set-selections &>/dev/null; then
    echo "libraries/restart-without-asking boolean true" | debconf-set-selections 2>/dev/null || true
fi

# Script directory and logs
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="/var/log/vps-setup"
LOG_FILE="$LOG_DIR/deployment.log"
STATE_FILE="$LOG_DIR/deployment-state.json"

# Ensure log dir exists
mkdir -p "$LOG_DIR"

# Redirect all output to log file and console
exec > >(tee -a "$LOG_FILE") 2>&1

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

#===============================================================================
# Logging Functions
#===============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date -Iseconds)
    echo -e "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE" 2>/dev/null || echo -e "${timestamp} [${level}] ${message}"
}

log_info() { log "INFO" "$*"; }
log_warn() { echo -e "${YELLOW}⚠️  $*${NC}"; log "WARN" "$*"; }
log_error() { echo -e "${RED}❌ $*${NC}"; log "ERROR" "$*"; }
log_success() { echo -e "${GREEN}✅ $*${NC}"; log "INFO" "$*"; }

#===============================================================================
# Banner
#===============================================================================

show_banner() {
    echo -e "${BLUE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   ██╗   ██╗██████╗ ███████╗    ██████╗ ██████╗ ██████╗                       ║
║   ██║   ██║██╔══██╗██╔════╝    ██╔══██╗██╔══██╗██╔══██╗                      ║
║   ██║   ██║██████╔╝███████╗    ██████╔╝██║  ██║██████╔╝                      ║
║   ╚██╗ ██╔╝██╔═══╝ ╚════██║    ██╔══██╗██║  ██║██╔═══╝                       ║
║    ╚████╔╝ ██║     ███████║    ██║  ██║██████╔╝██║                           ║
║     ╚═══╝  ╚═╝     ╚══════╝    ╚═╝  ╚═╝╚═════╝ ╚═╝                           ║
║                                                                              ║
║   Developer Workstation Automation                                           ║
║   Version 1.0.0 | Target: Debian 13 (Trixie)                                 ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#===============================================================================
# Pre-flight Checks
#===============================================================================

check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        if ! sudo -n true 2>/dev/null; then
            log_error "This script requires root or sudo privileges"
            exit 1
        fi
    fi
    log_success "Root/sudo privileges confirmed"
}

check_debian_version() {
    if ! grep -q "13" /etc/debian_version 2>/dev/null; then
        log_error "Debian 13 (Trixie) required. Found: $(cat /etc/debian_version 2>/dev/null || echo 'unknown')"
        exit 1
    fi
    log_success "Debian 13 (Trixie) confirmed"
}

check_architecture() {
    if [ "$(uname -m)" != "x86_64" ]; then
        log_error "x86_64 architecture required. Found: $(uname -m)"
        exit 1
    fi
    log_success "x86_64 architecture confirmed"
}

check_resources() {
    local ram_gb
    ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    local disk_gb
    disk_gb=$(df -BG / | awk 'NR==2{print $4}' | tr -d 'G')

    if [ "$ram_gb" -lt 4 ]; then
        log_error "Minimum 4GB RAM required. Found: ${ram_gb}GB"
        exit 1
    fi

    if [ "$disk_gb" -lt 40 ]; then
        log_error "Minimum 40GB free disk required. Found: ${disk_gb}GB"
        exit 1
    fi

    log_success "Resources: ${ram_gb}GB RAM, ${disk_gb}GB free disk"
}

check_internet() {
    if ! ping -c 3 -W 5 google.com &>/dev/null; then
        log_error "Internet connection required"
        exit 1
    fi
    log_success "Internet connectivity confirmed"
}

run_preflight_checks() {
    echo ""
    echo -e "${BLUE}Running pre-flight checks...${NC}"
    echo ""

    check_root
    check_debian_version
    check_architecture
    check_resources
    check_internet

    echo ""
    log_success "All pre-flight checks passed"
    echo ""
}

#===============================================================================
# Configuration
#===============================================================================

prompt_configuration() {
    echo -e "${BLUE}Configuration${NC}"
    echo "============="
    echo ""

    # Username
    if [ -z "${VPS_USERNAME:-}" ]; then
        if [ "${NON_INTERACTIVE:-false}" = "true" ]; then
            VPS_USERNAME="admin"
            log_warn "Non-interactive mode: Defaulting username to 'admin'"
        else
            read -p "Enter username for workstation user: " VPS_USERNAME
            if [ -z "$VPS_USERNAME" ]; then
                log_error "Username cannot be empty"
                exit 1
            fi
        fi
    fi

    # Password
    if [ -z "${VPS_PASSWORD:-}" ]; then
        if [ "${NON_INTERACTIVE:-false}" = "true" ]; then
            # Generate random password if not provided
            VPS_PASSWORD=$(openssl rand -base64 12)
            log_warn "Non-interactive mode: Generated random password for user '$VPS_USERNAME'"
            log_warn "Password: $VPS_PASSWORD"
        else
            read -sp "Enter password for $VPS_USERNAME: " VPS_PASSWORD
            echo ""
            if [ -z "$VPS_PASSWORD" ]; then
                log_error "Password cannot be empty"
                exit 1
            fi
            read -sp "Confirm password: " VPS_PASSWORD_CONFIRM
            echo ""
            if [ "$VPS_PASSWORD" != "$VPS_PASSWORD_CONFIRM" ]; then
                log_error "Passwords do not match"
                exit 1
            fi
        fi
    fi

    # Optional parameters with defaults
    VPS_TIMEZONE="${VPS_TIMEZONE:-UTC}"
    VPS_HOSTNAME="${VPS_HOSTNAME:-vps-workstation}"
    VPS_THEME="${VPS_THEME:-dark}"
    VPS_LOCALE="${VPS_LOCALE:-en_US.UTF-8}"

    echo ""
    echo -e "${BLUE}Configuration Summary${NC}"
    echo "====================="
    echo "Username:  $VPS_USERNAME"
    echo "Timezone:  $VPS_TIMEZONE"
    echo "Hostname:  $VPS_HOSTNAME"
    echo "Theme:     $VPS_THEME"
    echo "Locale:    $VPS_LOCALE"
    echo ""

    if [ "${NON_INTERACTIVE:-false}" != "true" ]; then
        read -p "Proceed with this configuration? [Y/n] " confirm
        if [[ "$confirm" =~ ^[Nn] ]]; then
            log_info "Setup cancelled by user"
            exit 0
        fi
    fi
}

#===============================================================================
# Password Hashing
#===============================================================================

hash_password() {
    local password="$1"
    # Use openssl for SHA-512 hashing (compatible with Python 3.13+)
    openssl passwd -6 "$password"
}

#===============================================================================
# Ansible Installation
#===============================================================================

install_ansible() {
    if command -v ansible-playbook &>/dev/null; then
        local version
        version=$(ansible --version | head -n1)
        log_success "Ansible already installed: $version"
        mkdir -p /var/log/vps-setup/retry /var/log/vps-setup/facts_cache
        return 0
    fi

    log_info "Installing Ansible..."
    apt-get update
    apt-get install -y ansible python3-apt
    log_success "Ansible installed: $(ansible --version | head -n1)"
    mkdir -p /var/log/vps-setup/retry /var/log/vps-setup/facts_cache

    # Pre-generate locale to avoid Ansible hang
    log_info "Pre-generating locale en_US.UTF-8..."

    # Ensure locales package is installed
    if ! dpkg -s locales >/dev/null 2>&1; then
        apt-get install -y locales
    fi

    # Uncomment/Add en_US.UTF-8 in /etc/locale.gen
    if [ -f /etc/locale.gen ]; then
        sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
        if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
            echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
        fi
    fi

    # Generate
    if command -v locale-gen &>/dev/null; then
        locale-gen en_US.UTF-8 || locale-gen
        update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 || true
    fi

    # Export for current session
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8
}

#===============================================================================
# State Management
#===============================================================================

init_state() {
    mkdir -p "$LOG_DIR"

    cat > "$STATE_FILE" << EOF
{
    "deployment_id": "$(uuidgen 2>/dev/null || cat /proc/sys/kernel/random/uuid)",
    "start_time": "$(date -Iseconds)",
    "current_phase": "0",
    "completed_phases": [],
    "failed_phases": [],
    "username": "$VPS_USERNAME",
    "hostname": "$VPS_HOSTNAME"
}
EOF

    log_success "Deployment state initialized: $(jq -r '.deployment_id' "$STATE_FILE")"
}

update_phase() {
    local phase="$1"
    local status="$2"

    # Update current phase in state file
    if command -v jq &>/dev/null; then
        local tmp=$(mktemp)
        jq ".current_phase = \"$phase\" | .last_update = \"$(date -Iseconds)\"" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    fi
}

#===============================================================================
# Main Deployment
#===============================================================================

run_ansible_deployment() {
    local password_hash=$(hash_password "$VPS_PASSWORD")

    log_info "Starting Ansible deployment..."

    cd "$SCRIPT_DIR"

    # Export variables for Ansible
    export VPS_USERNAME
    export VPS_PASSWORD_HASH="$password_hash"
    export VPS_TIMEZONE
    export VPS_HOSTNAME
    export VPS_THEME
    export VPS_LOCALE

    # Run main playbook
    ansible-playbook \
        -i inventory/hosts.yml \
        playbooks/main.yml \
        -e "vps_username=$VPS_USERNAME" \
        -e "vps_password_hash='$password_hash'" \
        -e "vps_timezone=$VPS_TIMEZONE" \
        -e "vps_hostname=$VPS_HOSTNAME" \
        -e "vps_theme=$VPS_THEME" \
        -e "vps_locale=$VPS_LOCALE" \
        --become \
        -v 2>&1 | tee -a "$LOG_FILE"
}

#===============================================================================
# Completion
#===============================================================================

show_completion() {
    local ip_addr=$(hostname -I | awk '{print $1}')

    echo ""
    echo -e "${GREEN}"
    cat << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║   🎉 DEPLOYMENT COMPLETE!                                                    ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║   Connection Details:                                                        ║
║   ─────────────────────────────────────────────────────────────────────────  ║
║   RDP Address:  $ip_addr:3389
║   Username:     $VPS_USERNAME
║   Password:     (as configured)
║                                                                              ║
║   Connect using Windows Remote Desktop Connection (mstsc.exe)                ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║   What's Installed:                                                          ║
║   ─────────────────────────────────────────────────────────────────────────  ║
║   • KDE Plasma Desktop with dark theme                                       ║
║   • VS Code, OpenCode AI, and development tools                              ║
║   • Node.js LTS, Python 3.12+, PHP 8.x                                       ║
║   • Docker with Compose V2                                                   ║
║   • Zsh with Oh My Zsh and Starship prompt                                   ║
║   • JetBrains Mono Nerd Font                                                 ║
║   • fail2ban and UFW firewall configured                                    ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║   ⚠️  IMPORTANT: Logout and login required for docker group membership       ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

#===============================================================================
# Main Entry Point
#===============================================================================

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --non-interactive|-n)
                NON_INTERACTIVE=true
                shift
                ;;
            --help|-h)
                echo "Usage: $0 [--non-interactive]"
                echo ""
                echo "Environment Variables:"
                echo "  VPS_USERNAME   - Required: Username for workstation user"
                echo "  VPS_PASSWORD   - Required: Password for the user"
                echo "  VPS_TIMEZONE   - Optional: System timezone (default: UTC)"
                echo "  VPS_HOSTNAME   - Optional: System hostname (default: vps-workstation)"
                echo "  VPS_THEME      - Optional: Desktop theme dark/light (default: dark)"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done

    show_banner
    run_preflight_checks
    prompt_configuration

    # Ensure we're root for the rest
    if [ "$(id -u)" -ne 0 ]; then
        exec sudo -E "$0" "$@"
    fi

    init_state
    install_ansible
    run_ansible_deployment
    show_completion
}

# Run main
main "$@"
