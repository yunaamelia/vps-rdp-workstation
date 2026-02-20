# ROLE: kde-apps

**Purpose**: KDE Plasma native applications (Konsole, Dolphin, Spectacle).
**Phase**: 7

## TASKS

- `main.yml`: Installs KDE application suite, Konsole terminal, Dolphin file manager.
- `uninstall.yml`: Removes KDE apps while preserving core Plasma desktop environment.

## VARIABLES

- `vps_kde_apps_install`: Boolean to enable/disable installation (default: true).
- `vps_kde_apps_konsole_install`: Install Konsole terminal (default: true).
- `vps_kde_apps_dolphin_install`: Install Dolphin file manager (default: true).
- `vps_kde_apps_spectacle_install`: Install Spectacle screenshot tool (default: true).
- `vps_kde_apps_kwrite_install`: Install KWrite text editor (default: true).

## DEPENDENCIES

- desktop (KDE Plasma must be installed first)
- Common

## ANTI-PATTERNS

- Installing KDE apps before Plasma framework is ready.
- Replacing Plasma desktop with alternative (breaks integration).
- Not respecting user's secondary terminal choice (Kitty may be preferred).

[Root Guidelines](../../AGENTS.md)
