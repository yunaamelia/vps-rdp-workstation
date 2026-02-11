# Test & Validation Knowledge Base

**Context:** Quality Assurance for VPS RDP Workstation automation.
**Focus:** Integration testing, success criteria validation, and remote deployment verification.

## STRUCTURE
```
tests/
├── validate.sh*          # PRIMARY: 30-point local success criteria check.
├── remote_test.sh*       # CI: Orchestrates remote VPS deployment & rollback.
├── strict_vars.yml       # Config: Strict variable definitions for testing.
├── integration/          # (Reserved) Future integration test suites.
└── unit/                 # (Reserved) Future unit test suites.
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Verify Install** | `./validate.sh` | Checks 30 items: FR (Functional), SR (Security), QR (Quality), DR (Docs). |
| **Remote CI** | `./remote_test.sh` | **DANGEROUS**. Wipes target dir, runs rollback, then clean install. |
| **Criteria List** | `validate.sh` | See lines 100+ for the exact commands used to verify success. |

## CONVENTIONS
*   **Color Output**: Scripts use ANSI colors (Green=Pass, Red=Fail, Yellow=Warn).
*   **Fail Fast**: `set -euo pipefail` is mandatory for logic scripts.
*   **Idempotency**: Validation checks must be read-only (e.g., `systemctl is-active`, `grep -q`).
*   **Categories**: Tests are grouped by type (Functional, Security, Quality, Documentation).

## ANTI-PATTERNS
*   **Hardcoded Secrets**: `remote_test.sh` currently contains hardcoded credentials. **DO NOT COMMIT** real secrets.
*   **Production Use**: `remote_test.sh` runs a rollback (cleanup) first. **NEVER** run this on a live user machine.
*   **Partial Validation**: `validate.sh` must pass ALL critical checks (exit code 0) for a release to be valid.

## COMMANDS
```bash
# Run local validation (on the VPS)
./tests/validate.sh

# Run remote integration test (from local dev machine)
# WARNING: Wipes target VPS.
./tests/remote_test.sh
```
