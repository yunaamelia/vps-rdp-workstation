#!/bin/bash
# =============================================================================
# Molecule Test Infrastructure Implementation Script
# Automates the setup of enhanced test scenarios and helpers
# =============================================================================

set -euo pipefail

# Colors
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly RESET='\033[0m'

log_info() {
    echo -e "${CYAN}[INFO]${RESET} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${RESET} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${RESET} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${RESET} $*"
}

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD} 🧪 Molecule Test Infrastructure Setup${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
}

# =============================================================================
# PHASE 1: Create New Molecule Scenarios
# =============================================================================
create_scenario() {
    local scenario_name=$1
    local roles=$2

    log_info "Creating scenario: ${scenario_name}"

    if [ -d "molecule/${scenario_name}" ]; then
        log_warning "Scenario ${scenario_name} already exists, skipping"
        return 0
    fi

    # Initialize scenario
    molecule init scenario "${scenario_name}" --driver-name docker 2>/dev/null || true

    # Create custom molecule.yml
    cat > "molecule/${scenario_name}/molecule.yml" <<EOF
---
# Molecule Scenario: ${scenario_name}
# Roles: ${roles}

dependency:
  name: galaxy
  options:
    requirements-file: \${MOLECULE_PROJECT_DIRECTORY}/molecule/requirements.yml
    ignore-errors: false

driver:
  name: docker

platforms:
  - name: debian-${scenario_name}
    image: debian:trixie
    pre_build_image: true
    privileged: true
    tty: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
    command: >-
      /bin/sh -c "if [ -x /lib/systemd/systemd ]; then exec /lib/systemd/systemd;
      else echo 'Systemd not found, sleeping' && while true; do sleep 1000; done; fi"
    tmpfs:
      - /run
      - /tmp

provisioner:
  name: ansible
  env:
    ANSIBLE_DEPRECATION_WARNINGS: "True"
    ANSIBLE_WARNINGS_ARE_ERRORS: "True"
    ANSIBLE_SYSTEM_WARNINGS: "True"
    ANSIBLE_CALLBACK_PLUGINS: "\${MOLECULE_PROJECT_DIRECTORY}/plugins/callback"
    ANSIBLE_CALLBACKS_ENABLED: "strict_deprecations"
  config_options:
    defaults:
      roles_path: \${MOLECULE_PROJECT_DIRECTORY}/roles
      collections_path: \${MOLECULE_PROJECT_DIRECTORY}/collections
      remote_tmp: /tmp/.ansible/tmp
      allow_world_readable_tmpfiles: true
      pipelining: true
  inventory:
    host_vars:
      debian-${scenario_name}:
        ansible_user: root
      localhost:
        ansible_connection: local
        ansible_become: false

verifier:
  name: ansible

scenario:
  name: ${scenario_name}
  test_sequence:
    - dependency
    - syntax
    - create
    - prepare
    - converge
    - idempotence
    - verify
    - destroy
EOF

    log_success "Created molecule.yml for ${scenario_name}"
}

# =============================================================================
# PHASE 2: Generate Scenario Files
# =============================================================================
generate_scenarios() {
    log_info "Generating new Molecule scenarios..."

    # Fonts scenario
    create_scenario "fonts" "fonts"

    # KDE scenario (optimization + apps + theme)
    create_scenario "kde" "kde-optimization, kde-apps, whitesur-theme"

    # Editors scenario
    create_scenario "editors" "editors"

    # TUI Tools scenario
    create_scenario "tui-tools" "tui-tools, text-processing, file-management"

    # Monitoring scenario
    create_scenario "monitoring" "system-performance, log-visualization"

    # Advanced Dev scenario
    create_scenario "advanced-dev" "dev-debugging, code-quality, ai-devtools, cloud-native"

    # Network tools scenario
    create_scenario "network" "network-tools"

    log_success "All scenarios generated"
}

