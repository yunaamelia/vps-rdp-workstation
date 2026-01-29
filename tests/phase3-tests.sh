#!/bin/bash
#===============================================================================
# Phase 3 Tests - Environment & Dependencies
#===============================================================================
set -e

echo "=== Phase 3: Environment Validation & Dependencies ==="

FAILED=0

# Test 1: External repositories
echo "Test 1: Checking external repositories..."
REPOS=("nodesource" "docker" "vscode" "github-cli")
for repo in "${REPOS[@]}"; do
    if ls /etc/apt/sources.list.d/ 2>/dev/null | grep -q "$repo"; then
        echo "  ✅ $repo repository configured"
    else
        echo "  ❌ $repo repository missing"
        ((FAILED++))
    fi
done

# Test 2: Node.js
echo "Test 2: Checking Node.js..."
if command -v node &>/dev/null; then
    NODE_VER=$(node --version | sed 's/v//' | cut -d'.' -f1)
    if [ "$NODE_VER" -ge 20 ]; then
        echo "  ✅ Node.js v$NODE_VER installed"
    else
        echo "  ❌ Node.js version too old"
        ((FAILED++))
    fi
else
    echo "  ❌ Node.js not installed"
    ((FAILED++))
fi

# Test 3: Python
echo "Test 3: Checking Python..."
if command -v python3 &>/dev/null; then
    PYTHON_VER=$(python3 --version | awk '{print $2}')
    echo "  ✅ Python $PYTHON_VER installed"
else
    echo "  ❌ Python not installed"
    ((FAILED++))
fi

# Test 4: PHP
echo "Test 4: Checking PHP..."
if command -v php &>/dev/null; then
    PHP_VER=$(php --version | head -1 | awk '{print $2}')
    echo "  ✅ PHP $PHP_VER installed"
else
    echo "  ❌ PHP not installed"
    ((FAILED++))
fi

# Test 5: Composer
echo "Test 5: Checking Composer..."
if command -v composer &>/dev/null; then
    echo "  ✅ Composer installed"
else
    echo "  ❌ Composer not installed"
    ((FAILED++))
fi

# Test 6: Git tools
echo "Test 6: Checking Git tools..."
for tool in git gh lazygit; do
    if command -v $tool &>/dev/null; then
        echo "  ✅ $tool installed"
    else
        echo "  ❌ $tool not installed"
        ((FAILED++))
    fi
done

# Test 7: Security packages
echo "Test 7: Checking security packages..."
for pkg in ufw fail2ban; do
    if dpkg -l | grep -q "^ii.*$pkg"; then
        echo "  ✅ $pkg installed"
    else
        echo "  ❌ $pkg not installed"
        ((FAILED++))
    fi
done

# Summary
echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== Phase 3 Validation: ALL TESTS PASSED ✅ ==="
    exit 0
else
    echo "=== Phase 3 Validation: $FAILED TESTS FAILED ❌ ==="
    exit 1
fi
