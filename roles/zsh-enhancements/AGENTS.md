# COMPONENT: Zsh Enhancements Role — Phase 11 (Terminal)

**Context**: Advanced Zsh plugins and utilities (zoxide, fzf) extending Oh My Zsh.

## OVERVIEW
Manages external OMZ plugins (cloned to `custom/plugins`) and installs modern navigation tools like `zoxide` and `fzf`. Handles git ownership for plugin directories.

## STRUCTURE
```
roles/zsh-enhancements/
└── tasks/          # Plugins dir → Clone plugins → Fix perms → Install tools
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Clone Plugins** | `tasks/main.yml:19-27` | Loop over `vps_omz_external_plugins` |
| **Git Safe Dir** | `tasks/main.yml:12-17` | Fixes "dubious ownership" for plugin repos |
| **Zoxide Install** | `tasks/main.yml:41-48` | `curl | bash` installer (no apt package in Debian stable) |
| **Perms Fix** | `tasks/main.yml:29-35` | Recursive chown to user |

## CONVENTIONS
*   **Git Config**: Proactively sets `safe.directory` for every plugin to prevent git status errors.
*   **External Installer**: Uses vendor script for `zoxide` as it provides the latest version.

## ANTI-PATTERNS
*   **Curl to Bash**: Zoxide installation pipes curl to bash.
*   **Manual Move**: Moves zoxide binary manually to `/usr/local/bin`.
