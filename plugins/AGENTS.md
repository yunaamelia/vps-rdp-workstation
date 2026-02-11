# Component: Plugins (Custom Callbacks)

## Architecture
- **Language**: Python (Ansible Callback API).
- **Purpose**: Overrides standard Ansible stdout to provide a cleaner or richer UI.

## Key Files
- `rich_tui.py`: Heavy. Uses `rich` library. Renders spinners, tables, and colors.
  - **Logic**: Hooks `v2_runner_on_start`, `v2_runner_on_ok`, etc. Swallows standard output.
- `clean_progress.py`: Minimalist. Text-only icons (✓/✗).

## Development Rules
- **Error Handling**: Must gracefully degrade if `rich` is not installed (ImportError handling).
- **Performance**: Avoid heavy computation in callback methods; blocks the playbook main thread.
- **Linting**: Uses `pylint`. Some docstring rules are explicitly disabled in config.
