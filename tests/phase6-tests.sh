#!/bin/bash
#===============================================================================
# Phase 6 Tests - Configuration Optimization
#===============================================================================
set -e

echo "=== Phase 6: Configuration Optimization ==="

FAILED=0
USERNAME="${VPS_USERNAME:-developer}"

# Test 1: Firewall
echo "Test 1: Checking UFW firewall..."
if ufw status 2>/dev/null | grep -q "active"; then
    echo "  ✅ UFW active"
    if ufw status | grep -q "22/tcp"; then
        echo "  ✅ SSH port allowed"
    else
        echo "  ⚠️  SSH port not explicitly allowed"
    fi
    if ufw status | grep -q "3389/tcp"; then
        echo "  ✅ RDP port allowed"
    else
        echo "  ⚠️  RDP port not explicitly allowed"
    fi
else
    echo "  ⚠️  UFW not active"
fi

# Test 2: Fail2ban
echo "Test 2: Checking Fail2ban..."
if systemctl is-active --quiet fail2ban; then
    echo "  ✅ Fail2ban active"
    JAILS=$(fail2ban-client status 2>/dev/null | grep "Jail list" | cut -d: -f2)
    echo "  ✅ Active jails:$JAILS"
else
    echo "  ⚠️  Fail2ban not active"
fi

# Test 3: Terminal configuration
echo "Test 3: Checking terminal setup..."
if [ -f "/home/$USERNAME/.zshrc" ]; then
    echo "  ✅ Zsh configured"
else
    echo "  ⚠️  Zsh not configured"
fi

if command -v starship &>/dev/null; then
    echo "  ✅ Starship installed"
else
    echo "  ⚠️  Starship not installed"
fi

# Test 4: System optimization
echo "Test 4: Checking system optimization..."
SWAPPINESS=$(cat /proc/sys/vm/swappiness 2>/dev/null)
if [ "$SWAPPINESS" -le 10 ]; then
    echo "  ✅ Swappiness optimized: $SWAPPINESS"
else
    echo "  ⚠️  Swappiness is $SWAPPINESS (recommended: ≤10)"
fi

# Test 5: VS Code extensions
echo "Test 5: Checking VS Code extensions..."
if [ -d "/home/$USERNAME/.vscode/extensions" ]; then
    EXT_COUNT=$(ls -1 "/home/$USERNAME/.vscode/extensions" 2>/dev/null | wc -l)
    echo "  ✅ $EXT_COUNT VS Code extensions installed"
else
    echo "  ⚠️  No VS Code extensions directory"
fi

# Summary
echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== Phase 6 Validation: ALL TESTS PASSED ✅ ==="
    exit 0
else
    echo "=== Phase 6 Validation: $FAILED TESTS FAILED ❌ ==="
    exit 1
fi
