# COMPONENT: Fonts Role — Phase 3 (Visual)

**Context**: Nerd Fonts and Powerline fonts installation for terminal and IDE support.

## OVERVIEW
Installs JetBrains Mono, Hack, and FiraCode Nerd Fonts (manual download/extract) and Powerline fonts (git clone). Configures fontconfig for RDP rendering optimization and sets font priority.

## STRUCTURE
```
roles/fonts/
├── tasks/          # Download → Extract → Install → Configure fontconfig
└── templates/      # 01-font-priority.conf.j2 (fontconfig priority)
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Nerd Fonts Download** | `tasks/main.yml:33-65` | `get_url` from GitHub releases |
| **Powerline Clone** | `tasks/main.yml:104-110` | `git` clone depth 1 to /tmp |
| **Powerline Install** | `tasks/main.yml:122-130` | Runs `install.sh` script |
| **RDP Rendering Fix** | `tasks/main.yml:140-161` | `10-rendering.conf` for antialiasing/hinting |
| **Font Priority** | `tasks/main.yml:164-170` | Template to prioritize JetBrains Mono |

## CONVENTIONS
*   **Manual Unarchive**: Uses `unarchive` module with `remote_src: true` for tarballs.
*   **Check Mode Safety**: Skips downloads/installs in check mode (`when: not ansible_check_mode`).
*   **Cleanup**: Explicitly removes `/tmp` artifacts after installation.

## ANTI-PATTERNS
*   **Hardcoded URLs**: GitHub release URLs are hardcoded (though version agnostic "latest" is used).
*   **Shell Script Installer**: Powerline fonts rely on external `install.sh`.
