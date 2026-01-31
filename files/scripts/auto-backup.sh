#!/bin/bash
# Automated backup script for VPS RDP Workstation
# Run via cron: 0 2 * * 0 /usr/local/bin/auto-backup

set -e

# Get username from argument or default
VPS_USERNAME="${1:-developer}"
BACKUP_DIR="/home/$VPS_USERNAME/backups"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

echo "Starting backup at $(date)"

mkdir -p "$BACKUP_DIR"

# Backup important configurations
tar -czf "$BACKUP_DIR/configs-$TIMESTAMP.tar.gz" \
    "/home/$VPS_USERNAME/.zshrc" \
    "/home/$VPS_USERNAME/.config/starship.toml" \
    "/home/$VPS_USERNAME/.config/Code/User/settings.json" \
    "/home/$VPS_USERNAME/.gitconfig" \
    /etc/xrdp/xrdp.ini \
    /etc/docker/daemon.json \
    2>/dev/null || true

echo "Configuration backup: $BACKUP_DIR/configs-$TIMESTAMP.tar.gz"

# Backup projects directory (if exists)
if [ -d "/home/$VPS_USERNAME/projects" ]; then
    tar -czf "$BACKUP_DIR/projects-$TIMESTAMP.tar.gz" \
        "/home/$VPS_USERNAME/projects" \
        --exclude='node_modules' \
        --exclude='venv' \
        --exclude='.venv' \
        --exclude='__pycache__' \
        --exclude='.git' \
        2>/dev/null || true

    echo "Projects backup: $BACKUP_DIR/projects-$TIMESTAMP.tar.gz"
fi

# Keep only last 7 days of backups
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +7 -delete 2>/dev/null || true

echo "Backup completed at $(date)"
