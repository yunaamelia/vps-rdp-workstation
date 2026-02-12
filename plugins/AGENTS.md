# COMPONENT: PYTHON CALLBACKS

**Purpose**: Custom Ansible stdout callback plugins for rich execution output.

## KEY FILES
- `callback/clean_progress.py`: Minimalist text-only icons (✓/✗). Low-dependency fallback.
- `callback/rich_tui.py`: Full TUI with spinners, tables, colors. Requires `rich` library.

## CONVENTIONS
- **Inheritance**: MUST inherit from `CallbackBase`.
- **Documentation**: MUST include a `DOCUMENTATION` YAML block (Ansible autodiscovery).
- **Redaction**: Handle `vps_user_password_hash` to prevent secret leakage in TUI/logs.
- **Performance**: Keep logic lightweight; callbacks run in main Ansible thread.
- **Degradation**: Gracefully fallback if external libs (e.g., `rich`) are missing.

## INTEGRATION
- **Selection**: `setup.sh` sets `ANSIBLE_STDOUT_CALLBACK` env var based on `--tui`/`--minimal` flags.
- **Path Resolution**: `ansible.cfg` points `callback_plugins` to `plugins/callback/`.
- **pipx Gotcha**: When Ansible installed via `pipx`, plugin path may not resolve — `setup.sh` handles injection.

## ANTI-PATTERNS
- **Blocking**: No network/heavy I/O inside callback methods.
- **Stdout Noise**: Strictly format or swallow unrestricted stdout.
- **Direct Import**: Never import `rich` at module level; wrap in try/except.
