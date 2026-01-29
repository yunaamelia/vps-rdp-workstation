# VPS RDP Workstation - Glossary

This glossary defines terms, acronyms, and technical references used in the VPS RDP Developer Workstation Automation project.

---

## General Terms

| Term | Definition |
|------|------------|
| **VPS** | Virtual Private Server - A virtual machine sold as a service by cloud providers |
| **RDP** | Remote Desktop Protocol - Microsoft's proprietary protocol for remote desktop access |
| **Workstation** | A complete development environment including desktop, tools, and services |
| **Idempotent** | Operations that produce the same result regardless of how many times they are executed |
| **Rollback** | The process of reverting a system to a previous known-good state |

---

## Operating System & Distribution

| Term | Definition |
|------|------------|
| **Debian 13 (Trixie)** | Current testing/stable release of Debian Linux distribution |
| **x86_64** | 64-bit CPU architecture (also known as AMD64) |
| **apt** | Advanced Package Tool - Debian's package management system |
| **systemd** | System and service manager for Linux operating systems |
| **sysctl** | Interface for examining and dynamically changing kernel parameters |

---

## Desktop Environment

| Term | Definition |
|------|------------|
| **KDE Plasma** | Modern, feature-rich desktop environment for Linux |
| **SDDM** | Simple Desktop Display Manager - Display manager for X11 and Wayland |
| **XRDP** | Open-source RDP server for Linux systems |
| **X11** | X Window System - Windowing system for bitmap displays |
| **Compositor** | Software that combines visual elements from multiple sources into a single image |
| **Wayland** | Modern display server protocol (not used in this project due to XRDP compatibility) |

---

## Security Terms

| Term | Definition |
|------|------------|
| **UFW** | Uncomplicated Firewall - User-friendly interface for iptables |
| **Fail2ban** | Intrusion prevention software that bans IPs showing malicious signs |
| **SSH** | Secure Shell - Cryptographic network protocol for secure remote access |
| **Jail** | Fail2ban configuration that monitors specific services for attacks |
| **TLS** | Transport Layer Security - Cryptographic protocol for secure communication |
| **RBAC** | Role-Based Access Control - Authorization based on user roles |
| **Sudo** | Program that allows users to run commands with elevated privileges |
| **GPG Key** | GNU Privacy Guard key for cryptographic verification of packages |

---

## Development Tools

| Term | Definition |
|------|------------|
| **Node.js** | JavaScript runtime built on Chrome's V8 JavaScript engine |
| **npm** | Node Package Manager - Default package manager for Node.js |
| **pnpm** | Fast, disk space efficient package manager for Node.js |
| **Yarn** | Alternative package manager for Node.js |
| **Python** | High-level, general-purpose programming language |
| **pipx** | Tool to install and run Python applications in isolated environments |
| **PHP** | Server-side scripting language for web development |
| **Composer** | Dependency manager for PHP |
| **Docker** | Container platform for developing, shipping, and running applications |
| **Docker Compose** | Tool for defining and running multi-container Docker applications |
| **VS Code** | Visual Studio Code - Popular source code editor by Microsoft |
| **GitHub CLI** | Command-line interface for GitHub operations |
| **Lazygit** | Terminal UI for git commands |

---

## Terminal & Shell

| Term | Definition |
|------|------------|
| **Zsh** | Z shell - Extended Bourne shell with many improvements |
| **Oh My Zsh** | Framework for managing Zsh configuration |
| **Starship** | Cross-shell prompt written in Rust |
| **Nerd Font** | Patched fonts with programming icons and symbols |
| **JetBrains Mono** | Monospace font designed for developers |1

---

## Automation & Configuration

| Term | Definition |
|------|------------|
| **Ansible** | Open-source automation tool for configuration management |
| **Playbook** | Ansible configuration file written in YAML |
| **Role** | Ansible organizational unit grouping related tasks |
| **Handler** | Ansible task triggered by notifications from other tasks |
| **Jinja2** | Python templating engine used by Ansible |
| **Inventory** | Ansible file listing target hosts and their groupings |
| **Facts** | System information gathered by Ansible about managed nodes |
| **Idempotency** | Property of operations that can be applied multiple times without changing the result |

---

## Cloud & Infrastructure

| Term | Definition |
|------|------------|
| **DigitalOcean** | Cloud infrastructure provider (example VPS provider) |
| **Droplet** | DigitalOcean's term for a VPS instance |
| **Snapshot** | Point-in-time backup of a VPS instance |
| **VM** | Virtual Machine - Software emulation of a physical computer |
| **IaC** | Infrastructure as Code - Managing infrastructure through code |

---

## Recovery & Reliability

| Term | Definition |
|------|------------|
| **RTO** | Recovery Time Objective - Maximum acceptable downtime |
| **RPO** | Recovery Point Objective - Maximum acceptable data loss period |
| **SPOF** | Single Point of Failure - Component whose failure stops the entire system |
| **DR** | Disaster Recovery - Procedures for recovering from catastrophic failures |
| **Checkpoint** | Saved system state that can be restored to |
| **Phased Rollback** | Rolling back specific deployment phases independently |

---

## Protocols & Ports

| Port | Protocol | Service |
|------|----------|---------|
| 22 | TCP | SSH (Secure Shell) |
| 3389 | TCP | RDP (Remote Desktop Protocol) |
| 443 | TCP | HTTPS (Secure web traffic) |
| 80 | TCP | HTTP (Web traffic) |

---

## File Paths & Conventions

| Path | Purpose |
|------|---------|
| `/etc/sudoers.d/` | Drop-in directory for sudo configurations |
| `/etc/xrdp/xrdp.ini` | XRDP main configuration file |
| `/etc/docker/daemon.json` | Docker daemon configuration |
| `/etc/fail2ban/jail.local` | Fail2ban local jail configuration |
| `/etc/ssh/sshd_config` | SSH daemon configuration |
| `/var/log/vps-setup/` | Deployment logs directory |
| `~/.zshrc` | Zsh shell configuration file |
| `~/.config/starship.toml` | Starship prompt configuration |
| `~/.xsession` | User X session startup script |

---

## Acronyms Quick Reference

| Acronym | Full Form |
|---------|-----------|
| APT | Advanced Package Tool |
| CIDR | Classless Inter-Domain Routing |
| CLI | Command Line Interface |
| CPU | Central Processing Unit |
| DNS | Domain Name System |
| EXT4 | Fourth Extended Filesystem |
| FOSS | Free and Open Source Software |
| FQDN | Fully Qualified Domain Name |
| GB | Gigabyte |
| GPG | GNU Privacy Guard |
| GUI | Graphical User Interface |
| IP | Internet Protocol |
| JSON | JavaScript Object Notation |
| LTS | Long Term Support |
| MB | Megabyte |
| NFS | Network File System |
| OS | Operating System |
| PAM | Pluggable Authentication Modules |
| PID | Process Identifier |
| RAID | Redundant Array of Independent Disks |
| RAM | Random Access Memory |
| SSD | Solid State Drive |
| TTY | TeleTYpewriter (terminal) |
| UID | User Identifier |
| UUID | Universally Unique Identifier |
| VCPU | Virtual CPU |
| YAML | YAML Ain't Markup Language |

---

*Last Updated: 2026-01-28*
