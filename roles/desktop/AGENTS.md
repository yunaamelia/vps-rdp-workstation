# Component: Desktop Role (KDE Plasma)

## OVERVIEW
Installs KDE Plasma desktop environment with SDDM, Nordic/WhiteSur theming, and performance tuning for RDP latency. **XRDP is now a separate role** (`roles/xrdp/`).

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Main Logic** | `tasks/main.yml` | KDE packages, SDDM, themes, Kvantum config. |
| **Toggles** | `defaults/main.yml` | `vps_install_desktop`, `vps_theme_variant`, `vps_kde_compositor_enabled`. |
| **Depends On** | `roles/xrdp/` | XRDP runs after desktop (Phase 3.1 in main.yml). |

## CONVENTIONS
*   **Performance First**: Compositor is DISABLED by default (`Enabled=false` in `kwinrc`) to prevent RDP lag.
*   **Session Handling**: Manages `~/.xsession` explicitly. MUST export `XDG_SESSION_TYPE=x11`.
*   **Theme Deployment**: Clones themes to `/tmp` first, then copies to `~/.local/share/`.
*   **Idempotency**: Theme scripts (WhiteSur) use `creates` or version checks to avoid re-running.

## ANTI-PATTERNS
*   **GUI Installers**: Never rely on GUI wizards. All configs (Kvantum, Plasma) must be file-based (`.config/`).
*   **Hardcoded Users**: ALWAYS use `{{ vps_username }}`. Never assume `root` or `1000`.
*   **Shell Pipe**: Avoid `curl | bash` patterns. Clone git repos and inspect/run installers with `ansible.builtin.command`.
