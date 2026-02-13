#!/bin/bash
# =============================================================================
#  VPS RDP Developer Workstation - Setup Wrapper
#  Version: 3.0.0
#  Context: Debian 13 (Trixie)
# =============================================================================
set -euo pipefail

# --- Constants & Configuration ---
readonly SCRIPT_VERSION="3.0.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly LOG_DIR="/var/log"
readonly STATE_DIR="/var/lib/vps-setup"

# Colors & Symbols
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly DIM='\033[2m'
readonly NC='\033[0m'

readonly CHECK="✓"
readonly CROSS="✗"
readonly WARN="⚠"
readonly INFO="ℹ"

# Banner Art
readonly BANNER_ART="${CYAN}
╦  ╦╔═╗╔═╗  ╦═╗╔╦╗╔═╗  ╦ ╦╔═╗╦═╗╦╔═╔═╗╔╦╗╔═╗╔╦╗╦╔═╗╔╗╔
╚╗╔╝╠═╝╚═╗  ╠╦╝ ║║╠═╝  ║║║║ ║╠╦╝╠╩╗╚═╗ ║ ╠═╣ ║ ║║ ║║║║
 ╚╝ ╩  ╚═╝  ╩╚══╩╝╩    ╚╩╝╚═╝╩╚═╩ ╩╚═╝ ╩ ╩ ╩ ╩ ╩╚═╝╝╚╝${NC}
${DIM}Version ${SCRIPT_VERSION} | Security-Hardened | Debian 13${NC}"

# Defaults
LOG_LEVEL="minimal"
DRY_RUN=false
VERBOSE=false
ROLLBACK_MODE=false
CI_MODE=false
K8S_MODE=false
ANSIBLE_ARGS=()

# --- Logging & UI ---

log() {
	local level="$1"
	local msg="$2"
	local color="$3"
	local icon="$4"

	# Console Output
	echo -e "${color}${icon}${NC} ${msg}" >&2

	# File Output (Redacted)
	if [[ -w "$LOG_DIR" ]]; then
		local clean_msg
		clean_msg=$(echo "$msg" | sed -E 's/(password|secret)=[^ ]+/\1=***/g')
		echo "[$(date +'%F %T')] [$level] $clean_msg" >>"${LOG_DIR}/vps-setup.log"
	fi
}

log_info() { log "INFO" "$1" "$BLUE" "$INFO"; }
log_success() { log "SUCCESS" "$1" "$GREEN" "$CHECK"; }
log_warn() { log "WARN" "$1" "$YELLOW" "$WARN"; }
log_error() { log "ERROR" "$1" "$RED" "$CROSS"; }

# --- Spinner ---
run_with_spinner() {
	local msg="$1"
	local cmd="$2"
	local temp_log
	temp_log=$(mktemp)

	# If verbose or CI, just run the command without spinner
	if [[ "${VERBOSE:-false}" == "true" ]] || [[ "${CI_MODE:-false}" == "true" ]]; then
		log_info "$msg"
		if eval "$cmd"; then
			rm -f "$temp_log"
			return 0
		else
			return $?
		fi
	fi

	echo -ne "${CYAN}${INFO} ${msg}${NC} "
	local pid

	(
		while :; do
			for s in / - \\ \|; do
				echo -ne "\b$s"
				sleep 0.1
			done
		done
	) &
	pid=$!

	# Run command and capture output
	if eval "$cmd" </dev/null >"$temp_log" 2>&1; then
		kill "$pid" 2>/dev/null || true
		wait "$pid" 2>/dev/null || true
		echo -e "\b${GREEN}${CHECK}${NC}"
		rm -f "$temp_log"
		return 0
	else
		local ret=$?
		kill "$pid" 2>/dev/null || true
		wait "$pid" 2>/dev/null || true
		echo -e "\b${RED}${CROSS}${NC}"
		log_error "Command failed: $cmd"
		echo -e "${RED}Error output:${NC}"
		cat "$temp_log"
		rm -f "$temp_log"
		return $ret
	fi
}

# TUI Functions
HEADER_HEIGHT=5
FOOTER_HEIGHT=3

draw_banner() {
	echo -e "$BANNER_ART"
}

init_tui() {
	# Skip if non-interactive or CI
	if [[ "${CI_MODE}" == "true" ]] || [[ ! -t 1 ]]; then return; fi

	clear
	local rows
	rows=$(tput lines)

	# Draw Header (Fixed top)
	tput sc
	tput cup 0 0
	echo -e "${CYAN}${BOLD}"
	draw_banner
	echo -e "${NC}"
	tput rc

	# Draw Footer (Fixed bottom)
	local footer_row=$((rows - FOOTER_HEIGHT))
	tput sc
	tput cup "$footer_row" 0
	echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
	tput rc

	# Set Scroll Region (Middle)
	echo -ne "\033[$((HEADER_HEIGHT + 2));$((rows - FOOTER_HEIGHT))r"
	tput cup $((HEADER_HEIGHT + 1)) 0
}

