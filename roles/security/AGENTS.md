# Security Role

## OVERVIEW
Hardens network and access security via UFW, Fail2ban, and SSH configuration (Zero-fail zone).

## WHERE TO LOOK
| Component | Location | Notes |
|-----------|----------|-------|
| **Firewall** | `tasks/main.yml` | UFW allow rules for `vps_ssh_port` and `vps_xrdp_port`. |
| **SSH Config** | `tasks/main.yml` | Uses `lineinfile` for `sshd_config` hardening. |
| **Fail2Ban** | `templates/jail.local.j2` | Custom jail definitions for SSH and XRDP. |
| **Updates** | `tasks/main.yml` | Configures `unattended-upgrades` for security patches. |

## CONVENTIONS
*   **Fail-Safe Ordering**: UFW allow rules MUST be processed before enabling the firewall to prevent lockout.
*   **Root Access**: `vps_ssh_root_login` defaults to `false`. Override only in inventory, never in defaults.
*   **Port Visibility**: Only ports explicitly defined in variables (`vps_ssh_port`, `vps_xrdp_port`) are opened.
*   **Idempotency**: SSH configuration uses regex-based `lineinfile` tasks to ensure safe, repeatable edits.

## ANTI-PATTERNS
*   **Manual Firewall Edits**: Do not run `ufw` commands manually; state will drift from Ansible configuration.
*   **Ignoring Lockout Risk**: Never apply this role without verifying SSH key access or having VPS console access.
*   **Blind Reordering**: This role MUST run after `common` but before any service roles (like `desktop` or `docker`).
