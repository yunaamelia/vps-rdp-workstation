# COMPONENT: WhiteSur Theme Role — Phase 8 (Visual)

**Context**: MacOS-like visual theme for KDE Plasma (Cursors, Icons, Application Style).

## OVERVIEW
Installs WhiteSur cursors, icons, and KDE theme from source. Configures Plasma globals, Kvantum, and sets up a startup script to apply the theme reliably after Plasma loads.

## STRUCTURE
```
roles/whitesur-theme/
└── tasks/          # Dependencies → Cursors → Icons → Theme → Autostart
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Install Scripts** | `tasks/main.yml` | Uses `./install.sh` with specific flags (`-c Dark`, `--round`) |
| **Kvantum Config** | `tasks/main.yml:132-139` | Sets `WhiteSurDark` in `kvantum.kvconfig` |
| **Apply Script** | `tasks/main.yml:142-156` | Creates `apply-whitesur-theme.sh` to handle DBus delays |
| **Autostart** | `tasks/main.yml:159-168` | Registers script to run on login |

## CONVENTIONS
*   **Installation Flags**: Uses strict flags (`-a`, `-b`) passed to `install.sh` based on ansible vars.
*   **Delayed Application**: Theme application is deferred to a script to ensure Plasma DBus services are ready.
*   **Idempotency**: `git` checkout handles versioning; `install.sh` is re-runnable.

## ANTI-PATTERNS
*   **Shell script reliance**: Heavily depends on the stability of the upstream `install.sh`.
*   **DBus Polling**: The apply script loops waiting for Plasma, which is fragile but necessary.
