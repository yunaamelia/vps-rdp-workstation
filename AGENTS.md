# PROJECT KNOWLEDGE BASE

**Generated:** Wed Feb 18 07:37:19 AM UTC 2026
**Commit:** 211a454
**Branch:** main

**Scope**: Ansible IaC — Debian 13 VPS → security-hardened RDP developer workstation.

## STRUCTURE
```
vps-rdp-workstation/
├── setup.sh              # CANONICAL ENTRY POINT. Handles secrets, Mitogen, validation.
├── ansible.cfg           # Pipelining, Mitogen, ARA.
├── inventory/            # Hosts and group_vars (configuration root).
├── playbooks/            # 10-phase orchestration logic.
├── roles/                # 25 independent functional units.
├── plugins/              # Custom callback/strategy plugins (Python).
├── molecule/             # Container-based testing scenarios.
└── tests/                # Shell-based validation scripts.
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Add Feature** | `roles/<new_role>` | Create role, add to `playbooks/main.yml`. |
| **Change Config** | `inventory/group_vars/all.yml` | Global variables (prefixed `vps_`). |
| **Test** | `molecule/default/` | Run `molecule test` for full verification. |
| **Debug** | `/var/log/vps-setup.log` | Full execution log on target. |

## EXECUTION ORDER
1. common → 2. security → 3. fonts → 4. desktop → 5. xrdp → 6. kde-optimization → 7. kde-apps →
8. whitesur-theme → 9. terminal → 10. shell-styling → 11. zsh-enhancements → 12. development →
13. docker → 14. editors → 15-25. specialized tool roles.

## CONVENTIONS
*   **Wrapper**: ALWAYS use `setup.sh`. Skips direct `ansible-playbook`.
*   **Vars**: Prefix `vps_<role>_`. `vps_username` for system-wide.
*   **FQCN**: Mandatory `ansible.builtin.*`.
*   **Idempotency**: Safe for repeat runs.
*   **Security**: MUST run before service exposure.

## PYTHON PLUGINS
### OVERVIEW
Custom Ansible plugins extending core functionality, primarily focused on rich TUI output and execution analytics.

### KEY FILES
*   `plugins/callback/clean_progress.py`: Minimalist stdout callback with unicode spinners.
*   `plugins/callback/rich_tui.py`: Advanced layout-based TUI using the `rich` library.

### CONVENTIONS
*   **Inheritance**: MUST inherit from `ansible.plugins.callback.CallbackBase`.
*   **Metadata**: Required `DOCUMENTATION` string (YAML) and `CALLBACK_VERSION = 2.0`.
*   **Safety**: Use `try/except` for third-party imports (e.g., `rich`) with mock fallbacks to prevent Ansible crashes.
*   **Threading**: Callbacks are thread-safe by design in Ansible, but avoid shared mutable state between tasks.

### ANTI-PATTERNS
*   **Blocking I/O**: NEVER perform synchronous network requests or heavy disk I/O in `v2_runner_*` methods.
*   **Direct Imports**: Do not import `rich` or `prettytable` at the top level without a safety wrapper.
*   **Verbosity**: Plugins should respect `ansible_verbosity` levels or custom `VPS_LOG_LEVEL`.

## ANTI-PATTERNS
*   **Plaintext**: NEVER store passwords in vars/logs.
*   **Root Login**: Disabled by default.
*   **Hardcoded Users**: Use `{{ vps_username }}` only.
*   **Manual Changes**: Do not modify `/usr` directly; use config files in `/etc`.

## UNIQUE PATTERNS
*   **Mitogen**: Strategy injection for 2-7x speedup.
*   **ARA**: Auto-recording runs to SQLite.
*   **Progress**: `/var/lib/vps-setup/progress.json` for `--resume`.
*   **Callbacks**: Custom Python callbacks for rich TUI output (`plugins/callback`).
