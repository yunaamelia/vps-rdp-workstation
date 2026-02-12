# Role: Shell Styling

**Context:** Delivers Fastfetch, Starship prompt, and a "batteries-included" Zsh configuration. Phase 4 (Visual).

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Install Logic** | `tasks/main.yml` | Fastfetch (deb), Starship (script), config deployment. |
| **Shell Config** | `templates/zshrc.j2` | **Source of Truth** for aliases, exports, and tool integration. |
| **Prompt Config** | `templates/starship.toml.j2` | Custom Starship configuration. |

## CONVENTIONS
*   **Monolithic Template**: `zshrc.j2` is the central brain. It integrates `eza`, `bat`, `fzf`, `zoxide`, `atuin` if present.
*   **Conditional Features**: Zsh checks for command existence (e.g., `(( $+commands[fzf] ))`) before enabling.
*   **Direct Sourcing**: Plugins sourced directly from `~/.oh-my-zsh/custom/plugins/` — no runtime plugin managers.
*   **Local Overrides**: Supports `~/.zshrc.local` for user-specific customizations not managed by Ansible.
*   **Depends On**: Requires `terminal` role (Zsh + OMZ installed first).

## ANTI-PATTERNS
*   **Runtime Plugin Managers**: Do not use `zplug`, `antigen`, or bundled OMZ logic. We source specific files directly.
*   **Hardcoded Secrets**: Never put API keys in `zshrc.j2`. Use `~/.zshrc.local`.
*   **Blocking Operations**: Fastfetch configured to run only in interactive terminals (`[[ -o interactive ]]`).
