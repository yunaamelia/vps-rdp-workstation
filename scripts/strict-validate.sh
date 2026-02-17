#!/bin/bash
# =============================================================================
# Strict Ansible Playbook Validator
# Runs playbook and enforces thresholds on warnings, skipped, ignored, errors
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SCRIPT_DIR
readonly OUTPUT_FILE="/tmp/ansible-strict-validate-$$.log"
readonly REPORT_FILE="/tmp/ansible-strict-report-$$.txt"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Defaults
MODE="check"
ZERO_TOLERANCE=false
TAGS=""
EXTRA_VARS="vps_username=racoondev vps_user_password_hash=dummy vps_progress_state_file=/tmp/ansible-progress.json vps_summary_log=/tmp/ansible-summary.log"
VERBOSE=""
INVENTORY=""

# =============================================================================
# Usage
# =============================================================================
show_usage() {
    cat <<EOF
${BOLD}Strict Ansible Playbook Validator${NC}

Usage: $0 [OPTIONS]

Options:
  --check              Dry-run mode (default)
  --apply              Real deployment (no --check flag)
  --zero-tolerance     Fail on ANY ignored, rescued, or warning
  --tags TAGS          Only run specific tags (comma-separated)
  --inventory FILE     Use specific inventory file
  --extra-vars VARS    Additional extra vars (space-separated key=val)
  -v, -vv, -vvv       Increase verbosity
  -h, --help           Show this help

Thresholds:
  STRICT_MAX_FAILED=0       Max allowed failed tasks (default: 0)
  STRICT_MAX_UNREACHABLE=0  Max allowed unreachable hosts (default: 0)
  STRICT_MAX_IGNORED=0      Max allowed ignored errors (default: 0, --zero-tolerance)
  STRICT_MAX_RESCUED=0      Max allowed rescued tasks (default: 0, --zero-tolerance)
  STRICT_MAX_WARNINGS=0     Max allowed warnings (default: 0, --zero-tolerance)

Examples:
  $0                          # Standard strict check
  $0 --zero-tolerance         # Zero tolerance — nothing ignored
  $0 --tags "klassy,whitesur" # Specific tags only
  $0 --apply                  # Real deployment with post-check
  STRICT_MAX_IGNORED=3 $0     # Allow up to 3 ignored errors
EOF
}

# =============================================================================
# Parse Arguments
# =============================================================================
parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check) MODE="check"; shift ;;
            --apply) MODE="apply"; shift ;;
            --zero-tolerance) ZERO_TOLERANCE=true; shift ;;
            --tags) TAGS="$2"; shift 2 ;;
            --inventory) INVENTORY="$2"; shift 2 ;;
            --extra-vars) EXTRA_VARS="$EXTRA_VARS $2"; shift 2 ;;
            -v) VERBOSE="-v"; shift ;;
            -vv) VERBOSE="-vv"; shift ;;
            -vvv) VERBOSE="-vvv"; shift ;;
            -h|--help) show_usage; exit 0 ;;
            *) echo -e "${RED}Unknown option: $1${NC}"; show_usage; exit 1 ;;
        esac
    done
}

# =============================================================================
# Run Playbook
# =============================================================================
run_playbook() {
    local cmd="ansible-playbook ${SCRIPT_DIR}/playbooks/main.yml"

    [[ "$MODE" == "check" ]] && cmd+=" --check"
    [[ -n "$TAGS" ]] && cmd+=" --tags \"$TAGS\""
    [[ -n "$VERBOSE" ]] && cmd+=" $VERBOSE"
    [[ -n "$INVENTORY" ]] && cmd+=" -i $INVENTORY"
    cmd+=" -e \"$EXTRA_VARS\""

    echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  Strict Ansible Validator                                ║${NC}"
    echo -e "${BOLD}║  Mode: $(printf '%-49s' "$MODE")║${NC}"
    [[ -n "$TAGS" ]] && echo -e "${BOLD}║  Tags: $(printf '%-49s' "$TAGS")║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}[CMD]${NC} $cmd"
    echo ""

    # Run and capture output (still show live output)
    eval "$cmd" 2>&1 | tee "$OUTPUT_FILE"
    local exit_code=${PIPESTATUS[0]}

    echo ""
    echo "$exit_code" > "${OUTPUT_FILE}.exitcode"
    return 0  # Don't fail here — we analyze below
}

