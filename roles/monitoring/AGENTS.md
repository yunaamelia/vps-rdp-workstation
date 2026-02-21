# COMPONENT: MONITORING ROLE

**Scope**: Docker-based monitoring stack — Prometheus + Grafana via Compose V2.

## KEY FILES

| File                              | Purpose                                    |
| --------------------------------- | ------------------------------------------ |
| `tasks/main.yml`                  | Deploy config, start Compose stack          |
| `defaults/main.yml`               | `vps_monitoring_install`, ports, dir paths  |
| `templates/docker-compose.yml.j2` | Prometheus + Grafana service definitions    |
| `templates/prometheus.yml.j2`     | Scrape targets and intervals                |
| `templates/alert.rules.j2`        | Alerting rules for Prometheus               |
| `handlers/main.yml`               | `Restart monitoring` — re-up Compose stack  |

## CONVENTIONS

- **Guard**: `vps_monitoring_install` (default `true`).
- **Install Dir**: `vps_monitoring_dir` → `/opt/monitoring`.
- **Ports**: Grafana `3000`, Prometheus `9090` (configurable via defaults).
- **Compose**: Uses `community.docker.docker_compose_v2` module, `pull: always`.
- **Depends on**: `docker` role (Phase 14). Docker Engine must be present.

## ANTI-PATTERNS

- **Default Grafana Password**: `defaults/main.yml` ships `admin` — override in `group_vars/all.yml`.
- **No uninstall.yml**: Missing rollback; Compose stack must be removed manually.
- **Phase ordering**: Must run after `docker` role; will fail without Docker Engine.

[Root Guidelines](../../AGENTS.md)
