# Workstation Optimization & Modernization Plan

## TL;DR

> **Quick Summary**: Comprehensive modernization of the workstation with best-in-class UI/UX (icons, fonts), deep performance tuning (kernel, I/O, ZRAM), and a suite of modern CLI/productivity tools.
> 
> **Deliverables**:
> - Modern Icon Themes (Tela-circle, Qogir)
> - Optimized Font Rendering (LCD subpixel)
> - Performance Tunings (ZRAM, BBR, I/O Scheduler, Cache Pressure)
> - Modern CLI Toolset (eza, fzf, delta, lazydocker, yazi, duf)
> - Optimized Starship Prompt
> 
> **Estimated Effort**: Medium
> **Parallel Execution**: YES - 3 Waves
> **Critical Path**: Repo Updates → Package Installs → Config Application

---

## Context

### Research Findings
- **UI/UX**: Papirus is solid, but **Tela-circle** and **Qogir** are current community favorites. Font rendering needs explicit **subpixel (RGB)** and **slight hinting** for RDP clarity.
- **Performance**: `vm.swappiness=10` is outdated for ZRAM; `vm.vfs_cache_pressure=50` helps desktop responsiveness. NVMe drives perform best with `none` or `kyber` scheduler.
- **Tools**: `eza` replaces `ls`, `delta` replaces `git diff`, `lazydocker` is essential for container management. `yazi` is the modern TUI file manager.

### Constraints
- **Terminal Role**: "Patch only" - do not rewrite the entire structure, just enhance config.
- **Security**: Already loosened in previous steps, maintain this balance.

---

## Work Objectives

### Core Objective
Transform the standard Ansible setup into a "Power User" workstation with 2025-era tooling and optimizations.

### Concrete Deliverables
- [ ] `/etc/sysctl.d/99-workstation.conf` with tuned parameters
- [ ] `/etc/udev/rules.d/60-io-scheduler.rules` for I/O tuning
- [ ] `/etc/fonts/conf.d/10-rendering.conf` for font quality
- [ ] Installed packages: `git-delta`, `duf`, `yazi`, `lazydocker`
- [ ] Icon themes in `~/.local/share/icons`

### Definition of Done
- [ ] All new tools (`delta`, `duf`, `yazi`) execute successfully
- [ ] Sysctl settings persist after reload
- [ ] Font rendering config is active
- [ ] Starship prompt loads instantly (<50ms)

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: NO (Ansible project, not app code)
- **Automated tests**: None (Infrastructure-as-Code)
- **Framework**: N/A

### Agent-Executed QA Scenarios (MANDATORY)

**Scenario: Verify CLI Tools**
  Tool: Bash
  Steps:
    1. Run `delta --version` → Assert exit code 0
    2. Run `duf --version` → Assert exit code 0
    3. Run `yazi --version` → Assert exit code 0
    4. Run `lazydocker --version` → Assert exit code 0

**Scenario: Verify Performance Tunings**
  Tool: Bash
  Steps:
    1. `sysctl vm.vfs_cache_pressure` → Assert value is 50
    2. `cat /sys/block/nvme0n1/queue/scheduler` (if NVMe) → Assert contains `[none]` or `[kyber]`
    3. `zramctl` → Assert ZRAM device exists and uses zstd

**Scenario: Verify UI Assets**
  Tool: Bash
  Steps:
    1. `ls ~/.local/share/icons/Tela-circle` → Assert directory exists
    2. `ls ~/.local/share/icons/Qogir` → Assert directory exists
    3. `cat /home/developer/.config/fontconfig/conf.d/10-rdp-rendering.conf` → Assert contains `rgba` and `hintstyle`

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation):
├── Task 1: Install Modern CLI Tools (System packages)
├── Task 2: Install Lazydocker (Binary install)
└── Task 3: Install Icon Themes (Git clones)

Wave 2 (Configuration):
├── Task 4: Apply Performance Tunings (Sysctl & Udev)
├── Task 5: Configure Font Rendering
└── Task 6: Patch Terminal Config (Starship & Aliases)

Wave 3 (Integration):
└── Task 7: Verify & Cleanup
```

---

## TODOs

- [ ] 1. Install Modern CLI Tools (apt/cargo)
  **What to do**:
  - Update `roles/tui-tools/tasks/main.yml` to include: `git-delta`, `duf`, `bat` (ensure installed), `fd-find`.
  - NOTE: `yazi` might need cargo or separate binary install if not in repo. Check availability first, fallback to cargo/binary.
  **Verification**: `delta --version`, `duf --version`

- [ ] 2. Install Lazydocker
  **What to do**:
  - Add task to `roles/docker/tasks/main.yml` (or `productivity`).
  - Fetch latest release from GitHub releases.
  - Install to `/usr/local/bin`.
  **Verification**: `lazydocker --version`

- [ ] 3. Install Modern Icon Themes
  **What to do**:
  - Update `roles/desktop/tasks/main.yml`.
  - Clone **Tela-circle** (vinceliuice/Tela-circle-icon-theme).
  - Clone **Qogir** (vinceliuice/Qogir-icon-theme).
  - Run their install scripts (usually `./install.sh -d ~/.local/share/icons`).
  **Verification**: `ls ~/.local/share/icons/Tela-circle`

- [ ] 4. Apply Deep Performance Tunings
  **What to do**:
  - Update `roles/system-performance/tasks/main.yml`.
  - Sysctl: `vm.vfs_cache_pressure=50`, `vm.dirty_ratio=10`, `vm.dirty_background_ratio=5`.
  - Udev: Create rule to set scheduler based on specific kernel docs (NVMe=none, SSD=mq-deadline).
  - Enable `systemd-oomd` if available (Debian 13 default).
  **Verification**: `sysctl -a | grep cache_pressure`

- [ ] 5. Configure Font Rendering
  **What to do**:
  - Update `roles/fonts/tasks/main.yml`.
  - Create `/home/{{ vps_username }}/.config/fontconfig/conf.d/10-rendering.conf`.
  - Settings: `antialias=true`, `hinting=true`, `hintstyle=hintslight`, `rgba=rgb`, `lcdfilter=lcddefault`.
  **Verification**: File existence and content check.

- [ ] 6. Patch Terminal Configuration
  **What to do**:
  - Edit `roles/shell-styling/templates/starship.toml.j2`.
  - Add `scan_timeout = 10` (ms) to root.
  - Disable heavy modules (like `package` or specific language versions if slow).
  - Add aliases to `roles/terminal/tasks/main.yml` (or zshrc template): `ls=eza`, `cat=bat`, `diff=delta`.
  **Verification**: `grep scan_timeout` in config.

- [ ] 7. Final Verification & Cleanup
  **What to do**:
  - Run a full validation check of all installed tools.
  - Ensure no broken configs.
