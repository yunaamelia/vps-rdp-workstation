#!/bin/bash
#===============================================================================
# State Tracker - Deployment state management
#===============================================================================

source "$(dirname "$0")/logger.sh" 2>/dev/null || true

STATE_FILE="${VPS_SETUP_LOG_DIR:-/var/log/vps-setup}/deployment-state.json"

# Initialize state
init_state() {
    local deployment_id="${1:-$(date +%s)}"

    mkdir -p "$(dirname "$STATE_FILE")"

    cat > "$STATE_FILE" << EOF
{
    "deployment_id": "$deployment_id",
    "start_time": "$(date -Iseconds)",
    "current_phase": "0",
    "completed_phases": [],
    "failed_phases": [],
    "checkpoint_created": false,
    "rollback_available": false,
    "last_updated": "$(date -Iseconds)"
}
EOF
    log_debug "State initialized with ID: $deployment_id"
}

# Get state value
get_state() {
    local key="$1"
    if [ -f "$STATE_FILE" ]; then
        jq -r ".$key // empty" "$STATE_FILE" 2>/dev/null
    fi
}

# Set state value
set_state() {
    local key="$1"
    local value="$2"

    if [ -f "$STATE_FILE" ]; then
        local tmp=$(mktemp)
        jq ".$key = $value | .last_updated = \"$(date -Iseconds)\"" "$STATE_FILE" > "$tmp"
        mv "$tmp" "$STATE_FILE"
        log_debug "State updated: $key = $value"
    fi
}

# Update current phase
set_current_phase() {
    local phase="$1"
    set_state "current_phase" "\"$phase\""
}

# Mark phase as completed
complete_phase() {
    local phase="$1"

    if [ -f "$STATE_FILE" ]; then
        local tmp=$(mktemp)
        jq ".completed_phases += [\"$phase\"] | .current_phase = \"$phase\" | .last_updated = \"$(date -Iseconds)\"" "$STATE_FILE" > "$tmp"
        mv "$tmp" "$STATE_FILE"
        log_success "Phase $phase marked as completed"
    fi
}

# Mark phase as failed
fail_phase() {
    local phase="$1"
    local reason="${2:-Unknown error}"

    if [ -f "$STATE_FILE" ]; then
        local tmp=$(mktemp)
        jq ".failed_phases += [{\"phase\": \"$phase\", \"reason\": \"$reason\", \"time\": \"$(date -Iseconds)\"}] | .last_updated = \"$(date -Iseconds)\"" "$STATE_FILE" > "$tmp"
        mv "$tmp" "$STATE_FILE"
        log_error "Phase $phase marked as failed: $reason"
    fi
}

# Check if phase was completed
is_phase_completed() {
    local phase="$1"
    if [ -f "$STATE_FILE" ]; then
        jq -e ".completed_phases | index(\"$phase\") != null" "$STATE_FILE" &>/dev/null
        return $?
    fi
    return 1
}

# Get deployment summary
get_summary() {
    if [ -f "$STATE_FILE" ]; then
        echo "=== Deployment State Summary ==="
        echo "Deployment ID: $(get_state 'deployment_id')"
        echo "Started: $(get_state 'start_time')"
        echo "Current Phase: $(get_state 'current_phase')"
        echo "Completed Phases: $(jq -r '.completed_phases | join(", ")' "$STATE_FILE")"
        echo "Failed Phases: $(jq -r '.failed_phases | length' "$STATE_FILE")"
        echo "Last Updated: $(get_state 'last_updated')"
        echo "Checkpoint: $(get_state 'checkpoint_created')"
        echo "Rollback Available: $(get_state 'rollback_available')"
    else
        echo "No deployment state found"
    fi
}

# Export functions
export -f init_state get_state set_state set_current_phase complete_phase fail_phase is_phase_completed get_summary