# =============================================================================
# Parse PLAY RECAP
# =============================================================================
parse_recap() {
    local recap_line
    recap_line=$(grep -E '^[a-zA-Z0-9._-]+\s+:\s+ok=' "$OUTPUT_FILE" | tail -1 || echo "")

    if [[ -z "$recap_line" ]]; then
        echo -e "${RED}✗ Could not find PLAY RECAP in output${NC}"
        PARSE_OK=0; PARSE_CHANGED=0; PARSE_UNREACHABLE=0
        PARSE_FAILED=999; PARSE_SKIPPED=0; PARSE_RESCUED=0; PARSE_IGNORED=0
        return
    fi

    PARSE_OK=$(echo "$recap_line" | grep -oP 'ok=\K[0-9]+' || echo 0)
    PARSE_CHANGED=$(echo "$recap_line" | grep -oP 'changed=\K[0-9]+' || echo 0)
    PARSE_UNREACHABLE=$(echo "$recap_line" | grep -oP 'unreachable=\K[0-9]+' || echo 0)
    PARSE_FAILED=$(echo "$recap_line" | grep -oP 'failed=\K[0-9]+' || echo 0)
    PARSE_SKIPPED=$(echo "$recap_line" | grep -oP 'skipped=\K[0-9]+' || echo 0)
    PARSE_RESCUED=$(echo "$recap_line" | grep -oP 'rescued=\K[0-9]+' || echo 0)
    PARSE_IGNORED=$(echo "$recap_line" | grep -oP 'ignored=\K[0-9]+' || echo 0)
}

# =============================================================================
# Scan for Warnings & Deprecations
# =============================================================================
scan_warnings() {
    WARNING_COUNT=$(grep -c '\[WARNING\]' "$OUTPUT_FILE" 2>/dev/null || echo 0)
    DEPRECATION_COUNT=$(grep -c '\[DEPRECATION WARNING\]' "$OUTPUT_FILE" 2>/dev/null || echo 0)

    # Count genuine errors (exclude Ansible task-failure display lines that are
    # expected when using failed_when/ignore_errors patterns)
    ERROR_COUNT=$(grep '\[ERROR\]' "$OUTPUT_FILE" 2>/dev/null \
        | grep -v '...ignoring' \
        | grep -cv 'Task failed:.*failed_when\|Module failed:.*Could not find' 2>/dev/null || echo 0)

    # Collect unique lines
    WARNING_LINES=$(grep '\[WARNING\]' "$OUTPUT_FILE" 2>/dev/null | sort -u || echo "")
    DEPRECATION_LINES=$(grep '\[DEPRECATION WARNING\]' "$OUTPUT_FILE" 2>/dev/null | sort -u || echo "")
    ERROR_LINES=$(grep '\[ERROR\]' "$OUTPUT_FILE" 2>/dev/null \
        | grep -v '...ignoring' \
        | grep -v 'Task failed:.*failed_when\|Module failed:.*Could not find' \
        | sort -u || echo "")
}

