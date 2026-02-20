# ROLE: tmux

**Purpose**: Terminal multiplexer for session management and window tiling (tmux).
**Phase**: 15-25

## TASKS

- `main.yml`: Installs tmux, configures keybindings, sets up sensible defaults.
- `uninstall.yml`: Removes tmux, preserves user's ~/.tmux.conf for restoration.

## VARIABLES

- `vps_tmux_install`: Boolean to enable/disable installation (default: true).
- `vps_tmux_config_theme`: Color scheme preference (default: dark).
- `vps_tmux_enable_mouse`: Enable mouse support in tmux (default: true).
- `vps_tmux_prefix_key`: Custom prefix key binding (default: C-b, suggest C-a for vim users).
- `vps_tmux_enable_plugins`: Install tpm (tmux plugin manager) (default: true).

## DEPENDENCIES

- Common (for base packages)
- terminal (for terminal emulator compatibility)

## ANTI-PATTERNS

- Overwriting user's existing tmux config without backup.
- Setting prefix key that conflicts with shell keybindings.
- Installing plugins (tpm) without documenting activation steps.

[Root Guidelines](../../AGENTS.md)
