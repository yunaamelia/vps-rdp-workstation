# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Ansible-based automation system that transforms a fresh Debian 13 VPS into a fully-configured RDP developer workstation with security hardening, KDE Plasma desktop (Nordic theme), and 50+ development tools. The project uses Mitogen acceleration (2-7x faster) and ARA for run analysis.

## Essential Commands

### Installation & Running

```bash
# Main installation (interactive)
./setup.sh

# Deploy to remote VPS
ansible-playbook -i inventory/remote_hosts.yml playbooks/main.yml --ask-become-pass

# Dry-run (preview changes)
./setup.sh --dry-run
# Or with Ansible directly
ansible-playbook playbooks/main.yml --check --diff

# Run specific role/phase
ansible-playbook playbooks/main.yml --tags security
ansible-playbook playbooks/main.yml --tags desktop,terminal

# Skip specific roles
ansible-playbook playbooks/main.yml --skip-tags cloud
```

### Development & Testing

```bash
# Install dependencies
pip install pre-commit ansible-core
ansible-galaxy collection install -r requirements.yml

# Setup pre-commit hooks
pre-commit install

# Run pre-commit checks manually
pre-commit run --all-files

# Lint playbooks
ansible-lint playbooks/main.yml
ansible-lint roles/*/

# Lint YAML files
yamllint .

# Lint shell scripts
shellcheck setup.sh

# Syntax check playbooks
ansible-playbook playbooks/main.yml --syntax-check

# List all tasks/tags
ansible-playbook playbooks/main.yml --list-tasks
ansible-playbook playbooks/main.yml --list-tags
```

### ARA - Ansible Run Analysis

```bash
# List all recorded playbook runs
ara playbook list

# Show specific run details
ara playbook show <playbook-id>

# Generate static HTML reports
ara-manage generate /var/www/html/ara-reports

# Start ARA web UI
ara-manage runserver
```

### Playbook Visualization

```bash
# Generate SVG diagram of playbook structure
ansible-playbook-grapher playbooks/main.yml -o docs/playbook-graph

# Include role tasks in diagram
ansible-playbook-grapher playbooks/main.yml --include-role-tasks -o docs/playbook-detailed
```

### Starship Prompt Optimization

AI-assisted configuration optimization for Starship prompt:

```bash
# Quick start
cat docs/STARSHIP_QUICKSTART.md

# Use AI prompt (ask Claude/Copilot):
# "Using .github/prompts/starship-optimizer.prompt.md, optimize my Starship config"

# Manual optimization
cp ~/.config/starship.toml ~/.config/starship.toml.backup.$(date +%Y%m%d_%H%M%S)
# Edit config, then:
starship config  # Validate
time starship prompt  # Performance test
source ~/.zshrc  # Reload

# Full implementation guide
cat docs/STARSHIP_OPTIMIZATION.md
```

## Architecture Overview

### Execution Flow

1. **setup.sh** - Entry point that handles:
   - Pre-flight validation (OS, architecture, prerequisites)
   - Secrets management (secure password file handling)
   - Environment setup (Mitogen, ARA initialization)
   - Ansible playbook execution with custom callbacks
   - Post-installation summary generation

2. **playbooks/main.yml** - Main orchestration playbook that:
    - Executes 25 roles in dependency order across 7 phases
    - Tracks progress in state file (`/var/lib/vps-setup/progress.json`)
    - Generates summary logs after completion
    - Uses custom callback plugins for enhanced output
    - NOTE: Role order refactored in v3.0.0 - `--resume` from older versions requires fresh start

3. **Roles** - Modular components organized by function (see Role Phases below)

### Role Phases & Dependencies

Roles execute in strict order to manage dependencies:

**Phase 1: Bootstrap**

- `common` - System packages, apt configuration, base utilities

**Phase 2: Security** (runs BEFORE exposing services)

- `security` - UFW firewall, fail2ban, SSH hardening, unattended upgrades

**Phase 3: Base System**

- `fonts` - Nerd Fonts (JetBrains Mono), font installation and configuration

**Phase 4: Desktop Environment** (runs AFTER fonts for theme dependencies)

- `desktop` - KDE Plasma, XRDP, SDDM display manager, Polonium tiling
- `xrdp` - XRDP service configuration and templates
- `kde-optimization` - KDE fine-tuning via `ini_file`, keybindings configuration
- `kde-apps` - KDE applications (Konsole, Spectacle, etc.)
- `whitesur-theme` - WhiteSur theme, icons, and cursors

**Phase 5: User Configuration** (runs AFTER desktop/fonts)

