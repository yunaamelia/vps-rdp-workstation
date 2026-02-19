#!/bin/bash
# Molecule Test Debugging Helper Script
# Quick diagnostic commands for investigating test failures

set -euo pipefail

BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BOLD}=== Molecule Test Debugging Helper ===${NC}\n"

# Function to print section headers
section() {
    echo -e "\n${BOLD}${BLUE}### $1 ###${NC}"
}

# Function to run command with label
run_cmd() {
    local label="$1"
    shift
    echo -e "${YELLOW}Running:${NC} $label"
    "$@" || echo -e "${RED}Command failed (non-fatal)${NC}"
    echo ""
}

# Check if we're in the right directory
if [[ ! -f "molecule/default/verify.yml" ]]; then
    echo -e "${RED}Error: Must be run from project root${NC}"
    exit 1
fi

section "1. Test Log Analysis"
run_cmd "Find recent test logs" ls -lht *.log 2>/dev/null | head -10
run_cmd "Count failures in logs" grep -c "FAILED\|fatal:" *.log 2>/dev/null || echo "No critical failures found"

section "2. Molecule Status"
run_cmd "List active instances" molecule list
run_cmd "Check Docker containers" docker ps -a | grep -E "molecule|NAME"

section "3. Last Test Results"
if [[ -f molecule_test_output.log ]]; then
    echo -e "${YELLOW}Last test summary:${NC}"
    grep "Molecule executed\|PLAY RECAP" molecule_test_output.log | tail -10
else
    echo "No test output found"
fi

section "4. Common Failure Patterns"
echo -e "${YELLOW}Checking for known issues...${NC}\n"

# Check for race conditions
if grep -q "getent.*failed" *.log 2>/dev/null; then
    echo -e "${RED}⚠ Race condition detected: User check before DB sync${NC}"
    echo "  Fix: Add wait_for task before user check"
fi

# Check for undefined variables
if grep -q "is undefined" *.log 2>/dev/null; then
    echo -e "${RED}⚠ Undefined variable error found${NC}"
    echo "  Fix: Check verify.yml for variable references without registration"
fi

# Check for wrong expectations
if grep -q "Hostname not set correctly" *.log 2>/dev/null; then
    echo -e "${RED}⚠ Hostname mismatch detected${NC}"
    echo "  Fix: Verify expected hostname matches role configuration"
fi

# Check for package errors
if grep -q "no packages found matching" *.log 2>/dev/null; then
    echo -e "${YELLOW}⚠ Package check failed${NC}"
    echo "  Tip: Check if package is installed or if test is checking wrong package name"
fi

echo ""

section "5. Quick Diagnostics"
echo -e "${YELLOW}Select an action:${NC}"
echo "1) Run full molecule test"
echo "2) Run verify only"
echo "3) Connect to test container"
echo "4) View verify.yml"
echo "5) Check test expectations vs actual state"
echo "6) Analyze specific log file"
echo "7) Clean and restart"
echo "0) Exit"

read -p "Enter choice [0-7]: " choice

case $choice in
    1)
        echo -e "${GREEN}Running full molecule test...${NC}"
        molecule test --scenario-name default
        ;;
    2)
        echo -e "${GREEN}Running verify only...${NC}"
        molecule verify
        ;;
    3)
        echo -e "${GREEN}Connecting to test container...${NC}"
        echo "Run these commands to check state:"
        echo "  cat /etc/hostname"
        echo "  getent passwd testuser"
        echo "  ls -la /etc/xrdp/"
        echo "  dpkg -l | grep -E 'xrdp|kde|plasma'"
        molecule login
        ;;
    4)
        echo -e "${GREEN}Viewing verify.yml...${NC}"
        ${EDITOR:-less} molecule/default/verify.yml
        ;;
    5)
        echo -e "${GREEN}Checking test expectations vs actual state...${NC}"
        echo ""
        echo -e "${BOLD}Expected Values (from verify.yml):${NC}"
        grep -E "that:|fail_msg:" molecule/default/verify.yml | head -20
        echo ""
        echo -e "${BOLD}Actual State (from logs):${NC}"
        grep -E "hostname|testuser|xrdp" *.log 2>/dev/null | tail -20
        ;;
    6)
        echo -e "${GREEN}Available log files:${NC}"
        ls -1 *.log 2>/dev/null
        read -p "Enter log filename: " logfile
        if [[ -f "$logfile" ]]; then
            less "$logfile"
        else
            echo -e "${RED}File not found${NC}"
        fi
        ;;
    7)
        echo -e "${YELLOW}Cleaning up and restarting...${NC}"
        molecule destroy
        echo "Cleanup complete. Run 'molecule test' to start fresh."
        ;;
    0)
        echo "Exiting..."
        ;;
    *)
        echo -e "${RED}Invalid choice${NC}"
        ;;
esac

section "6. Debugging Tips"
cat << 'EOF'

Quick Reference for Common Issues:

1. "User not found" error
   → Add wait_for task before user check
   → Or use retries with until condition

2. "Hostname not set correctly"
   → Check verify.yml line 46 for expected value
   → Compare with common role hostname setting

3. "Package not found"
   → Verify package name is correct
   → Consider checking config file instead of package

4. "Undefined variable"
   → Find where variable should be registered
   → Add task to register it OR remove reference

5. "FAILED - RETRYING" messages
   → This is NORMAL for container startup
   → Not a real failure if it eventually succeeds

6. NPM ENOENT errors
   → Check if failed_when: false is set
   → These are often expected on first check

Commands to remember:
  molecule test              # Full test suite
  molecule converge          # Apply roles only
  molecule verify            # Run tests only
  molecule login             # Interactive debugging
  molecule destroy           # Clean up
  molecule list              # Show instances

For detailed analysis, see:
  TEST_FAILURE_ANALYSIS.md      (Full root cause analysis)
  TEST_DEBUGGING_SUMMARY.md     (Executive summary)
EOF

echo -e "\n${BOLD}${GREEN}=== Debugging Helper Complete ===${NC}\n"
