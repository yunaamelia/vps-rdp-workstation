# Project Knowledge Base

**Generated:** 2026-02-11
**Context:** High-Performance Ansible Automation for VPS RDP Workstations.

## OVERVIEW
Ansible-based automation transforming Debian 13 into a security-hardened RDP developer workstation. Uses a Bash wrapper (`setup.sh`) for secret hashing and Mitogen injection to enforce security and performance.

## STRUCTURE
```
.
├── setup.sh*             # MASTER CONTROL: Wrapper for ansible-playbook (Secrets+Mitogen)
├── ansible.cfg           # Core config: Pipelining, Mitogen, ARA, Log paths
├── playbooks/            # Orchestration logic (main.yml, rollback.yml)
├── roles/                # 23+ configuration units (flat hierarchy)
├── plugins/              # Python callbacks (TUI/Clean output)
├── tests/                # Integration tests (Molecule, validate.sh)
├── inventory/            # Host definitions + Group Vars
└── .github/              # CI Pipelines (Molecule + Linting)
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Deploy** | `./setup.sh` | **MANDATORY ENTRY POINT**. Handles secrets. |
| **Orchestrate** | `playbooks/main.yml` | Defines role order and dependencies. |
| **Configure** | `inventory/group_vars/all.yml` | 220+ tunable knobs. Source of Truth. |
| **Validate** | `tests/validate.sh` | 30-point success criteria check. |
| **UI/UX** | `plugins/callback/` | Custom Python output formatters. |

## CONVENTIONS
*   **Wrapper Mandate**: NEVER run `ansible-playbook` directly. Use `setup.sh` to ensure `vps_user_password_hash` is generated securely.
*   **Role Structure**: Flat `roles/`. Each role has `tasks/`, `defaults/`, `meta/`.
*   **Variables**: Namespaced with `vps_<role>_` prefix. Booleans `install_<feature>` toggle roles.
*   **Idempotency**: All tasks must be safe to re-run.
*   **Check Mode**: Full support for `--check` (dry-run) required.

## ANTI-PATTERNS (THIS PROJECT)
*   **Plaintext Secrets**: NEVER store passwords in vars/inventory. Hash in `setup.sh` only.
*   **Logging Secrets**: Tasks handling sensitive data MUST use `no_log: true`.
*   **Root Login**: Default disabled. `vps_ssh_root_login` controls this.
*   **Reordering Roles**: `security` MUST run before services (`desktop`, `docker`).

## UNIQUE STYLES
*   **Mitogen**: Accelerated transport injected dynamically.
*   **ARA Records**: Execution history recorded to SQLite by default.
*   **Progress Tracking**: JSON state file at `/var/lib/vps-setup/progress.json`.

## COMMANDS
```bash
# Production Deploy
./setup.sh

# CI / Non-Interactive
VPS_USERNAME=user VPS_SECRETS_FILE=./secrets ./setup.sh --ci

# Dry Run (Safe)
./setup.sh --dry-run

# Run Validation
./tests/validate.sh
```

## NOTES
*   **Target**: Debian 13 (Trixie) ONLY.
*   **Memory**: 4GB+ RAM required for KDE Plasma roles.
*   **Recovery**: Use `./setup.sh --resume` to continue from last successful role.
