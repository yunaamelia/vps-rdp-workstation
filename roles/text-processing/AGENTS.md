# ROLE: text-processing

**Purpose**: Advanced text filtering and processing tools (ripgrep, fd, jq, yq).
**Phase**: 15-25

## TASKS

- `main.yml`: Installs ripgrep for fast searching, fd for file discovery, jq/yq for JSON/YAML.
- `uninstall.yml`: Removes text processing tools and any shell aliases or completions.

## VARIABLES

- `vps_text_processing_install`: Boolean to enable/disable installation (default: true).
- `vps_text_processing_ripgrep_install`: Install ripgrep (rg) for searching (default: true).
- `vps_text_processing_fd_install`: Install fd for finding files (default: true).
- `vps_text_processing_jq_install`: Install jq for JSON processing (default: true).
- `vps_text_processing_yq_install`: Install yq for YAML processing (default: true).

## DEPENDENCIES

- Common (for base packages)
- None for text processing workflow

## ANTI-PATTERNS

- Installing ripgrep but not updating user's grep aliases to use rg.
- Not documenting ripgrep syntax differences from grep (simpler but different).
- Overriding jq completions if user has existing jq setup.

[Root Guidelines](../../AGENTS.md)
