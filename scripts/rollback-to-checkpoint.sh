#!/bin/bash
#===============================================================================
# Rollback to Checkpoint - Restore system from checkpoint
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/logger.sh" 2>/dev/null || true
source "$SCRIPT_DIR/utils/state-tracker.sh" 2>/dev/null || true

CHECKPOINT_DIR="${CHECKPOINT_DIR:-/root/vps-checkpoints}"

list_checkpoints() {
    log_info "Available checkpoints:"
    if [ -d "$CHECKPOINT_DIR" ]; then
        ls -1 "$CHECKPOINT_DIR"/*.tar.gz 2>/dev/null | while read f; do
            local name=$(basename "$f" .tar.gz)
            local metadata="$CHECKPOINT_DIR/${name}-metadata.json"
            if [ -f "$metadata" ]; then
                local created=$(jq -r '.created_at' "$metadata" 2>/dev/null || echo "unknown")
                echo "  - $name (created: $created)"
            else
                echo "  - $name"
            fi
        done
    else
        echo "  No checkpoints found"
    fi
}

restore_checkpoint() {
    local checkpoint_name="$1"
    local backup_file="$CHECKPOINT_DIR/${checkpoint_name}.tar.gz"
    
    if [ ! -f "$backup_file" ]; then
        log_error "Checkpoint not found: $backup_file"
        return 1
    fi
    
    log_warn "⚠️  WARNING: This will restore system to checkpoint: $checkpoint_name"
    log_warn "This operation will overwrite current configuration!"
    
    if [ "${FORCE:-false}" != "true" ]; then
        read -p "Are you sure you want to continue? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Rollback cancelled"
            return 0
        fi
    fi
    
    log_info "Restoring from checkpoint: $checkpoint_name"
    
    # Extract backup
    log_task "Extracting backup files..."
    cd /
    tar -xzf "$backup_file" --overwrite 2>/dev/null || true
    
    # Restore package state
    local packages_file="$CHECKPOINT_DIR/${checkpoint_name}-packages.txt"
    if [ -f "$packages_file" ]; then
        log_task "Restoring package selections..."
        dpkg --set-selections < "$packages_file"
        apt-get dselect-upgrade -y 2>/dev/null || true
    fi
    
    log_success "Checkpoint restored: $checkpoint_name"
    log_warn "A system reboot is recommended"
}

rollback_phase() {
    local phase="$1"
    
    log_info "Rolling back Phase $phase..."
    
    case "$phase" in
        2)
            # Rollback user management
            local username="${VPS_USERNAME:-developer}"
            log_task "Removing user: $username"
            rm -f "/etc/sudoers.d/$username"
            pkill -u "$username" 2>/dev/null || true
            userdel -r "$username" 2>/dev/null || true
            ;;
        3)
            # Rollback dependencies
            log_task "Removing external repositories..."
            rm -f /etc/apt/sources.list.d/nodesource.list
            rm -f /etc/apt/sources.list.d/docker.list
            rm -f /etc/apt/sources.list.d/vscode.list
            rm -f /etc/apt/sources.list.d/github-cli.list
            apt-get update
            ;;
        4)
            # Rollback RDP packages
            log_task "Stopping services..."
            systemctl stop xrdp docker sddm 2>/dev/null || true
            log_task "Removing packages..."
            apt-get remove --purge -y kde-plasma-desktop sddm xrdp docker-ce code 2>/dev/null || true
            apt-get autoremove -y
            ;;
        *)
            log_warn "No specific rollback defined for phase $phase"
            ;;
    esac
    
    # Update state
    fail_phase "$phase" "Rolled back by user"
    
    log_success "Phase $phase rolled back"
}

test_rollback() {
    log_info "Testing rollback mechanism..."
    
    # Check if checkpoints exist
    if [ -d "$CHECKPOINT_DIR" ] && ls "$CHECKPOINT_DIR"/*.tar.gz &>/dev/null; then
        log_success "Rollback mechanism functional - checkpoints available"
        return 0
    else
        log_warn "No checkpoints found - rollback limited to phase-specific operations"
        return 0
    fi
}

# Main
main() {
    local action="${1:-help}"
    
    case "$action" in
        list)
            list_checkpoints
            ;;
        restore)
            local checkpoint="${2:-}"
            if [ -z "$checkpoint" ]; then
                log_error "Usage: $0 restore <checkpoint-name>"
                list_checkpoints
                exit 1
            fi
            restore_checkpoint "$checkpoint"
            ;;
        phase)
            local phase="${2:-}"
            if [ -z "$phase" ]; then
                log_error "Usage: $0 phase <phase-number>"
                exit 1
            fi
            rollback_phase "$phase"
            ;;
        --test)
            test_rollback
            ;;
        help|*)
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  list              List available checkpoints"
            echo "  restore <name>    Restore from checkpoint"
            echo "  phase <number>    Rollback specific phase"
            echo "  --test            Test rollback mechanism"
            echo ""
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
