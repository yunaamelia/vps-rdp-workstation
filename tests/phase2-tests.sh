#!/bin/bash
#===============================================================================
# Phase 2 Tests - User Management & Access Configuration
#===============================================================================
set -e

echo "=== Phase 2: User Management & Access Configuration ==="

FAILED=0
USERNAME="${VPS_USERNAME:-developer}"

# Test 1: User exists
echo "Test 1: Checking user account..."
if id "$USERNAME" &>/dev/null; then
    echo "  ✅ User $USERNAME exists"
else
    echo "  ❌ User $USERNAME does not exist"
    ((FAILED++))
fi

# Test 2: Home directory exists
echo "Test 2: Checking home directory..."
if [ -d "/home/$USERNAME" ]; then
    echo "  ✅ Home directory exists"
else
    echo "  ❌ Home directory missing"
    ((FAILED++))
fi

# Test 3: Sudo configuration
echo "Test 3: Checking sudo configuration..."
if [ -f "/etc/sudoers.d/$USERNAME" ]; then
    if visudo -c -f "/etc/sudoers.d/$USERNAME" &>/dev/null; then
        echo "  ✅ Sudo configuration valid"
    else
        echo "  ❌ Sudo configuration invalid"
        ((FAILED++))
    fi
else
    echo "  ❌ Sudo configuration file missing"
    ((FAILED++))
fi

# Test 4: User in sudo group
echo "Test 4: Checking group membership..."
if groups "$USERNAME" 2>/dev/null | grep -q sudo; then
    echo "  ✅ User in sudo group"
else
    echo "  ❌ User not in sudo group"
    ((FAILED++))
fi

# Test 5: SSH directory (optional)
echo "Test 5: Checking SSH configuration..."
if [ -d "/home/$USERNAME/.ssh" ]; then
    PERMS=$(stat -c "%a" "/home/$USERNAME/.ssh")
    if [ "$PERMS" = "700" ]; then
        echo "  ✅ SSH directory with correct permissions"
    else
        echo "  ⚠️  SSH directory exists but permissions are $PERMS (should be 700)"
    fi
else
    echo "  ⚠️  SSH directory not created (optional)"
fi

# Summary
echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== Phase 2 Validation: ALL TESTS PASSED ✅ ==="
    exit 0
else
    echo "=== Phase 2 Validation: $FAILED TESTS FAILED ❌ ==="
    exit 1
fi
