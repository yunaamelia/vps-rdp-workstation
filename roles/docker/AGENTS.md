# Docker Role Knowledge Base

**Context:** Container infrastructure — Phase 6. Guarded by `install_docker | default(true)`.

## OVERVIEW
Installs Docker Engine (CE), Compose V2 plugin, and `lazydocker` TUI with production-ready daemon configuration.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Install** | `tasks/main.yml` | Docker apt repo + GPG key + GitHub API fetch for lazydocker. |
| **Config** | `templates/daemon.json.j2` | JSON log rotation & BuildKit enabled by default. |
| **Tunables** | `defaults/main.yml` | `docker_log_max_size` (10m), `docker_storage_driver`. |
| **Restart** | `handlers/main.yml` | Systemd restart with daemon-reload. |

## CONVENTIONS
*   **TUI Installation**: `lazydocker` fetched dynamically from GitHub Releases (no apt package).
*   **Daemon Config**: Enforces `json-file` logging with rotation to prevent disk exhaustion.
*   **User Access**: Automatically adds `{{ vps_username }}` to `docker` group.
*   **Container Safety**: Skips service start if `ansible_virtualization_type == "docker"` (CI containers).
*   **sysctl Skip**: `failed_when` guards sysctl tasks inside Docker (no kernel access).

## ANTI-PATTERNS
*   **Variable Naming**: Uses `docker_` prefix in defaults (legacy pattern), unlike `vps_<role>_`.
*   **GitHub Rate Limit**: `lazydocker` version check relies on GitHub API — may fail unauthenticated.
