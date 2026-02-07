# VPS RDP Developer Workstation

> 🚀 Single-command automation to transform a fresh Debian 13 VPS into a fully-configured RDP developer workstation with security hardening and beautiful logging.

[![CI](https://github.com/yunaamelia/vps-rdp-workstation/actions/workflows/ci.yml/badge.svg)](https://github.com/yunaamelia/vps-rdp-workstation/actions/workflows/ci.yml)
[![Version](https://img.shields.io/badge/version-3.0.0-blue.svg)](https://github.com/example/vps-rdp-workstation)
[![Debian](https://img.shields.io/badge/debian-13%20trixie-green.svg)](https://www.debian.org/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

## ✨ Features

- **🖥️ KDE Plasma Desktop** with Nordic theme optimized for RDP
- **🔐 Security Hardened** - UFW firewall, fail2ban, SSH hardening
- **⚡ One Command Setup** - Complete automation from fresh VPS
- **⚡ Mitogen Acceleration** - 2-7x faster Ansible execution
- **📊 ARA Reports** - Beautiful HTML reports of every Ansible run
- **📈 Playbook Grapher** - Visual SVG diagrams of playbook structure
- **🛠️ Full Dev Stack** - Node.js, Python, PHP, Docker
- **🎨 Beautiful Terminal** - Zsh + Oh My Zsh + Agnoster + 7 plugins
- **📦 50+ Dev Tools** - lazygit, ripgrep, fzf, btop, and more
- **🤖 AI Dev Tools** - aider, shell-gpt pre-installed

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/example/vps-rdp-workstation.git
cd vps-rdp-workstation

# Run setup (interactive mode)
./setup.sh

# Or with environment variables (CI mode)
VPS_USERNAME=developer VPS_SECRETS_FILE=/root/.secrets ./setup.sh --ci
```

## 📋 Prerequisites

| Requirement      | Specification                  |
| ---------------- | ------------------------------ |
| **OS**           | Debian 13 (Trixie)             |
| **Architecture** | x86_64 (amd64)                 |
| **RAM**          | 4GB minimum, 8GB recommended   |
| **Storage**      | 40GB minimum, 60GB recommended |
| **Access**       | Root or sudo privileges        |

## 🔧 Configuration

### Environment Variables

| Variable           | Required | Default         | Description                  |
| ------------------ | -------- | --------------- | ---------------------------- |
| `VPS_USERNAME`     | ✅       | -               | Primary workstation username |
| `VPS_SECRETS_FILE` | ⚪       | -               | Path to password file (0600) |
| `VPS_TIMEZONE`     | ⚪       | UTC             | System timezone              |
| `VPS_HOSTNAME`     | ⚪       | dev-workstation | System hostname              |

### Secrets File Format

```bash
# Create secrets file
echo "password=YourSecurePassword123!" > ~/.secrets
chmod 600 ~/.secrets
```

## 🏗️ What Gets Installed

### Desktop Environment

- KDE Plasma Desktop with Nordic theme
- Polonium tiling extension for KWin _(archived upstream, final stable version)_
- XRDP for Windows Remote Desktop access
- SDDM display manager
- Papirus icon theme
- Firefox ESR

### Development Stack

- **Node.js 20 LTS** with npm, yarn, pnpm, TypeScript
- **Python 3.12** with pipx, black, pytest, poetry
- **PHP** with Composer and common extensions
- **Docker** with Compose V2 and BuildKit

### Code Editors

- Visual Studio Code with 10+ extensions
- OpenCode AI agent

### Terminal Environment

- Zsh with Oh My Zsh
- Agnoster theme with JetBrains Mono Nerd Font
- 7 external plugins: autosuggestions, syntax-highlighting, fzf-tab, forgit
- Zoxide for smart directory jumping
- **Starship Prompt** with AI-assisted optimization ([guide](docs/STARSHIP_OPTIMIZATION.md))

### Developer Tools

| Category        | Tools                          |
| --------------- | ------------------------------ |
| **TUI**         | lazygit, tig, ranger, mc       |
| **Network**     | nmap, mtr, iftop, httpie       |
| **Performance** | btop, dstat, ncdu, inxi        |
| **Text**        | ripgrep, fd, jq, yq, pandoc    |
| **Quality**     | shellcheck, hadolint, yamllint |
| **AI**          | aider, shell-gpt               |

## 🔐 Security Features

- ✅ UFW firewall with default-deny incoming
- ✅ SSH hardening (root login disabled, rate limiting)
- ✅ fail2ban for SSH and RDP brute-force protection
- ✅ Unattended security updates
- ✅ Secure password hashing (SHA-512)
- ✅ No credentials in logs or command history

## 📁 Project Structure

```
vps-rdp-workstation/
├── setup.sh              # Main entry point
├── ansible.cfg           # Ansible configuration
├── inventory/
│   ├── hosts.yml         # Inventory file
│   └── group_vars/all.yml # Configuration variables
├── playbooks/
│   └── main.yml          # Main orchestration playbook
├── roles/
│   ├── common/           # System foundation
│   ├── security/         # Firewall, fail2ban, SSH
│   ├── fonts/            # Nerd Fonts
│   ├── desktop/          # KDE Plasma + XRDP
│   ├── development/      # Node.js, Python, PHP
│   ├── docker/           # Docker Engine
│   ├── terminal/         # Zsh + Oh My Zsh
│   ├── zsh-enhancements/ # External plugins
│   ├── editors/          # VS Code, OpenCode
│   └── [10 tool roles]/  # Various dev tools
├── templates/
│   └── summary-log.j2    # Summary log template
└── docs/
    └── README.md
```

## 🛠️ Development Setup

1.  **Install Python Dependencies:**

    ```bash
    pip install pre-commit ansible-core
    ```

2.  **Install Ansible Collections:**

    ```bash
    ansible-galaxy collection install -r requirements.yml
    ```

3.  **Setup Pre-commit Hooks:**
    ```bash
    pre-commit install
    ```

## 🎯 Usage Examples

```bash
# Interactive installation
./setup.sh

# Dry run (preview changes)
./setup.sh --dry-run

# Verbose mode
./setup.sh --verbose

# CI/CD mode (non-interactive)
VPS_USERNAME=developer VPS_SECRETS_FILE=/root/.secrets ./setup.sh --ci

# Skip validation (advanced)
./setup.sh --skip-validation
```

## 🔌 Connecting via RDP

1. Open **Windows Remote Desktop** (`mstsc.exe`)
2. Enter your VPS IP address: `your-vps-ip:3389`
3. Login with your configured username and password
4. Enjoy your Nordic-themed KDE Plasma desktop!

## 📝 Logs

| Log File                         | Purpose                        |
| -------------------------------- | ------------------------------ |
| `/var/log/vps-setup.log`         | Full detailed installation log |
| `/var/log/vps-setup-error.log`   | Errors and warnings only       |
| `/var/log/vps-setup-summary.log` | Beautiful summary report       |
| `/var/log/ara-database.sqlite`   | ARA run history database       |

## 📊 Analysis & Visualization

### ARA - Ansible Run Analysis

Every playbook run is automatically recorded. View your run history:

```bash
# List all recorded playbook runs
ara playbook list

# Show details of a specific run
ara playbook show <playbook-id>

# Generate static HTML reports
ara-manage generate /var/www/html/ara-reports

# Start the ARA web UI (development)
ara-manage runserver
```

### Playbook Grapher - Visual Documentation

Generate SVG diagrams showing playbook structure and task flow:

```bash
# Generate playbook diagram
ansible-playbook-grapher playbooks/main.yml -o docs/playbook-graph

# Include role tasks in the graph
ansible-playbook-grapher playbooks/main.yml --include-role-tasks -o docs/playbook-detailed
```

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting a PR.

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<p align="center">
  Made with ❤️ for developers who need remote workstations
</p>
