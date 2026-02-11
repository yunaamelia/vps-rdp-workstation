# Component: Security Role

## Critical Mission
**Zero-fail zone.** Configures the firewall, SSH access, and intrusion prevention. A mistake here locks out the user.

## Enforced Rules
1.  **Execution Order**: MUST be Phase 2 (immediately after `common`).
2.  **Fail-Safe**: `ufw` must allow SSH (port `vps_ssh_port`) BEFORE enabling.
3.  **Root Access**: `vps_ssh_root_login` defaults to `false`. Do not change default without explicit user request.
4.  **Fail2Ban**: Jails for SSH (`sshd`) and XRDP (`xrdp-sesman`) are mandatory.

## Task Specifics
- **UFW**: Default policy is `deny` incoming. Explicit allow for SSH/XRDP.
- **SSH Hardening**: `PermitRootLogin`, `PasswordAuthentication`, `PubkeyAuthentication` managed via templates.
- **Unattended Upgrades**: Enabled for security updates only.

## Validation
After changes, verify:
- SSH port is accessible.
- UFW status is active.
- No syntax errors in `sshd_config` (`sshd -t`).
