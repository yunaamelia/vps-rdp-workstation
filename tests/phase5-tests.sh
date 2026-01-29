#!/bin/bash
#===============================================================================
# Phase 5 Tests - Installation Validation
#===============================================================================
set -e

echo "=== Phase 5: Installation Validation ==="

FAILED=0

# Test 1: Language execution
echo "Test 1: Testing language execution..."

if node -e "console.log('ok')" &>/dev/null; then
    echo "  ✅ Node.js execution OK"
else
    echo "  ❌ Node.js execution failed"
    ((FAILED++))
fi

if python3 -c "print('ok')" &>/dev/null; then
    echo "  ✅ Python execution OK"
else
    echo "  ❌ Python execution failed"
    ((FAILED++))
fi

if php -r "echo 'ok';" &>/dev/null; then
    echo "  ✅ PHP execution OK"
else
    echo "  ❌ PHP execution failed"
    ((FAILED++))
fi

# Test 2: Package managers
echo "Test 2: Testing package managers..."
if npm list -g --depth=0 &>/dev/null; then
    echo "  ✅ npm working"
else
    echo "  ❌ npm not working"
    ((FAILED++))
fi

if pip3 list &>/dev/null; then
    echo "  ✅ pip working"
else
    echo "  ❌ pip not working"
    ((FAILED++))
fi

# Test 3: Services
echo "Test 3: Checking services..."
SERVICES=("xrdp" "docker" "sddm")
for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc"; then
        echo "  ✅ $svc active"
    else
        echo "  ❌ $svc not active"
        ((FAILED++))
    fi
done

# Test 4: Docker socket
echo "Test 4: Checking Docker socket..."
if [ -S /var/run/docker.sock ]; then
    echo "  ✅ Docker socket exists"
else
    echo "  ❌ Docker socket missing"
    ((FAILED++))
fi

# Test 5: GUI applications
echo "Test 5: Checking GUI applications..."
for app in code konsole dolphin firefox-esr; do
    if command -v "$app" &>/dev/null; then
        echo "  ✅ $app available"
    else
        echo "  ⚠️  $app not found"
    fi
done

# Summary
echo ""
if [ $FAILED -eq 0 ]; then
    echo "=== Phase 5 Validation: ALL TESTS PASSED ✅ ==="
    exit 0
else
    echo "=== Phase 5 Validation: $FAILED TESTS FAILED ❌ ==="
    exit 1
fi
