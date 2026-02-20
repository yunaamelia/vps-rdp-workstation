# COMPONENT: INVENTORY

**Scope**: Configuration root for hosts and global variables.

## STRUCTURE

| File                 | Purpose                                          |
| -------------------- | ------------------------------------------------ |
| `hosts.yml`          | Main inventory (target hosts, connection params) |
| `remote_hosts.yml`   | Alternative remote targets                       |
| `group_vars/all.yml` | Canonical config root (all `vps_` prefixed vars) |

## CONVENTIONS

- **Variable Prefix**: ALL global vars MUST use `vps_` prefix (e.g., `vps_username`, `vps_timezone`).
- **Role Prefix Pattern**: `vps_<role>_<feature>` (e.g., `vps_docker_install`, `vps_xrdp_allow_root`).
- **YAML Standard**: 2-space indentation, multi-line map syntax.
- **Ordering**: Group variables by category (System, Security, Desktop, Development).
- **Security Level**: Control hardening via `vps_security_level` (standard|hardened|paranoid).

## ANTI-PATTERNS

- **Plaintext Secrets**: NEVER store passwords/hashes in plaintext here.
- **Hardcoded IPs**: Avoid in `hosts.yml`; use `setup.sh` overrides.
- **Duplicate Definitions**: Don't repeat `group_vars/all.yml` vars in role defaults.
- **Manual Edits**: Never modify inventory during running deployment.

[Root Guidelines](../AGENTS.md)