cleanup_tui() {
	# Reset scroll region and cursor
	if [[ -t 1 ]]; then
		echo -ne "\033[r"
		tput cup $(($(tput lines) - 1)) 0
	fi
}

handle_resize() {
	cleanup_tui
	init_tui
}

# --- Core Logic ---

validate_system() {
	log_info "Running pre-flight validation..."

	# OS Check
	if [[ ! -f /etc/debian_version ]]; then
		log_error "This script requires Debian Linux."
		return 1
	fi

	# Root Check
	if [[ $EUID -ne 0 ]]; then
		log_error "Must run as root (or sudo)."
		return 1
	fi

	# Dependencies
	local deps=(python3 curl wget git)
	local missing=()
	for cmd in "${deps[@]}"; do
		if ! command -v "$cmd" &>/dev/null; then missing+=("$cmd"); fi
	done

	if [[ ${#missing[@]} -gt 0 ]]; then
		log_info "Installing dependencies: ${missing[*]}"
		run_with_spinner "Installing system dependencies..." \
			"apt-get update -qq && apt-get install -y -qq ${missing[*]}"
	fi
}

setup_ansible() {
	log_info "Setting up Ansible environment..."

	# Install pipx & ansible if missing
	if ! command -v pipx &>/dev/null; then
		run_with_spinner "Installing pipx..." \
			"apt-get install -y -qq pipx python3-venv"
		pipx ensurepath >/dev/null 2>&1
	fi
	export PATH="$PATH:$HOME/.local/bin"

	# Install core tools via pipx
	# Map package names to their main binary commands
	declare -A tools=(
		["ansible-core"]="ansible"
		["ansible-navigator"]="ansible-navigator"
		["ara"]="ara-manage"
	)

	for package in "${!tools[@]}"; do
		binary="${tools[$package]}"
		if ! command -v "$binary" &>/dev/null; then
			log_info "Installing $package..."
			run_with_spinner "Installing $package via pipx..." \
				"pipx install --quiet $package"
		fi
	done

	# Install Python libs (via apt to avoid break-system-packages)
	if ! python3 -c "import rich" &>/dev/null; then
		log_info "Installing python3-rich..."
		run_with_spinner "Installing python3-rich..." \
			"apt-get install -y -qq python3-rich"
	fi

	# Inject rich into Ansible pipx environments to ensure TUI callback works
	log_info "Injecting dependencies into Ansible environments..."
	for tool in ansible-core ansible-navigator; do
		if pipx list --short | grep -q "^$tool "; then
			# We use --force to ensure it's injected even if pipx thinks it might be there but broken
			# and || true to prevent exit if injection fails (it's not strictly critical for basic execution, just UI)
			run_with_spinner "Injecting 'rich' into $tool..." \
				"pipx inject $tool rich --force" || true
		fi
	done

	log_info "Installing Ansible collections..."
	log_warn "⏱  Downloading Ansible collections (60+ MB) - this may take 10-15 minutes on slow connections"
	log_info "   Progress is logged to: /var/log/vps-setup-ansible.log"
	log_info "   You can monitor with: tail -f /var/log/vps-setup-ansible.log"
	# Install into local ./collections dir to match ansible.cfg configuration
	mkdir -p "${SCRIPT_DIR}/collections"
	export ANSIBLE_COLLECTIONS_PATH="${SCRIPT_DIR}/collections"
	run_with_spinner "Installing collections (community.general, ansible.posix)..." \
		"ansible-galaxy collection install community.general ansible.posix -p ${SCRIPT_DIR}/collections --force"
}

get_credentials() {
	log_info "Configuring credentials..."
	if [[ "${VERBOSE:-false}" == "true" ]]; then
		log_info "DEBUG: HOME=$HOME"
		log_info "DEBUG: PATH=$PATH"
		if command -v ansible-navigator; then
			log_info "DEBUG: ansible-navigator found at $(command -v ansible-navigator)"
		else
			log_error "DEBUG: ansible-navigator NOT found in PATH"
			ls -la "$HOME/.local/bin" || true
		fi
	fi

	# Username
	if [[ -z "${VPS_USERNAME:-}" ]]; then
		read -rp "Enter username: " VPS_USERNAME
	fi

	# Password (Secure)
	if [[ -n "${VPS_SECRETS_FILE:-}" ]] && [[ -f "$VPS_SECRETS_FILE" ]]; then
		# Read from file (expected format: password=...)
		# shellcheck disable=SC2002
		VPS_PASSWORD=$(cat "$VPS_SECRETS_FILE" | grep "^password=" | cut -d= -f2-)
	fi

	if [[ -z "${VPS_PASSWORD:-}" ]]; then
		# In CI mode, fail if password is missing
		if [[ "${CI_MODE:-false}" == "true" ]]; then
			log_error "CI_MODE is enabled but VPS_PASSWORD is not set."
			exit 1
		fi

		# Interactive prompt
		stty -echo
		read -rp "Enter password: " VPS_PASSWORD
		echo
		stty echo
	fi

	# Generate Hash
	if command -v openssl &>/dev/null; then
		VPS_USER_PASSWORD_HASH=$(openssl passwd -6 "$VPS_PASSWORD")
	else
		log_error "openssl not found for password hashing."
		return 1
	fi

	export VPS_USERNAME
	export VPS_USER_PASSWORD_HASH
	unset VPS_PASSWORD
}

run_playbook() {
	local playbook="$1"
	local mode="${2:-stdout}"

	log_info "Launching Ansible ($playbook)..."

	# Export Configs
	export VPS_LOG_LEVEL="$LOG_LEVEL"
	export ANSIBLE_DEPRECATION_WARNINGS=False
	# Ensure absolute path for callback plugins and python path
	export ANSIBLE_CALLBACK_PLUGINS="${SCRIPT_DIR}/plugins/callback"
	export ANSIBLE_COLLECTIONS_PATH="${SCRIPT_DIR}/collections"
	export PYTHONPATH="${SCRIPT_DIR}:${PYTHONPATH:-}"

	# UI Mode Selection
	if [[ "$VERBOSE" == "true" ]]; then
		export ANSIBLE_STDOUT_CALLBACK="default"
		mode="stdout"
	else
		# Prevent TUI conflict: ansible-navigator has its own UI.
		# Do NOT use rich_tui when running inside navigator.
		export ANSIBLE_STDOUT_CALLBACK="rich_tui"
		export ANSIBLE_NAVIGATOR_MODE="1" # Explicitly signal navigator mode to callback
		export VPS_FORCE_TUI="true"       # Force TUI output even in navigator mode (fixes silent execution)
	fi

	# Build Args
	local args=(
		"--inventory" "inventory/hosts.yml"
		"--mode" "$mode"
		"--ee" "false"
		"-e" "vps_username=$VPS_USERNAME"
		"-e" "vps_user_password_hash=$VPS_USER_PASSWORD_HASH"
	)

	if [[ "$K8S_MODE" == "true" ]]; then
		args+=("-e" "install_cloud_native_tools=true")
	fi

	if [[ "$DRY_RUN" == "true" ]]; then
		args+=("--check")
	fi

	args+=("${ANSIBLE_ARGS[@]}")

	# Clean TUI before handover
	cleanup_tui

	# Execute
	if ansible-navigator run "$playbook" "${args[@]}"; then
		log_success "Playbook finished successfully."
	else
		log_error "Playbook failed."
		exit 1
	fi
}

main() {
	# Argument Parsing
	while [[ $# -gt 0 ]]; do
		case "$1" in
		--)
			shift
			ANSIBLE_ARGS=("$@")
			break
			;;
		--help)
			echo "Usage: $0 [--dry-run] [--verbose] [--ci] [--k8s] [-- <ansible-args>]"
			exit 0
			;;
		--dry-run)
			DRY_RUN=true
			shift
			;;
		--verbose)
			VERBOSE=true
			shift
			;;
		--ci)
			CI_MODE=true
			shift
			;;
		--k8s)
			K8S_MODE=true
			shift
			;;
		--log-level)
			LOG_LEVEL="$2"
			shift 2
			;;
		--rollback)
			ROLLBACK_MODE=true
			shift
			;;
		*)
			log_error "Unknown arg: $1"
			exit 1
			;;
		esac
	done

	# Initialization
	trap 'cleanup_tui; unset VPS_USER_PASSWORD_HASH' EXIT
	if [[ "$CI_MODE" != "true" ]]; then trap 'handle_resize' WINCH; fi

	mkdir -p "$LOG_DIR" "$STATE_DIR"

	# Start TUI
	init_tui

	# Workflow
	validate_system
	setup_ansible
	get_credentials

	if [[ "$ROLLBACK_MODE" == "true" ]]; then
		run_playbook "playbooks/rollback.yml"
	else
		# Always use stdout mode for better visibility and to avoid TUI conflicts
		run_playbook "playbooks/main.yml" "stdout"
	fi
}

main "$@"
