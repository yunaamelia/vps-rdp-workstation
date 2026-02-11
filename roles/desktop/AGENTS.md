# Component: Desktop Role (KDE/XRDP)

## Critical Functionality
Installs the complete GUI stack: KDE Plasma, XRDP server, SDDM, and visual themes. This is the "heavy" part of the automation.

## Key Dependencies
- **Ordering**: MUST run **after** `security` (Firewall) and `fonts`.
- **Files**:
  - `.xsession`: CRITICAL for XRDP. Must launch the correct session (`/usr/bin/startplasma-x11`).
  - `xrdp.ini`: Configures crypto levels (tls1.2+) and performance.

## Fragility Warnings
- **Theme Scripts**: Uses `ansible.builtin.shell` to run 3rd-party installers (Nordic, Catppuccin). These fetch from GitHub.
  - **Risk**: URLs break, scripts change. Verify idempotency manually if modifying.
- **Polonium**: Tiling script installation is complex (KWin scripting API).
- **Service Restart**: Restarting `xrdp` kills active sessions.

## Modification Rules
- **Themes**: Toggled via `vps_theme_variant` ("nordic" vs "catppuccin"). Do not hardcode paths.
- **Performance**: Optimizations (compositor settings, animations) are aggressive. Check `kwinrc` changes carefully.
