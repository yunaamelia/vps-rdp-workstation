#!/bin/bash
#===============================================================================
# Phase 1 Tests - System Preparation & Checkpoint
#===============================================================================
set -e

echo "=== Phase 1: System Preparation & Checkpoint ==="

FAILED=0
LOG_DIR="${VPS_SETUP_LOG_DIR:-/var/log/vps-setup}"

# Test 1: Log directory exists
echo "Test 1: Checking log directory..."
if [ -d "$LOG_DIR" ]; then
    echo "  ✅ Log directory exists: $LOG_DIR"
else
    echo "  ❌ Log directory missing"
    ((FAILED++))
fi

# Test 2: Initial system state documented
echo "Test 2: Checking initial state documentation..."
if [ -f "$LOG_DIR/initial-system-info.txt" ]; then
    echo "  ✅ System info documented"
else
    echo "  ❌ System info not documented"
    ((FAILED++))
fi

if [ -f "$LOG_DIR/initial-packages.txt" ]; then
    echo "  ✅ Package list documented"
else
    echo "  ❌ Package list not documented"
    ((FAILED++))
fi

# Test 3: Deployment state initialized
echo "Test 3: Checking deployment state..."
if [ -f "$LOG_DIR/deployment-state.json" ]; then
    echo "  ✅ Deployment state initialized"
else
    echo "  ❌ Deployment state missing"
    ((FAILED++))
fi

# Test 4: Checkpoint exists (optional)
echo "Test 4: Checking for checkpoint..."
CHECKPOINT_DIR="${CHECKPOINT_DIR:-/root/vps-checkpoints}"
if [ -d "$CHECKPOINT_DIR" ] && ls "$CHECKPOINT_DIR"/*.tar.gz &>/dev/null; then
    echo "  ✅ Checkpoint available"
else
    echo "  ⚠️  No checkpoint found (optional)"
fi

# Summary
echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== Phase 1 Validation: ALL TESTS PASSED ✅ ==="
    exit 0
else
    echo "=== Phase 1 Validation: $FAILED TESTS FAILED ❌ ==="
    exit 1
fi
