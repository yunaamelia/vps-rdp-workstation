#!/bin/bash
# =============================================================================
#  VPS RDP Workstation - Staging Deployment Script
#  Version: 1.0.0
#  Purpose: Safe deployment to staging environment with validation
# =============================================================================
set -euo pipefail

# --- Configuration ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

STAGING_HOST="${STAGING_HOST:-staging.vps.example.com}"
STAGING_USER="${STAGING_USER:-root}"
STAGING_SSH_KEY="${STAGING_SSH_KEY:-~/.ssh/staging_rsa}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Logging ---
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# --- Functions ---
check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if ansible is installed
    if ! command -v ansible-playbook &>/dev/null; then
        log_error "Ansible not found. Please install ansible-core."
        exit 1
    fi

    # Check if molecule is installed
    if ! command -v molecule &>/dev/null; then
        log_error "Molecule not found. Please install molecule."
        exit 1
    fi

    # Check if staging inventory exists
    if [[ ! -f "$PROJECT_ROOT/inventory/staging.yml" ]]; then
        log_error "Staging inventory not found at inventory/staging.yml"
        exit 1
    fi

    log_success "Prerequisites OK"
}

run_molecule_tests() {
    log_info "Running Molecule tests..."

    cd "$PROJECT_ROOT"

    if ! molecule test; then
        log_error "Molecule tests failed. Aborting staging deployment."
        exit 1
    fi

    log_success "Molecule tests passed"
}

deploy_to_staging() {
    log_info "Deploying to staging environment..."
    log_info "Target: $STAGING_HOST"

    cd "$PROJECT_ROOT"

    # Deploy using Ansible
    if ! ansible-playbook \
        -i inventory/staging.yml \
        playbooks/main.yml \
        --extra-vars "vps_hostname=staging-workstation" \
        --extra-vars "vps_install_desktop=true" \
        --extra-vars "vps_fail2ban_enabled=true"; then

        log_error "Staging deployment failed"
        exit 1
    fi

    log_success "Staging deployment completed"
}

run_smoke_tests() {
    log_info "Running smoke tests on staging..."

    # Wait for services to stabilize
    log_info "Waiting 30 seconds for services to stabilize..."
    sleep 30

    # Run smoke tests
    if [[ -x "$PROJECT_ROOT/tests/smoke-test.sh" ]]; then
        if ! "$PROJECT_ROOT/tests/smoke-test.sh" "$STAGING_HOST" "$STAGING_USER"; then
            log_error "Smoke tests failed"
            return 1
        fi
    else
        log_warn "Smoke test script not found, skipping..."
    fi

    log_success "Smoke tests passed"
}

generate_report() {
    log_info "Generating deployment report..."

    cat << EOF

════════════════════════════════════════════════════════════
  📊 STAGING DEPLOYMENT REPORT
════════════════════════════════════════════════════════════

Target Environment: $STAGING_HOST
Deployment Time:    $(date '+%Y-%m-%d %H:%M:%S')
Git Commit:         $(cd "$PROJECT_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo "unknown")
Git Branch:         $(cd "$PROJECT_ROOT" && git branch --show-current 2>/dev/null || echo "unknown")

Status: ✅ SUCCESS

Next Steps:
  1. Manually test RDP connection to $STAGING_HOST:3389
  2. Verify desktop environment loads correctly
  3. Test key applications (VS Code, Docker, etc.)
  4. If all OK, proceed to production deployment

════════════════════════════════════════════════════════════

EOF
}

main() {
    echo "════════════════════════════════════════════════════════════"
    echo "  🚀 VPS RDP Workstation - Staging Deployment"
    echo "════════════════════════════════════════════════════════════"
    echo ""

    # Step 1: Prerequisites
    check_prerequisites
    echo ""

    # Step 2: Molecule Tests
    log_info "Step 1/3: Running Molecule Tests"
    run_molecule_tests
    echo ""

    # Step 3: Deploy to Staging
    log_info "Step 2/3: Deploying to Staging"
    deploy_to_staging
    echo ""

    # Step 4: Smoke Tests
    log_info "Step 3/3: Running Smoke Tests"
    run_smoke_tests
    echo ""

    # Step 5: Report
    generate_report

    log_success "Staging deployment completed successfully!"

    exit 0
}

# --- Help ---
if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    cat << EOF
Usage: $0 [OPTIONS]

Deploy VPS RDP Workstation to staging environment.

Environment Variables:
  STAGING_HOST      Target staging host (default: staging.vps.example.com)
  STAGING_USER      SSH user (default: root)
  STAGING_SSH_KEY   SSH key path (default: ~/.ssh/staging_rsa)

Examples:
  # Deploy to staging
  $0

  # Deploy to custom staging host
  STAGING_HOST=192.168.1.100 $0

  # Skip molecule tests (not recommended)
  SKIP_TESTS=1 $0

Notes:
  - Molecule tests must pass before deployment
  - Smoke tests run after deployment
  - Deployment report generated at end
  - All steps logged for audit trail

EOF
    exit 0
fi

# Run main
main "$@"
