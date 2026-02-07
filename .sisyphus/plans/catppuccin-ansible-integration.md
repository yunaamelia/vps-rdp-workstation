# Catppuccin Mocha Theme - Ansible Integration

## TL;DR

> **Quick Summary**: Integrate manually-configured Catppuccin Mocha theme into the vps-rdp-workstation Ansible project, enabling automatic provisioning of the complete theme stack (Starship prompt, Konsole colorscheme, KDE Plasma theme, GTK2/3/4, cursors) on new VPS deployments.
> 
> **Deliverables**:
> - New `roles/catppuccin-theme/` role with all theme assets and templates
> - Updated `roles/fonts/` to include Hack Nerd Font
> - Updated `roles/shell-styling/` with Starship installation + config
> - Updated `roles/terminal/` with Catppuccin Konsole colorscheme
> - Updated `roles/desktop/` to use Catppuccin instead of Nordic
> - New theme variables in `inventory/group_vars/all.yml`
> 
> **Estimated Effort**: Medium (12-15 TODOs, ~2-3 hours)
> **Parallel Execution**: YES - 3 waves
> **Critical Path**: Task 1 (variables) → Task 2 (role structure) → Tasks 3-7 (parallel) → Task 8 (desktop) → Task 9 (integration)

---

## Context

### Original Request
User manually configured Catppuccin Mocha theme on their local system (Starship, KDE, GTK, Konsole, cursors, fonts) and wants to integrate all configurations into the Ansible project so new VPS deployments automatically get the theme.

### Interview Summary
**Key Discussions**:
- **Theme choice**: Catppuccin Mocha with Blue accent (user's explicit choice)
- **Font strategy**: Hack Nerd Font Mono for terminal, JetBrainsMono for system UI
- **Icon theme**: Keep Papirus-Dark (works well with Catppuccin)
- **Performance**: NO blur/transparency effects (RDP compatibility)
- **Fallback**: Keep Nordic theme available via variable toggle

**Research Findings**:
- Project has 21 roles with clear phase dependencies
- Existing theme roles: `desktop` (Nordic), `fonts` (JetBrainsMono NF), `terminal` (Konsole), `shell-styling` (zshrc)
- Starship is NOT currently installed - only Oh My Zsh with Agnoster theme
- User's configs exist at `~/.config/starship.toml`, `~/.config/kdeglobals`, GTK settings, etc.
- Docs already contain Starship integration design (`docs/STARSHIP_OPTIMIZATION.md`) with Catppuccin palette

### Metis Review
**Identified Gaps** (addressed):
- **Font inconsistency**: Konsole uses Hack NF, kdeglobals uses JetBrainsMono - resolved: use Hack NF Mono for terminal, JetBrains for system
- **Starship installation method**: Not specified - resolved: use binary download (faster, no build deps)
- **Cursor theme mismatch**: GTK settings had breeze_cursors - resolved: switch to catppuccin-mocha-blue-cursors
- **Theme asset download**: Need to handle GitHub releases for GTK/cursors - resolved: add download tasks

---

## Work Objectives

### Core Objective
Enable automatic provisioning of Catppuccin Mocha theme stack on new VPS deployments through Ansible automation.

### Concrete Deliverables
- `roles/catppuccin-theme/` - New role for theme asset management
- `roles/catppuccin-theme/templates/*.j2` - Templates for kdeglobals, GTK configs
- `roles/catppuccin-theme/files/` - Static files (colorscheme, cursors)
- `roles/shell-styling/templates/starship.toml.j2` - Starship prompt template
- Updated `roles/fonts/tasks/main.yml` - Add Hack Nerd Font
- Updated `roles/terminal/tasks/main.yml` - Deploy Catppuccin colorscheme
- Updated `roles/desktop/tasks/main.yml` - Conditional Nordic/Catppuccin installation
- Updated `inventory/group_vars/all.yml` - New theme variables

### Definition of Done
- [x] `ansible-playbook playbooks/main.yml --check --diff` shows no errors
- [x] `ansible-lint roles/catppuccin-theme/` passes
- [x] Theme files deployed to correct locations with proper ownership
- [x] Starship prompt works in new terminal sessions
- [x] Konsole uses Catppuccin Mocha colorscheme
- [x] KDE uses Catppuccin Mocha global theme
- [x] GTK apps use Catppuccin theme

### Must Have
- Catppuccin Mocha with Blue accent across all components
- Hack Nerd Font Mono for terminal
- Starship prompt with Catppuccin palette
- Konsole colorscheme deployment
- KDE global theme deployment
- GTK2/3/4 theme configurations
- Idempotent tasks (safe to run multiple times)
- Proper file ownership (`{{ vps_username }}`)

### Must NOT Have (Guardrails)
- NO blur/transparency effects (RDP performance)
- NO hardcoded usernames (use `{{ vps_username }}`)
- NO secrets in templates
- NO breaking existing Nordic fallback
- NO proportional fonts for terminal (must use Mono variant)
- NO modifications to security role
- NO AI-generated comments explaining obvious code

---

## Verification Strategy (MANDATORY)

> **UNIVERSAL RULE: ZERO HUMAN INTERVENTION**
>
> ALL tasks in this plan MUST be verifiable WITHOUT any human action.
> The executing agent will run verification commands directly.

### Test Decision
- **Infrastructure exists**: YES (project has validation scripts)
- **Automated tests**: NO (Ansible project uses `--check --diff` for validation)
- **Framework**: ansible-lint, yamllint, shellcheck

### Agent-Executed QA Scenarios (MANDATORY — ALL tasks)

**Verification Tool by Deliverable Type:**

| Type | Tool | How Agent Verifies |
|------|------|-------------------|
| **Ansible tasks** | Bash (`ansible-playbook --check --diff`) | Dry-run, check output for errors |
| **YAML files** | Bash (`yamllint`, `ansible-lint`) | Lint output clean |
| **Templates** | Bash (`ansible-playbook --syntax-check`) | Syntax validation |
| **File deployment** | Bash (`ls -la`, `cat`) | Verify files exist with correct perms |

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately):
├── Task 1: Add theme variables to group_vars/all.yml [no dependencies]
└── Task 2: Create catppuccin-theme role structure [no dependencies]

