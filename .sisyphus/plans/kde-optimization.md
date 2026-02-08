# KDE Desktop Optimization Plan

## TL;DR

> **Quick Summary**: Enhance the KDE Plasma desktop experience on Debian 13 with expert UI/UX optimizations, performance tuning, and workflow tools.
>
> **Deliverables**:
> - Optimized `roles/desktop` with new packages (`yakuake`, `dolphin-plugins`, `kcalc`, etc.)
> - New `optimizations.yml` task file for advanced configurations
> - Polonium Tiling Window Manager installation
> - Konsave configuration manager installation via pipx
> - Performance tuning (Baloo disabled, Dolphin previews enabled)
>
> **Estimated Effort**: Medium
> **Parallel Execution**: YES (Wave 1: Packages & Pipx setup; Wave 2: Polonium & Konsave; Wave 3: Configs)
> **Critical Path**: Install Pipx → Install Konsave

---

## Context

### Original Request
Implement expert-level KDE optimizations including visual refinements, performance tuning, and workflow enhancements based on the "awesome-kde" list.

### Metis Review & Analysis
**Key Constraints Identified**:
- **Execution Order**: `desktop` role runs *before* `development`. Installing `konsave` via pip requires `python3-pip` and `pipx` to be installed *within* the `desktop` role first.
- **PEP 668**: Debian 13 restricts system-wide pip. `pipx` is the compliant solution.
- **Polonium**: Not in Debian repos. Must install via `get_url` (GitHub Releases) + `kpackagetool6`.
- **Config**: Use `community.general.ini_file` for robust config management (`baloofilerc`, `dolphinrc`).

---

## Work Objectives

### Core Objective
Transform the basic KDE setup into a power-user workstation with tiling, instant terminal access, and optimized file management.

### Concrete Deliverables
- Modified `roles/desktop/tasks/main.yml`: Added packages and include for optimizations.
- New `roles/desktop/tasks/optimizations.yml`: Tasks for Polonium, Konsave, and Configs.
- Configured `~/.config/baloofilerc`: File search disabled.
- Configured `~/.config/dolphinrc`: Previews enabled.

### Definition of Done
- [x] `konsave --version` returns version number
- [x] `kpackagetool6 --list-packages` shows Polonium
- [x] `yakuake`, `kcalc`, `spectacle` are present in `dpkg -l`
- [x] `baloofilerc` contains `Indexing-Enabled=false`

### Must Have
- **Idempotency**: All tasks must be safe to run multiple times.
- **User Context**: All user-level changes (pipx, kpackagetool) must run as `{{ vps_username }}`.
- **Dependency Safety**: Ensure `pipx` is installed before using it.

### Must NOT Have
- **System Pip**: Do not use `pip install` with sudo or `--break-system-packages`.
- **Manual Steps**: No requirement for user to manually configure settings.

---

## Verification Strategy

### Test Decision
- **Infrastructure exists**: NO (Ansible project, not app code)
- **Automated tests**: Agent-Executed QA Scenarios ONLY.
- **Framework**: N/A

### Agent-Executed QA Scenarios (MANDATORY)

#### Scenario 1: Verify Package Installation
- **Tool**: Bash
- **Steps**:
  1. Run `dpkg -l | grep -E "yakuake|dolphin-plugins|ffmpegthumbs|kcalc|spectacle"`
  2. Assert output contains all package names
  3. Run `dpkg -l | grep python3-pipx`
  4. Assert output contains `python3-pipx`
- **Evidence**: `dpkg_check.txt`

#### Scenario 2: Verify Konsave Installation
- **Tool**: interactive_bash (tmux)
- **Steps**:
  1. `tmux new-session: su - {{ vps_username }}`
  2. Send keys: `pipx list`
  3. Assert output contains `package konsave`
  4. Send keys: `konsave --version`
  5. Assert output matches version pattern
- **Evidence**: `konsave_check.txt`

#### Scenario 3: Verify Polonium Installation
- **Tool**: interactive_bash (tmux)
- **Steps**:
  1. `tmux new-session: su - {{ vps_username }}`
  2. Send keys: `kpackagetool6 --list-packages --type KWin/Script`
  3. Assert output contains `polonium`
- **Evidence**: `polonium_check.txt`

#### Scenario 4: Verify Configuration (Baloo & Dolphin)
- **Tool**: Bash
- **Steps**:
  1. `cat /home/{{ vps_username }}/.config/baloofilerc`
  2. Assert file contains `Indexing-Enabled=false`
  3. `cat /home/{{ vps_username }}/.config/dolphinrc`
  4. Assert file contains `[PreviewSettings]` section (or specific keys enabled)
- **Evidence**: `config_check.txt`

---

## Execution Strategy

### Parallel Execution Waves
**Wave 1**:
- Task 1: Update main package list (adds deps for Wave 2)

**Wave 2**:
- Task 2: Create optimizations.yml (logic)
- Task 3: Include optimizations in main.yml

**Wave 3**:
- Task 4: Run Playbook & Verify

### Agent Dispatch Summary
- **Tasks 1-3**: `task(category="quick", load_skills=["ansible-expert", "bash-pro"])`
- **Task 4**: `task(category="quick", load_skills=["ansible-expert"])`

---

## TODOs

- [x] 1. Update `roles/desktop/tasks/main.yml` Package List
  **What to do**:
  - Add `python3-pip`, `pipx`, `python3-venv` (vital for pipx) to the `apt` task.
  - Add GUI tools: `yakuake`, `dolphin-plugins`, `sweeper`, `filelight`, `kcalc`, `spectacle`, `kdeconnect`.
  - Add visual tools: `ffmpegthumbs`, `kdegraphics-thumbnailers`, `svgpart`, `markdownpart`.
  - **Dependencies**: None.
  - **Parallel**: Wave 1.

- [x] 2. Create `roles/desktop/tasks/optimizations.yml`
  **What to do**:
  - Create file with `block` running as `become: true` and `become_user: "{{ vps_username }}"`.
  - **Sub-task A: Konsave**:
    - `community.general.pipx`: name=konsave state=present.
  - **Sub-task B: Polonium**:
    - Check if installed: `shell: kpackagetool6 --list-packages ...`
    - Download: `get_url` to `/tmp/polonium.kwinscript` (from GitHub releases).
    - Install: `shell: kpackagetool6 --install /tmp/polonium.kwinscript`.
  - **Sub-task C: Configs**:
    - `community.general.ini_file`: Disable Baloo (`[Basic Settings] Indexing-Enabled=false`).
    - `community.general.ini_file`: Enable Dolphin previews (`[PreviewSettings] Plugins=...`).
  - **References**:
    - Ansible `ini_file` docs.
    - `kpackagetool6` usage.
  - **Parallel**: Wave 2.

- [x] 3. Include Optimizations in `roles/desktop/tasks/main.yml`
  **What to do**:
  - Add `include_tasks: optimizations.yml` at the end of `main.yml`.
  - Ensure it runs *after* package installation.
  - **Parallel**: Wave 2 (after Task 1).

- [x] 4. Run Playbook and Verification
  **What to do**:
  - Run `./setup.sh` (or specific ansible-playbook command).
  - Execute all verification scenarios defined above.
  - **Parallel**: Wave 3.

---

## Success Criteria

### Verification Commands
```bash
# Quick check script
ansible-playbook playbooks/main.yml --tags desktop --check
```

### Final Checklist
- [x] All 15+ new packages installed
- [x] Pipx installed and functional
- [x] Konsave installed via pipx
- [x] Polonium installed as KWin script
- [x] Baloo disabled in config
