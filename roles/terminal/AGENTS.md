# COMPONENT: Terminal Role — Phase 4 (Visual)

**Context**: Zsh shell + Oh My Zsh + Konsole terminal emulator configuration.

## OVERVIEW
Installs Zsh, clones Oh My Zsh via git (not installer script), configures `.zshrc` (theme, plugins, PATH), sets up Konsole with Catppuccin colorscheme and Hack Nerd Font.

## STRUCTURE
```
roles/terminal/
├── defaults/       # OMZ toggle, theme, plugins list, terminal emulator
├── tasks/          # Zsh → OMZ → .zshrc config → Konsole setup
└── templates/      # konsole-profile.j2 (Catppuccin + font config)
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **OMZ install** | `tasks/main.yml:31-39` | `ansible.builtin.git` clone, depth=1 |
| **.zshrc creation** | `tasks/main.yml:57-68` | `copy` from OMZ template, `force: false` (preserves user edits) |
| **PATH block** | `tasks/main.yml:101-116` | `blockinfile` — npm-global + .local/bin |
| **Konsole colorscheme** | `tasks/main.yml:134-142` | Copies from `catppuccin-theme/files/konsole/` |
| **Konsole profile** | `templates/konsole-profile.j2` | Font, colorscheme, scrollback |

## CONVENTIONS
*   **force: false on .zshrc**: Preserves user modifications. Only writes if file doesn't exist.
*   **Check mode stub**: Creates empty `.zshrc` via `touch` when OMZ not cloned (dry-run safety).
*   **Cross-role dependency**: Konsole colorscheme sourced from `roles/catppuccin-theme/files/konsole/` — conditional on `vps_theme_variant == 'catppuccin-mocha'`.
*   **git safe.directory**: Adds OMZ path to git `safe.directory` to avoid ownership warnings.

## ANTI-PATTERNS
*   **Duplicate PATH entry**: `.local/bin` appears twice in blockinfile block (Node + pipx). Harmless but messy.
*   **No handler**: Theme/plugin changes require manual `source ~/.zshrc` — no automatic reload.
