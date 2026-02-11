# COMPONENT: PYTHON CALLBACKS

**Purpose**: Enhance Ansible stdout with TUI/Clean formatting.

## STRUCTURE
```
plugins/
└── callback/
    ├── rich_tui.py       # Heavy: Spinners, tables, colors (requires 'rich')
    └── clean_progress.py # Light: Text-only icons (✓/✗)
```

## CONVENTIONS
*   **Hooking**: Uses Ansible Callback API (`v2_runner_on_start`, etc.).
*   **Degradation**: `rich_tui.py` falls back gracefully if `rich` lib missing.
*   **Performance**: Callbacks run in main thread. Keep logic lightweight.

## ANTI-PATTERNS
*   **Blocking Ops**: No network/heavy I/O in callback methods.
*   **Stdout Noise**: Do not print unrestricted stdout; strictly format or swallow.
