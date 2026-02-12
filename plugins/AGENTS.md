# COMPONENT: PYTHON CALLBACKS

**Purpose**: Python callback plugins for enhancing Ansible stdout.

## KEY FILES
- `callback/clean_progress.py`: Minimalist text-only icons (✓/✗).
- `callback/rich_tui.py`: Rich TUI with spinners, tables, and colors.

## CONVENTIONS
- **Inheritance**: MUST inherit from `CallbackBase`.
- **Documentation**: MUST include a `DOCUMENTATION` YAML block.
- **Redaction**: Handle `vps_user_password_hash` to prevent secret leakage in TUI/logs.
- **Performance**: Keep logic lightweight; callbacks run in main Ansible thread.
- **Degradation**: Gracefully fallback if external libs (e.g., `rich`) are missing.

## INTEGRATION
- **Control**: `setup.sh` sets `ANSIBLE_STDOUT_CALLBACK` based on environment/flags.
- **Isolation**: Note that `pipx` isolation can affect plugin path resolution.

## ANTI-PATTERNS
- **Blocking**: No network/heavy I/O inside callback methods.
- **Stdout Noise**: Strictly format or swallow unrestricted stdout.
