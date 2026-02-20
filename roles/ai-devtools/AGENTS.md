# ROLE: ai-devtools

**Purpose**: AI-assisted development tools for code generation and CLI enhancements.
**Phase**: 14-15

## TASKS

- `main.yml`: Installs aider and shell-gpt from pip, configures API keys via environment.
- `uninstall.yml`: Removes aider and shell-gpt packages, cleans pip cache.

## VARIABLES

- `vps_ai_devtools_install`: Boolean to enable/disable installation (default: true).
- `vps_ai_devtools_aider_install`: Install aider CLI for AI pair programming (default: true).
- `vps_ai_devtools_shell_gpt_install`: Install shell-gpt for bash/zsh assistance (default: true).
- `vps_ai_devtools_api_key`: OpenAI or provider API key (from env or secrets file).

## DEPENDENCIES

- development (Python pip must be available)
- Common (for base system packages)

## ANTI-PATTERNS

- Hardcoding API keys in playbooks — always use environment variables or vault.
- Installing without checking if pip/python3 is available.
- Not documenting that users must set API_KEY environment variable for functionality.

[Root Guidelines](../../AGENTS.md)
