# KDE Optimization Plan

## TL;DR

> **Quick Summary**: Implement a new Ansible role `kde-optimization` to install power tools (Yakuake, Filelight), disable resource-heavy indexing (Baloo), and tune KWin compositor for low-latency RDP performance.
>
> **Deliverables**:
> - New Ansible role: `roles/kde-optimization/`
> - Updated playbook: `playbooks/main.yml`
> - Configured Tools: Yakuake, Filelight, KSystemLog, KCalc
> - Optimized Configs: `baloofilerc`, `kwinrc`, `dolphinrc`
>
> **Estimated Effort**: Short (1-2 hours)
> **Parallel Execution**: Sequential (runs after `desktop` role)

---

## Context

### Original Request
Research and implement KDE best practices for UI/UX, performance, and tools on a VPS/RDP workstation.

### Interview Summary
**Key Decisions**:
- **Disable Baloo**: Yes (Critical for VPS IOPS).
- **Optimize Compositor**: Yes (Disable blur/animations for RDP smoothness).
- **Install Power Tools**: Yes (Yakuake, Filelight, etc.).
- **Developer UX**: Yes (Dolphin terminal panel, full paths).

### Metis Review
**Guardrails**:
- Do not modify existing `roles/desktop` logic; extend via new role.
- Ensure configs target the correct user (`{{ vps_username }}`), not root.
- Handle idempotency for config edits using `ini_file` module.

---

## Work Objectives

### Core Objective
Transform the default KDE installation into a high-performance, developer-focused environment optimized for remote access.

### Concrete Deliverables
- `roles/kde-optimization/tasks/main.yml`
- `roles/kde-optimization/handlers/main.yml`
- `roles/kde-optimization/defaults/main.yml`
- `playbooks/main.yml` (updated)

### Must Have
- `yakuake` installed and working.
- Baloo service disabled and config set to `Indexing-Enabled=false`.
- KWin `AnimationSpeed` set to instant/fast.
- Dolphin showing full paths.

### Must NOT Have
- Broken RDP session (changes must be safe).
- High CPU usage from indexing.

---

## Verification Strategy

> **UNIVERSAL RULE: ZERO HUMAN INTERVENTION**
> All tasks verifiable by agent automation.

### Test Decision
- **Infrastructure exists**: Yes (validate.sh).
- **Automated tests**: No unit tests for Ansible YAML, but **Agent-Executed QA** is mandatory.

### Agent-Executed QA Scenarios

```
Scenario: Verify Power Tools Installation
  Tool: Bash (dpkg)
  Preconditions: Playbook run completed
  Steps:
    1. Run `dpkg -l | grep yakuake`
    2. Assert output contains "yakuake"
    3. Run `dpkg -l | grep filelight`
    4. Assert output contains "filelight"
  Expected Result: Packages are installed
  Evidence: Terminal output

Scenario: Verify Baloo Disabled
  Tool: Bash
  Preconditions: Playbook run completed
  Steps:
    1. Run `balooctl status` (as user)
    2. Assert output contains "Baloo is currently disabled"
    3. Check `~/.config/baloofilerc`
    4. Assert `Indexing-Enabled=false`
  Expected Result: Indexing is off
  Evidence: Command output

Scenario: Verify Compositor Tuning
  Tool: Bash
  Preconditions: Playbook run completed
  Steps:
    1. Read `~/.config/kwinrc`
    2. Assert `[Compositing] AnimationSpeed` is present
    3. Assert `[Compositing] LatencyPolicy` is present
  Expected Result: Configs applied
  Evidence: File content
```

---

## TODOs

- [x] 1. Create `kde-optimization` Role Structure
  **What to do**:
  - Create directories: `roles/kde-optimization/{tasks,handlers,defaults,meta}`
  - Create empty `main.yml` files.
  - Define role dependencies in `meta/main.yml` (depends on `desktop`).

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `bash-linux`

  **Acceptance Criteria**:
  - [x] Directory structure exists.
  - [x] `meta/main.yml` defines dependency.

- [x] 2. Implement Package Installation Task
  **What to do**:
  - Edit `roles/kde-optimization/tasks/main.yml`.
  - Add `ansible.builtin.apt` task for: `yakuake`, `filelight`, `ksystemlog`, `kcalc`, `partitionmanager`.
  - Add tag `kde-opt`.

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: `ansible-instructions`

  **Acceptance Criteria**:
  - [ ] Task installs all requested packages.
  - [ ] Idempotent (state=present).

- [x] 3. Implement Baloo Disabling Task
  **What to do**:
  - Add task to stop/disable `baloo_file` service (user level).
  - Add task to configure `~/.config/baloofilerc` using `community.general.ini_file`.
  - Section `[Basic Settings]`, Key `Indexing-Enabled`, Value `false`.
  - **Crucial**: Run as `{{ vps_username }}`.

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high` (Ansible logic)
  - **Skills**: `ansible-instructions`

  **Acceptance Criteria**:
  - [ ] Baloo service stopped.
  - [ ] Config file updated correctly.

- [x] 4. Implement Compositor & Dolphin Tuning
  **What to do**:
  - Edit `roles/kde-optimization/tasks/main.yml`.
  - **KWin**: Edit `~/.config/kwinrc`.
    - `[Compositing] AnimationSpeed=0`
    - `[Compositing] LatencyPolicy=ForceLowestLatency`
    - `[Plugins] blurEnabled=false`
  - **Dolphin**: Edit `~/.config/dolphinrc`.
    - `[General] ShowFullPath=true`
    - `[General] FilterBar=true`
  - Use `notify: Restart KWin` handler (optional, complex to do live, maybe just log message).

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: `ansible-instructions`

  **Acceptance Criteria**:
  - [ ] `kwinrc` modified.
  - [ ] `dolphinrc` modified.
  - [ ] Correct owner/permissions.

- [x] 5. Integrate into Main Playbook
  **What to do**:
  - Edit `playbooks/main.yml`.
  - Add `kde-optimization` role AFTER `desktop` and BEFORE `editors`.
  - Use tags `[desktop, kde, optimization]`.

  **Recommended Agent Profile**:
  - **Category**: `quick`

  **Acceptance Criteria**:
  - [ ] Role added to playbook.
  - [ ] Syntax check passes.

- [x] 6. Run Validation
  **What to do**:
  - Run `ansible-playbook playbooks/main.yml --tags kde-optimization --check`.
  - Verify no syntax errors.

  **Recommended Agent Profile**:
  - **Category**: `quick`

  **Acceptance Criteria**:
  - [x] Playbook runs without error.
