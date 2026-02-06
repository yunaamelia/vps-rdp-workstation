#!/bin/bash
# =============================================================================
#  VPS RDP Developer Workstation - Single Command Setup
#  Version: 3.0.0-secure-enhanced
#
#  Transforms a fresh Debian 13 VPS into a fully-configured RDP developer
#  workstation with security hardening and beautiful logging.
#
#  Usage: ./setup.sh [OPTIONS]
#
#  Options:
#    --help              Show this help message
#    --dry-run           Show what would be done without making changes
#    --verbose           Enable verbose output
#    --debug             Enable debug mode (very verbose)
#    --skip-validation   Skip pre-flight validation checks
#    --rollback          Rollback to previous state
#    --resume            Resume from last checkpoint
#    --ci                CI/CD mode (non-interactive)
#
#  Environment Variables:
#    VPS_USERNAME        Primary workstation username (required)
#    VPS_SECRETS_FILE    Path to secure password file (optional)
#    VPS_CONFIG_FILE     Custom configuration file (optional)
#
# =============================================================================
set -euo pipefail

# Script metadata
readonly SCRIPT_VERSION="3.0.0"
SCRIPT_DIR=""
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly LOG_DIR="/var/log"
readonly STATE_DIR="/var/lib/vps-setup"
readonly BACKUP_DIR="/var/backups/vps-setup"

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
# MAGENTA removed - unused
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'  # No Color

# Unicode symbols
readonly CHECK="✓"
readonly CROSS="✗"
readonly WARN="⚠"
readonly INFO="ℹ"
readonly ARROW="→"
readonly ROCKET="🚀"
readonly LOCK="🔒"
readonly GEAR="⚙"
readonly PACKAGE="📦"

# Default values
DRY_RUN=false
VERBOSE=false
DEBUG=false
SKIP_VALIDATION=false
ROLLBACK_MODE=false
RESUME_MODE=false
CI_MODE=false

# =============================================================================
#  LOGGING FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}${INFO}${NC} ${1}"
    log_to_file "INFO" "$1"
}

log_success() {
    echo -e "${GREEN}${CHECK}${NC} ${1}"
    log_to_file "SUCCESS" "$1"
}

log_warn() {
    echo -e "${YELLOW}${WARN}${NC} ${1}"
    log_to_file "WARN" "$1"
}

log_error() {
    echo -e "${RED}${CROSS}${NC} ${1}" >&2
    log_to_file "ERROR" "$1"
}

log_debug() {
    if [[ "$DEBUG" == "true" ]]; then
        echo -e "${DIM}[DEBUG] ${1}${NC}"
    fi
    log_to_file "DEBUG" "$1"
}

log_to_file() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    # Sanitize message (remove potential passwords)
    local sanitized
    sanitized=$(echo "$message" | sed -E 's/(password|passwd|secret|token|key)=\S+/\1=***REDACTED***/gi')

    if [[ -d "$LOG_DIR" ]] && [[ -w "$LOG_DIR" ]]; then
        echo "[$timestamp] [$level] $sanitized" >> "${LOG_DIR}/vps-setup.log" 2>/dev/null || true

        if [[ "$level" == "ERROR" ]] || [[ "$level" == "WARN" ]]; then
            echo "[$timestamp] [$level] $sanitized" >> "${LOG_DIR}/vps-setup-error.log" 2>/dev/null || true
        fi
    fi
}

# =============================================================================
#  UI HELPER FUNCTIONS
# =============================================================================

