# Configuration Guide

Complete configuration reference for VPS RDP Workstation v3.0.0 with refactored variable naming.

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `VPS_USERNAME` | Primary user account | Required |
| `VPS_HOSTNAME` | System hostname | Required |
| `VPS_TIMEZONE` | System timezone | `UTC` |
| `VPS_SECRETS_FILE` | Path to password file | Optional |

## Password File Format

Create a secure password file:
```bash
cat > ~/.vps-secrets << 'EOF'
{
  "vps_password": "YourSecurePassword123!"
}
EOF
chmod 0600 ~/.vps-secrets
export VPS_SECRETS_FILE=~/.vps-secrets
```

## Ansible Variables

Edit `inventory/group_vars/all.yml`:

### System Core Variables

```yaml
vps_username: "developer"          # Primary user account
vps_timezone: "UTC"                # System timezone
vps_hostname: "dev-workstation"    # System hostname
vps_default_font_size: 10          # Default font size (shared across roles)
vps_default_monospace_font: "JetBrainsMono"  # Monospace font (shared across roles)
```

### Security Settings

```yaml
vps_ssh_port: 22
vps_ssh_root_login: false
vps_ssh_password_auth: true
vps_ssh_pubkey_auth: true
vps_ssh_max_auth_tries: 3

vps_firewall_enabled: true
vps_fail2ban_enabled: true
vps_fail2ban_bantime: 3600
vps_fail2ban_maxretry: 5
```

### Fonts Configuration

```yaml
vps_fonts_install_nerd_fonts: true
vps_fonts_install_powerline_fonts: true
vps_fonts_default_monospace_font: "JetBrainsMono"
vps_fonts_default_font_size: 10
```

### Desktop & Theme Settings

```yaml
vps_install_desktop: true
vps_install_xrdp: true

# KDE Theme (via whitesur-theme role)
vps_whitesur_install: true
vps_theme_variant: "whitesur"
vps_kde_icon_theme: "WhiteSur-dark"
vps_kde_cursor_theme: "WhiteSur-cursors"

# KDE Manual Configuration (hybrid approach)
vps_kde_clone_config: true         # Clone shalva97/kde-configuration-files for panel layout
vps_kde_autostart_apps: []         # List of autostart applications

# XRDP Settings
vps_xrdp_port: 3389
vps_xrdp_color_depth: 24
```

### Terminal Settings

```yaml
# Konsole (primary, KDE-native)
# (configured via KDE system settings)

# Kitty (backup terminal emulator)
vps_terminal_install_kitty: true
vps_terminal_kitty_theme: "Nordic"
vps_terminal_kitty_font_family: "JetBrainsMono"
vps_terminal_kitty_font_size: 10
```

### Development Tools

```yaml
# Node.js
vps_development_install_nodejs: true
vps_development_nodejs_version: "20"

# Python
vps_development_install_python: true
vps_development_python_version: "3.12"
vps_development_python_pipx_packages:
  - black
  - pytest
  - poetry

# PHP
vps_development_install_php: true
vps_development_php_extensions:
  - curl
  - json
  - mbstring

# Composer
vps_development_install_composer: true

# Docker
vps_docker_install: true
vps_docker_log_max_size: "10m"
vps_docker_log_max_file: "3"
vps_docker_storage_driver: "overlay2"
```

### Code Editors

```yaml
# VS Code
vps_editors_install_vscode: true
vps_editors_vscode_extensions:
  - ms-python.python
  - ms-vscode.cpptools
  - hashicorp.terraform

# OpenCode
vps_editors_install_opencode: true

# Antigravity (AI tool)
vps_editors_install_antigravity: false
```

### CLI Tools (all optional)

```yaml
# TUI Tools
vps_tui_tools_install: true
# (lazygit, tig, ranger, mc, etc.)

# Network Tools
vps_network_tools_install: true
# (nmap, mtr, iftop, httpie, etc.)

# System Performance
vps_system_performance_install: true
# (btop, dstat, ncdu, inxi, etc.)

# Text Processing
vps_text_processing_install: true
# (ripgrep, fd, jq, yq, pandoc, etc.)

# File Management
vps_file_management_install: true
# (zoxide, trash-cli, etc.)

# Development & Debugging
vps_dev_debugging_install: true
# (gdb, strace, ltrace, valgrind, etc.)

# Code Quality
vps_code_quality_install: true
# (shellcheck, hadolint, yamllint, etc.)

# Productivity
vps_productivity_install: true
# (thefuck, tmux, etc.)

# Log Visualization
vps_log_visualization_install: true
# (lnav, multitail, etc.)

# AI Developer Tools
vps_ai_devtools_install: true
# (aider, shell-gpt, etc.)

# Cloud Native (optional, disabled by default)
vps_cloud_native_tools_install: false
# (kubectl, helm, k9s, etc.)
```

## Variable Naming Convention

All role-specific variables follow the pattern `vps_<role>_<variable>`:

- **Docker role**: `vps_docker_install`, `vps_docker_log_max_size`, `vps_docker_storage_driver`
- **Development role**: `vps_development_install_nodejs`, `vps_development_nodejs_version`, `vps_development_python_pipx_packages`
- **Editors role**: `vps_editors_install_vscode`, `vps_editors_vscode_extensions`
- **Terminal role**: `vps_terminal_install_kitty`, `vps_terminal_kitty_theme`
- **TUI Tools role**: `vps_tui_tools_install`, `vps_tui_tools_lazygit_version`

**Shared system variables** use `vps_` prefix only:
- `vps_username` - System user account
- `vps_timezone` - System timezone
- `vps_hostname` - System hostname
- `vps_default_font_size` - Default font size (used by multiple roles)
- `vps_default_monospace_font` - Default monospace font (used by multiple roles)

## Role Tags

Run specific components using tags (format: `[phase, role, feature]`):

```bash
# Bootstrap and security only
./setup.sh --tags bootstrap,security

# Desktop environment
./setup.sh --tags desktop

# All terminal and shell tools
./setup.sh --tags userconfig

# Development tools
./setup.sh --tags devtools

# Specific development tool
./setup.sh --tags development

# All tools (Phase 7)
./setup.sh --tags tools
```

## Skip Components

```bash
# Skip desktop (headless server mode)
./setup.sh --skip-tags desktop

# Skip XRDP (KDE without RDP)
./setup.sh --skip-tags xrdp

# Skip cloud tools
./setup.sh --skip-tags cloud

# Skip optional plugins
./setup.sh --skip-tags zsh
```

## Migration from v2.x to v3.0.0

The v3.0.0 release includes significant refactoring:

1. **Role Reordering**: Desktop environment now comes before terminal to satisfy KDE/WhiteSur dependencies
2. **Variable Renaming**: All role variables now use `vps_<role>_` naming convention for consistency
3. **New Features**: Kitty terminal emulator (backup), hybrid KDE config templates
4. **Progress Tracking**: `--resume` from v2.x versions will NOT work. Use `--fresh` or remove progress file and restart

If upgrading from v2.x:
```bash
# Remove old progress file (or it will conflict)
rm /var/lib/vps-setup/progress.json

# Run fresh installation with v3.0.0
./setup.sh
```