- `terminal` - Zsh, Oh My Zsh base installation, **Kitty terminal** (backup)
- `shell-styling` - Agnoster theme, fastfetch
- `zsh-enhancements` - External plugins (autosuggestions, syntax-highlighting, fzf-tab, forgit)

**Phase 6: Development Tools**

- `development` - Node.js 20 LTS, Python 3.12, PHP, Composer
- `docker` - Docker Engine, Docker Compose V2
- `editors` - VS Code, OpenCode AI agent

**Phase 7: CLI Tools** (conditionally installed)

- `tui-tools` - lazygit, tig, ranger, mc
- `network-tools` - nmap, mtr, iftop, httpie
- `system-performance` - btop, dstat, ncdu
- `text-processing` - ripgrep, fd, jq, yq, pandoc
- `file-management` - zoxide, trash-cli
- `dev-debugging` - gdb, strace, ltrace, valgrind
- `code-quality` - shellcheck, hadolint, yamllint
- `productivity` - thefuck, tmux
- `log-visualization` - lnav, multitail
- `ai-devtools` - aider, shell-gpt
- `cloud-native` - kubectl, helm, k9s (optional, default: false)

### Key Design Patterns

**Idempotency**: All roles are designed to be idempotent - safe to run multiple times.

**Check Mode**: All tasks support Ansible's `--check` mode (dry-run) except where explicitly disabled with `check_mode: false`.

**Secrets Management**:

- Passwords NEVER stored in vars or inventory
- Passed via environment variables or secure files (0600 permissions)
- Automatically sanitized in logs (see setup.sh log_to_file function)
- `no_log: true` used for sensitive tasks

**Progress Tracking**:

- State file: `/var/lib/vps-setup/progress.json` tracks role completion
- Enables resume functionality after failures
- JSON format with version, timestamps, completed/failed roles

**Custom Callback Plugins**:

- `plugins/callback/clean_progress.py` - Clean progress output without task names
- `plugins/callback/rich_tui.py` - Rich TUI with colors and formatting

### Configuration System

**Hierarchy** (later overrides earlier):

1. `inventory/group_vars/all.yml` - Default configuration (220+ variables)
2. Environment variables (`VPS_*`)
3. Runtime parameters passed to setup.sh
4. Secrets file (for passwords only)

**Key Variables**:

- `vps_username` - Primary user account (required)
- `vps_user_password_hash` - SHA-512 password hash (required)
- `vps_security_level` - standard | hardened | paranoid
- `install_*` - Boolean flags to enable/disable tool categories
- `vps_install_desktop` - Enable/disable desktop environment
- `vps_ssh_root_login` - Allow root SSH login (security consideration)

See `inventory/group_vars/all.yml` for complete variable documentation.

## Working with Roles

### Creating a New Role

```bash
# Create role structure
ansible-galaxy role init roles/my-new-role

# Minimum required files:
# - tasks/main.yml (entry point)
# - meta/main.yml (dependencies)
# - defaults/main.yml (default variables)
```

### Role Structure Convention

```
roles/role-name/
├── tasks/
│   └── main.yml          # Main entry point
├── handlers/
│   └── main.yml          # Handlers (service restarts, etc)
├── templates/
│   └── config.j2         # Jinja2 templates
├── files/
│   └── script.sh         # Static files
├── defaults/
│   └── main.yml          # Default variables (lowest precedence)
├── vars/
│   └── main.yml          # Role variables (higher precedence)
└── meta/
    └── main.yml          # Dependencies, galaxy info
```

### Adding Role to Playbook

In `playbooks/main.yml`:

```yaml
- role: my-new-role
  tags: [my-role, category]
  when: install_my_feature | default(true) # Make it optional
```

Add role to appropriate phase based on dependencies.

## Security Considerations

**Critical Security Rules**:

1. NEVER commit passwords, API keys, or secrets to version control
2. NEVER log sensitive data - use `no_log: true` for tasks handling secrets
3. NEVER store user passwords in plaintext - always use SHA-512 hash
4. NEVER skip validation unless debugging - validation prevents misconfigurations
5. The `security` role MUST run before desktop/services that expose ports

**Security Defaults**:

- UFW firewall enabled with default-deny incoming
- fail2ban protecting SSH (port 22) and RDP (port 3389)
- SSH with rate limiting, root login configurable
- Unattended security updates enabled
- XRDP with TLS encryption (TLSv1.2+)

**File Permissions**:

- Secrets file: 0600 (owner read/write only)
- State/progress files: 0644 (world-readable for troubleshooting)
- Backup directory: 0750 (owner + group)
- Log files: 0640 (owner read/write, group read)

## Testing & Validation

