#!/bin/bash
#===============================================================================
# Phase 7 Tests - Final Validation
#===============================================================================
set -e

echo "=== Phase 7: Final Validation ==="

FAILED=0
USERNAME="${VPS_USERNAME:-developer}"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║              FINAL SYSTEM VALIDATION                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Test 1: All services
echo ""
echo "=== Services Status ==="
SERVICES=("xrdp" "xrdp-sesman" "sddm" "docker" "fail2ban")
for svc in "${SERVICES[@]}"; do
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo "  ✅ $svc: active"
    else
        echo "  ⚠️  $svc: inactive"
    fi
done

# Test 2: Network ports
echo ""
echo "=== Network Ports ==="
if ss -tlnp | grep -q ":22"; then
    echo "  ✅ Port 22 (SSH): listening"
else
    echo "  ❌ Port 22: not listening"
    ((FAILED++))
fi

if ss -tlnp | grep -q ":3389"; then
    echo "  ✅ Port 3389 (RDP): listening"
else
    echo "  ❌ Port 3389: not listening"
    ((FAILED++))
fi

# Test 3: Development tools
echo ""
echo "=== Development Tools ==="
echo "  Node.js: $(node --version 2>/dev/null || echo 'not found')"
echo "  npm: $(npm --version 2>/dev/null || echo 'not found')"
echo "  Python: $(python3 --version 2>/dev/null || echo 'not found')"
echo "  PHP: $(php --version 2>/dev/null | head -1 || echo 'not found')"
echo "  Docker: $(docker --version 2>/dev/null || echo 'not found')"
echo "  Compose: $(docker compose version 2>/dev/null || echo 'not found')"

# Test 4: Terminal tools
echo ""
echo "=== Terminal Tools ==="
TOOLS=(tmux fzf rg bat opencode)
for tool in "${TOOLS[@]}"; do
    if command -v "$tool" &>/dev/null; then
        echo "  ✅ $tool: installed"
    else
        echo "  ⚠️  $tool: not found"
    fi
done

# Test 5: User configuration
echo ""
echo "=== User Configuration ==="
SHELL=$(grep "^$USERNAME:" /etc/passwd | cut -d: -f7)
echo "  User: $USERNAME"
echo "  Shell: $SHELL"
echo "  Groups: $(groups $USERNAME 2>/dev/null | cut -d: -f2)"

# Test 6: System resources
echo ""
echo "=== System Resources ==="
echo "  Memory: $(free -h | awk '/^Mem:/{print $3 "/" $2}')"
echo "  Disk: $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 " used)"}')"
echo "  Load: $(uptime | awk -F'load average:' '{print $2}')"

# Summary
echo ""
echo "══════════════════════════════════════════════════════════════"
if [ $FAILED -eq 0 ]; then
    echo "✅ FINAL VALIDATION: ALL CRITICAL TESTS PASSED"
    echo ""
    echo "🎉 VPS RDP Workstation is ready!"
    echo "   Connect via RDP: $(hostname -I | awk '{print $1}'):3389"
    echo "   Username: $USERNAME"
    exit 0
else
    echo "❌ FINAL VALIDATION: $FAILED CRITICAL TESTS FAILED"
    exit 1
fi