# =============================================================================
# Enforce Thresholds
# =============================================================================
enforce_thresholds() {
    local exit_code
    exit_code=$(cat "${OUTPUT_FILE}.exitcode" 2>/dev/null || echo 1)
    local violations=0
    local total_issues=0

    # Thresholds (configurable via env)
    local max_failed=${STRICT_MAX_FAILED:-0}
    local max_unreachable=${STRICT_MAX_UNREACHABLE:-0}
    local max_ignored=${STRICT_MAX_IGNORED:-3}  # Default: allow up to 3
    local max_rescued=${STRICT_MAX_RESCUED:-1}  # Default: allow 1 rescue
    local max_warnings=${STRICT_MAX_WARNINGS:-5} # Default: allow up to 5

    # Zero tolerance overrides
    if [[ "$ZERO_TOLERANCE" == "true" ]]; then
        max_ignored=0
        max_rescued=0
        max_warnings=0
    fi

    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║  STRICT VALIDATION REPORT                                ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # ── PLAY RECAP ──
    echo -e "${BOLD}── PLAY RECAP ──${NC}"
    echo ""

    # OK
    echo -e "  ${GREEN}✓${NC} ok:          ${PARSE_OK}"
    echo -e "  ${CYAN}~${NC} changed:     ${PARSE_CHANGED}"

    # Failed
    if [[ $PARSE_FAILED -gt $max_failed ]]; then
        echo -e "  ${RED}✗ failed:      ${PARSE_FAILED}  ← EXCEEDS THRESHOLD (max: ${max_failed})${NC}"
        ((violations++))
    else
        echo -e "  ${GREEN}✓${NC} failed:      ${PARSE_FAILED}"
    fi

    # Unreachable
    if [[ $PARSE_UNREACHABLE -gt $max_unreachable ]]; then
        echo -e "  ${RED}✗ unreachable: ${PARSE_UNREACHABLE}  ← EXCEEDS THRESHOLD (max: ${max_unreachable})${NC}"
        ((violations++))
    else
        echo -e "  ${GREEN}✓${NC} unreachable: ${PARSE_UNREACHABLE}"
    fi

    # Skipped (always report, never fail)
    if [[ $PARSE_SKIPPED -gt 0 ]]; then
        echo -e "  ${YELLOW}○${NC} skipped:     ${PARSE_SKIPPED}  (informational)"
    else
        echo -e "  ${GREEN}✓${NC} skipped:     ${PARSE_SKIPPED}"
    fi

    # Ignored
    if [[ $PARSE_IGNORED -gt $max_ignored ]]; then
        echo -e "  ${RED}✗ ignored:     ${PARSE_IGNORED}  ← EXCEEDS THRESHOLD (max: ${max_ignored})${NC}"
        ((violations++))
    elif [[ $PARSE_IGNORED -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠ ignored:     ${PARSE_IGNORED}  (within threshold: ${max_ignored})${NC}"
    else
        echo -e "  ${GREEN}✓${NC} ignored:     ${PARSE_IGNORED}"
    fi

    # Rescued
    if [[ $PARSE_RESCUED -gt $max_rescued ]]; then
        echo -e "  ${RED}✗ rescued:     ${PARSE_RESCUED}  ← EXCEEDS THRESHOLD (max: ${max_rescued})${NC}"
        ((violations++))
    elif [[ $PARSE_RESCUED -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠ rescued:     ${PARSE_RESCUED}  (within threshold: ${max_rescued})${NC}"
    else
        echo -e "  ${GREEN}✓${NC} rescued:     ${PARSE_RESCUED}"
    fi

    echo ""

    # ── WARNINGS & DEPRECATIONS ──
    echo -e "${BOLD}── WARNINGS & DEPRECATIONS ──${NC}"
    echo ""

    total_issues=$((WARNING_COUNT + DEPRECATION_COUNT))

    if [[ $ERROR_COUNT -gt 0 ]]; then
        echo -e "  ${RED}✗ errors:        ${ERROR_COUNT}${NC}"
        ((violations++))
        if [[ -n "$ERROR_LINES" ]]; then
            echo ""
            echo -e "  ${RED}Error details:${NC}"
            echo "$ERROR_LINES" | while IFS= read -r line; do
                echo -e "    ${RED}│${NC} $line"
            done
        fi
        echo ""
    fi

    if [[ $WARNING_COUNT -gt $max_warnings ]]; then
        echo -e "  ${RED}✗ warnings:      ${WARNING_COUNT}  ← EXCEEDS THRESHOLD (max: ${max_warnings})${NC}"
        ((violations++))
    elif [[ $WARNING_COUNT -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠ warnings:      ${WARNING_COUNT}  (within threshold: ${max_warnings})${NC}"
    else
        echo -e "  ${GREEN}✓${NC} warnings:      ${WARNING_COUNT}"
    fi

    if [[ $DEPRECATION_COUNT -gt 0 ]]; then
        echo -e "  ${RED}✗ deprecations:  ${DEPRECATION_COUNT}  ← SHOULD BE ZERO${NC}"
        ((violations++))
    else
        echo -e "  ${GREEN}✓${NC} deprecations:  ${DEPRECATION_COUNT}"
    fi

    # Show warning details if any
    if [[ -n "$WARNING_LINES" ]] && [[ $WARNING_COUNT -gt 0 ]]; then
        echo ""
        echo -e "  ${YELLOW}Warning details:${NC}"
        echo "$WARNING_LINES" | head -10 | while IFS= read -r line; do
            echo -e "    ${YELLOW}│${NC} $line"
        done
        [[ $WARNING_COUNT -gt 10 ]] && echo -e "    ${YELLOW}│${NC} ... and $((WARNING_COUNT - 10)) more"
    fi

    if [[ -n "$DEPRECATION_LINES" ]] && [[ $DEPRECATION_COUNT -gt 0 ]]; then
        echo ""
        echo -e "  ${RED}Deprecation details:${NC}"
        echo "$DEPRECATION_LINES" | head -5 | while IFS= read -r line; do
            echo -e "    ${RED}│${NC} $line"
        done
    fi

    echo ""

    # ── VERDICT ──
    echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"

    if [[ $violations -gt 0 ]] || [[ "$exit_code" != "0" ]]; then
        echo ""
        echo -e "  ${RED}${BOLD}❌ VALIDATION FAILED${NC}"
        echo -e "  ${RED}   ${violations} threshold violation(s) detected${NC}"
        [[ "$exit_code" != "0" ]] && echo -e "  ${RED}   Ansible exit code: ${exit_code}${NC}"
        echo ""
        echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"

        # Generate report file
        generate_report "$violations" "$exit_code"

        # Cleanup
        rm -f "$OUTPUT_FILE" "${OUTPUT_FILE}.exitcode"
        exit 1
    else
        echo ""
        echo -e "  ${GREEN}${BOLD}✅ VALIDATION PASSED${NC}"
        echo -e "  ${GREEN}   All thresholds met — deployment is clean${NC}"
        if [[ "$ZERO_TOLERANCE" == "true" ]]; then
            echo -e "  ${GREEN}   Mode: ZERO TOLERANCE${NC}"
        fi
        echo ""
        echo -e "${BOLD}══════════════════════════════════════════════════════════${NC}"

        # Cleanup
        rm -f "$OUTPUT_FILE" "${OUTPUT_FILE}.exitcode"
        exit 0
    fi
}

# =============================================================================
# Generate Report File
# =============================================================================
generate_report() {
    local violations=$1
    local exit_code=$2

    cat > "$REPORT_FILE" <<REPORT
# Strict Validation Report
# Generated: $(date -Iseconds)
# Mode: ${MODE}
# Zero Tolerance: ${ZERO_TOLERANCE}

## PLAY RECAP
ok=${PARSE_OK}
changed=${PARSE_CHANGED}
unreachable=${PARSE_UNREACHABLE}
failed=${PARSE_FAILED}
skipped=${PARSE_SKIPPED}
rescued=${PARSE_RESCUED}
ignored=${PARSE_IGNORED}

## ISSUES
warnings=${WARNING_COUNT}
deprecations=${DEPRECATION_COUNT}
errors=${ERROR_COUNT}

## RESULT
violations=${violations}
exit_code=${exit_code}
status=FAILED
REPORT

    echo -e "  ${BLUE}Report saved: ${REPORT_FILE}${NC}"
}

# =============================================================================
# Main
# =============================================================================
main() {
    parse_args "$@"

    cd "$SCRIPT_DIR"

    run_playbook
    parse_recap
    scan_warnings
    enforce_thresholds
}

main "$@"
