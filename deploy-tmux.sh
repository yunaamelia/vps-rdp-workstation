#!/bin/bash
# =============================================================================
# VPS RDP Workstation - Tmux Deployment Wrapper
# Solusi untuk menghindari hang pada deployment non-interactive
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly LOG_FILE="${SCRIPT_DIR}/logs/vps-tmux-deploy.log"
readonly TMUX_SESSION="vps-setup"
readonly STATE_FILE="${SCRIPT_DIR}/var/tmux-deploy.state"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# =============================================================================
# Helper Functions
# =============================================================================

log() {
	local msg="$1"
	echo -e "${BLUE}[$(date +'%F %T')]${NC} $msg"
	echo "[$(date +'%F %T')] $msg" >>"$LOG_FILE"
}

error() {
	local msg="$1"
	echo -e "${RED}✗ $msg${NC}" >&2
	echo "[$(date +'%F %T')] ERROR: $msg" >>"$LOG_FILE"
}

success() {
	local msg="$1"
	echo -e "${GREEN}✓ $msg${NC}"
	echo "[$(date +'%F %T')] SUCCESS: $msg" >>"$LOG_FILE"
}

warn() {
	local msg="$1"
	echo -e "${YELLOW}⚠ $msg${NC}"
	echo "[$(date +'%F %T')] WARN: $msg" >>"$LOG_FILE"
}

# =============================================================================
# Validation
# =============================================================================

validate_environment() {
	log "Validating environment..."

	# Check if running as root
	if [[ $EUID -ne 0 ]]; then
		error "Script harus dijalankan sebagai root (atau dengan sudo)"
		exit 1
	fi

	# Check if tmux is installed
	if ! command -v tmux &>/dev/null; then
		log "Installing tmux..."
		apt-get update -qq && apt-get install -y -qq tmux
	fi

	# Check if setup.sh exists
	if [[ ! -f "${SCRIPT_DIR}/setup.sh" ]]; then
		error "setup.sh tidak ditemukan di ${SCRIPT_DIR}"
		exit 1
	fi

	# Create log directory
	mkdir -p "$(dirname "$LOG_FILE")"
	mkdir -p "$(dirname "$STATE_FILE")"

	success "Environment valid"
}

# =============================================================================
# Credential Setup
# =============================================================================

setup_credentials() {
	log "Setting up credentials..."

	# Check if credentials are provided via environment
	if [[ -z "${VPS_USERNAME:-}" ]]; then
		warn "VPS_USERNAME tidak di-set"
		read -rp "Masukkan username: " VPS_USERNAME
		export VPS_USERNAME
	fi

	if [[ -z "${VPS_SECRETS_FILE:-}" ]]; then
		warn "VPS_SECRETS_FILE tidak di-set"
		read -rsp "Masukkan password: " VPS_PASSWORD
		echo

		# Create temporary secrets file
		VPS_SECRETS_FILE="/tmp/vps-secrets-$$"
		echo "password=${VPS_PASSWORD}" >"$VPS_SECRETS_FILE"
		chmod 600 "$VPS_SECRETS_FILE"
		export VPS_SECRETS_FILE

		# Mark for cleanup
		TEMP_SECRETS=true
	fi

	export VPS_USERNAME
	export VPS_SECRETS_FILE

	success "Credentials configured (user: $VPS_USERNAME)"
}

# =============================================================================
# Tmux Session Management
# =============================================================================

create_tmux_session() {
	log "Creating tmux session: $TMUX_SESSION"

	# Kill existing session if exists
	if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
		warn "Session $TMUX_SESSION sudah ada, menghentikan..."
		tmux kill-session -t "$TMUX_SESSION"
		sleep 1
	fi

	local deploy_cmd="cd '${SCRIPT_DIR}' && \
        export VPS_USERNAME='${VPS_USERNAME}' && \
        export VPS_SECRETS_FILE='${VPS_SECRETS_FILE}' && \
        export TERM='screen-256color' && \
        sudo -E ./setup.sh 2>&1 | tee -a '${LOG_FILE}' && \
        echo 'DEPLOYMENT_COMPLETE' > '${STATE_FILE}'"

	# Create detached session
	tmux new-session -d -s "$TMUX_SESSION" -n "deploy" bash -c "$deploy_cmd"

	success "Tmux session created: $TMUX_SESSION"
	log "Untuk memantau progress: tmux attach -t $TMUX_SESSION"
}

monitor_deployment() {
	log "Monitoring deployment..."
	log "Session: $TMUX_SESSION"
	log "Log file: $LOG_FILE"

	local wait_time=0
	local max_wait=3600 # 1 hour timeout
	local check_interval=5

	echo ""
	echo "=========================================="
	echo "Deployment sedang berjalan di tmux"
	echo "=========================================="
	echo ""
	echo "Commands yang tersedia:"
	echo "  1. Pantau real-time: tmux attach -t $TMUX_SESSION"
	echo "  2. Lihat log: tail -f $LOG_FILE"
	echo "  3. Detach dari tmux: Ctrl+B lalu D"
	echo ""
	echo "Menunggu deployment selesai..."
	echo ""

	# Show initial progress
	tail -n 20 "$LOG_FILE" 2>/dev/null || true

	# Monitor until completion or timeout
	while [[ $wait_time -lt $max_wait ]]; do
		# Check if deployment completed
		if [[ -f "$STATE_FILE" ]]; then
			local state
			state=$(cat "$STATE_FILE" 2>/dev/null || echo "")
			if [[ "$state" == "DEPLOYMENT_COMPLETE" ]]; then
				success "Deployment selesai!"
				return 0
			fi
		fi

		# Check if session still exists
		if ! tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
			# Session ended, check if it was successful
			if [[ -f "$STATE_FILE" ]] && [[ "$(cat "$STATE_FILE")" == "DEPLOYMENT_COMPLETE" ]]; then
				success "Deployment selesai!"
				return 0
			else
				error "Session berakhir tanpa indikasi sukses"
				return 1
			fi
		fi

		# Show progress every 30 seconds
		if [[ $((wait_time % 30)) -eq 0 ]] && [[ $wait_time -gt 0 ]]; then
			local last_lines
			last_lines=$(tail -n 5 "$LOG_FILE" 2>/dev/null || echo "(log file not available)")
			echo ""
			echo "--- Progress (after ${wait_time}s) ---"
			echo "$last_lines"
			echo "--------------------------------------"
		fi

		sleep $check_interval
		wait_time=$((wait_time + check_interval))
	done

	error "Deployment timeout setelah ${max_wait} detik"
	return 1
}

