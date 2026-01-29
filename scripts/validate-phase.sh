#!/bin/bash
#===============================================================================
# Validate Phase - Framework for running phase validation tests
#===============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
TESTS_DIR="$PROJECT_DIR/tests"

source "$SCRIPT_DIR/utils/logger.sh" 2>/dev/null || true
source "$SCRIPT_DIR/utils/state-tracker.sh" 2>/dev/null || true

validate_phase() {
    local phase="$1"
    local test_script="$TESTS_DIR/phase${phase}-tests.sh"
    
    log_info "Validating Phase $phase..."
    
    if [ ! -f "$test_script" ]; then
        log_warn "No test script found for Phase $phase: $test_script"
        return 0
    fi
    
    if [ ! -x "$test_script" ]; then
        chmod +x "$test_script"
    fi
    
    if bash "$test_script"; then
        log_success "Phase $phase validation PASSED"
        complete_phase "$phase"
        return 0
    else
        log_error "Phase $phase validation FAILED"
        fail_phase "$phase" "Validation tests failed"
        return 1
    fi
}

validate_all() {
    local failed=0
    
    for phase in 1 2 3 4 5 6 7; do
        local test_script="$TESTS_DIR/phase${phase}-tests.sh"
        if [ -f "$test_script" ]; then
            log_info "Running Phase $phase tests..."
            if ! bash "$test_script"; then
                ((failed++))
                log_error "Phase $phase tests failed"
            fi
        fi
    done
    
    # Run comprehensive validation
    if [ -f "$TESTS_DIR/comprehensive-validation.sh" ]; then
        log_info "Running comprehensive validation..."
        if ! bash "$TESTS_DIR/comprehensive-validation.sh"; then
            ((failed++))
        fi
    fi
    
    if [ $failed -eq 0 ]; then
        log_success "All validations PASSED"
        return 0
    else
        log_error "$failed phase(s) failed validation"
        return 1
    fi
}

# Main
main() {
    local action="${1:-help}"
    
    case "$action" in
        [1-8])
            validate_phase "$action"
            ;;
        all)
            validate_all
            ;;
        comprehensive)
            if [ -f "$TESTS_DIR/comprehensive-validation.sh" ]; then
                bash "$TESTS_DIR/comprehensive-validation.sh"
            else
                log_error "Comprehensive validation script not found"
                exit 1
            fi
            ;;
        help|*)
            echo "Usage: $0 <phase-number|all|comprehensive>"
            echo ""
            echo "Options:"
            echo "  1-8             Validate specific phase"
            echo "  all             Run all phase validations"
            echo "  comprehensive   Run comprehensive validation only"
            echo ""
            ;;
    esac
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    main "$@"
fi
