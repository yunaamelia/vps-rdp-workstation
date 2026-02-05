# Configuration Guide

Complete configuration reference for VPS RDP Workstation.

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

### Desktop Settings

```yaml
vps_install_desktop: true
vps_kde_theme: "nordic"
vps_icon_theme: "Papirus-Dark"
vps_xrdp_port: 3389
vps_xrdp_color_depth: 24
```

### Development Tools

```yaml
install_nodejs: true
install_python: true
install_php: true
install_docker: true
install_vscode: true
```

### Optional Features

```yaml
install_cloud_tools: false  # kubectl, helm, k9s
install_antigravity: false  # Placeholder
```

## Role Tags

Run specific components:
```bash
# Security only
./setup.sh --tags security

# Desktop only
./setup.sh --tags desktop

# Development tools
./setup.sh --tags development,docker,editors
```

## Skip Components

```bash
# Skip desktop
./setup.sh --skip-tags desktop

# Skip cloud tools
./setup.sh --skip-tags cloud
```
