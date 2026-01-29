#!/bin/bash
#===============================================================================
# Phase 4 Tests - RDP Workstation Packages
#===============================================================================
set -e

echo "=== Phase 4: RDP Workstation Packages ==="

FAILED=0
USERNAME="${VPS_USERNAME:-developer}"

# Test 1: Fonts
echo "Test 1: Checking fonts..."
if fc-list | grep -qi "jetbrains"; then
    echo "  ✅ JetBrains Mono Nerd Font installed"
else
    echo "  ❌ JetBrains font not found"
    ((FAILED++))
fi

# Test 2: KDE packages
echo "Test 2: Checking KDE Plasma..."
PKGS=("kde-plasma-desktop" "sddm" "konsole")
for pkg in "${PKGS[@]}"; do
    if dpkg -l | grep -q "^ii.*$pkg"; then
        echo "  ✅ $pkg installed"
    else
        echo "  ❌ $pkg not installed"
        ((FAILED++))
    fi
done

# Test 3: XRDP
echo "Test 3: Checking XRDP..."
if dpkg -l | grep -q "^ii.*xrdp"; then
    echo "  ✅ XRDP installed"
    if systemctl is-active --quiet xrdp; then
        echo "  ✅ XRDP service active"
    else
        echo "  ❌ XRDP service not active"
        ((FAILED++))
    fi
else
    echo "  ❌ XRDP not installed"
    ((FAILED++))
fi

# Test 4: XRDP port
echo "Test 4: Checking XRDP port..."
if ss -tlnp | grep -q ":3389"; then
    echo "  ✅ XRDP listening on port 3389"
else
    echo "  ❌ XRDP not listening on port 3389"
    ((FAILED++))
fi

# Test 5: Docker
echo "Test 5: Checking Docker..."
if command -v docker &>/dev/null; then
    echo "  ✅ Docker installed"
    if systemctl is-active --quiet docker; then
        echo "  ✅ Docker service active"
    else
        echo "  ❌ Docker service not active"
        ((FAILED++))
    fi
else
    echo "  ❌ Docker not installed"
    ((FAILED++))
fi

# Test 6: User in docker group
echo "Test 6: Checking docker group..."
if groups "$USERNAME" 2>/dev/null | grep -q docker; then
    echo "  ✅ User in docker group"
else
    echo "  ❌ User not in docker group"
    ((FAILED++))
fi

# Test 7: VS Code
echo "Test 7: Checking VS Code..."
if command -v code &>/dev/null; then
    echo "  ✅ VS Code installed"
else
    echo "  ❌ VS Code not installed"
    ((FAILED++))
fi

# Test 8: .xsession file
echo "Test 8: Checking .xsession..."
if [ -f "/home/$USERNAME/.xsession" ]; then
    echo "  ✅ .xsession configured"
else
    echo "  ❌ .xsession missing"
    ((FAILED++))
fi

# Summary
echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== Phase 4 Validation: ALL TESTS PASSED ✅ ==="
    exit 0
else
    echo "=== Phase 4 Validation: $FAILED TESTS FAILED ❌ ==="
    exit 1
fi
