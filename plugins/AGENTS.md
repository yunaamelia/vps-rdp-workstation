# COMPONENT: PYTHON PLUGINS

**Scope**: Custom Ansible callbacks + vendored Mitogen strategy.

## KEY FILES

| File                         | Purpose                                              |
| ---------------------------- | ---------------------------------------------------- |
| `callback/clean_progress.py` | Minimalist. Unicode ✓/✗ icons. Low-dependency.       |
| `callback/rich_tui.py`       | Full TUI. Spinners, tables, colors. Requires `rich`. |
| `mitogen/`                   | Vendored v0.3.21 for 2-7x execution speedup.         |

## CONVENTIONS

- **Inheritance**: MUST inherit from `ansible.plugins.callback.CallbackBase`.
- **Documentation**: MUST include `DOCUMENTATION` YAML block for autodiscovery.
- **Redaction**: Handle `vps_user_password_hash` to prevent secret leakage.
- **Degradation**: Wrap `rich` imports in try/except for fallback.
- **Threading**: Callbacks run in main Ansible thread; keep lightweight.

## INTEGRATION

- **Selection**: `setup.sh` sets `ANSIBLE_STDOUT_CALLBACK` via `--tui`/`--minimal` flags.
- **Path**: `ansible.cfg` points `callback_plugins` to `plugins/callback/`.
- **pipx Injection**: `setup.sh` injects `rich` into pipx-managed Ansible environments.

## ANTI-PATTERNS

- **Blocking I/O**: NEVER synchronous network/disk I/O in callback methods.
- **Direct Import**: Never import `rich` at module level; wrap in try/except.
- **Stdout Noise**: Strictly format or swallow unrestricted stdout.
- **Module-Level State**: Avoid shared mutable state between tasks.

[Root Guidelines](../AGENTS.md)