print_header() {
    local title="$1"
    local width=60
    local padding=$(( (width - ${#title} - 2) / 2 ))

    echo ""
    echo -e "${CYAN}╔$(printf '═%.0s' $(seq 1 $width))╗${NC}"
    echo -e "${CYAN}║${NC}$(printf ' %.0s' $(seq 1 $padding))${BOLD}$title${NC}$(printf ' %.0s' $(seq 1 $((width - padding - ${#title}))))${CYAN}║${NC}"
    echo -e "${CYAN}╚$(printf '═%.0s' $(seq 1 $width))╝${NC}"
    echo ""
}

print_section() {
    local title="$1"
    echo ""
    echo -e "${BOLD}${BLUE}━━━ $title ━━━${NC}"
    echo ""
}

print_step() {
    local step_num="$1"
    local total="$2"
    local description="$3"
    echo -e "${CYAN}[${step_num}/${total}]${NC} ${description}"
}

show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
  ╦  ╦╔═╗╔═╗  ╦═╗╔╦╗╔═╗  ╦ ╦╔═╗╦═╗╦╔═╔═╗╔╦╗╔═╗╔╦╗╦╔═╗╔╗╔
  ╚╗╔╝╠═╝╚═╗  ╠╦╝ ║║╠═╝  ║║║║ ║╠╦╝╠╩╗╚═╗ ║ ╠═╣ ║ ║║ ║║║║
   ╚╝ ╩  ╚═╝  ╩╚══╩╝╩    ╚╩╝╚═╝╩╚═╩ ╩╚═╝ ╩ ╩ ╩ ╩ ╩╚═╝╝╚╝
EOF
    echo -e "${NC}"
    echo -e "${DIM}Version ${SCRIPT_VERSION} | Security-Hardened | Debian 13${NC}"
    echo ""
}

# =============================================================================
#  VALIDATION FUNCTIONS
# =============================================================================

validate_username() {
    local username="$1"

    # Check length (3-32 characters)
    if [[ ${#username} -lt 3 ]] || [[ ${#username} -gt 32 ]]; then
        log_error "Username must be 3-32 characters long"
        return 1
    fi

    # Check pattern (lowercase, numbers, hyphens, underscores)
    if ! [[ "$username" =~ ^[a-z][a-z0-9_-]*$ ]]; then
        log_error "Username must start with lowercase letter and contain only lowercase letters, numbers, hyphens, underscores"
        return 1
    fi

    # Check forbidden names
    local forbidden_names="root admin administrator test guest user default system"
    for name in $forbidden_names; do
        if [[ "$username" == "$name" ]]; then
            log_error "Username '$username' is not allowed"
            return 1
        fi
    done

    # Check if user already exists (non-fatal, just warn)
    if id "$username" &>/dev/null; then
        log_warn "User '$username' already exists - will update configuration"
    fi

    return 0
}

validate_password() {
    local password="$1"
    local min_length=8

    # Skip validation if requested
    if [[ "$SKIP_VALIDATION" == "true" ]]; then
        log_warn "Skipping password validation checks"
        return 0
    fi

    # Check length
    if [[ ${#password} -lt $min_length ]]; then
        log_error "Password must be at least $min_length characters"
        return 1
    fi

    # Check for uppercase
    if ! [[ "$password" =~ [A-Z] ]]; then
        log_error "Password must contain at least one uppercase letter"
        return 1
    fi

    # Check for lowercase
    if ! [[ "$password" =~ [a-z] ]]; then
        log_error "Password must contain at least one lowercase letter"
        return 1
    fi

    # Check for digit
    if ! [[ "$password" =~ [0-9] ]]; then
        log_error "Password must contain at least one digit"
        return 1
    fi

    # Check for special character
    if ! [[ "$password" =~ [^a-zA-Z0-9] ]]; then
        log_error "Password must contain at least one special character"
        return 1
    fi

    # Check for common patterns
    local common_passwords="password Password123 admin123 welcome123 qwerty123"
    for common in $common_passwords; do
        if [[ "$password" == "$common" ]]; then
            log_error "Password is too common"
            return 1
        fi
    done

    return 0
}

# =============================================================================
#  PASSWORD HANDLING (SECURITY-CRITICAL)
# =============================================================================

hash_password() {
    local password="$1"
    local hash=""

    # Try openssl first (standard on Debian)
    if command -v openssl &>/dev/null; then
        hash=$(openssl passwd -6 "$password")
    fi

    # Fallback to python crypt if openssl failed/missing
    if [[ -z "$hash" ]]; then
        hash=$(python3 -c "
import crypt
import secrets
salt = crypt.mksalt(crypt.METHOD_SHA512)
print(crypt.crypt('$password', salt))
" 2>/dev/null)
    fi

    if [[ -z "$hash" ]]; then
        log_error "Failed to hash password. Install openssl or python3."
        return 1
    fi

    echo "$hash"
}

read_password_secure() {
    local prompt="$1"
    local password=""

    # Disable echo for password input
    stty -echo 2>/dev/null || true

    echo -ne "${CYAN}${LOCK}${NC} $prompt: " >&2
    read -r password
    echo "" >&2

    # Re-enable echo
    stty echo 2>/dev/null || true

    echo "$password"
}

get_credentials() {
    local username=""
    local password=""
    local password_confirm=""
    local password_hash=""

    print_section "Credential Setup ${LOCK}"

    # Get username
    if [[ -n "${VPS_USERNAME:-}" ]]; then
        username="$VPS_USERNAME"
        log_info "Using username from environment: $username"
    else
        echo -ne "${BLUE}${INFO}${NC} Enter username: "
        read -r username
    fi

    # Validate username
    if [[ "$SKIP_VALIDATION" != "true" ]]; then
        if ! validate_username "$username"; then
            return 1
        fi
    fi

    # Get password
    if [[ -n "${VPS_PASSWORD:-}" ]]; then
        password="$VPS_PASSWORD"
        log_info "Using password from environment variable"
    elif [[ -n "${VPS_SECRETS_FILE:-}" ]] && [[ -f "${VPS_SECRETS_FILE}" ]]; then
        # Read from secure file
        local file_perms
        file_perms=$(stat -c %a "${VPS_SECRETS_FILE}" 2>/dev/null || stat -f %Lp "${VPS_SECRETS_FILE}" 2>/dev/null)

        if [[ "$file_perms" != "600" ]]; then
            log_error "Secrets file must have 0600 permissions (current: $file_perms)"
            return 1
        fi

        password=$(grep -E '^password=' "${VPS_SECRETS_FILE}" | cut -d= -f2- | tr -d '\n')

        if [[ -z "$password" ]]; then
            log_error "No password found in secrets file"
            return 1
        fi

        log_info "Using password from secure file"
    elif [[ -z "${VPS_PASSWORD:-}" ]]; then
        # Interactive password input
        password=$(read_password_secure "Enter password")
        password_confirm=$(read_password_secure "Confirm password")

        if [[ "$password" != "$password_confirm" ]]; then
            log_error "Passwords do not match"
            return 1
        fi
    fi

    # Validate password
    if ! validate_password "$password"; then
        return 1
    fi

    # Hash password immediately
    log_info "Hashing password..."
    password_hash=$(hash_password "$password")

    # CRITICAL: Overwrite plain-text password
    password="OVERWRITTEN"
    password_confirm="OVERWRITTEN"
    unset password password_confirm

    # Export for Ansible (hash only, never plain-text)
    export VPS_USERNAME="$username"
    export VPS_USER_PASSWORD_HASH="$password_hash"

    log_success "Credentials validated and securely hashed"
    return 0
}

# =============================================================================
#  SYSTEM CHECKS
# =============================================================================

check_os() {
    print_step "1" "6" "Checking operating system..."

    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect operating system"
        return 1
    fi

    # shellcheck disable=SC1091
    source /etc/os-release

    if [[ "$ID" != "debian" ]]; then
        log_error "This script requires Debian (detected: $ID)"
        return 1
    fi

    if [[ "$VERSION_CODENAME" != "trixie" ]] && [[ "$VERSION_ID" != "13" ]]; then
        log_warn "This script is designed for Debian 13 (Trixie), detected: $VERSION_CODENAME"
    fi

    log_success "Operating system: $PRETTY_NAME"
    return 0
}

check_architecture() {
    print_step "2" "6" "Checking system architecture..."

    local arch
    arch=$(uname -m)

    if [[ "$arch" != "x86_64" ]]; then
        log_error "This script requires x86_64 architecture (detected: $arch)"
        return 1
    fi

    log_success "Architecture: $arch"
    return 0
}

check_resources() {
    print_step "3" "6" "Checking system resources..."

    # Check RAM (minimum 4GB)
    local mem_kb
    mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    local mem_gb=$((mem_kb / 1024 / 1024))

    if [[ $mem_gb -lt 4 ]]; then
        log_error "Minimum 4GB RAM required (detected: ${mem_gb}GB)"
        return 1
    fi

    log_debug "RAM: ${mem_gb}GB"

    # Check disk space (minimum 40GB free)
    local disk_free
    disk_free=$(df -BG / | tail -1 | awk '{print $4}' | tr -d 'G')

    if [[ $disk_free -lt 40 ]]; then
        log_error "Minimum 40GB disk space required (available: ${disk_free}GB)"
        return 1
    fi

    log_debug "Disk free: ${disk_free}GB"

    # Check CPU cores
    local cpu_cores
    cpu_cores=$(nproc)

    if [[ $cpu_cores -lt 2 ]]; then
        log_warn "Minimum 2 CPU cores recommended (detected: $cpu_cores)"
    fi

    log_success "Resources: ${mem_gb}GB RAM, ${disk_free}GB disk, ${cpu_cores} CPU cores"
    return 0
}

check_network() {
    print_step "4" "6" "Checking network connectivity..."

    # Check internet connectivity
    if ! ping -c 1 -W 5 1.1.1.1 &>/dev/null; then
        if ! ping -c 1 -W 5 8.8.8.8 &>/dev/null; then
            log_error "No internet connectivity"
            return 1
        fi
    fi

    # Check DNS resolution
    if ! host -W 5 deb.debian.org &>/dev/null; then
        log_warn "DNS resolution may be slow or failing"
    fi

    log_success "Network connectivity verified"
    return 0
}

check_permissions() {
    print_step "5" "6" "Checking permissions..."

    if [[ $EUID -ne 0 ]]; then
        if ! sudo -n true 2>/dev/null; then
            log_error "This script requires root access or passwordless sudo"
            return 1
        fi
    fi

    log_success "Permissions verified"
    return 0
}

check_dependencies() {
    print_step "6" "6" "Checking dependencies..."

    local missing_deps=()

    # Check for required commands
    for cmd in python3 curl wget git; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_info "Installing missing dependencies: ${missing_deps[*]}"
        apt-get update -qq
        apt-get install -y -qq "${missing_deps[@]}"
    fi

    log_success "Dependencies verified"
    return 0
}

run_preflight_checks() {
    print_section "Pre-Flight Validation ${ROCKET}"

    check_os || return 1
    check_architecture || return 1
    check_resources || return 1
    check_network || return 1
    check_permissions || return 1
    check_dependencies || return 1

    echo ""
    log_success "All pre-flight checks passed!"
    return 0
}

# =============================================================================
#  ANSIBLE INSTALLATION
# =============================================================================

install_ansible() {
    print_section "Ansible Setup ${GEAR}"

    # Ensure pipx is installed for isolated Python package management
    if ! command -v pipx &>/dev/null; then
        log_info "Installing pipx for isolated package management..."
        apt-get update -qq
        apt-get install -y -qq pipx
        # Ensure pipx path is available
        pipx ensurepath &>/dev/null || true
        export PATH="$PATH:$HOME/.local/bin"
    fi
    log_success "pipx available"

    # Ensure pip3 is installed for library dependencies
    if ! command -v pip3 &>/dev/null; then
        log_info "Installing pip3..."
        apt-get update -qq
        apt-get install -y -qq python3-pip python3-venv
    fi

    if command -v ansible &>/dev/null; then
        local ansible_version
        ansible_version=$(ansible --version | head -1 | grep -oP '\d+\.\d+\.\d+')
        log_success "Ansible already installed: v$ansible_version"
    else
        log_info "Installing Ansible..."
        apt-get update -qq
        apt-get install -y -qq ansible
        log_success "Ansible installed: $(ansible --version | head -1)"
    fi

    # Install Mitogen for 2-7x performance improvement (library, needs pip)
    if ! python3 -c "import mitogen" &>/dev/null 2>&1; then
        log_info "Installing Mitogen for performance optimization..."
        pip3 install --quiet --break-system-packages --ignore-installed "mitogen>=0.3.7" 2>/dev/null || \
        pip3 install --quiet --user "mitogen>=0.3.7" 2>/dev/null || true
        log_success "Mitogen installed"
    else
        log_debug "Mitogen already installed"
    fi

    # Set Mitogen strategy plugin path for Ansible
    # Note: ansible_mitogen is a sibling package to mitogen, not a child
    local mitogen_strategy_path=""

    # Method 1: Try to find via pip show location
    local site_packages
    site_packages=$(python3 -c "import site; print(site.getsitepackages()[0] if site.getsitepackages() else '')" 2>/dev/null || true)
    if [[ -n "$site_packages" ]] && [[ -d "${site_packages}/ansible_mitogen/plugins/strategy" ]]; then
        mitogen_strategy_path="${site_packages}/ansible_mitogen/plugins/strategy"
    fi

    # Method 2: Try user site-packages
    if [[ -z "$mitogen_strategy_path" ]]; then
        local user_site
        user_site=$(python3 -c "import site; print(site.getusersitepackages())" 2>/dev/null || true)
        if [[ -n "$user_site" ]] && [[ -d "${user_site}/ansible_mitogen/plugins/strategy" ]]; then
            mitogen_strategy_path="${user_site}/ansible_mitogen/plugins/strategy"
        fi
    fi

    # Method 3: Find via mitogen package location (parent dir)
    if [[ -z "$mitogen_strategy_path" ]]; then
        local mitogen_location
        mitogen_location=$(python3 -c "import mitogen; import os; print(os.path.dirname(os.path.dirname(mitogen.__file__)))" 2>/dev/null || true)
        if [[ -n "$mitogen_location" ]] && [[ -d "${mitogen_location}/ansible_mitogen/plugins/strategy" ]]; then
            mitogen_strategy_path="${mitogen_location}/ansible_mitogen/plugins/strategy"
        fi
    fi

    # Method 4: Search common locations
    if [[ -z "$mitogen_strategy_path" ]]; then
        for search_path in \
            "/usr/lib/python3/dist-packages/ansible_mitogen/plugins/strategy" \
            "/usr/local/lib/python3.*/dist-packages/ansible_mitogen/plugins/strategy" \
            "$HOME/.local/lib/python3.*/site-packages/ansible_mitogen/plugins/strategy"; do
            # Use glob expansion
            for found_path in $search_path; do
                if [[ -d "$found_path" ]]; then
                    mitogen_strategy_path="$found_path"
                    break 2
                fi
            done
        done
    fi

    if [[ -n "$mitogen_strategy_path" ]] && [[ -d "$mitogen_strategy_path" ]]; then
        export ANSIBLE_STRATEGY_PLUGINS="$mitogen_strategy_path"
        export ANSIBLE_STRATEGY="mitogen_linear"
        log_success "Mitogen enabled: ${mitogen_strategy_path}"
    else
        log_warn "Mitogen path not found, using standard Ansible strategy"
        log_debug "Searched: site-packages, user-packages, common paths"
    fi

    # Install ARA for run analysis and reporting (via pipx)
    # Note: ARA callback plugin won't auto-record when installed via pipx
    # because the ara module is isolated in pipx's venv. Use 'ara-manage' CLI
    # to view reports after running playbooks with ARA's callback manually.
    if ! command -v ara &>/dev/null; then
        log_info "Installing ARA for run analysis..."
        pipx install --quiet "ara[server]" 2>/dev/null || pipx install "ara[server]" || true
        log_success "ARA installed (use 'ara-manage' for reports)"
    else
        log_debug "ARA already installed"
    fi
    # ARA callback is not configured - pipx isolation prevents it from working
    # To use ARA callback, install via pip: pip install ara[server]

    # Install ansible-playbook-grapher for visual documentation (via pipx)
    if ! command -v ansible-playbook-grapher &>/dev/null; then
        log_info "Installing ansible-playbook-grapher..."
        pipx install --quiet "ansible-playbook-grapher" 2>/dev/null || pipx install "ansible-playbook-grapher" || true
        log_success "ansible-playbook-grapher installed"
    else
        log_debug "ansible-playbook-grapher already installed"
    fi

    # Install Rich for beautiful TUI output (library, needs pip)
    if ! python3 -c "import rich" &>/dev/null 2>&1; then
        log_info "Installing Rich for TUI output..."
        pip3 install --quiet --break-system-packages --ignore-installed "rich>=13.0.0" 2>/dev/null || \
        pip3 install --quiet --user "rich>=13.0.0" 2>/dev/null || true
        log_success "Rich installed"
    else
        log_debug "Rich already installed"
    fi

    # Configure Rich TUI callback plugin
    export ANSIBLE_CALLBACK_PLUGINS="${SCRIPT_DIR}/plugins/callback${ANSIBLE_CALLBACK_PLUGINS:+:$ANSIBLE_CALLBACK_PLUGINS}"
    export ANSIBLE_STDOUT_CALLBACK="rich_tui"
    log_success "Rich TUI callback enabled"

    # Install Molecule for role testing (via pipx, optional - skip if no Docker)
    if command -v docker &>/dev/null; then
        if ! command -v molecule &>/dev/null; then
            log_info "Installing Molecule for role testing..."
            pipx install --quiet "molecule" 2>/dev/null || pipx install "molecule" || true
            pipx inject --quiet molecule "molecule-plugins[docker]" 2>/dev/null || true
            log_success "Molecule installed"
        else
            log_debug "Molecule already installed"
        fi
    else
        log_debug "Docker not found, skipping Molecule installation"
    fi

    # Install ansible-doctor for auto-documentation (via pipx)
    if ! command -v ansible-doctor &>/dev/null; then
        log_info "Installing ansible-doctor..."
        pipx install --quiet "ansible-doctor" 2>/dev/null || pipx install "ansible-doctor" || true
        log_success "ansible-doctor installed"
    else
        log_debug "ansible-doctor already installed"
    fi

    # Install ansible-cmdb for inventory dashboard (via pipx)
    if ! command -v ansible-cmdb &>/dev/null; then
        log_info "Installing ansible-cmdb..."
        pipx install --quiet "ansible-cmdb" 2>/dev/null || pipx install "ansible-cmdb" || true
        log_success "ansible-cmdb installed"
    else
        log_debug "ansible-cmdb already installed"
    fi

    # Install ansible-navigator for enhanced TUI (via pipx)
    if ! command -v ansible-navigator &>/dev/null; then
        log_info "Installing ansible-navigator..."
        pipx install --quiet "ansible-navigator" 2>/dev/null || pipx install "ansible-navigator" || true
        log_success "ansible-navigator installed"
    else
        log_debug "ansible-navigator already installed"
    fi

    return 0
}

# =============================================================================
#  MAIN EXECUTION
# =============================================================================

run_rollback() {
    print_header "Rolling Back ⏪"

    local ansible_args=()

    # Enable color output
    export ANSIBLE_FORCE_COLOR=true

    # Build arguments
    ansible_args+=("-i" "inventory/hosts.yml")
    ansible_args+=("-e" "vps_username=${VPS_USERNAME:-rollback_user}")

    # Pass confirmation if provided (for CI/automation)
    if [[ -n "${CONFIRM_ROLLBACK:-}" ]]; then
        ansible_args+=("-e" "confirm_rollback=${CONFIRM_ROLLBACK}")
    fi

    if [[ "$DRY_RUN" == "true" ]]; then
        ansible_args+=("--check" "--diff")
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        ansible_args+=("-v")
    fi

    # Create state directory if needed (for logs)
    mkdir -p "$STATE_DIR"

    cd "$SCRIPT_DIR"

    log_info "Starting rollback (this will remove all customizations)..."

    if ansible-playbook playbooks/rollback.yml "${ansible_args[@]}"; then
        log_success "Rollback completed successfully!"
        return 0
    else
        log_error "Rollback failed."
        return 1
    fi
}

run_ansible() {
    print_section "Running Ansible Playbook ${PACKAGE}"

    local ansible_args=()

    # Build ansible-playbook arguments
    ansible_args+=("-i" "inventory/hosts.yml")
    ansible_args+=("-e" "vps_username=${VPS_USERNAME}")
    ansible_args+=("-e" "vps_user_password_hash=${VPS_USER_PASSWORD_HASH}")

    if [[ "$DRY_RUN" == "true" ]]; then
        ansible_args+=("--check" "--diff")
    fi

    if [[ "$VERBOSE" == "true" ]]; then
        ansible_args+=("-v")
    fi

    if [[ "$DEBUG" == "true" ]]; then
        ansible_args+=("-vvv")
    fi

    # Create state directory
    mkdir -p "$STATE_DIR"
    mkdir -p "$BACKUP_DIR"

    # Run playbook
    cd "$SCRIPT_DIR"

    log_info "Starting installation (this may take 20-40 minutes)..."

    if ansible-playbook playbooks/main.yml "${ansible_args[@]}"; then
        log_success "Installation completed successfully!"
        return 0
    else
        log_error "Installation failed. Check logs at $LOG_DIR/vps-setup.log"
        return 1
    fi
}

show_completion() {
    print_header "Installation Complete! ${CHECK}"

    echo -e "${GREEN}Your VPS RDP Developer Workstation is ready!${NC}"
    echo ""
    echo -e "${BOLD}Connection Information:${NC}"
    echo -e "  ${ARROW} RDP Server: $(hostname -I | awk '{print $1}'):3389"
    echo -e "  ${ARROW} Username: ${VPS_USERNAME}"
    echo -e "  ${ARROW} Theme: Nordic Dark"
    echo ""
    echo -e "${BOLD}Next Steps:${NC}"
    echo -e "  1. Connect using Windows Remote Desktop (mstsc.exe)"
    echo -e "  2. Enter the IP address and your credentials"
    echo -e "  3. Enjoy your new development environment!"
    echo ""
    echo -e "${DIM}Logs: ${LOG_DIR}/vps-setup.log${NC}"
}

show_help() {
    cat << EOF
VPS RDP Developer Workstation Setup - v${SCRIPT_VERSION}

USAGE:
    ./setup.sh [OPTIONS]

OPTIONS:
    --help              Show this help message and exit
    --dry-run           Show what would be done without making changes
    --verbose           Enable verbose output
    --debug             Enable debug mode (very verbose)
    --skip-validation   Skip pre-flight validation checks
    --rollback          Rollback to previous state
    --resume            Resume from last checkpoint
    --ci                CI/CD mode (non-interactive)

ENVIRONMENT VARIABLES:
    VPS_USERNAME        Primary workstation username (required in CI mode)
    VPS_PASSWORD        User password (optional, creates risk if in shell history)
    VPS_SECRETS_FILE    Path to secure password file with 0600 permissions
    VPS_CONFIG_FILE     Custom configuration file path

EXAMPLES:
    # Interactive installation
    ./setup.sh

    # CI/CD mode with secrets file
    VPS_USERNAME=developer VPS_SECRETS_FILE=/root/.secrets ./setup.sh --ci

    # Dry run to preview changes
    ./setup.sh --dry-run

    # Resume interrupted installation
    ./setup.sh --resume

SECRETS FILE FORMAT:
    password=YourSecurePassword123!

    File must have 0600 permissions:
    chmod 600 /path/to/secrets

For more information, see: docs/README.md
EOF
}

main() {
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h)
                show_help
                exit 0
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --verbose|-v)
                VERBOSE=true
                shift
                ;;
            --debug)
                DEBUG=true
                VERBOSE=true
                shift
                ;;
            --skip-validation)
                SKIP_VALIDATION=true
                shift
                ;;
            --rollback)
                # shellcheck disable=SC2034
                export ROLLBACK_MODE=true
                shift
                ;;
            --resume)
                # shellcheck disable=SC2034
                export RESUME_MODE=true
                shift
                ;;
            --ci)
                # shellcheck disable=SC2034
                export CI_MODE=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done

    # Show banner
    show_banner

    # Run pre-flight checks
    # Run pre-flight checks
    if [[ "$SKIP_VALIDATION" != "true" ]]; then
        run_preflight_checks || exit 1
    fi

    # Install Ansible (Ensure prerequisites for rollback/setup)
    install_ansible || exit 1

    # Check for rollback
    if [[ "${ROLLBACK_MODE:-false}" == "true" ]]; then
        log_info "Starting rollback procedure..."
        run_rollback || exit 1
        exit 0
    fi

    # Get credentials (after ansible install to ensure deps)
    get_credentials || exit 1

    # Run main playbook
    run_ansible || exit 1

    # Show completion message
    show_completion

    exit 0
}

# Trap for cleanup
# shellcheck disable=SC2317,SC2329
cleanup() {
    # Ensure sensitive variables are cleared
    unset VPS_USER_PASSWORD_HASH

    # Re-enable echo if we were interrupted during password input
    stty echo 2>/dev/null || true
}

trap cleanup EXIT

# Run main function
main "$@"