# =============================================================================
# Cleanup
# =============================================================================

cleanup() {
	log "Cleaning up..."

	# Remove temporary secrets file
	if [[ "${TEMP_SECRETS:-false}" == "true" ]] && [[ -f "${VPS_SECRETS_FILE:-}" ]]; then
		shred -u "$VPS_SECRETS_FILE" 2>/dev/null || rm -f "$VPS_SECRETS_FILE"
		log "Temporary secrets file removed"
	fi

	# Remove state file
	rm -f "$STATE_FILE"
}

# =============================================================================
# Status Check
# =============================================================================

show_status() {
	echo "=========================================="
	echo "VPS Deployment Status"
	echo "=========================================="
	echo ""

	# Check if tmux session exists
	if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
		echo -e "${GREEN}● Session aktif${NC}: $TMUX_SESSION"
		echo ""
		echo "Untuk melihat progress:"
		echo "  tmux attach -t $TMUX_SESSION"
		echo ""
	else
		echo -e "${YELLOW}○ Session tidak aktif${NC}"
		echo ""
	fi

	# Show recent log entries
	if [[ -f "$LOG_FILE" ]]; then
		echo "Recent log entries:"
		echo "---"
		tail -n 20 "$LOG_FILE"
		echo "---"
		echo ""
		echo "Full log: $LOG_FILE"
	fi

	# Check progress file
	if [[ -f "/var/lib/vps-setup/progress.json" ]]; then
		echo ""
		echo "Progress JSON:"
		head -20 "/var/lib/vps-setup/progress.json" 2>/dev/null || true
	fi
}

# =============================================================================
# Usage
# =============================================================================

show_usage() {
	cat <<EOF
Usage: $0 [OPTIONS] [COMMAND]

Commands:
  start       Mulai deployment dalam tmux session (default)
  status      Cek status deployment
  attach      Attach ke tmux session yang sedang berjalan
  kill        Hentikan tmux session
  logs        Tampilkan log deployment

Options:
  -u, --user USERNAME     Set username (skip prompt)
  -p, --password PASS     Set password (skip prompt)
  -s, --secrets FILE      Set secrets file path
  -h, --help              Show this help

Environment Variables:
  VPS_USERNAME            Username untuk VPS
  VPS_SECRETS_FILE        Path ke file secrets
  VPS_PASSWORD            Password (alternative to secrets file)

Examples:
  # Interactive mode
  sudo $0

  # With environment variables
  sudo VPS_USERNAME=dev VPS_PASSWORD=secret123 $0

  # With secrets file
  sudo VPS_USERNAME=dev VPS_SECRETS_FILE=/root/.secrets $0

  # Check status
  $0 status

  # Attach to running session
  $0 attach

  # View logs
  $0 logs

EOF
}

# =============================================================================
# Main
# =============================================================================

main() {
	local command="start"
	local custom_user=""
	local custom_password=""
	local custom_secrets=""

	# Parse arguments
	while [[ $# -gt 0 ]]; do
		case "$1" in
		-h | --help)
			show_usage
			exit 0
			;;
		-u | --user)
			custom_user="$2"
			shift 2
			;;
		-p | --password)
			custom_password="$2"
			shift 2
			;;
		-s | --secrets)
			custom_secrets="$2"
			shift 2
			;;
		start | status | attach | kill | logs)
			command="$1"
			shift
			;;
		*)
			error "Unknown option: $1"
			show_usage
			exit 1
			;;
		esac
	done

	# Apply custom credentials
	[[ -n "$custom_user" ]] && export VPS_USERNAME="$custom_user"
	[[ -n "$custom_password" ]] && export VPS_PASSWORD="$custom_password"
	[[ -n "$custom_secrets" ]] && export VPS_SECRETS_FILE="$custom_secrets"

	# Execute command
	case "$command" in
	start)
		trap cleanup EXIT
		validate_environment
		setup_credentials
		create_tmux_session
		monitor_deployment
		;;
	status)
		show_status
		;;
	attach)
		if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
			tmux attach -t "$TMUX_SESSION"
		else
			error "Session $TMUX_SESSION tidak ditemukan"
			exit 1
		fi
		;;
	kill)
		if tmux has-session -t "$TMUX_SESSION" 2>/dev/null; then
			tmux kill-session -t "$TMUX_SESSION"
			success "Session $TMUX_SESSION dihentikan"
		else
			warn "Session $TMUX_SESSION tidak ditemukan"
		fi
		;;
	logs)
		if [[ -f "$LOG_FILE" ]]; then
			tail -f "$LOG_FILE"
		else
			error "Log file tidak ditemukan: $LOG_FILE"
			exit 1
		fi
		;;
	*)
		error "Unknown command: $command"
		show_usage
		exit 1
		;;
	esac
}

main "$@"
