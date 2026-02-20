# COMPONENT: MOLECULE TESTING

**Scope**: 31 test scenarios for container-based role validation.

## STRUCTURE

| Scenario    | Purpose                            |
| ----------- | ---------------------------------- |
| `default/`  | Base system + security + RDP stack |
| `security/` | UFW, fail2ban, SSH hardening       |
| `desktop/`  | KDE Plasma, SDDM                   |
| `xrdp/`     | RDP server, port 3389              |
| `docker/`   | Engine, Compose V2                 |
| `chaos/`    | Failure injection testing          |
| `helpers/`  | Shared test fixtures               |

## DRIVER

- **Image**: `geerlingguy/docker-debian12-ansible` (Debian 12 base)
- **Privileged**: Required for systemd (XRDP, UFW). Mount `/sys/fs/cgroup`.
- **Cgroups**: Host cgroup mount for systemd-in-Docker.

## PROVISIONER

- **Ansible**: Core engine for converge + verify.
- **Pipelining**: Enabled to reduce SSH overhead.
- **Interpreter**: `/usr/bin/python3` hardcoded for consistency.

## CONVENTIONS

- **Idempotency**: Run converge twice; second run must report zero changes.
- **Verifier**: Use Ansible assertions (`verify.yml`), not Goss/Inspec.
- **Naming**: Scenario name matches role name exactly.

## ANTI-PATTERNS

- **Privileged Overuse**: Only set `privileged: true` for systemd/kernel roles.
- **State Leakage**: Scenarios must not depend on previous execution state.
- **Missing Idempotency**: Must verify zero-change on second converge.

[Root Guidelines](../AGENTS.md)
