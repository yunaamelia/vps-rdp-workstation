# VPS RDP Developer Workstation

![Ansible](https://img.shields.io/badge/Ansible-2.14+-EE0000?style=flat&logo=ansible)
![Debian](https://img.shields.io/badge/Debian-13%20Trixie-A81D33?style=flat&logo=debian)
![License](https://img.shields.io/badge/License-MIT-blue)

Automated deployment of a complete remote developer workstation with KDE Plasma desktop, XRDP access, Docker, VS Code, and terminal enhancements. Connect via RDP from anywhere.

## Technology Stack

| Technology | Version | Purpose |
|------------|---------|---------|
| **Ansible** | 2.14+ | Infrastructure automation |
| **Debian** | 13 (Trixie) | Target operating system |
| **KDE Plasma** | Latest | Desktop environment |
| **XRDP** | Latest | Remote desktop server |
| **Docker** | CE Latest | Container runtime |
| **Node.js** | 20.x LTS | JavaScript runtime |
| **Python** | 3.x | System scripting |

## Quick Start

**Prerequisites:** Debian 13 (Trixie), 4GB+ RAM, 40GB+ disk, root access

```bash
# 1. Clone the repository
git clone https://github.com/your-org/vps-rdp-workstation.git
cd vps-rdp-workstation

# 2. Run pre-flight checks
./scripts/pre-flight-checks.sh

# 3. Run setup (will prompt for username)
sudo ./setup.sh
```

**Connect via RDP:** Use any RDP client to connect to port `3389`.

## Project Structure

```
vps-rdp-workstation/
├── setup.sh                 # Main entry point
├── ansible.cfg              # Ansible configuration
├── inventory/               # Host and variable definitions
│   └── group_vars/all.yml   # Configuration variables
├── playbooks/               # Deployment orchestration
│   ├── main.yml             # 10-phase deployment
│   ├── rollback.yml         # Rollback procedures
│   └── tasks/               # Phase implementations
├── roles/                   # Reusable Ansible roles (12)
├── templates/               # Jinja2 configuration templates
├── tests/                   # Validation scripts
└── docs/                    # Project documentation
```

<details>
<summary>View detailed documentation</summary>

- [Folder Structure Blueprint](docs/Project_Folders_Structure_Blueprint.md)
- [Technology Stack Blueprint](docs/Technology_Stack_Blueprint.md)
- [Workflow Documentation](docs/PROJECT-WORKFLOW-DOCUMENTATION.md)
- [Code Exemplars](docs/EXEMPLARS.md)

</details>

## What Gets Installed

### Desktop Environment
- KDE Plasma (minimal) with Breeze Dark/Catppuccin themes
- XRDP optimized for performance
- JetBrains Mono Nerd Font

### Development Tools
- Docker CE with docker-compose
- VS Code with extensions (ESLint, Prettier, Python, GitLens)
- Node.js 20.x + npm/pnpm/yarn
- Python 3 + pipx tools
- PHP + Composer
- Git + Lazygit + GitHub CLI

### Terminal Enhancements
- Zsh + Oh My Zsh
- Starship prompt
- Modern CLI tools (bat, exa, fd, ripgrep)
- Fuzzy finding (fzf, atuin)

### Security
- UFW firewall (SSH + RDP only)
- Fail2ban with SSH jail
- SSH hardening
- Unattended security updates

## Deployment Phases

| Phase | Name | Description |
|-------|------|-------------|
| 1 | Preparation | System logging, initial state |
| 2 | User Management | Create user, sudo configuration |
| 3 | Dependencies | Node.js, Python, PHP, Lazygit |
| 4 | Desktop | KDE Plasma, XRDP |
| 5 | Development Tools | Docker, VS Code, editors |
| 6 | Validation | Service verification |
| 7 | Optimization | Security hardening, performance |
| 8-9 | Enhancements | Terminal tools, plugins |
| 10 | Final | Cleanup, documentation |

## Configuration

Edit `inventory/group_vars/all.yml` to customize:

```yaml
# User
vps_username: "apexdev"
vps_timezone: "GMT+8"

# Theme
vps_theme: "catppuccin"  # or "breeze-dark"

# Features
install_docker: true
install_vscode: true
install_antigravity: true
```

## Testing

```bash
# Run comprehensive validation
./tests/comprehensive-validation.sh

# Run phase-specific tests
./tests/phase5-tests.sh
```

## Rollback

```bash
# Rollback specific phase
ansible-playbook playbooks/rollback.yml --tags phase5

# Full rollback
ansible-playbook playbooks/rollback.yml
```

## Development Workflow

1. **Setup**: Clone repo, configure `inventory/group_vars/all.yml`
2. **Deploy**: Run `./setup.sh` or `ansible-playbook playbooks/main.yml`
3. **Test**: Run phase tests after each modification
4. **Commit**: Follow conventional commits

## Contributing

1. Follow patterns in [Code Exemplars](docs/EXEMPLARS.md)
2. Add tests for new features
3. Update documentation
4. Run pre-commit hooks before pushing

## License

MIT License - see [LICENSE](LICENSE) for details.

---

**Documentation:** See `docs/` folder for detailed architecture and workflow documentation.
