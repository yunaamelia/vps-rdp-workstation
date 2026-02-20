# VPS RDP Workstation - AI Agent Instructions

> **What is this project?** Ansible IaC that transforms a fresh Debian 13 VPS into a security-hardened RDP developer workstation with KDE Plasma, 50+ dev tools, and beautiful logging.

---

## Quick Reference

| Task               | Command                                 | Notes              |
| ------------------ | --------------------------------------- | ------------------ |
| **Full Setup**     | `./setup.sh`                            | Interactive mode   |
| **Dry Run**        | `./setup.sh --dry-run`                  | Preview changes    |
| **CI Mode**        | `./setup.sh --ci`                       | Non-interactive    |
| **Specific Roles** | `./setup.sh -- --tags security,desktop` | Granular execution |
| **Validate**       | `./tests/validate.sh`                   | 30+ criteria check |
| **Check Status**   | `cat /var/lib/vps-setup/progress.json`  | Installation state |

---

## CRITICAL: Execution Order

**The 25 roles MUST execute in this order. NEVER reorder:**

```
Phase 1:  common (foundation)
Phase 2:  security (UFW, fail2ban, SSH) ← MUST run before services
Phase 3:  fonts (Nerd Fonts)
Phase 4:  desktop (KDE Plasma, SDDM)
Phase 5:  xrdp (RDP server, port 3389)
Phase 6:  kde-optimization → kde-apps → whitesur-theme
Phase 7:  terminal → tmux → shell-styling → zsh-enhancements
Phase 8:  development (Node.js, Python, PHP) → docker → editors
Phase 9:  Tool roles (tui-tools, network-tools, etc.)
```

**⚠️ SECURITY RULE:** NEVER move `security` role after service roles (`desktop`, `xrdp`, `docker`). This would expose services before hardening.

---

## Tool Usage Guide

### vps-setup

```
Modes:
- full: Complete installation (default)
- dry-run: Preview changes without applying
- ci: Non-interactive CI/CD mode

Tags: Run specific phases (e.g., "security,desktop")
```

**Example:**

```typescript
(await vps) - setup({ mode: "dry-run", tags: "security,desktop" });
```

### vps-validate

```
Categories:
- all: Complete validation (default)
- security: Firewall, SSH, fail2ban
- desktop: KDE, XRDP, theme
- tools: Development tools
- quick: Fast sanity check
```

### vps-status

Returns current installation progress, system info, and recent logs.

### vps-role-run

Run specific Ansible roles. Useful for:

- Re-running failed roles
- Updating specific components

**Example:**

```typescript
(await vps) - role - run({ roles: "security,fonts" });
```

### vps-molecule-test

Run Molecule tests for Ansible roles in Docker containers.

**Example:**

```typescript
(await vps) - molecule - test({ role: "security" });
```

---

## Anti-Patterns (NEVER DO)

| Violation                         | Why It's Bad                                                    |
| --------------------------------- | --------------------------------------------------------------- |
| Run `ansible-playbook` directly   | Bypasses setup.sh validation, Mitogen injection, secret hashing |
| Move security role after services | Exposes ports before firewall is configured                     |
| Store plaintext passwords         | Security violation; always hash with SHA-512                    |
| Skip progress tracking            | Breaks `--resume` capability                                    |
| Use global handlers in roles      | Violates role isolation                                         |

---

## Variable Naming Convention

All variables use `vps_<role>_<feature>` prefix:

```yaml
vps_docker_install: true
vps_docker_log_max_size: "50m"
vps_xrdp_allow_root: false # NEVER true in production
vps_username: "developer"
```

---

## File Locations

| What               | Where                              |
| ------------------ | ---------------------------------- |
| **Entry Point**    | `setup.sh`                         |
| **Main Playbook**  | `playbooks/main.yml`               |
| **Configuration**  | `inventory/group_vars/all.yml`     |
| **Progress State** | `/var/lib/vps-setup/progress.json` |
| **Full Log**       | `/var/log/vps-setup.log`           |
| **Summary Log**    | `/var/log/vps-setup-summary.log`   |
| **ARA Database**   | `/var/log/ara-database.sqlite`     |

---

## Troubleshooting

### Setup Fails

1. Check logs: `tail -100 /var/log/vps-setup.log`
2. Verify progress: `cat /var/lib/vps-setup/progress.json`
3. Re-run with verbose: `./setup.sh --verbose`
4. Run specific failed role: `vps-role-run({ roles: "failed_role_name" })`

### RDP Connection Issues

1. Verify xrdp running: `systemctl status xrdp`
2. Check firewall: `ufw status | grep 3389`
3. Test locally: `xfreerdp /v:localhost:3389`

### Validation Failures

1. Run category-specific: `vps-validate({ category: "security" })`
2. Check service status: `systemctl status ufw ssh xrdp`

---

## Architecture Overview

```
vps-rdp-workstation/
├── setup.sh              # CANONICAL ENTRY (validates, hashes, injects)
├── ansible.cfg           # Pipelining, callbacks, fact caching
├── inventory/
│   └── group_vars/all.yml # Global variables (vps_* prefix)
├── playbooks/
│   └── main.yml          # 25-role orchestration
├── roles/                # 25 flat roles, each with AGENTS.md
├── plugins/
│   ├── callback/         # clean_progress.py, rich_tui.py
│   └── mitogen/          # Vendored v0.3.21 for 2-7x speedup
└── molecule/             # 31 test scenarios
```

---

## Performance Notes

- **Mitogen**: Vendored in `plugins/mitogen/` for 2-7x Ansible speedup
- **Pipelining**: Enabled in `ansible.cfg`
- **Fact Caching**: `/tmp/ansible_facts_cache` with 24h TTL
- **Forks**: 10 concurrent hosts

---

## Security Features

- ✅ UFW firewall (default-deny incoming)
- ✅ SSH hardening (root login disabled, rate limiting)
- ✅ fail2ban for SSH and RDP
- ✅ Unattended security updates
- ✅ SHA-512 password hashing
- ✅ No credentials in logs or command history