Wave 2 (After Wave 1):
├── Task 3: Create Starship template + installation [depends: 1, 2]
├── Task 4: Add Hack Nerd Font to fonts role [depends: 1]
├── Task 5: Create Konsole colorscheme file [depends: 2]
├── Task 6: Create GTK config templates [depends: 2]
└── Task 7: Create kdeglobals template [depends: 2]

Wave 3 (After Wave 2):
├── Task 8: Update desktop role for Catppuccin [depends: 2, 7]
├── Task 9: Update terminal role for colorscheme [depends: 5]
└── Task 10: Update shell-styling for Starship [depends: 3]

Wave 4 (Final):
└── Task 11: Integration + validation [depends: all]
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 3, 4, 8 | 2 |
| 2 | None | 3, 5, 6, 7, 8 | 1 |
| 3 | 1, 2 | 10 | 4, 5, 6, 7 |
| 4 | 1 | 11 | 3, 5, 6, 7 |
| 5 | 2 | 9 | 3, 4, 6, 7 |
| 6 | 2 | 8 | 3, 4, 5, 7 |
| 7 | 2 | 8 | 3, 4, 5, 6 |
| 8 | 2, 6, 7 | 11 | 9, 10 |
| 9 | 5 | 11 | 8, 10 |
| 10 | 3 | 11 | 8, 9 |
| 11 | All | None | None (final) |

---

## TODOs

### Wave 1: Foundation