# =============================================================================
# PHASE 3: Update CI Configuration
# =============================================================================
update_ci() {
    log_info "Updating CI configuration..."

    if [ -f ".github/workflows/ci-enhanced.yml" ]; then
        log_info "Enhanced CI workflow already exists"

        read -p "Replace existing .github/workflows/ci.yml with enhanced version? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            cp .github/workflows/ci.yml .github/workflows/ci.yml.backup
            mv .github/workflows/ci-enhanced.yml .github/workflows/ci.yml
            log_success "CI configuration updated (backup saved as ci.yml.backup)"
        else
            log_warning "Skipping CI update"
        fi
    else
        log_warning "ci-enhanced.yml not found"
    fi
}

# =============================================================================
# PHASE 4: Verify Installation
# =============================================================================
verify_setup() {
    log_info "Verifying test infrastructure..."

    local errors=0

    # Check scenarios
    local expected_scenarios=(default devtools shell fonts kde editors tui-tools monitoring advanced-dev network)
    for scenario in "${expected_scenarios[@]}"; do
        if [ -d "molecule/${scenario}" ]; then
            log_success "✓ Scenario ${scenario} exists"
        else
            log_error "✗ Scenario ${scenario} missing"
            ((errors++))
        fi
    done

    # Check helpers
    if [ -f "molecule/helpers/service_verify.yml" ]; then
        log_success "✓ Service helper exists"
    else
        log_error "✗ Service helper missing"
        ((errors++))
    fi

    # Check fixtures
    if [ -f "molecule/fixtures/test_data.yml" ]; then
        log_success "✓ Test data fixtures exist"
    else
        log_error "✗ Test data fixtures missing"
        ((errors++))
    fi

    echo ""
    if [ $errors -eq 0 ]; then
        log_success "All checks passed!"
        return 0
    else
        log_error "${errors} checks failed"
        return 1
    fi
}

# =============================================================================
# PHASE 5: Run Quick Test
# =============================================================================
quick_test() {
    log_info "Running quick test on default scenario..."

    if ! command -v molecule &> /dev/null; then
        log_error "Molecule not installed. Run: pip install -r requirements.txt"
        return 1
    fi

    log_info "Running: molecule test --scenario-name default"

    if molecule test --scenario-name default; then
        log_success "Default scenario test passed!"
    else
        log_error "Default scenario test failed"
        return 1
    fi
}

# =============================================================================
# Main Execution
# =============================================================================
main() {
    print_header

    # Check if we're in the right directory
    if [ ! -f "ansible.cfg" ]; then
        log_error "Not in project root directory. Please run from vps-rdp-workstation/"
        exit 1
    fi

    # Check if molecule is installed
    if ! command -v molecule &> /dev/null; then
        log_warning "Molecule not installed"
        read -p "Install molecule and dependencies? (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            pip install -r requirements.txt
            log_success "Dependencies installed"
        else
            log_error "Cannot proceed without molecule"
            exit 1
        fi
    fi

    # Phase 1: Generate scenarios
    generate_scenarios

    # Phase 2: Update CI (optional)
    update_ci

    # Phase 3: Verify setup
    if ! verify_setup; then
        log_error "Setup verification failed"
        exit 1
    fi

    # Phase 4: Quick test (optional)
    echo ""
    read -p "Run quick test on default scenario? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        quick_test
    fi

    # Summary
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo -e "${BOLD} ✅ Setup Complete!${RESET}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
    echo ""
    echo "Next steps:"
    echo "  1. Review generated scenarios in molecule/"
    echo "  2. Customize converge.yml and verify.yml for each scenario"
    echo "  3. Run: molecule test --all"
    echo "  4. Review MOLECULE_TEST_ANALYSIS.md for detailed recommendations"
    echo ""
    echo "Quick commands:"
    echo "  - Test single scenario: molecule test --scenario-name <name>"
    echo "  - Test all scenarios:   molecule test --all"
    echo "  - List scenarios:       molecule list"
    echo ""
}

main "$@"
