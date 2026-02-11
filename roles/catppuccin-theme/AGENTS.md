# COMPONENT: Catppuccin Theme Role

**Context**: Visual styling for GTK, KDE, and Cursors using the Catppuccin Mocha palette.

## OVERVIEW
Installs Catppuccin Mocha GTK theme, cursor theme, and applies KDE color configurations. Activated only when `vps_theme_variant == 'catppuccin-mocha'`.

## STRUCTURE
```
roles/catppuccin-theme/
├── defaults/       # Versions and Download URLs
├── files/          # Konsole color schemes
├── tasks/          # Download/Extract logic
└── templates/      # KDE/GTK config (kdeglobals, gtk settings)
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Install Logic** | `tasks/main.yml` | Downloads/extracts to `~/.themes` & `~/.icons`. |
| **Versions** | `defaults/main.yml` | Update `catppuccin_gtk_version` here. |
| **KDE Colors** | `templates/kdeglobals.j2` | Defines the specific RGB palette. |
| **GTK Config** | `templates/gtk-*.ini.j2` | GTK 3/4 settings. |

## CONVENTIONS
*   **Trigger**: All tasks are conditional on `vps_theme_variant == 'catppuccin-mocha'`.
*   **User Scope**: Installs to user directories (`/home/{{ vps_username }}/...`), NOT system-wide (`/usr/share`).
*   **Idempotency**: `unarchive` tasks use `creates` to prevent redownloading/re-extracting.
*   **Cleanup**: Always removes temporary `.zip` files from `/tmp`.

## ANTI-PATTERNS
*   **External Deps**: Relies on GitHub releases. No fallback if offline.
*   **Manual Color Hash**: `ColorSchemeHash` in `kdeglobals.j2` is hardcoded; do not modify manually without regenerating.
