# Changelog

All notable changes to VPS RDP Workstation will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - 2026-02-05

### Added
- Complete Ansible automation with 20 modular roles
- KDE Plasma desktop with Nordic theme
- XRDP remote desktop access
- 210+ development tools from 6 awesome lists
- Custom callback plugin for beautiful progress output
- Comprehensive validation script (30 success criteria)
- Rollback playbook with confirmation prompt
- Three-tier logging (main, error, summary)
- Documentation suite (README, SECURITY, TROUBLESHOOTING, CONFIGURATION, ARCHITECTURE)

### Security
- File-based password input with 0600 permissions
- SHA-512 password hashing
- Firewall-first deployment principle
- UFW with default deny incoming
- SSH hardening (no root login, max 3 auth tries)
- Fail2ban for SSH and XRDP
- Download checksum verification (SHA-256)
- Log sanitization (no passwords or hashes logged)
- Automatic security updates via unattended-upgrades

### Development Tools
- Node.js 20.x LTS with npm
- Python 3.12 with pip and pipx
- PHP 8.2 with Composer
- Docker 25.x with Compose V2
- VS Code with essential extensions
- lazygit, tig, ranger, mc (TUI tools)
- ripgrep, fd, jq, yq (text processing)
- btop, dstat, ncdu (system monitoring)

### Terminal
- Zsh with Oh My Zsh
- Agnoster theme with Powerline symbols
- JetBrains Mono Nerd Font
- zsh-autosuggestions, zsh-syntax-highlighting
- zoxide for smart directory navigation

## [2.0.0] - Previous Version

### Changed
- Migrated from shell scripts to Ansible
- Restructured for idempotency

## [1.0.0] - Initial Release

### Added
- Basic VPS setup automation
- Single shell script deployment