- [x] 1. Add theme variables to group_vars/all.yml

  **What to do**:
  - Add new section `# Catppuccin Theme Configuration` with variables:
    - `vps_theme_variant: "catppuccin-mocha"` (options: catppuccin-mocha, nordic)
    - `vps_theme_accent: "blue"`
    - `vps_install_starship: true`
    - `vps_terminal_font: "Hack Nerd Font Mono"`
    - `vps_cursor_theme: "catppuccin-mocha-blue-cursors"`
  - Update existing `vps_kde_theme` default from "nordic" to "catppuccin-mocha"
  - Keep `vps_icon_theme: "papirus-dark"` unchanged

  **Must NOT do**:
  - Remove existing Nordic-related variables (keep as fallback)
  - Change security-related variables

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Single file edit with clear variable additions
  - **Skills**: [`clean-code`]
    - `clean-code`: Ensures proper YAML formatting and structure

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 2)
  - **Blocks**: Tasks 3, 4, 8
  - **Blocked By**: None (can start immediately)

  **References**:
  - `inventory/group_vars/all.yml:1-360` - Existing variable structure and naming conventions
  - `roles/desktop/defaults/main.yml` - Current theme variable patterns

  **Acceptance Criteria**:
  - [x] `yamllint inventory/group_vars/all.yml` → 0 errors
  - [x] Variables accessible: `ansible -m debug -a "var=vps_theme_variant" localhost`
  - [x] Existing variables unchanged: grep for `vps_kde_theme`, `vps_icon_theme`

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Variables are valid YAML and accessible
    Tool: Bash
    Preconditions: None
    Steps:
      1. yamllint inventory/group_vars/all.yml
      2. Assert: exit code 0, no errors in output
      3. grep -E "vps_theme_variant|vps_theme_accent|vps_install_starship" inventory/group_vars/all.yml
      4. Assert: all three variables found
    Expected Result: Clean YAML, all new variables present
    Evidence: Command output captured
  ```

  **Commit**: YES
  - Message: `feat(vars): add Catppuccin theme configuration variables`
  - Files: `inventory/group_vars/all.yml`
  - Pre-commit: `yamllint inventory/group_vars/all.yml`

---

- [x] 2. Create catppuccin-theme role structure

  **What to do**:
  - Create role directory structure:
    ```
    roles/catppuccin-theme/
    ├── tasks/main.yml
    ├── defaults/main.yml
    ├── files/
    │   └── konsole/catppuccin-mocha.colorscheme
    ├── templates/
    │   ├── kdeglobals.j2
    │   ├── gtk-3.0-settings.ini.j2
    │   ├── gtk-4.0-settings.ini.j2
    │   └── gtkrc-2.0.j2
    └── meta/main.yml
    ```
  - Create `tasks/main.yml` with:
    - Task to download GTK theme from GitHub releases
    - Task to download cursor theme from GitHub releases
    - Task to create necessary directories
    - Task to deploy templates
  - Create `defaults/main.yml` with:
    - `catppuccin_gtk_version: "1.0.3"`
    - `catppuccin_cursors_version: "1.0.1"`
    - Theme download URLs

  **Must NOT do**:
  - Include blur/transparency settings
  - Hardcode username (use `{{ vps_username }}`)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
    - Reason: Multiple files, new role structure, requires careful organization
  - **Skills**: [`clean-code`, `backend-patterns`]
    - `clean-code`: Proper file structure and naming
    - `backend-patterns`: Role organization patterns

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1 (with Task 1)
  - **Blocks**: Tasks 3, 5, 6, 7, 8
  - **Blocked By**: None (can start immediately)

  **References**:
  - `roles/desktop/` - Existing role structure pattern
  - `roles/fonts/tasks/main.yml:1-50` - Download and extract pattern
  - `/home/apexdev/.local/share/konsole/catppuccin-mocha.colorscheme` - Source colorscheme file
  - `https://github.com/catppuccin/gtk/releases` - GTK theme releases
  - `https://github.com/catppuccin/cursors/releases` - Cursor theme releases

  **Acceptance Criteria**:
  - [x] `ansible-lint roles/catppuccin-theme/` → 0 errors
  - [x] All directories created: tasks/, defaults/, files/, templates/, meta/
  - [x] `ansible-playbook playbooks/main.yml --syntax-check` → passes

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Role structure is valid and lintable
    Tool: Bash
    Preconditions: Role files created
    Steps:
      1. ls -la roles/catppuccin-theme/
      2. Assert: tasks/, defaults/, files/, templates/, meta/ directories exist
      3. ansible-lint roles/catppuccin-theme/
      4. Assert: exit code 0 or only warnings (no errors)
      5. cat roles/catppuccin-theme/tasks/main.yml
      6. Assert: file contains valid YAML with task definitions
    Expected Result: Complete role structure, passes linting
    Evidence: Directory listing and lint output captured

  Scenario: Download URLs are accessible
    Tool: Bash
    Preconditions: Internet access
    Steps:
      1. curl -sI https://github.com/catppuccin/gtk/releases/download/v1.0.3/catppuccin-mocha-blue-standard+default.zip
      2. Assert: HTTP 200 or 302 (redirect to download)
      3. curl -sI https://github.com/catppuccin/cursors/releases/download/v1.0.1/catppuccin-mocha-blue-cursors.zip
      4. Assert: HTTP 200 or 302
    Expected Result: Both URLs accessible
    Evidence: HTTP status codes captured
  ```

  **Commit**: YES
  - Message: `feat(role): create catppuccin-theme role with GTK/cursor downloads`
  - Files: `roles/catppuccin-theme/*`
  - Pre-commit: `ansible-lint roles/catppuccin-theme/`

---

### Wave 2: Templates and Files

- [x] 3. Create Starship installation and template
- [x] 4. Add Hack Nerd Font to fonts role
- [x] 5. Create Konsole colorscheme file
- [x] 6. Create GTK config templates
- [x] 7. Create kdeglobals template
- [x] 8. Update desktop role for Catppuccin support
- [x] 9. Update terminal role for Konsole colorscheme
- [x] 10. Update shell-styling role for Starship integration

  **What to do**:
  - Add Starship installation tasks (from Task 3) to `roles/shell-styling/tasks/main.yml`
  - Add task to deploy `starship.toml.j2` template
  - Update `zshrc.j2` to include Starship init (conditional on `vps_install_starship`)
  - Keep Oh My Zsh theme as fallback when Starship disabled

  **Must NOT do**:
  - Remove Oh My Zsh support
  - Make Starship mandatory (keep optional)

  **Recommended Agent Profile**:
  - **Category**: `quick`
    - Reason: Task additions following existing patterns
  - **Skills**: [`clean-code`, `bash-pro`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Tasks 8, 9)
  - **Blocks**: Task 11
  - **Blocked By**: Task 3

  **References**:
  - `roles/shell-styling/tasks/main.yml` - Where to add Starship tasks
  - `roles/shell-styling/templates/zshrc.j2` - Template to modify
  - `roles/shell-styling/templates/starship.toml.j2` - Template to deploy

  **Acceptance Criteria**:
  - [x] Starship installation task present
  - [x] Starship config deployment task present
  - [x] zshrc.j2 contains conditional Starship init
  - [x] `ansible-lint roles/shell-styling/` → 0 errors

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Shell-styling includes Starship
    Tool: Bash
    Preconditions: Tasks added
    Steps:
      1. grep -i "starship" roles/shell-styling/tasks/main.yml
      2. Assert: Installation and config deployment tasks found
      3. grep "vps_install_starship" roles/shell-styling/templates/zshrc.j2
      4. Assert: Conditional block for Starship init
      5. ansible-lint roles/shell-styling/
      6. Assert: exit code 0 or warnings only
    Expected Result: Complete Starship integration
    Evidence: Grep and lint output captured
  ```

  **Commit**: NO (groups with Task 11)

---

### Wave 4: Final Integration

- [x] 11. Integration validation and playbook update

  **What to do**:
  - Add `catppuccin-theme` role to `playbooks/main.yml` (after fonts, before desktop)
  - Run full syntax check: `ansible-playbook playbooks/main.yml --syntax-check`
  - Run full lint: `ansible-lint playbooks/main.yml roles/`
  - Run dry-run: `ansible-playbook playbooks/main.yml --check --diff`
  - Update `playbooks/templates/summary-log.j2` to reflect theme variable

  **Must NOT do**:
  - Change role execution order (security must still run early)
  - Skip syntax validation

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
    - Reason: Integration and validation, mostly command execution
  - **Skills**: [`clean-code`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Sequential (final)
  - **Blocks**: None (final task)
  - **Blocked By**: All previous tasks

  **References**:
  - `playbooks/main.yml:1-100` - Main playbook structure
  - `playbooks/templates/summary-log.j2` - Summary template

  **Acceptance Criteria**:
  - [x] catppuccin-theme role added to playbooks/main.yml in correct phase
  - [x] `ansible-playbook playbooks/main.yml --syntax-check` → passes
  - [x] `ansible-lint playbooks/main.yml roles/` → 0 errors
  - [x] `ansible-playbook playbooks/main.yml --check` → no fatal errors

  **Agent-Executed QA Scenarios**:

  ```
  Scenario: Full playbook validation
    Tool: Bash
    Preconditions: All previous tasks complete
    Steps:
      1. ansible-playbook playbooks/main.yml --syntax-check
      2. Assert: exit code 0
      3. ansible-lint playbooks/main.yml
      4. Assert: exit code 0 or only warnings
      5. grep "catppuccin-theme" playbooks/main.yml
      6. Assert: Role present in playbook
    Expected Result: Valid, lintable playbook with catppuccin-theme role
    Evidence: All command outputs captured

  Scenario: Dry-run succeeds
    Tool: Bash
    Preconditions: All changes applied
    Steps:
      1. ansible-playbook playbooks/main.yml --check --diff --limit localhost 2>&1 | head -100
      2. Assert: No FATAL errors in output
      3. Assert: Output shows theme-related tasks
    Expected Result: Clean dry-run execution
    Evidence: Truncated dry-run output captured
  ```

  **Commit**: YES
  - Message: `feat(integration): complete Catppuccin theme Ansible integration`
  - Files: `playbooks/main.yml`, `playbooks/templates/summary-log.j2`, all role changes
  - Pre-commit: `ansible-lint playbooks/main.yml roles/`

---

## Commit Strategy

| After Task | Message | Files | Verification |
|------------|---------|-------|--------------|
| 1 | `feat(vars): add Catppuccin theme configuration variables` | `inventory/group_vars/all.yml` | yamllint |
| 2 | `feat(role): create catppuccin-theme role with GTK/cursor downloads` | `roles/catppuccin-theme/*` | ansible-lint |
| 3 | `feat(starship): add Starship prompt installation and Catppuccin config` | `roles/shell-styling/templates/*`, `roles/shell-styling/tasks/main.yml` | ansible-lint |
| 8 | `feat(desktop): add Catppuccin Mocha theme support with Nordic fallback` | `roles/desktop/tasks/main.yml`, `roles/desktop/meta/main.yml` | ansible-lint |
| 11 | `feat(integration): complete Catppuccin theme Ansible integration` | `playbooks/main.yml`, all remaining | full validation |

---

## Success Criteria

### Verification Commands
```bash
# Syntax check
ansible-playbook playbooks/main.yml --syntax-check
# Expected: playbook: playbooks/main.yml (no errors)

# Lint all roles
ansible-lint playbooks/main.yml roles/
# Expected: 0 errors (warnings acceptable)

# Dry-run
ansible-playbook playbooks/main.yml --check --diff --limit localhost
# Expected: No FATAL errors, shows catppuccin tasks

# Variable check
ansible -m debug -a "var=vps_theme_variant" localhost
# Expected: vps_theme_variant: catppuccin-mocha
```

### Final Checklist
- [x] All "Must Have" present:
  - [x] Catppuccin Mocha Blue theme configured
  - [x] Hack Nerd Font Mono for terminal
  - [x] Starship prompt with Catppuccin palette
  - [x] Konsole colorscheme
  - [x] KDE global theme
  - [x] GTK2/3/4 configs
- [x] All "Must NOT Have" absent:
  - [x] No blur/transparency effects
  - [x] No hardcoded usernames
  - [x] No secrets in templates
  - [x] Nordic fallback preserved
- [x] All linting passes
- [x] Dry-run succeeds
