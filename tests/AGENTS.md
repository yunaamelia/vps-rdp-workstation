# Test & Validation Knowledge Base

**Context:** Validation & Integration testing for Debian 13 RDP workstations.

## KEY FILES
* `validate.sh`: Post-deploy acceptance. 30+ criteria. Runs ON target.
* `remote_test.sh`: Full lifecycle. **DANGEROUS** (hardcoded creds).
* `molecule/`: (If present) Role-level testing.

## CONVENTIONS
* `validate.sh` must run on target machine.
* Verify: Services (XRDP, Docker), Ports (3389), Security (UFW).
* Fail-fast logic; ANSI color output.

## ANTI-PATTERNS
* **Production**: Never run `remote_test.sh` on live environments.
* **CI**: Do not skip validation unless `--skip-validation` is explicit.
* **Secrets**: No plaintext creds in git-tracked files.

## COMMANDS
```bash
# Local acceptance (on VPS)
./tests/validate.sh

# Remote lifecycle (Dev only)
./tests/remote_test.sh
```
