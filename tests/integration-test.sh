#!/bin/bash
# =============================================================================
#  VPS RDP Workstation - Integration Test Suite
#  Version: 1.0.0
#  Purpose: Deep functional validation of features after deployment
# =============================================================================
set -euo pipefail

# --- Configuration ---
HOST="${1:-localhost}"
USER="${2:-testuser}"
export TIMEOUT=60

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# --- Logging Functions ---
log_info() { echo -e "${CYAN}[INFO]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_test() { echo -e "  ✓ $1"; }

# --- Helper ---
ssh_cmd() {
    ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$USER@$HOST" "$1"
}

# --- Main Test Execution ---
main() {
    local failed=0

    echo "════════════════════════════════════════════════════════════"
    echo "  🚀 VPS RDP Workstation - Integration Tests"
    echo "  Target: $HOST"
    echo "  User: $USER"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    if [[ "$HOST" == "localhost" || "$HOST" == "127.0.0.1" ]]; then
        log_error "Integration tests require a remote or mock staging host, not localhost."
        exit 1
    fi

    # 1. Test RDP Connection (Simulated if xfreerdp not installed locally)
    log_info "1. Testing RDP Connection Readiness..."
    if command -v xfreerdp &> /dev/null; then
        log_info "xfreerdp found! Running connection test (expecting cert warnings)..."
        # We just try to connect and immediately drop, looking for successful negotiation
        if timeout 3 xfreerdp /v:"$HOST" /u:"$USER" /p:"wrongpassword" /cert:ignore +auth-only 2>&1 | grep -q "Authentication only"; then
            log_test "RDP Server is responding to negotiation"
        else
            log_error "RDP Negotiation failed"
            ((failed++))
        fi
    else
        log_info "xfreerdp not found locally, simulating RDP port check..."
        if timeout 5 nc -zv "$HOST" 3389 2>&1 | grep -q "succeeded"; then
            log_test "RDP port 3389 is open and accepting TCP connections"
        else
            log_error "RDP port 3389 is closed"
            ((failed++))
        fi
    fi
    echo ""

    # 2. Test Git Operations
    log_info "2. Testing Git Operations..."
    local git_test_dir="/tmp/integration_git_test_$$"
    if ssh_cmd "mkdir -p $git_test_dir && cd $git_test_dir && git init && echo 'test' > test.txt && git add test.txt && git -c user.name='Integration Test' -c user.email='test@example.com' commit -m 'Initial commit'"; then
        log_test "Git init, add, and commit successful"
    else
        log_error "Git operations failed"
        ((failed++))
    fi
    ssh_cmd "rm -rf $git_test_dir"
    echo ""

    # 3. Test Docker Compose Deployment
    log_info "3. Testing Docker Compose Deployment..."
    local compose_dir="/tmp/integration_docker_$$"
    if ssh_cmd "mkdir -p $compose_dir"; then
        ssh_cmd "cat << 'EOF' > $compose_dir/docker-compose.yml
services:
  test_web:
    image: nginx:alpine
    ports:
      - '18080:80'
EOF"
        log_info "Deploying test container..."
        if ssh_cmd "cd $compose_dir && docker compose up -d"; then
            log_test "Docker Compose 'up' successful"

            # Verify it's running
            sleep 3
            if ssh_cmd "curl -s http://localhost:18080 | grep -q 'Welcome to nginx'"; then
                log_test "Container is serving HTTP traffic"
            else
                log_error "Container not serving HTTP traffic"
                ((failed++))
            fi

            log_info "Tearing down test container..."
            ssh_cmd "cd $compose_dir && docker compose down"
        else
            log_error "Docker Compose deployment failed"
            ((failed++))
        fi
        ssh_cmd "rm -rf $compose_dir"
    else
        log_error "Failed to setup docker compose testing directory"
        ((failed++))
    fi
    echo ""

    # 4. Test Desktop Environment Files & Services
    log_info "4. Testing Desktop Session Readiness..."
    if ssh_cmd "ls /usr/bin/startplasma-x11 &> /dev/null"; then
        log_test "KDE Plasma executable found"
    else
        log_error "KDE Plasma executable missing"
        ((failed++))
    fi

    if ssh_cmd "grep -q 'startplasma-x11' /etc/xrdp/startwm.sh"; then
        log_test "XRDP is configured to launch KDE Plasma"
    else
        log_error "XRDP startwm.sh is missing KDE Plasma configuration"
        ((failed++))
    fi
    echo ""

    # Final Report
    echo "════════════════════════════════════════════════════════════"
    if [[ $failed -eq 0 ]]; then
        echo -e "${GREEN}✅ All integration tests passed!${NC}"
        echo "════════════════════════════════════════════════════════════"
        exit 0
    else
        echo -e "${RED}❌ $failed integration test(s) failed${NC}"
        echo "════════════════════════════════════════════════════════════"
        exit 1
    fi
}

# --- Help Text ---
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat << EOF
Usage: $0 <HOST> [USER]

Integration test suite for VPS RDP Workstation deployment validation.
Requires a remote host (cannot be run against localhost).

Arguments:
  HOST    Target host (IP or Domain)
  USER    SSH user (default: testuser)

Examples:
  $0 192.168.1.100 testuser
  $0 staging.example.com testuser

Exit codes:
  0    All tests passed
  1    One or more tests failed
EOF
    exit 0
fi

# Run tests
main "$@"