### Pre-commit Hooks

The repository uses pre-commit hooks (`.pre-commit-config.yaml`):

- **trailing-whitespace** - No trailing whitespace
- **end-of-file-fixer** - Files end with newline
- **check-yaml** - Valid YAML syntax (with --unsafe for Ansible)
- **shellcheck** - Shell script linting
- **ansible-lint** - Playbook best practices
- **yamllint** - Strict YAML formatting (`.yamllint` config)
- **pylint** - Python code quality (callback plugins only)

### Linting Rules

**ansible-lint**: Uses default rules, excludes `collections/` directory
**yamllint**: Max line length 180, truthy warnings, allows implicit octal in quotes
**shellcheck**: Severity warning, excludes SC1091 (source following)

### Testing in CI/CD

See `.github/workflows/vps-setup.yml` for GitHub Actions workflow.

## Common Modifications

### Adding a New Package to Existing Role

Edit role's `tasks/main.yml`:

```yaml
- name: Install new package
  ansible.builtin.apt:
    name: package-name
    state: present
  tags: [role-name, packages]
```

### Modifying Desktop Theme

Edit `inventory/group_vars/all.yml`:

```yaml
vps_kde_theme: "breeze-dark" # Change from "nordic"
vps_icon_theme: "breeze-dark"
```

### Changing Default Ports

Edit `inventory/group_vars/all.yml`:

```yaml
vps_ssh_port: 2222 # Change SSH port
vps_xrdp_port: 13389 # Change RDP port
```

Then ensure firewall rules are updated in `roles/security/tasks/main.yml`.

### Disabling Optional Components

Edit `inventory/group_vars/all.yml`:

```yaml
install_ai_devtools: false
install_cloud_native_tools: false
vps_install_desktop: false # Headless server mode
```

## Ansible Configuration

**ansible.cfg key settings**:

- `strategy_plugins` - Set by setup.sh for Mitogen acceleration
- `callback_whitelist` - Enables ARA recording and profiling
- `forks: 10` - Parallel execution (single host = no effect)
- `pipelining: true` - Reduces SSH overhead
- `gathering: smart` - Cache facts for 24h
- `log_path` - Full execution log at `/var/log/vps-setup-ansible.log`

**Mitogen Acceleration**:

- Loaded dynamically by setup.sh from pip install location
- Set via `ANSIBLE_STRATEGY_PLUGINS` and `ANSIBLE_STRATEGY=mitogen_linear`
- 2-7x speedup over standard SSH connection
- Particularly effective for roles with many small tasks

## Troubleshooting

**Check logs**:

- `/var/log/vps-setup.log` - Full installation log
- `/var/log/vps-setup-error.log` - Errors/warnings only
- `/var/log/vps-setup-summary.log` - Summary report
- `/var/log/vps-setup-ansible.log` - Raw Ansible output

**Check progress state**:

```bash
cat /var/lib/vps-setup/progress.json
```

**Resume after failure**:

```bash
./setup.sh --resume
```

**Run specific failed role**:

```bash
ansible-playbook playbooks/main.yml --tags role-name --start-at-task="Task Name"
```

**Debug mode**:

```bash
./setup.sh --debug  # Very verbose output
ansible-playbook playbooks/main.yml -vvv  # Ansible verbose mode
```

## Important File Locations

- `ansible.cfg` - Ansible configuration
- `ansible-navigator.yml` - Navigator config (EE disabled)
- `setup.sh` - Main entry point with validation and setup logic
- `playbooks/main.yml` - Main orchestration playbook
- `playbooks/rollback.yml` - Rollback playbook (if needed)
- `inventory/hosts.yml` - Localhost inventory
- `inventory/remote_hosts.yml` - Remote VPS inventory template
- `inventory/group_vars/all.yml` - All configuration variables
- `roles/` - 21 role directories
- `plugins/callback/` - Custom Ansible callback plugins
- `templates/summary-log.j2` - Summary report template
- `.pre-commit-config.yaml` - Pre-commit hook configuration
- `.yamllint` - YAML linting rules
- `requirements.yml` - Ansible collections (community.general 8.5.0)

## External Dependencies

**Python packages** (install via pip):

- ansible-core>=2.16,<2.17
- pre-commit
- mitogen (for acceleration)
- ara[server] (for run analysis)
- ansible-playbook-grapher (for visualization)
- yamllint, ansible-lint, pylint

**Ansible collections** (install via ansible-galaxy):

- community.general 8.5.0

**System requirements**:

- Debian 13 (Trixie) x86_64
- 4GB RAM minimum (8GB recommended)
- 40GB storage minimum
- Root or sudo privileges
