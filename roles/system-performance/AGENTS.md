# COMPONENT: System Performance Role — Phase 8 (Tools)

**Context**: Kernel tuning, I/O schedulers, memory optimization, and monitoring tools.

## OVERVIEW
Installs monitoring tools (htop, btop, dstat, ncdu, iotop, inxi), configures sysctl for BBR + VM tuning, sets per-disk-type I/O schedulers via udev, enables zram (zstd) and systemd-oomd. Installs `duf` from GitHub releases.

## STRUCTURE
```
roles/system-performance/
├── handlers/       # Reload udev rules (udevadm control + trigger)
└── tasks/          # Packages → zram → sysctl → udev → oomd → duf
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Monitoring tools** | `tasks/main.yml:3-27` | htop, btop, dstat, ncdu, iotop, sysstat, inxi, strace, lsof, psmisc |
| **Zram** | `tasks/main.yml:29-42` | `zram-tools` package, ALGO=zstd in `/etc/default/zramswap` |
| **Sysctl tuning** | `tasks/main.yml:44-82` | BBR, vfs_cache_pressure=50, dirty_ratio=10/5 |
| **I/O schedulers** | `tasks/main.yml:84-98` | Udev rules: NVMe→none, SSD→mq-deadline, HDD→bfq |
| **systemd-oomd** | `tasks/main.yml:100-111` | OOM protection daemon |
| **duf** | `tasks/main.yml:113-123` | GitHub releases, `shell` + `creates: /usr/bin/duf` |

## SYSCTL VALUES
| Parameter | Value | File | Purpose |
|-----------|-------|------|---------|
| `net.ipv4.tcp_congestion_control` | `bbr` | `99-workstation.conf` | Modern congestion control |
| `vm.vfs_cache_pressure` | `50` | `99-workstation.conf` | Favor inode/dentry cache |
| `vm.dirty_ratio` | `10` | `99-workstation.conf` | Max dirty page % before sync |
| `vm.dirty_background_ratio` | `5` | `99-workstation.conf` | Background writeback threshold |

## CONVENTIONS
*   **Sysctl file**: All tuning in `/etc/sysctl.d/99-workstation.conf` (single file, not scattered).
*   **Docker guard**: BBR sysctl uses `failed_when` with `ansible_virtualization_type != 'docker'` — silently skips in containers where sysctl is restricted.
*   **Handler**: `udevadm control --reload-rules && udevadm trigger` — triggers on I/O scheduler rule change.

## ANTI-PATTERNS
*   **duf from shell**: Uses `curl` + `dpkg -i` with `creates` guard. Fragile if GitHub API changes. Consider switching to apt when Debian packages duf.
*   **No rollback**: Sysctl and udev changes persist across reboots. Remove `/etc/sysctl.d/99-workstation.conf` and `/etc/udev/rules.d/60-io-scheduler.rules` to revert.
