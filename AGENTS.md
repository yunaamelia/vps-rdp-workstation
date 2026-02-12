# Project Knowledge Base

**Generated:** 2026-02-12
**Scope:** Ansible IaC — Debian 13 VPS → security-hardened RDP developer workstation.

## OVERVIEW
Single-purpose automation: transforms a fresh Debian 13 (Trixie) VPS into a fully configured KDE Plasma RDP workstation with 50+ dev tools, security hardening, and beautiful logging. ~21k lines across 626 files.

## STRUCTURE
```
.
├── setup.sh*             # CANONICAL ENTRY POINT (secrets + mitogen + validation)
├── ansible.cfg           # Pipelining, Mitogen strategy, ARA callback, log paths
├── playbooks/            # Orchestration: main.yml (10-phase), rollback.yml
├── roles/                # 25 flat roles (tasks → defaults → handlers → templates → meta)
├── plugins/              # Python callbacks: clean_progress.py, rich_tui.py
├── tests/                # validate.sh (30+ criteria), remote_test.sh, molecule/
├── inventory/            # hosts.yml + group_vars/all.yml (variable hierarchy root)
├── scripts/              # Helper scripts (grapher, reporting)
├── docs/                 # Guides (Starship optimization, architecture)
└── gitops-repo/          # Embedded K8s manifests (ArgoCD, monitoring)
```

## EXECUTION ORDER (CRITICAL)
```
1. common → 2. security → 3. fonts → 4. desktop → 5. xrdp → 6. kde-optimization → 7. kde-apps → 
8. catppuccin-theme → 9. terminal → 10. shell-styling → 11. zsh-enhancements → 12. development → 
13. docker → 14. editors → 15-25. tool roles (tui-tools, network-tools, system-performance, 
text-processing, file-management, dev-debugging, code-quality, productivity, log-visualization, 
ai-devtools, cloud-native)
```
Security ALWAYS before service exposure. `common` cannot be skipped.

## WHERE TO LOOK
| Task | Location |
|------|----------|
| **Deploy** | `./setup.sh` (NEVER `ansible-playbook` directly) |
| **Orchestrate** | `playbooks/main.yml` |
| **Configure vars** | `inventory/group_vars/all.yml` |
| **Role defaults** | `roles/<name>/defaults/main.yml` |
| **Validate** | `tests/validate.sh` (runs ON target) |
| **UI callbacks** | `plugins/callback/` |
| **CI pipeline** | `.github/workflows/ci.yml` (lint → dry-run → molecule) |

## CONVENTIONS
*   **Wrapper Mandate**: ALWAYS use `setup.sh`. It handles secret hashing, Mitogen injection, and environment validation.
*   **Variable Namespace**: `vps_<role>_` prefix convention (e.g., `vps_docker_install`, `vps_development_install_nodejs`, `vps_terminal_install_kitty`). Shared system variables use `vps_` prefix only (e.g., `vps_username`, `vps_timezone`, `vps_default_font_size`).
*   **FQCN Required**: Always `ansible.builtin.*`, `community.general.*`. No short module names.
*   **Tags Schema**: `[phase, role, feature]` — e.g., `[desktop, kde, optimization]`.
*   **Idempotency**: Every task safe for repeated runs. Test by running twice.
*   **Check Mode**: All roles MUST support `--check --diff`.
*   **Secret Handling**: `no_log: true` on any task touching `vps_user_password_hash`.
*   **YAML Style**: 2-space indent, expanded map syntax, single quotes (double only for escapes/Jinja).
*   **Block/Rescue**: Critical roles (common, security, desktop, xrdp, docker) include error handling.

## ANTI-PATTERNS
*   **Direct `ansible-playbook`**: Skips secret hashing + Mitogen + validation.
*   **Plaintext secrets**: Never in vars, inventory, or logs.
*   **Root login**: `vps_ssh_root_login: false` by default. Override only in inventory.
*   **Reordering roles**: Security before services is load-bearing.
*   **Global handlers**: Keep handlers within their role.
*   **Hardcoded users**: Always `{{ vps_username }}`, never `root` or UID 1000.
*   **`curl | bash`**: Clone repos, inspect, then `ansible.builtin.command`.

## UNIQUE PATTERNS
*   **Mitogen**: Dynamic strategy plugin injection for 2-7x speedup.
*   **ARA Reporting**: Every run auto-recorded to SQLite. View: `ara playbook list`.
*   **Progress Tracking**: JSON state at `/var/lib/vps-setup/progress.json` — enables `--resume`.
*   **Dual Callbacks**: `clean_progress.py` (minimal) vs `rich_tui.py` (full TUI). Selected by `setup.sh`.
*   **Pre-commit**: ansible-lint + shellcheck + yamllint enforced.

## COMMANDS
```bash
# Standard deploy
./setup.sh

# CI/CD (non-interactive)
VPS_USERNAME=dev VPS_SECRETS_FILE=./secrets ./setup.sh --ci

# Dry run
./setup.sh --dry-run

# Specific roles only
./setup.sh -- --tags security,desktop

# Validate installation
./tests/validate.sh

# Lint
yamllint . && ansible-lint playbooks/ roles/
```

## VARIABLE HIERARCHY
Role defaults → `group_vars/all.yml` → playbook vars → CLI `--extra-vars`

## NOTES
*   **Target**: Debian 13 (Trixie) ONLY. x86_64.
*   **Hardware**: 4GB+ RAM required (8GB recommended for KDE Plasma).
*   **Resume**: `--resume` continues from last failed role via progress.json.
