# ROLE: file-management

**Purpose**: Advanced file managers and navigation tools (ranger, mc, fzf-enhanced).
**Phase**: 15-25

## TASKS

- `main.yml`: Installs ranger TUI file manager, mc (midnight commander), configures keybindings.
- `uninstall.yml`: Removes ranger and mc, cleans config files from ~/.config.

## VARIABLES

- `vps_file_management_install`: Boolean to enable/disable installation (default: true).
- `vps_file_management_ranger_install`: Install ranger for terminal file browsing (default: true).
- `vps_file_management_mc_install`: Install midnight commander (default: true).
- `vps_file_management_ranger_theme`: Color scheme (default: default).
- `vps_file_management_ranger_preview_images`: Enable image preview support (default: false).

## DEPENDENCIES

- Common (for base packages)
- text-processing (for preview filters like fzf)

## ANTI-PATTERNS

- Installing ranger without image preview handlers (python-ueberzug or similar).
- Overwriting user's custom ranger config without backup.
- Not documenting ranger vs. mc differences for user preference.

[Root Guidelines](../../AGENTS.md)
