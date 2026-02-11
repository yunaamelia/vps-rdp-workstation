# Role: Shell Styling

**Context:** Delivers Fastfetch, Starship prompt, and a "batteries-included" Zsh configuration.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Install Logic** | `tasks/main.yml` | Fastfetch (deb), Starship (script), config deployment. |
| **Shell Config** | `templates/zshrc.j2` | **Source of Truth** for aliases, exports, and tool integration. |
| **Prompt Config** | `templates/starship.toml.j2` | Custom Starship configuration. |

## CONVENTIONS
*   **Monolithic Template**: `zshrc.j2` is the central brain. It integrates `eza`, `bat`, `fzf`, `zoxide`, `atuin` if present.
*   **Conditional Features**: The Zsh script checks for command existence (e.g., `(( $+commands[fzf] ))`) before enabling integration.
*   **Direct Sourcing**: Plugins are sourced directly from `/home/{{ vps_username }}/.oh-my-zsh/custom/plugins/` for performance, avoiding runtime plugin managers.
*   **Local Overrides**: Supports `~/.zshrc.local` for user-specific customizations not managed by Ansible.

## ANTI-PATTERNS
*   **Runtime Plugin Managers**: Do not use `zplug`, `antigen`, or `oh-my-zsh` bundled logic in the template. We source specific files directly.
*   **Hardcoded Secrets**: Never put API keys in `zshrc.j2`. Use environment variables or `~/.zshrc.local`.
*   **Blocking Operations**: Fastfetch is configured to run only in interactive terminals (`[[ -o interactive ]]`).
