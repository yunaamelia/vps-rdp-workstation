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

# Defaults
LOG_LEVEL="minimal"
DRY_RUN=false
VERBOSE=false
ROLLBACK_MODE=false
CI_MODE=false
K8S_MODE=false
ANSIBLE_ARGS=()

# --- Logging & UI ---

run_rich() {
	# Ensure python3 is available before calling
	if command -v python3 &>/dev/null; then
		python3 "${SCRIPT_DIR}/scripts/rich_cli.py" "$@"
	else
		# Fallback if python3 is missing (should only happen during bootstrap)
		local cmd="$1"
		shift
		case "$cmd" in
		log) echo "[$1] $2" ;;
		spinner)
			echo "Running: $1..."
			eval "$2"
			;;
		banner) echo "VPS RDP WORKSTATION v${SCRIPT_VERSION}" ;;
		esac
	fi
}

log_info() { run_rich log info "$1"; }
log_success() { run_rich log success "$1"; }
log_warn() { run_rich log warn "$1"; }
log_error() { run_rich log error "$1"; }

run_with_spinner() {
	local msg="$1"
	local cmd="$2"
	# If verbose or CI, skip spinner
	if [[ "${VERBOSE:-false}" == "true" ]] || [[ "${CI_MODE:-false}" == "true" ]]; then
		log_info "$msg"
		eval "$cmd"
	else
		run_rich spinner "$msg" "$cmd"
	fi
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
		# Use simple apt-get here as python3 might be missing
		apt-get update -qq && apt-get install -y -qq "${missing[@]}"
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

	# Upgrade pipx if version < 1.7.0 (Required for Ansible community.general.pipx module)
	# Ubuntu 24.04 ships with 1.4.3 which causes "The pipx tool must be at least at version 1.7.0"
	local pipx_version
	pipx_version=$(pipx --version 2>/dev/null || echo "0.0.0")

	if dpkg --compare-versions "$pipx_version" "lt" "1.7.0"; then
		log_warn "Pipx version $pipx_version is too old (<1.7.0). Upgrading via dedicated venv..."

		run_with_spinner "Ensuring python3-venv is installed..." \
			"apt-get install -y -qq python3-venv python3-pip"

		run_with_spinner "Removing outdated system pipx..." \
			"apt-get remove -y pipx || true"

		run_with_spinner "Installing latest pipx into /opt/pipx-venv..." \
			"rm -rf /opt/pipx-venv && python3 -m venv /opt/pipx-venv && /opt/pipx-venv/bin/pip install pipx && ln -sf /opt/pipx-venv/bin/pipx /usr/local/bin/pipx"

		log_success "Pipx upgraded to $(pipx --version)"
	fi

	export PATH="$PATH:$HOME/.local/bin"

	# Install core tools via pipx
	declare -A tools=(
		["ansible-core"]="ansible"
		["ansible-navigator"]="ansible-navigator"
		["ara"]="ara-manage"
		["pre-commit"]="pre-commit"
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
			run_with_spinner "Injecting 'rich' into $tool..." \
				"pipx inject $tool rich --force" || true
		fi
	done

	log_info "Installing Ansible collections..."
	# Install into local ./collections dir to match ansible.cfg configuration
	mkdir -p "${SCRIPT_DIR}/collections"
	export ANSIBLE_COLLECTIONS_PATH="${SCRIPT_DIR}/collections"
	run_with_spinner "Installing collections (community.general, ansible.posix)..." \
		"ansible-galaxy collection install community.general ansible.posix -p ${SCRIPT_DIR}/collections --force"
}

get_credentials() {
	log_info "Configuring credentials..."

	# Username
	if [[ -z "${VPS_USERNAME:-}" ]]; then
		read -rp "Enter username: " VPS_USERNAME
	fi

	# Password (Secure)
	if [[ -n "${VPS_SECRETS_FILE:-}" ]] && [[ -f "$VPS_SECRETS_FILE" ]]; then
		VPS_PASSWORD=$(grep "^password=" "$VPS_SECRETS_FILE" | cut -d= -f2-)
	fi

	if [[ -z "${VPS_PASSWORD:-}" ]]; then
		if [[ "${CI_MODE:-false}" == "true" ]]; then
			log_error "CI_MODE is enabled but VPS_PASSWORD is not set."
			exit 1
		fi

		read -rsp "Enter password: " VPS_PASSWORD
		echo
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

	log_info "Launching Ansible ($playbook)..."

	# Export Configs
	export VPS_LOG_LEVEL="$LOG_LEVEL"
	export ANSIBLE_DEPRECATION_WARNINGS=False
	export ANSIBLE_CALLBACK_PLUGINS="${SCRIPT_DIR}/plugins/callback"
	export ANSIBLE_COLLECTIONS_PATH="${SCRIPT_DIR}/collections"
	export ANSIBLE_LOG_PATH="/var/log/vps-setup-ansible.log"
	export PYTHONPATH="${SCRIPT_DIR}:${PYTHONPATH:-}"

	# UI Mode Selection
	if [[ "$VERBOSE" == "true" ]]; then
		export ANSIBLE_STDOUT_CALLBACK="default"
	else
		# Use our new Rich TUI callback
		export ANSIBLE_STDOUT_CALLBACK="rich_tui"
		export VPS_FORCE_TUI="true"
	fi

	# Build Args for ansible-playbook
	local args=(
		"--inventory" "inventory/hosts.yml"
		"-e" "vps_username=$VPS_USERNAME"
		"-e" "vps_user_password_hash=$VPS_USER_PASSWORD_HASH"
	)

	if [[ "$K8S_MODE" == "true" ]]; then
		args+=("-e" "install_cloud_native_tools=true")
	fi

	if [[ "$DRY_RUN" == "true" ]]; then
		args+=("--check")
	fi

	if [[ "$VERBOSE" == "true" ]]; then
		args+=("-v")
	fi

	args+=("${ANSIBLE_ARGS[@]}")

	# Execute using ansible-playbook directly to avoid TUI/buffer conflicts with navigator
	if ansible-playbook "$playbook" "${args[@]}"; then
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
			echo "Usage: $0 [--dry-run] [--verbose] [--ci] [--k8s] [--full] [-- <ansible-args>]"
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
		--full)
			LOG_LEVEL="full"
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
	trap 'unset VPS_USER_PASSWORD_HASH' EXIT
	mkdir -p "$LOG_DIR" "$STATE_DIR"

	# Banner
	run_rich banner "$SCRIPT_VERSION"

	# Workflow
	validate_system
	setup_ansible
	get_credentials

	if [[ "$ROLLBACK_MODE" == "true" ]]; then
		run_playbook "playbooks/rollback.yml"
	else
		run_playbook "playbooks/main.yml" "stdout"
	fi
}

main "$@"
