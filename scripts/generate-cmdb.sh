#!/bin/bash
# =============================================================================
# Generate Ansible CMDB Dashboard
# Creates a static HTML inventory dashboard from Ansible facts
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="${PROJECT_DIR}/docs/inventory-dashboard"
FACTS_DIR="/tmp/ansible_facts_cache"

# Colors
readonly GREEN='\033[0;32m'
readonly CYAN='\033[0;36m'
readonly YELLOW='\033[0;33m'
readonly RED='\033[0;31m'
readonly NC='\033[0m'

log_info() {
    echo -e "${CYAN}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

print_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}  📊 Ansible CMDB Dashboard Generator${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

# Check if ansible-cmdb is installed
check_dependencies() {
    if ! command -v ansible-cmdb &>/dev/null; then
        log_error "ansible-cmdb is not installed"
        log_info "Install it with: pip install ansible-cmdb"
        exit 1
    fi
    log_success "ansible-cmdb found"
}

# Gather facts if needed
gather_facts() {
    log_info "Gathering facts from inventory..."

    cd "$PROJECT_DIR"

    # Create facts directory
    mkdir -p "$FACTS_DIR"

    # Gather facts using setup module
    ansible all -i inventory/hosts.yml -m setup --tree "$FACTS_DIR" 2>/dev/null || {
        log_warn "Could not gather live facts, using cached facts if available"
    }

    if [[ -z "$(ls -A "$FACTS_DIR" 2>/dev/null)" ]]; then
        log_error "No facts available. Run a playbook first or check inventory."
        exit 1
    fi

    log_success "Facts gathered successfully"
}

# Generate CMDB HTML
generate_cmdb() {
    log_info "Generating CMDB dashboard..."

    mkdir -p "$OUTPUT_DIR"

    # Generate HTML with ansible-cmdb
    ansible-cmdb \
        --template html_fancy \
        --columns name,os,ip,arch,mem,cpus,virt,disk_usage \
        "$FACTS_DIR" > "${OUTPUT_DIR}/index.html"

    log_success "Dashboard generated: ${OUTPUT_DIR}/index.html"
}

# Generate summary JSON for API consumption
generate_summary() {
    log_info "Generating summary data..."

    ansible-cmdb \
        --template json \
        "$FACTS_DIR" > "${OUTPUT_DIR}/inventory.json"

    log_success "Summary JSON: ${OUTPUT_DIR}/inventory.json"
}

# Main
main() {
    print_header

    check_dependencies
    gather_facts
    generate_cmdb
    generate_summary

    echo ""
    log_success "CMDB dashboard generated successfully!"
    echo ""
    echo -e "  ${CYAN}→${NC} HTML Dashboard: ${OUTPUT_DIR}/index.html"
    echo -e "  ${CYAN}→${NC} JSON Data:      ${OUTPUT_DIR}/inventory.json"
    echo ""
    echo -e "  Open in browser: ${CYAN}xdg-open ${OUTPUT_DIR}/index.html${NC}"
    echo ""
}

main "$@"
