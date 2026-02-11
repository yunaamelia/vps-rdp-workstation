# Docker Role Knowledge Base

**Context:** Container infrastructure setup including Engine, Compose, and tools.

## OVERVIEW
Installs Docker Engine (CE), Compose V2 plugin, and `lazydocker` TUI with production-ready daemon configuration.

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Install** | `tasks/main.yml` | Apt repos + GitHub API fetch for lazydocker. |
| **Config** | `templates/daemon.json.j2` | JSON log rotation & BuildKit enabled by default. |
| **Tunables** | `defaults/main.yml` | `docker_log_max_size` (10m), `docker_storage_driver`. |
| **Restart** | `handlers/main.yml` | Systemd restart with daemon-reload. |

## CONVENTIONS
*   **TUI Installation**: `lazydocker` is fetched dynamically from GitHub Releases (no apt package).
*   **Daemon Config**: Enforces `json-file` logging with rotation to prevent disk exhaustion.
*   **User Access**: Automatically adds `{{ vps_username }}` to `docker` group.
*   **Safety**: Skips service start if running inside a container (`ansible_virtualization_type == "docker"`).

## ANTI-PATTERNS
*   **Variable Naming**: Uses `docker_` prefix in defaults (legacy pattern), unlike newer `vps_<role>_`.
*   **External Dependency**: Relies on GitHub API for `lazydocker` version check (potential rate limit risk).
