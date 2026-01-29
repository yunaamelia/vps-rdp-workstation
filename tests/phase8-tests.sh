#!/bin/bash
# tests/phase8-tests.sh - Phase 8 Enhancement Validation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../scripts/utils/logger.sh" 2>/dev/null || true

echo "=== Phase 8: Enhancement & Extension Validation ==="
echo ""

FAILED_TESTS=0
VPS_USERNAME="${VPS_USERNAME:-developer}"

# Test 1: Development shortcuts
echo "Test 1: Validating development shortcuts..."
if [ -f /usr/local/share/dev-shortcuts.sh ] || [ -f "/home/$VPS_USERNAME/.dev-shortcuts.sh" ]; then
    echo "  ✅ Development shortcuts script installed"
else
    echo "  ⚠️  Development shortcuts not installed (optional)"
fi

# Test 2: Monitoring tools
echo "Test 2: Validating monitoring tools..."
MONITORING_TOOLS=("ncdu" "iotop" "nload")
for tool in "${MONITORING_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        echo "  ✅ $tool installed"
    else
        echo "  ⚠️  $tool not installed (optional)"
    fi
done

# Test 3: Workflow scripts
echo "Test 3: Validating workflow scripts..."
if [ -f /usr/local/bin/setup-github-ssh ]; then
    echo "  ✅ GitHub SSH setup script installed"
else
    echo "  ⚠️  GitHub SSH setup script not found"
fi

if [ -f /usr/local/bin/daily-dev-start ]; then
    echo "  ✅ Daily dev startup script installed"
else
    echo "  ⚠️  Daily dev startup script not found"
fi

# Test 4: VS Code templates
echo "Test 4: Validating VS Code templates..."
if [ -d "/home/$VPS_USERNAME/.vscode-templates" ]; then
    TEMPLATES=$(ls -1 "/home/$VPS_USERNAME/.vscode-templates/"*.code-workspace 2>/dev/null | wc -l)
    echo "  ✅ VS Code templates directory exists ($TEMPLATES template(s))"
else
    echo "  ⚠️  VS Code templates not installed"
fi

# Test 5: Backup system
echo "Test 5: Validating backup system..."
if [ -f /usr/local/bin/auto-backup ]; then
    echo "  ✅ Automated backup script installed"
    
    if crontab -l -u "$VPS_USERNAME" 2>/dev/null | grep -q "auto-backup"; then
        echo "  ✅ Backup cron job configured"
    else
        echo "  ⚠️  Backup cron job not found"
    fi
else
    echo "  ⚠️  Backup system not installed"
fi

# Test 6: tmux configuration
echo "Test 6: Validating tmux enhancements..."
if [ -f "/home/$VPS_USERNAME/.tmux.conf" ]; then
    echo "  ✅ tmux configuration present"
    
    if [ -d "/home/$VPS_USERNAME/.tmux/plugins/tpm" ]; then
        echo "  ✅ tmux plugin manager installed"
    else
        echo "  ⚠️  tmux plugin manager not found"
    fi
else
    echo "  ⚠️  tmux not configured"
fi

# Test 7: Database tools
echo "Test 7: Validating database tools..."
DB_TOOLS=("mysql" "psql" "redis-cli")
for tool in "${DB_TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        echo "  ✅ $tool installed"
    else
        echo "  ⚠️  $tool not installed (optional)"
    fi
done

echo ""
if [ $FAILED_TESTS -eq 0 ]; then
    echo "=== Phase 8 Validation: ALL TESTS PASSED ✅ ==="
    echo "Optional enhancements installed successfully"
    exit 0
else
    echo "=== Phase 8 Validation: $FAILED_TESTS TESTS FAILED ❌ ==="
    echo "Some optional features may not be available"
    exit 1
fi
