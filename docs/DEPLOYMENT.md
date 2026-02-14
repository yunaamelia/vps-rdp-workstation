---
post_title: Deployment Guide
author1: antigravity
post_slug: deployment-guide
microsoft_alias: antigravity
featured_image: /assets/deployment-guide.png
categories: [DevOps, Automation]
tags: [ansible, debian, deployment, guide]
ai_note: false
summary: Comprehensive guide for deploying the VPS RDP workstation using Ansible.
post_date: 2026-02-13
---

**Target System**: Debian 13 (Trixie) VPS
**Architecture**: x86_64
**Minimum Requirements**: 4GB RAM (8GB Recommended for KDE Plasma 6)

## Quick Start

The entire provisioning process is wrapped in `setup.sh`, which handles secret
generation, Ansible installation, Mitogen optimization, and playbook execution.

```bash
# 1. Clone the repository
git clone https://github.com/yunaamelia/vps-rdp-workstation.git
cd vps-rdp-workstation

# 2. Configure secrets (optional, interactive if skipped)
# cp secrets.example secrets
# nano secrets

# 3. Run the deployment
./setup.sh
```

**Note**: Do **NOT** run `ansible-playbook` directly. `setup.sh` performs
critical environment validation and variable injection.

---

## Deployment Phases

The playbook (`playbooks/main.yml`) executes roles in a strict dependency order.
Security and connectivity (XRDP) are prioritized before developer tools.

### Phase 1: Foundation (Critical)
1.  **common**: System packages, locale, time, user setup.
2.  **security**: UFW firewall, fail2ban, SSH hardening, sysctl tuning.
3.  **fonts**: Nerd Fonts (JetBrainsMono, Hack) required for terminal styling.

### Phase 2: Desktop Environment
4.  **desktop**: KDE Plasma 6 base installation (minimal).
5.  **xrdp**: Remote Desktop Protocol server with audio support and TLS security.
6.  **kde-optimization**: Disabling animations/indexing, power settings, wallpaper.
7.  **kde-apps**: Essential GUI apps (Firefox, Dolphin, Ark).
8.  **whitesur-theme**: WhiteSur theme, icons, and cursors.

### Phase 3: Developer Environment
9.  **terminal**: Kitty terminal emulator config.
10. **shell-styling**: Starship prompt, fast-syntax-highlighting.
11. **zsh-enhancements**: Autosuggestions, history, aliases.
12. **development**: Git, build-essential, Python/Node.js runtimes.
13. **docker**: Docker Engine, Compose v2, daemon tuning.
14. **editors**: Neovim (LazyVim), VS Code (remote-ssh ready).

### Phase 4: Tooling (Parallelizable)
15. **tui-tools**: htop, btop, fzf, ripgrep, bat.
16. **network-tools**: curl, wget, dig, nmap.
17. **system-performance**: perf, strace, iotop.
18. **text-processing**: jq, yq, sed, awk.
19. **file-management**: ranger, ncdu, fd.
20. **dev-debugging**: gdb, lldb, valgrind.
21. **code-quality**: shellcheck, pre-commit, hadolint.
22. **productivity**: taskwarrior, timewarrior.
23. **log-visualization**: lnav, goaccess.
24. **ai-devtools**: gh-copilot, fabric.
25. **cloud-native**: kubectl, k9s, helm.

---

## Partial Deployment (Tags)

You can run specific parts of the provisioning using Ansible tags passed to
`setup.sh`.

```bash
# Only update security settings
./setup.sh -- --tags security

# Only re-deploy KDE configurations
./setup.sh -- --tags kde-optimization

# Fix XRDP and Audio
./setup.sh -- --tags xrdp

# Update dotfiles (shell/terminal)
./setup.sh -- --tags dotfiles
```

**Common Tags**: `security`, `desktop`, `xrdp`, `dev`, `docker`, `editors`, `tools`.

---

## Verification

After deployment, verify the installation:

```bash
# Run the validation suite (checks ports, services, versions)
./tests/validate.sh
```

**Expected Output**:
- XRDP listening on 3389
- UFW enabled (allowing 22, 3389)
- Docker active
- User shell set to Zsh

---

## Rollback / Uninstall

To remove major components (Use with caution):

```bash
ansible-playbook playbooks/rollback.yml
```
*Note: This does not reset the OS completely, but removes the desktop environment
and heavier packages.*
