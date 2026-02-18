# COMPONENT: KDE Optimization Role — Phase 3.1 (Desktop)

**Context**: Performance tuning and UX polish for KDE Plasma, optimized for RDP usage.

## OVERVIEW
Disables Baloo file indexing (via balooctl6 and config), tunes KWin compositor for lowest latency (animations off, blur off), installs Polonium tiling window manager (from source for Plasma 6 support), configures Dolphin defaults, sets system font to JetBrainsMono Nerd Font. All config via `community.general.ini_file`.

## STRUCTURE
```
roles/kde-optimization/
├── handlers/       # Reconfigure KWin handler
└── tasks/          # Baloo → Polonium → KWin → Dolphin → fonts
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Baloo disable** | `tasks/main.yml` | `balooctl6 disable` + `baloofilerc` config |
| **Polonium install** | `tasks/main.yml` | Git clone master → `kpackagetool6 -i` |
| **KWin tuning** | `tasks/main.yml` | `kwinrc` — AnimationSpeed=0, LatencyPolicy=ForceLowestLatency |
| **Dolphin config** | `tasks/main.yml` | `dolphinrc` — ShowFullPath, FilterBar |
| **System font** | `tasks/main.yml` | `kdeglobals` — 5 font entries (regular, fixed, menu, toolbar, smallest) |

## CONVENTIONS
*   **ini_file everywhere**: All KDE config changes use `community.general.ini_file` with `create: true` — safe for fresh installs.
*   **User-scoped**: All configs written to `/home/{{ vps_username }}/.config/`, never system-wide `/etc/xdg/`.
*   **Baloo guard**: Checks `which balooctl` before attempting disable — safe on minimal installs.
*   **Guard variable**: `vps_install_desktop | default(true)` on KDE power tools install.

## ANTI-PATTERNS
*   **Empty handlers file**: `handlers/main.yml` contains only `---`. No KDE reload mechanism — changes take effect on next login/session restart.
*   **Font hardcoded**: JetBrainsMono Nerd Font string uses KDE's internal format with magic numbers (`-1,5,50,0,0,0,0,0`). Do not manually edit without regenerating via KDE System Settings.
