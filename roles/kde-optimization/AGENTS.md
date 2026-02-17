# COMPONENT: KDE Optimization Role — Phase 3.1 (Desktop)

**Context**: Performance tuning and UX polish for KDE Plasma, optimized for RDP usage.

## OVERVIEW
Disables Baloo file indexing, tunes KWin compositor for lowest latency (animations off, blur off), installs Polonium tiling window manager, configures Dolphin defaults, sets system font to JetBrainsMono Nerd Font. All config via `community.general.ini_file`.

## STRUCTURE
```
roles/kde-optimization/
├── handlers/       # EMPTY (1 line `---`)
└── tasks/          # Polonium → Baloo → KWin → Dolphin → fonts
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Polonium install** | `tasks/main.yml` | Download release → `kpackagetool6 -i` |
| **Baloo disable** | `tasks/main.yml:14-47` | `balooctl disable` + `baloofilerc` config |
| **KWin tuning** | `tasks/main.yml:49-74` | `kwinrc` — AnimationSpeed=0, LatencyPolicy=ForceLowestLatency, blur disabled |
| **Dolphin config** | `tasks/main.yml:76-89` | `dolphinrc` — ShowFullPath, FilterBar |
| **System font** | `tasks/main.yml:91-107` | `kdeglobals` — 5 font entries (regular, fixed, menu, toolbar, smallest) |

## CONVENTIONS
*   **ini_file everywhere**: All KDE config changes use `community.general.ini_file` with `create: true` — safe for fresh installs.
*   **User-scoped**: All configs written to `/home/{{ vps_username }}/.config/`, never system-wide `/etc/xdg/`.
*   **Baloo guard**: Checks `which balooctl` before attempting disable — safe on minimal installs.
*   **Guard variable**: `vps_install_desktop | default(true)` on KDE power tools install.

## ANTI-PATTERNS
*   **Empty handlers file**: `handlers/main.yml` contains only `---`. No KDE reload mechanism — changes take effect on next login/session restart.
*   **Font hardcoded**: JetBrainsMono Nerd Font string uses KDE's internal format with magic numbers (`-1,5,50,0,0,0,0,0`). Do not manually edit without regenerating via KDE System Settings.
