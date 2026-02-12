# Project Knowledge Base

**Generated:** 2026-02-12
**Context:** Ansible automation for Debian 13 VPS RDP workstation.

## OVERVIEW
Transforms Debian 13 into a security-hardened RDP workstation. Enforces performance via Mitogen and visibility via ARA reporting.

## STRUCTURE
```
.
├── setup.sh*             # MASTER CONTROL: Mandatory wrapper (Secrets + Mitogen)
├── ansible.cfg           # Config: Pipelining, Mitogen, ARA, Log paths
├── playbooks/            # Orchestration: main.yml, rollback.yml
├── roles/                # Configuration: Flat units (tasks, defaults, meta)
├── plugins/              # Extension: Python callbacks (TUI/Clean output)
├── tests/                # Validation: Molecule, validate.sh
└── inventory/            # Definition: Host vars, group_vars/all.yml
```

## WHERE TO LOOK
| Task | Location |
|------|----------|
| **Deploy** | `./setup.sh` |
| **Orchestrate** | `playbooks/main.yml` |
| **Configure** | `inventory/group_vars/all.yml` |
| **Validate** | `tests/validate.sh` |
| **UI/UX** | `plugins/callback/` |

## CONVENTIONS
*   **Wrapper Mandate**: ALWAYS use `setup.sh`. Never run `ansible-playbook` directly.
*   **Variables**: Namespaced as `vps_<role>_`.
*   **Role Structure**: Flat `roles/` directory.
*   **Secret Handling**: Use `no_log: true` for tasks handling sensitive data.
*   **Idempotency**: All tasks must be safe for repeated execution.

## ANTI-PATTERNS
*   **Direct Execution**: Running `ansible-playbook` skips secret hashing.
*   **Plaintext Secrets**: Storing passwords in vars or inventory.
*   **Root Access**: Enabling root login (use `vps_ssh_root_login` to control).
*   **Out-of-Order**: Running services before security hardening.

## UNIQUE STYLES
*   **Mitogen**: Dynamic injection for 2-7x execution speedup.
*   **ARA Reporting**: Automatic run history recorded to SQLite.
*   **Progress Tracking**: JSON state at `/var/lib/vps-setup/progress.json`.

## COMMANDS
```bash
# Standard Deployment
./setup.sh

# CI/CD (Non-Interactive)
VPS_USERNAME=dev VPS_SECRETS_FILE=./secrets ./setup.sh --ci

# Dry Run
./setup.sh --dry-run

# Validation
./tests/validate.sh
```

## NOTES
*   **Target**: Debian 13 (Trixie) ONLY.
*   **Hardware**: 4GB+ RAM required for KDE Plasma.
*   **Resume**: Use `--resume` to continue from last failed role.
