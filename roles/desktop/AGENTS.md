# Component: Desktop Role (KDE/XRDP)

## OVERVIEW
Orchestrates a lightweight KDE Plasma environment optimized for RDP latency, including XRDP, SDDM, and Nordic/Catppuccin theming.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Main Logic** | `tasks/main.yml` | 500+ lines. Organized by: KDE, XRDP, Themes, Performance. |
| **XRDP Config** | `templates/*.j2` | `xrdp.ini`, `sesman.ini`, `startwm.sh`. Critical for connectivity. |
| **Toggles** | `defaults/main.yml` | `vps_install_xrdp`, `vps_theme_variant`, `vps_kde_compositor_enabled`. |
| **Optimization** | `tasks/main.yml` | Search `[desktop, performance]` tags. Disables Baloo/Akonadi. |

## CONVENTIONS
*   **Performance First**: Compositor is DISABLED by default (`Enabled=false` in `kwinrc`) to prevent RDP lag.
*   **Session Handling**: Manages `~/.xsession` explicitly. MUST export `XDG_SESSION_TYPE=x11`.
*   **Theme Deployment**: Clones themes to `/tmp` first, then copies to `~/.local/share/`.
*   **Idempotency**: Theme scripts (Catppuccin) use `creates` or version checks to avoid re-running.

## ANTI-PATTERNS
*   **GUI Installers**: Never rely on GUI wizards. All configs (Kvantum, Plasma) must be file-based (`.config/`).
*   **Hardcoded Users**: ALWAYS use `{{ vps_username }}`. Never assume `root` or `1000`.
*   **Shell Pipe**: Avoid `curl | bash` patterns. Clone git repos and inspect/run installers with `ansible.builtin.command`.
*   **Restarting XRDP**: Be careful with `notify: Restart XRDP`; can kill active connections during setup.
