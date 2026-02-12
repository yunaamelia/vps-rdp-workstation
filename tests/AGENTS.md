# Test & Validation Knowledge Base

**Context:** Validation & integration testing for Debian 13 RDP workstations.

## KEY FILES
* `validate.sh`: Post-deploy acceptance. 30+ criteria. Runs ON target.
* `remote_test.sh`: Full lifecycle over SSH. **DANGEROUS** (hardcoded creds).
* `molecule/`: (If present) Role-level testing via Molecule.

## CI PIPELINE
```
lint (yamllint + ansible-lint + shellcheck) → dry-run (--check --diff) → molecule
```
* CI mode: `VPS_SECRETS_FILE=/root/.secrets ./setup.sh --ci`
* Strict vars toggle: `inventory/group_vars/all.yml` → `vps_strict_mode`

## CONVENTIONS
* `validate.sh` must run on target machine (not controller).
* Verifies: Services (XRDP, Docker), Ports (3389), Security (UFW), User existence.
* Fail-fast logic; ANSI color output; exit code 0/1.
* Second run of full playbook MUST produce zero changes (idempotency gate).

## ANTI-PATTERNS
* **Production**: Never run `remote_test.sh` on live environments.
* **CI**: Do not skip validation unless `--skip-validation` is explicit.
* **Secrets**: No plaintext creds in git-tracked files.
* **Partial Tests**: Always run full validate.sh, not individual checks.

## COMMANDS
```bash
# Local acceptance (on VPS)
./tests/validate.sh

# Remote lifecycle (Dev only)
./tests/remote_test.sh
```
