#!/bin/bash
#===============================================================================
# Create Checkpoint - System backup before deployment
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/logger.sh" 2>/dev/null || true
source "$SCRIPT_DIR/utils/state-tracker.sh" 2>/dev/null || true

CHECKPOINT_DIR="${CHECKPOINT_DIR:-/root/vps-checkpoints}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
CHECKPOINT_NAME="checkpoint-${TIMESTAMP}"

create_filesystem_checkpoint() {
    log_info "Creating filesystem checkpoint: $CHECKPOINT_NAME"
    
    mkdir -p "$CHECKPOINT_DIR"
    
    # Create backup archive
    local backup_file="$CHECKPOINT_DIR/${CHECKPOINT_NAME}.tar.gz"
    
    log_task "Backing up /etc..."
    log_task "Backing up /home..."
    log_task "Backing up /root/.ssh..."
    log_task "Backing up package state..."
    
    tar -czf "$backup_file" \
        --exclude='/etc/mtab' \
        --exclude='/etc/fstab' \
        /etc \
        /home \
        /root/.ssh 2>/dev/null \
        /var/lib/dpkg/status \
        2>/dev/null || true
    
    # Save package list
    dpkg --get-selections > "$CHECKPOINT_DIR/${CHECKPOINT_NAME}-packages.txt"
    
    # Save service states
    systemctl list-unit-files --state=enabled > "$CHECKPOINT_DIR/${CHECKPOINT_NAME}-services.txt" 2>/dev/null || true
    
    # Create checkpoint metadata
    cat > "$CHECKPOINT_DIR/${CHECKPOINT_NAME}-metadata.json" << EOF
{
    "checkpoint_name": "$CHECKPOINT_NAME",
    "created_at": "$(date -Iseconds)",
    "hostname": "$(hostname)",
    "os_version": "$(lsb_release -d 2>/dev/null | cut -f2 || cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)",
    "kernel": "$(uname -r)",
    "backup_file": "$backup_file",
    "packages_file": "$CHECKPOINT_DIR/${CHECKPOINT_NAME}-packages.txt"
}
EOF
    
    log_success "Checkpoint created: $CHECKPOINT_DIR/$CHECKPOINT_NAME"
    echo "$CHECKPOINT_NAME"
}

create_digitalocean_snapshot() {
    local droplet_id="$1"
    local snapshot_name="pre-deployment-$TIMESTAMP"
    
    log_info "Creating DigitalOcean snapshot: $snapshot_name"
    
    if command -v doctl &>/dev/null; then
        doctl compute droplet-action snapshot "$droplet_id" \
            --snapshot-name "$snapshot_name" \
            --wait
        log_success "DigitalOcean snapshot created: $snapshot_name"
        return 0
    else
        log_warn "doctl not installed, falling back to filesystem checkpoint"
        return 1
    fi
}

# Main
main() {
    log_phase_start "0" "Creating System Checkpoint"
    
    local checkpoint_type="${1:-filesystem}"
    local droplet_id="${2:-}"
    
    case "$checkpoint_type" in
        digitalocean|do)
            if [ -n "$droplet_id" ]; then
                create_digitalocean_snapshot "$droplet_id" || create_filesystem_checkpoint
            else
                log_error "Droplet ID required for DigitalOcean snapshot"
                create_filesystem_checkpoint
            fi
            ;;
        filesystem|*)
            create_filesystem_checkpoint
            ;;
    esac
    
    # Update state
    if [ -f "$SCRIPT_DIR/utils/state-tracker.sh" ]; then
        set_state "checkpoint_created" "true"
        set_state "rollback_available" "true"
        set_state "checkpoint_name" "\"$CHECKPOINT_NAME\""
    fi
    
    log_phase_end "0" "success"
}

# Run if executed directly
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
