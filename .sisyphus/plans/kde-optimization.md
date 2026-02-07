# KDE Optimization Plan

## TL;DR

> **Quick Summary**: Implement high-impact tools and performance optimizations for KDE Plasma over RDP, including Kvantum, Yakuake, Karousel, and font rendering fixes.
> 
> **Deliverables**:
> - Updated `roles/desktop/tasks/main.yml` with new tasks
> - Installed tools: Yakuake, Kvantum, Kompare, Filelight, KRDC, Smb4K
> - Installed KWin scripts: Karousel, Window Title Applet
> - Configured performance: Disabled Baloo, optimized fonts, zero animations
> 
> **Estimated Effort**: Short
> **Parallel Execution**: NO - sequential Ansible task editing
> **Critical Path**: Edit playbook -> Run playbook

---

## Context

### Original Request
Analyze `awesome-kde` and implement recommendations for a VPS RDP workstation.

### Research Findings
- **UI/UX**: Kvantum needed for uniform styling. Yakuake for quick terminal.
- **RDP Performance**: Disable Baloo (IO bottleneck), force grayscale fonts (compression artifacts), zero animations (bandwidth).
- **Productivity**: Karousel for tiling, Window Title for panel context.

---

## Work Objectives

### Core Objective
Enhance the KDE Plasma experience on RDP by adding missing power-user tools and applying protocol-specific performance tunings.

### Concrete Deliverables
- Modified `roles/desktop/tasks/main.yml`

### Definition of Done
- [ ] Ansible playbook syntax check passes
- [ ] Role contains all new tasks (tools, tiling, performance)

### Must Have
- Idempotent tasks (use `creates` or `changed_when` where appropriate)
- Correct user permissions (`become_user: {{ vps_username }}`)
- Error handling for KPackage installation

### Must NOT Have
- Broken indentation in YAML
- Hardcoded usernames

---

## Verification Strategy

### Automated Tests
- **Syntax Check**: `ansible-playbook playbooks/main.yml --syntax-check`
- **Lint**: `ansible-lint roles/desktop/tasks/main.yml`

### Agent-Executed QA Scenarios

```
Scenario: Verify playbook syntax
  Tool: interactive_bash (tmux)
  Preconditions: Repo checked out
  Steps:
    1. Run: ansible-playbook playbooks/main.yml --syntax-check
    2. Assert: Output contains "No errors found" or exit code 0
  Expected Result: Valid YAML syntax
  Evidence: Terminal output
```

---

## TODOs

- [x] 1. Update Desktop Role with Tools and Optimizations

  **What to do**:
  - Edit `roles/desktop/tasks/main.yml`
  - Insert "Power User Tools" block (apt install)
  - Insert "KWin Scripts" block (Karousel, Window Title)
  - Insert "Performance" block (Baloo, Fonts, Animation)
  
  **References**:
  - `kde.md`: Source of recommended configurations
  - `roles/desktop/tasks/main.yml`: Target file

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`ansible-expert`]

  **Acceptance Criteria**:
  - [x] File `roles/desktop/tasks/main.yml` contains `Install essential KDE tools`
  - [x] File `roles/desktop/tasks/main.yml` contains `Disable Baloo file indexing`
  - [x] File `roles/desktop/tasks/main.yml` contains `Configure font rendering for RDP`
  - [x] `ansible-playbook playbooks/main.yml --syntax-check` passes

- [x] 2. Activate Kvantum Style
  **What to do**:
  - Update `.xsession` creation task in `roles/desktop/tasks/main.yml`
  - Add `export QT_STYLE_OVERRIDE=kvantum` before `startplasma-x11`
  
  **Reason**: Installing Kvantum is useless if not active.

- [x] 3. Disable Akonadi Server
  **What to do**:
  - Add task to configure `~/.config/akonadi/akonadiserverrc`
  - Set `StartServer=false` in `[QMF]` section (or general)
  
  **Reason**: Recommended in kde.md to save RAM.

- [x] 4. Configure Yakuake Autostart
  **What to do**:
  - Create `~/.config/autostart` directory
  - Symlink or copy `/usr/share/applications/org.kde.yakuake.desktop` to `~/.config/autostart/`
  
  **Reason**: "Eliminate startup latency" requires it to run on login.

- [x] 5. Cleanup Build Artifacts
  **What to do**:
  - Add tasks to remove `/tmp/karousel` and `/tmp/window-title`
  
  **Reason**: Keep the system clean after installation.

---

## Success Criteria

### Verification Commands
```bash
ansible-playbook playbooks/main.yml --syntax-check
```

### Final Checklist
- [x] All requested tools added to package list
- [x] Performance tweaks implemented
- [x] Playbook structure remains valid
