# COMPONENT: XRDP Role — Phase 3.1 (Desktop)

**Context**: RDP server for remote KDE Plasma access. Runs AFTER desktop role.

## OVERVIEW
Installs xrdp + xorgxrdp, configures TLS via `ssl-cert` group, deploys session/compositor templates, enables systemd service.

## STRUCTURE
```
roles/xrdp/
├── defaults/       # Port, color depth, encryption, audio toggle
├── handlers/       # Restart XRDP (systemd)
├── tasks/          # Install → ssl-cert group → templates → service
└── templates/      # xrdp.ini.j2, sesman.ini.j2, startwm.sh.j2
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **TLS Config** | `templates/xrdp.ini.j2` | Encryption level, port, color depth |
| **Session Mgmt** | `templates/sesman.ini.j2` | Session types, max sessions |
| **Window Manager** | `templates/startwm.sh.j2` | Starts KDE Plasma via startplasma-x11 |
| **Defaults** | `defaults/main.yml` | `vps_xrdp_port`, `vps_xrdp_color_depth`, etc. |

## KEY VARIABLES
| Variable | Default | Purpose |
|----------|---------|---------|
| `vps_install_xrdp` | `true` | Guard toggle |
| `vps_xrdp_port` | `3389` | Listening port |
| `vps_xrdp_color_depth` | `24` | Color depth (16/24/32) |
| `vps_xrdp_encryption` | `"high"` | TLS encryption level |
| `vps_xrdp_audio` | `true` | PulseAudio over RDP |

## CONVENTIONS
*   **ssl-cert group**: `xrdp` user added to `ssl-cert` for TLS certificate access.
*   **Check mode**: `ignore_errors: "{{ ansible_check_mode }}"` on service start — service won't exist on first dry-run.
*   **Handler**: Single "Restart XRDP" via `ansible.builtin.systemd`.

## ANTI-PATTERNS
*   **Restarting XRDP kills active sessions**: Handler triggers on config change — warn users of active RDP connections.
*   **Port conflict**: If UFW not configured first (security role), port 3389 may be unreachable.
