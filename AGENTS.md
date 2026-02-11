# Project Context: VPS RDP Workstation

## System Architecture
**Stack**: Ansible Core + Mitogen (accelerator) + ARA (reporter).
**Target**: Debian 13 "Trixie" (Strict requirement).
**Entry Point**: `./setup.sh` (Bash wrapper). **DO NOT** run `ansible-playbook` directly for deployments; the wrapper handles secret hashing and library injection.

## Critical Workflows
- **Deploy**: `./setup.sh` (Interactive) or `VPS_USERNAME=u VPS_SECRETS_FILE=f ./setup.sh --ci` (CI).
- **Validation**: `./tests/validate.sh` checks 30 success criteria (functional/security).
- **Dry Run**: `./setup.sh --dry-run` (Safe preview).
- **Resume**: `./setup.sh --resume` (Uses `/var/lib/vps-setup/progress.json`).

## Security Constraints
- **Secrets**: NEVER store plaintext passwords in variables. `setup.sh` hashes inputs (SHA-512) -> exports `VPS_USER_PASSWORD_HASH` -> Ansible consumes hash.
- **Logs**: Tasks handling secrets MUST use `no_log: true`.
- **SSH**: Root login disabled by default.
- **Firewall**: `security` role MUST run before any service-exposing role (`desktop`, `docker`).

## Development Rules
- **Formatting**: `yamllint` (180 char line limit), `ansible-lint`.
- **Idempotency**: All tasks must be re-runnable without side effects.
- **State**: Check `check_mode: false` carefully; only allowed for critical setup (backup dirs) or read-only API calls.
- **Commits**: Run `pre-commit run --all-files` before pushing.

## Directory Map
- `setup.sh`: **MASTER CONTROL**. Env setup, validation, orchestration.
- `roles/`: 23+ configuration units. See `roles/AGENTS.md`.
- `playbooks/`: Orchestration logic. See `playbooks/AGENTS.md`.
- `plugins/`: Custom Python callbacks. See `plugins/AGENTS.md`.
- `inventory/`: `group_vars/all.yml` holds ALL tunable knobs.
