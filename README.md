# VPS RDP Developer Workstation

Transform a fresh **Debian 13 (Trixie)** VPS into a fully-configured RDP developer workstation with a single command.

## 🚀 Quick Start

```bash
# Clone or download to your VPS
cd /opt
git clone https://github.com/your-repo/vps-rdp-workstation.git
cd vps-rdp-workstation

# Make executable
chmod +x setup.sh

# Run (interactive mode)
sudo ./setup.sh

# Run (non-interactive mode)
export VPS_USERNAME="developer"
export VPS_PASSWORD="your-secure-password"
sudo -E ./setup.sh --non-interactive
```

## ✨ What Gets Installed

### Desktop Environment
- **KDE Plasma** (minimal installation) with dark theme
- **XRDP** for Windows Remote Desktop connections
- **SDDM** display manager

### Development Tools
- **VS Code** with essential extensions
- **Node.js LTS** (v20.x) with npm, yarn, pnpm
- **Python 3.12+** with pipx and common tools
- **PHP 8.x** with Composer
- **Docker** with Compose V2
- **GitHub CLI**, **Lazygit**

### Terminal Experience
- **Zsh** with Oh My Zsh
- **Starship** prompt (Catppuccin theme)
- **JetBrains Mono Nerd Font**

### Security
- **UFW** firewall (deny by default)
- **Fail2ban** with SSH and XRDP protection
- **SSH hardening** (no root, limited retries)
- **Unattended security updates**

## 📋 Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| OS | Debian 13 (Trixie) | Debian 13 (Trixie) |
| CPU | 2 cores | 4+ cores |
| RAM | 4 GB | 8 GB |
| Storage | 40 GB | 60+ GB |
| Architecture | x86_64 | x86_64 |

## 🔧 Configuration

Edit `inventory/group_vars/all.yml` before running to customize:

```yaml
# User settings
vps_username: developer
vps_hostname: vps-workstation
vps_timezone: UTC

# Desktop theme
vps_theme: dark  # or 'light'

# Security
ssh_port: 22
xrdp_port: 3389

# What to install
install_docker: true
install_browser: true
install_opencode: true
```

## 🔐 Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `VPS_USERNAME` | Yes (non-interactive) | - | Workstation user |
| `VPS_PASSWORD` | Yes (non-interactive) | - | User password |
| `VPS_TIMEZONE` | No | UTC | System timezone |
| `VPS_HOSTNAME` | No | vps-workstation | System hostname |
| `VPS_THEME` | No | dark | KDE theme |

## 📁 Project Structure

```
vps-rdp-workstation/
├── setup.sh                 # Main entry point
├── ansible.cfg              # Ansible configuration
├── inventory/
│   ├── hosts.yml            # Target hosts
│   └── group_vars/all.yml   # Configuration variables
├── playbooks/
│   ├── main.yml             # Orchestration
│   ├── phase1-preparation.yml
│   ├── phase2-user-management.yml
│   ├── phase3-dependencies.yml
│   ├── phase4-rdp-packages.yml
│   ├── phase5-validation.yml
│   ├── phase6-optimization.yml
│   ├── phase7-final-validation.yml
│   └── phase8-enhancements.yml
├── templates/               # Configuration templates
├── scripts/                 # Utility scripts
└── tests/                   # Validation tests
```

## 🔄 Deployment Phases

| Phase | Description | Time |
|-------|-------------|------|
| 1 | System preparation, checkpoint | 5-10 min |
| 2 | User management, sudo config | 2-3 min |
| 3 | Development dependencies | 10-15 min |
| 4 | Desktop, XRDP, Docker, tools | 15-20 min |
| 5 | Installation validation | 2-3 min |
| 6 | Security, optimization | 5-10 min |
| 7 | Final validation | 2-3 min |
| 8 | Optional enhancements | 2-5 min |

**Total: 45-60 minutes**

## 🖥️ Connecting via RDP

After deployment, connect using Windows Remote Desktop:

1. Open `mstsc.exe` (Remote Desktop Connection)
2. Enter: `<your-vps-ip>:3389`
3. Login with your configured username and password
4. Enjoy your KDE Plasma desktop!

## 🛠️ Troubleshooting

### RDP Connection Refused
```bash
# Check XRDP status
sudo systemctl status xrdp

# Restart XRDP
sudo systemctl restart xrdp

# Check firewall
sudo ufw status
```

### Docker Permission Denied
```bash
# Logout and login again for group changes
# Or run:
newgrp docker
```

### Black Screen on RDP
```bash
# Check xsession file
cat ~/.xsession

# Restart display manager
sudo systemctl restart sddm
```

## 📝 Logs

All deployment logs are stored in `/var/log/vps-setup/`:

- `deployment.log` - Full deployment log
- `phase*-complete.txt` - Phase completion markers
- `deployment-summary.txt` - Final summary
- `final-validation-report.txt` - Validation results

## 🔙 Rollback

To rollback to a previous state:

```bash
# Rollback specific phase
ansible-playbook playbooks/rollback.yml --tags phase4

# Full system rollback (requires snapshot)
./scripts/rollback-full.sh <snapshot-id>
```

## 📄 License

MIT License

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## 🙏 Acknowledgments

- [Ansible](https://www.ansible.com/)
- [KDE Plasma](https://kde.org/plasma-desktop/)
- [XRDP](https://github.com/neutrinolabs/xrdp)
- [Oh My Zsh](https://ohmyz.sh/)
- [Starship](https://starship.rs/)
