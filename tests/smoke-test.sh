#!/bin/bash
# =============================================================================
#  VPS RDP Workstation - Smoke Test Suite
#  Version: 1.0.0
#  Purpose: Quick validation of critical services after deployment
# =============================================================================
set -euo pipefail

# --- Configuration ---
HOST="${1:-localhost}"
USER="${2:-testuser}"
TIMEOUT="${TIMEOUT:-30}"
export TIMEOUT
VERBOSE="${VERBOSE:-false}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# --- Logging Functions ---
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_test() {
    echo -e "  ✓ $1"
}

# --- Test Functions ---
test_port() {
    local port=$1
    local service=$2

    if timeout 5 nc -zv "$HOST" "$port" 2>&1 | grep -q "succeeded"; then
        log_test "$service port $port is open"
        return 0
    else
        log_error "$service port $port is closed or unreachable"
        return 1
    fi
}

test_ssh_command() {
    local cmd=$1
    local description=$2

    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$USER@$HOST" "$cmd" &>/dev/null; then
        log_test "$description"
        return 0
    else
        log_error "$description failed"
        return 1
    fi
}

# --- Main Test Execution ---
main() {
    local failed=0

    echo "════════════════════════════════════════════════════════════"
    echo "  🔍 VPS RDP Workstation - Smoke Tests"
    echo "  Target: $HOST"
    echo "  User: $USER"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    # Test 1: Network Connectivity
    log_info "Testing network connectivity..."
    if ! ping -c 1 -W 3 "$HOST" &>/dev/null; then
        log_error "Host $HOST is unreachable"
        exit 1
    fi
    log_test "Host is reachable"
    echo ""

    # Test 2: SSH Port
    log_info "Testing SSH service..."
    test_port 22 "SSH" || ((failed++))
    echo ""

    # Test 3: XRDP Port
    log_info "Testing XRDP service..."
    test_port 3389 "XRDP" || ((failed++))
    echo ""

    # Test 4: SSH Connectivity (if not localhost)
    if [[ "$HOST" != "localhost" && "$HOST" != "127.0.0.1" ]]; then
        log_info "Testing SSH authentication..."
        if timeout 10 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$USER@$HOST" "echo OK" &>/dev/null; then
            log_test "SSH authentication successful"
        else
            log_error "SSH authentication failed"
            ((failed++))
        fi
        echo ""

        # Test 5: Docker
        log_info "Testing Docker..."
        test_ssh_command "docker --version" "Docker is installed" || ((failed++))
        test_ssh_command "docker ps" "Docker daemon is running" || ((failed++))
        echo ""

        # Test 6: UFW Firewall
        log_info "Testing firewall..."
        if ssh -o ConnectTimeout=5 "$USER@$HOST" "sudo ufw status" 2>/dev/null | grep -q "Status: active"; then
            log_test "UFW firewall is active"
        else
            log_warn "UFW firewall status unknown (may need sudo)"
        fi
        echo ""

        # Test 7: fail2ban
        log_info "Testing fail2ban..."
        if ssh -o ConnectTimeout=5 "$USER@$HOST" "sudo systemctl is-active fail2ban" 2>/dev/null | grep -q "active"; then
            log_test "fail2ban is running"
        else
            log_warn "fail2ban status unknown (may need sudo)"
        fi
        echo ""

        # Test 8: User Shell
        log_info "Testing user environment..."
        if ssh -o ConnectTimeout=5 "$USER@$HOST" "echo \$SHELL" 2>/dev/null | grep -q "zsh"; then
            log_test "User shell is zsh"
        else
            log_warn "User shell is not zsh (found: $(ssh "$USER@$HOST" "echo \$SHELL" 2>/dev/null || echo 'unknown'))"
        fi
        echo ""

        # Test 9: Essential Tools
        log_info "Testing essential tools..."
        for tool in git curl wget node npm python3; do
            if ssh -o ConnectTimeout=5 "$USER@$HOST" "command -v $tool" &>/dev/null; then
                log_test "$tool is installed"
            else
                log_error "$tool is not installed"
                ((failed++))
            fi
        done
        echo ""

        # Test 10: Docker Compose
        log_info "Testing Docker Compose..."
        test_ssh_command "docker compose version" "Docker Compose is available" || ((failed++))
        echo ""
    else
        log_warn "Skipping SSH-based tests for localhost"
        echo ""
    fi

    # Final Report
    echo "════════════════════════════════════════════════════════════"
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✅ All smoke tests passed!${NC}"
        echo "════════════════════════════════════════════════════════════"
        exit 0
    else
        echo -e "${RED}❌ $failed test(s) failed${NC}"
        echo "════════════════════════════════════════════════════════════"
        exit 1
    fi
}

# --- Help Text ---
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat << EOF
Usage: $0 [HOST] [USER]

Smoke test suite for VPS RDP Workstation deployment validation.

Arguments:
  HOST    Target host (default: localhost)
  USER    SSH user (default: testuser)

Environment:
  VERBOSE=true    Enable verbose output

Examples:
  # Test localhost
  $0

  # Test remote VPS
  $0 192.168.1.100 developer

  # Test staging environment
  $0 staging.example.com testuser

Exit codes:
  0    All tests passed
  1    One or more tests failed

EOF
    exit 0
fi

# Run tests
main "$@"
