# Project Guidelines

This Ansible automation transforms a Debian 13 VPS into an RDP developer workstation with KDE Plasma, security hardening, and 50+ dev tools.

## Code Style

**YAML**: 2-space indentation, expanded syntax only (no one-liners). Always use FQCN modules (`ansible.builtin.*`, `community.general.*`). Task names in imperative present tense.

```yaml
# Reference: roles/common/tasks/main.yml
- name: Install system packages
  ansible.builtin.apt:
    name: "{{ item }}"
    state: present
  tags: [common, packages]
```

**Python Callbacks**: Follow `CallbackBase` pattern with DOCUMENTATION block. See [plugins/callback/clean_progress.py](../plugins/callback/clean_progress.py).

**Jinja2**: Always `.j2` extension. Use `| default(value)` for optional vars. See [playbooks/templates/summary-log.j2](../playbooks/templates/summary-log.j2).

## Architecture

**10-Phase Execution Order** (CRITICAL - security before services):

1. `common` → 2. `security` → 3. `fonts` → 4. `desktop` → 5. `xrdp` → 6. `kde-optimization` → 7. `kde-apps` → 8. `whitesur-theme` → 9. `terminal` → 10. `shell-styling` → 11. `zsh-enhancements` → 12. `development` → 13. `docker` → 14. `editors` → 15-25. tool roles

**Variable Hierarchy**: Role defaults → [group_vars/all.yml](../inventory/group_vars/all.yml) → playbook vars → CLI extra vars

**Progress Tracking**: State file at `/var/lib/vps-setup/progress.json` enables resume after failures.

**Custom Callbacks**: `clean_progress.py` (minimalist) or `rich_tui.py` (full TUI). Both in [plugins/callback/](../plugins/callback/).

## Build and Test

```bash
# Standard installation
./setup.sh

# CI/CD mode (non-interactive)
VPS_USERNAME=dev VPS_SECRETS_FILE=/root/.secrets ./setup.sh --ci

# Dry run (preview changes)
./setup.sh --dry-run  # or: ansible-playbook playbooks/main.yml --check --diff

# Run specific roles
ansible-playbook playbooks/main.yml --tags security,desktop

# Validate installation
./tests/validate.sh  # 30 success criteria

# Lint before commit
yamllint .
ansible-lint playbooks/ roles/
pylint plugins/callback/*.py
```

## Project Conventions

**Secrets Management**: NEVER log passwords. Use `no_log: true` for tasks handling `vps_user_password_hash`. See [setup.sh](../setup.sh) lines 463-489 for secure password hashing pattern.

**Variable Naming Convention**: All role variables use the `vps_<role>_` prefix. Examples:
- Docker role: `vps_docker_install`, `vps_docker_log_max_size`
- Development role: `vps_development_install_nodejs`, `vps_development_nodejs_version`
- Terminal role: `vps_terminal_install_kitty`, `vps_terminal_kitty_theme`
- Shared system variables: `vps_username`, `vps_timezone`, `vps_default_font_size`, `vps_default_monospace_font`

**Idempotency**: All tasks must be safe to run multiple times. Test by running twice - second run should report zero changes.

**Mitogen Acceleration**: 2-7x speedup via dynamic strategy plugin detection. See [setup.sh](../setup.sh) lines 184-215.

**Multi-Level Tagging**: Use `[phase, role, feature]` for granular execution:

```yaml
- role: desktop
  tags: [desktop, kde, optimization] # phase → role → feature
```

**Block/Rescue Error Handling**: Critical roles (common, security, desktop, xrdp, docker) include block/rescue error handling for improved failure recovery.

**Role Dependencies**: NEVER move `security` role before `common`. NEVER expose services before security hardening completes.

## Integration Points

**Entry Point**: [setup.sh](../setup.sh) → validates environment → invokes [playbooks/main.yml](../playbooks/main.yml)

**ARA Reporting**: Auto-records all runs. View with `ara playbook list` or `ara-manage runserver`.

**Progress State**: JSON at `/var/lib/vps-setup/progress.json` tracks role completion with timestamps.

**Logs**:

- `/var/log/vps-setup.log` - full execution log
- `/var/log/vps-setup-error.log` - errors only
- `/var/log/vps-setup-summary.log` - human-readable summary (from [playbooks/templates/summary-log.j2](../playbooks/templates/summary-log.j2))

## Security

**Pre-Service Hardening**: `security` role (UFW, fail2ban, SSH hardening) MUST run before `desktop` role exposes XRDP port 3389.

**Password Security**: Plain-text passwords immediately hashed with SHA-512 and original variable overwritten. Never store in vars/inventory.

**SSH Hardening**: Root login disabled by default (`vps_ssh_root_login: false` in [group_vars/all.yml](../inventory/group_vars/all.yml)).

---

**Detailed Guides**: See [CLAUDE.md](../CLAUDE.md) (425 lines) for commands/workflows and [.github/AI_AGENT_GUIDE.md](AI_AGENT_GUIDE.md) (1193 lines) for comprehensive architecture.
