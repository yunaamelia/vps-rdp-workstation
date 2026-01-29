#!/bin/bash
#===============================================================================
# Logger Utility - Centralized logging for VPS RDP Workstation deployment
#===============================================================================

# Log directory
LOG_DIR="${VPS_SETUP_LOG_DIR:-/var/log/vps-setup}"
LOG_FILE="${LOG_DIR}/deployment.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    touch "$LOG_FILE"
    chmod 644 "$LOG_FILE"
    log_info "Logging initialized at $(date -Iseconds)"
}

# Log functions
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

log_info() {
    local message="$1"
    echo -e "${BLUE}[INFO]${NC} $message"
    log "INFO" "$message"
}

log_success() {
    local message="$1"
    echo -e "${GREEN}[✅ SUCCESS]${NC} $message"
    log "SUCCESS" "$message"
}

log_warn() {
    local message="$1"
    echo -e "${YELLOW}[⚠️  WARN]${NC} $message"
    log "WARN" "$message"
}

log_error() {
    local message="$1"
    echo -e "${RED}[❌ ERROR]${NC} $message" >&2
    log "ERROR" "$message"
}

log_debug() {
    local message="$1"
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "${CYAN}[DEBUG]${NC} $message"
    fi
    log "DEBUG" "$message"
}

log_phase_start() {
    local phase="$1"
    local description="$2"
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC} Phase $phase: $description"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    log "PHASE" "Starting Phase $phase: $description"
}

log_phase_end() {
    local phase="$1"
    local status="$2"
    if [ "$status" = "success" ]; then
        log_success "Phase $phase completed successfully"
    else
        log_error "Phase $phase failed"
    fi
}

log_task() {
    local task="$1"
    echo -e "  ${CYAN}→${NC} $task"
    log "TASK" "$task"
}

# Export functions
export -f log log_info log_success log_warn log_error log_debug
export -f log_phase_start log_phase_end log_task init_logging
