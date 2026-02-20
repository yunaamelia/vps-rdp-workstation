# ROLE: log-visualization

**Purpose**: Log aggregation and visualization tools (lnav, grc for colorized output).
**Phase**: 15-25

## TASKS

- `main.yml`: Installs lnav for structured log navigation, grc for log colorization.
- `uninstall.yml`: Removes lnav, grc, and custom log format configurations.

## VARIABLES

- `vps_log_visualization_install`: Boolean to enable/disable installation (default: true).
- `vps_log_visualization_lnav_install`: Install lnav TUI for log analysis (default: true).
- `vps_log_visualization_grc_install`: Install grc for colorized log output (default: true).
- `vps_log_visualization_lnav_theme`: Color theme preference (default: default).
- `vps_log_visualization_enable_aliases`: Create grc aliases for common commands (default: true).

## DEPENDENCIES

- Common (for base packages)
- None for log visibility workflow

## ANTI-PATTERNS

- Installing lnav without properly formatted log files to parse.
- Overriding grc colorization globally (user may prefer uncolored logs).
- Not documenting that lnav requires specific log format support for full features.

[Root Guidelines](../../AGENTS.md)
