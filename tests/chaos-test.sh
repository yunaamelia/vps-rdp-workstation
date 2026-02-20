#!/bin/bash
# VPS RDP Workstation - Chaos Testing Suite
# Tests service recovery and resilience
set -euo pipefail

HOST="${1:-localhost}"
USER="${2:-testuser}"

echo "🌪️ Starting Chaos Testing on $HOST..."

ssh_cmd() {
    ssh -o StrictHostKeyChecking=no "$USER@$HOST" "$1"
}

# 1. Kill XRDP and check recovery
echo "🔪 Killing XRDP Service..."
ssh_cmd "sudo killall -9 xrdp || true"
sleep 5
if ssh_cmd "sudo systemctl is-active xrdp" >/dev/null 2>&1; then
    echo "✅ XRDP recovered successfully"
else
    echo "❌ XRDP failed to recover!"
    exit 1
fi

# 2. Kill Docker daemon
echo "🔪 Killing Dockerd..."
ssh_cmd "sudo killall -9 dockerd || true"
sleep 5
if ssh_cmd "sudo systemctl is-active docker" >/dev/null 2>&1; then
    echo "✅ Docker recovered successfully"
else
    echo "❌ Docker failed to recover!"
    exit 1
fi

echo "🎉 All chaos tests passed. System is resilient."
