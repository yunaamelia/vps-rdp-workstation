#!/bin/bash
#===============================================================================
# Error Handler - Comprehensive error handling for deployment
#===============================================================================

source "$(dirname "$0")/logger.sh" 2>/dev/null || true

# Error codes
declare -A ERROR_CODES=(
    [SUCCESS]=0
    [GENERAL_ERROR]=1
    [PREREQ_FAILED]=10
    [NETWORK_ERROR]=20
    [PACKAGE_ERROR]=30
    [SERVICE_ERROR]=40
    [CONFIG_ERROR]=50
    [VALIDATION_ERROR]=60
    [ROLLBACK_ERROR]=70
    [USER_ABORT]=99
)

# Get error code
get_error_code() {
    local name="$1"
    echo "${ERROR_CODES[$name]:-1}"
}

# Error handler function
handle_error() {
    local exit_code=$?
    local line_number=$1
    local command="$2"
    local error_type="${3:-GENERAL_ERROR}"
    
    log_error "Error occurred in script at line $line_number"
    log_error "Failed command: $command"
    log_error "Exit code: $exit_code"
    
    # Log to error file
    echo "$(date -Iseconds) | Line: $line_number | Command: $command | Exit: $exit_code" \
        >> "${LOG_DIR:-/var/log/vps-setup}/errors.log"
    
    return $(get_error_code "$error_type")
}

# Setup error trap
setup_error_trap() {
    set -E
    trap 'handle_error ${LINENO} "$BASH_COMMAND"' ERR
}

# Cleanup on exit
cleanup_on_exit() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        log_warn "Script exiting with code: $exit_code"
        # Optionally trigger rollback
        if [ "${AUTO_ROLLBACK:-false}" = "true" ]; then
            log_warn "Auto-rollback is enabled, initiating rollback..."
            # Source rollback script if available
            if [ -f "$(dirname "$0")/../rollback-to-checkpoint.sh" ]; then
                bash "$(dirname "$0")/../rollback-to-checkpoint.sh"
            fi
        fi
    fi
}

# Retry function with exponential backoff
retry_command() {
    local max_attempts=${1:-3}
    local delay=${2:-5}
    local command="${@:3}"
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        log_debug "Attempt $attempt/$max_attempts: $command"
        if eval "$command"; then
            return 0
        fi
        
        if [ $attempt -lt $max_attempts ]; then
            log_warn "Command failed, retrying in ${delay}s..."
            sleep $delay
            delay=$((delay * 2))  # Exponential backoff
        fi
        ((attempt++))
    done
    
    log_error "Command failed after $max_attempts attempts: $command"
    return 1
}

# Assert function for validation
assert() {
    local condition="$1"
    local message="${2:-Assertion failed}"
    
    if ! eval "$condition"; then
        log_error "ASSERTION FAILED: $message"
        log_error "Condition: $condition"
        return $(get_error_code "VALIDATION_ERROR")
    fi
    return 0
}

# Check command exists
require_command() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null; then
        log_error "Required command not found: $cmd"
        return $(get_error_code "PREREQ_FAILED")
    fi
    log_debug "Found required command: $cmd"
    return 0
}

# Export functions
export -f handle_error setup_error_trap cleanup_on_exit retry_command assert require_command get_error_code
