# Full Codebase Refactor — Ansible Best Practices, Role Reordering, KDE Manual Config

## TL;DR

> **Quick Summary**: Refactor the vps-rdp-workstation Ansible codebase (25 roles, ~21k lines) to follow canonical best practices: reorder roles, standardize variable naming, improve code quality (FQCN, tags, block/rescue, idempotency), add hybrid KDE manual configuration (Jinja2 templates + git clone), and add Kitty as backup terminal alongside Konsole.
>
> **Deliverables**:
> - Reordered `playbooks/main.yml` following bootstrap → security → base → services → desktop → user config → dev tools sequence
> - All variables renamed to `vps_<role>_` convention with two-phase compatibility approach
> - FQCN compliance, hierarchical tags, block/rescue on critical roles
> - KDE manual config templates for theme, keybindings, and autostart (panel stays as git clone)
> - Kitty terminal installed and configured as backup to Konsole
> - Updated validate.sh, molecule tests, and documentation
>
> **Estimated Effort**: Large (10 tasks, ~40+ file changes)
> **Parallel Execution**: YES — 6 waves
> **Critical Path**: Task 1 → Task 2 → Task 3 → Task 4 → Task 5 → Task 8

---

## Context

### Original Request
User requested a full refactor using best practices implementation, reordering roles per best practices, and adding manual configuration. Initially wanted to remove KDE Plasma for XFCE4, but **reversed that decision** — KDE Plasma stays as the desktop environment.

### Interview Summary
**Key Discussions**:
- Desktop: KDE Plasma STAYS (user reversed initial decision)
- Terminal: Konsole (primary, KDE-native) + Kitty (backup/alternative)
- KDE config: HYBRID — Jinja2 templates for theme/keybindings/autostart + git clone from GitHub for panel layout and complex KWin configs
- Manual config scope: ALL — theme/appearance, keybindings/shortcuts, panel/taskbar layout, autostart applications
- Test strategy: Molecule + validate.sh (both already exist)

**Research Findings**:
- Red Hat CoP, Spacelift, dev-sec agree on canonical ordering: security before services
- ~50+ variables violate `vps_<role>_` naming convention (docker, development, editors, fonts, tui-tools, catppuccin-theme roles)
- Duplicate XRDP templates exist in both desktop and xrdp roles (stale copies in desktop)
- Duplicate handler `"Restart XRDP"` in both desktop and xrdp roles
- Desktop role skipped in Molecule CI (commented out in converge.yml)
- KDE panel layout is extremely complex (JSON-like, not ini-based) — must stay as git clone
- External `shalva97/kde-configuration-files` repo clone requires `fish` shell dependency

### Metis Review
**Identified Gaps** (addressed):
- Duplicate XRDP templates and handlers → Task 1 (cleanup)
- Variable rename strategy (big bang vs gradual) → Two-phase approach with compatibility shims
- Panel layout complexity → Stays as git clone, NOT templated
- `--resume` flag invalidation after reorder → Task 2 includes progress.json handling
- Stale backup file `starship.toml.j2.frost-backup` → Task 1 cleanup
- Inconsistent `min_ansible_version` in role meta → Task 1 standardization
- `default_font_size` variable ownership ambiguity → Shared `vps_default_font_size`
- Molecule hardcoded password → Flagged but out of scope (test-only)

---

## Work Objectives

### Core Objective
Refactor the Ansible codebase to follow canonical best practices while preserving identical runtime behavior, then add hybrid KDE manual configuration control and Kitty terminal.

### Concrete Deliverables
- Reordered `playbooks/main.yml` with canonical role sequence
- All role variables renamed to `vps_<role>_` convention
- FQCN compliance across all 25 roles
- Hierarchical tags `[phase, role, feature]` on all role entries
- `block/rescue` error handling on critical roles (common, security, desktop, xrdp, docker)
- KDE config templates: `kdeglobals.j2` (theme), `kglobalshortcutsrc.j2` (keybindings), autostart `.desktop` entries
- Git clone retained for panel layout and KWin scripts
- Kitty terminal package + `kitty.conf.j2` template
- Updated `tests/validate.sh` with new variable names and Kitty check
- Updated `molecule/default/converge.yml` with correct role names
- Updated documentation (README.md, AGENTS.md, CLAUDE.md)

### Definition of Done
- [x] `yamllint . && ansible-lint playbooks/ roles/` → zero errors
- [x] `ansible-playbook playbooks/main.yml --syntax-check` → exit 0
- [x] `grep -rh 'name:' roles/*/handlers/main.yml | sort | uniq -d` → empty (no duplicate handlers)
- [x] All role defaults use `vps_<role>_` prefix
- [x] `molecule test` → passes
- [x] `./tests/validate.sh` → all criteria pass

### Must Have
- Role ordering preserves invariants: common first → security second → desktop before xrdp → fonts+theme before terminal → terminal before zsh-enhancements
- Variable rename uses two-phase approach with compatibility shims
- Zero behavior changes — same packages, same configs, same services
- Idempotency preserved (second run = zero changes)

### Must NOT Have (Guardrails)
- Do NOT rewrite working task logic — only restructure and rename
- Do NOT change package lists or config file content during refactor phases
- Do NOT create new Molecule scenarios — only update existing
- Do NOT touch `setup.sh`, callback plugins, or `scripts/` directory
- Do NOT template KDE panel layout (too complex, stays as git clone)
- Do NOT remove the external KDE config clone (`shalva97/kde-configuration-files`)
- Do NOT rename `vps_username` or other already-correct shared `vps_*` variables
- Do NOT bump tool versions — keep current pins
- Do NOT restructure into Ansible collections
- Do NOT add new tools to the dev stack beyond Kitty

---

## Verification Strategy

> **UNIVERSAL RULE: ZERO HUMAN INTERVENTION**
>
> ALL tasks in this plan MUST be verifiable WITHOUT any human action.

### Test Decision
- **Infrastructure exists**: YES
- **Automated tests**: Tests-after (update existing validate.sh + molecule)
- **Framework**: molecule (existing), validate.sh (existing, to update), linting (yamllint, ansible-lint, shellcheck)

### Agent-Executed QA Scenarios (MANDATORY — ALL tasks)

**Verification Tool by Deliverable Type:**

| Type | Tool | How Agent Verifies |
|------|------|-------------------|
| **YAML/Ansible files** | Bash (yamllint, ansible-lint) | Run linters, assert zero errors |
| **Role structure** | Bash (grep, find) | Search for violations, assert empty |
| **Playbook validity** | Bash (ansible-playbook --syntax-check) | Run syntax check, assert exit 0 |
| **Config templates** | Bash (ansible-playbook --check --diff) | Dry run, verify template rendering |

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Start Immediately):
└── Task 1: Cleanup (stale files, handler dedup, meta standardization)

Wave 2 (After Wave 1):
└── Task 2: Role reordering in playbooks/main.yml

Wave 3 (After Wave 2):
├── Task 3: Variable namespace — Phase 1 (add compatibility shims)
└── Task 5: Code quality (FQCN + tags + block/rescue + idempotency)

Wave 4 (After Wave 3):
├── Task 4: Variable namespace — Phase 2 (remove old names)
└── Task 6: Add Kitty terminal

Wave 5 (After Wave 4):
├── Task 7: KDE manual config templates (hybrid)
└── Task 8: Update tests (validate.sh + molecule)

Wave 6 (After Wave 5):
├── Task 9: Update documentation
└── Task 10: Final verification gate

Critical Path: Task 1 → Task 2 → Task 3 → Task 4 → Task 7 → Task 8 → Task 10
Parallel Speedup: ~35% faster than sequential
```

### Dependency Matrix

| Task | Depends On | Blocks | Can Parallelize With |
|------|------------|--------|---------------------|
| 1 | None | 2 | None (first) |
| 2 | 1 | 3, 5 | None |
| 3 | 2 | 4 | 5 |
| 4 | 3 | 7, 8 | 6 |
| 5 | 2 | 7 | 3 |
| 6 | 3 | 8 | 4 |
| 7 | 4, 5 | 9 | 8 |
| 8 | 4, 6 | 10 | 7 |
| 9 | 7 | 10 | 8 |
| 10 | 8, 9 | None | None (final) |

### Agent Dispatch Summary

| Wave | Tasks | Recommended Agents |
|------|-------|-------------------|
| 1 | 1 | task(category="quick", load_skills=["clean-code"]) |
| 2 | 2 | task(category="unspecified-low", load_skills=["clean-code"]) |
| 3 | 3, 5 | dispatch parallel, each category="unspecified-high" |
| 4 | 4, 6 | dispatch parallel, 4=unspecified-high, 6=quick |
| 5 | 7, 8 | dispatch parallel, both unspecified-high |
| 6 | 9, 10 | dispatch parallel, 9=writing, 10=quick |

---

## Role Ordering Constraints (IMMUTABLE)

These ordering invariants MUST survive the refactor:

| Constraint | Reason |
|-----------|--------|
| `common` → first | Creates user, base packages, apt cache |
| `security` → second | SSH hardening, UFW, fail2ban BEFORE any service exposure |
| `desktop` → before `xrdp` | XRDP needs KDE Plasma installed |
| `fonts` + `catppuccin-theme` → before `terminal` + `shell-styling` | Templates reference font/colorscheme files |
| `terminal` → before `zsh-enhancements` | OMZ must exist before plugins clone |
| `shell-styling` → after `terminal` | Modifies .zshrc that terminal role creates |

### Target Role Order

```yaml
# Phase 1: Bootstrap
- role: common            # tags: [bootstrap, common]

# Phase 2: Security
- role: security           # tags: [security, hardening]

# Phase 3: Base System
- role: fonts              # tags: [base, fonts]

# Phase 4: Desktop Environment
- role: desktop            # tags: [desktop, kde]
- role: xrdp               # tags: [desktop, xrdp]
- role: kde-optimization   # tags: [desktop, kde, optimization]
- role: kde-apps           # tags: [desktop, kde, apps]
- role: catppuccin-theme   # tags: [desktop, theme, catppuccin]

# Phase 5: User Configuration
- role: terminal           # tags: [userconfig, terminal]
- role: shell-styling      # tags: [userconfig, shell, styling]
- role: zsh-enhancements   # tags: [userconfig, zsh, plugins]

# Phase 6: Development Tools
- role: development        # tags: [devtools, languages]
- role: docker             # tags: [devtools, docker]
- role: editors            # tags: [devtools, editors]

# Phase 7: CLI Tool Roles
- role: tui-tools          # tags: [tools, tui]
- role: network-tools      # tags: [tools, network]
- role: system-performance # tags: [tools, performance]
- role: text-processing    # tags: [tools, text]
- role: file-management    # tags: [tools, files]
- role: dev-debugging      # tags: [tools, debugging]
- role: code-quality       # tags: [tools, quality]
- role: productivity       # tags: [tools, productivity]
- role: log-visualization  # tags: [tools, logging]
- role: ai-devtools        # tags: [tools, ai]
- role: cloud-native       # tags: [tools, cloud]
```

---

## TODOs

- [x] 1. Cleanup: Remove Stale Files, Deduplicate Handlers, Standardize Meta

  **What to do**:
  - Remove stale XRDP templates from desktop role: `roles/desktop/templates/{xrdp.ini.j2, sesman.ini.j2, startwm.sh.j2}` — verify NO task in `roles/desktop/tasks/` references them first using grep
  - Remove duplicate `"Restart XRDP"` handler from `roles/desktop/handlers/main.yml` — keep ONLY in `roles/xrdp/handlers/main.yml`
  - Remove stale backup file: `roles/shell-styling/templates/starship.toml.j2.frost-backup`
  - Standardize `min_ansible_version` to `"2.14"` across ALL `roles/*/meta/main.yml` files (catppuccin-theme currently has `"2.1"`)
  - Verify all roles have consistent meta structure: `galaxy_info.role_name`, `galaxy_info.description`, `dependencies: []`

  **Must NOT do**:
  - Do NOT remove any templates that are actively referenced by tasks
  - Do NOT change handler logic — only remove the duplicate definition

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`clean-code`]
    - `clean-code`: File cleanup and standardization patterns

  **Parallelization**:
  - **Can Run In Parallel**: NO (first task)
  - **Parallel Group**: Wave 1 (solo)
  - **Blocks**: Task 2
  - **Blocked By**: None

  **References**:
  - `roles/desktop/templates/` — Stale XRDP templates to remove (duplicates of `roles/xrdp/templates/`)
  - `roles/desktop/handlers/main.yml` — Duplicate `"Restart XRDP"` handler to remove
  - `roles/xrdp/handlers/main.yml` — Canonical handler location (keep this one)
  - `roles/desktop/tasks/main.yml` — Verify no task references the stale templates
  - `roles/shell-styling/templates/starship.toml.j2.frost-backup` — Stale backup to remove
  - `roles/catppuccin-theme/meta/main.yml` — Has `min_ansible_version: "2.1"` (should be `"2.14"`)
  - All `roles/*/meta/main.yml` — Standardize min_ansible_version

  **Acceptance Criteria**:
  - [ ] `ls roles/desktop/templates/xrdp.ini.j2 roles/desktop/templates/sesman.ini.j2 roles/desktop/templates/startwm.sh.j2 2>&1 | grep -c 'No such file'` → 3
  - [ ] `grep -c 'Restart XRDP' roles/desktop/handlers/main.yml` → 0
  - [ ] `ls roles/shell-styling/templates/starship.toml.j2.frost-backup 2>&1 | grep -c 'No such file'` → 1
  - [ ] `grep -rP 'min_ansible_version.*2\.1[^4]' roles/*/meta/main.yml | wc -l` → 0
  - [ ] `yamllint roles/*/meta/main.yml && ansible-lint playbooks/ roles/` → exit 0
  - [ ] `ansible-playbook playbooks/main.yml --syntax-check` → exit 0

  **Agent-Executed QA Scenarios**:
  ```
  Scenario: Verify stale templates removed
    Tool: Bash
    Steps:
      1. Run: ls roles/desktop/templates/xrdp.ini.j2 2>&1
      2. Assert: output contains "No such file"
      3. Run: grep -r 'xrdp.ini.j2\|sesman.ini.j2' roles/desktop/tasks/ 2>/dev/null | wc -l
      4. Assert: output is 0 (no references to removed files)
    Expected Result: Stale files removed, no broken references

  Scenario: Verify handler deduplication
    Tool: Bash
    Steps:
      1. Run: grep -rh 'name:' roles/*/handlers/main.yml | sort | uniq -d
      2. Assert: empty output (no duplicate handler names)
      3. Run: grep 'Restart XRDP' roles/xrdp/handlers/main.yml | wc -l
      4. Assert: output is 1 (handler exists in canonical location)
    Expected Result: Zero duplicate handlers across all roles

  Scenario: Lint verification after cleanup
    Tool: Bash
    Steps:
      1. Run: yamllint . 2>&1 | tail -5
      2. Assert: exit code 0
      3. Run: ansible-lint playbooks/ roles/ 2>&1 | tail -5
      4. Assert: exit code 0
    Expected Result: All linting passes
  ```

  **Commit**: YES
  - Message: `refactor(cleanup): remove stale XRDP templates, deduplicate handlers, standardize meta`
  - Files: `roles/desktop/templates/`, `roles/desktop/handlers/main.yml`, `roles/shell-styling/templates/`, `roles/*/meta/main.yml`
  - Pre-commit: `yamllint . && ansible-lint playbooks/ roles/`

---

- [x] 2. Reorder Roles in playbooks/main.yml

  **What to do**:
  - Reorder the role list in `playbooks/main.yml` to match the Target Role Order defined above
  - Update tag schemas to follow `[phase, role, feature]` hierarchy (e.g., `tags: [bootstrap, common]`, `tags: [desktop, kde, optimization]`)
  - Invalidate `progress.json` compatibility: add a comment in `playbooks/main.yml` documenting the new order and noting that `--resume` from pre-refactor runs requires a fresh start
  - Verify the new order respects ALL immutable ordering constraints

  **Must NOT do**:
  - Do NOT change any role content — only the order in main.yml and tags
  - Do NOT add or remove roles — same 25 roles, different order
  - Do NOT change the `pre_tasks` or `post_tasks` sections

  **Recommended Agent Profile**:
  - **Category**: `unspecified-low`
  - **Skills**: [`clean-code`]

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 2 (solo)
  - **Blocks**: Tasks 3, 5
  - **Blocked By**: Task 1

  **References**:
  - `playbooks/main.yml` — Current role ordering (lines where roles are listed)
  - Target Role Order section above — Exact order to implement
  - Role Ordering Constraints section above — Immutable invariants
  - `inventory/group_vars/all.yml` — Variable references for when: conditions on roles

  **Acceptance Criteria**:
  - [ ] `ansible-playbook playbooks/main.yml --syntax-check` → exit 0
  - [ ] `ansible-playbook playbooks/main.yml --check --diff -i inventory/hosts.yml -e 'vps_username=testuser vps_user_password_hash=$6$test' 2>&1 | tail -1` → no unexpected failures
  - [ ] `grep -A2 'role:' playbooks/main.yml | grep 'tags:' | wc -l` → matches number of roles (all have tags)
  - [ ] Order validation: common appears before security, security before desktop, desktop before xrdp, fonts before terminal

  **Agent-Executed QA Scenarios**:
  ```
  Scenario: Role ordering constraint validation
    Tool: Bash
    Steps:
      1. Run: grep -n 'role:' playbooks/main.yml
      2. Parse line numbers for common, security, desktop, xrdp, fonts, terminal, zsh-enhancements
      3. Assert: common_line < security_line < fonts_line < desktop_line
      4. Assert: desktop_line < xrdp_line
      5. Assert: fonts_line < terminal_line
      6. Assert: terminal_line < zsh_enhancements_line
    Expected Result: All ordering constraints satisfied

  Scenario: Syntax check passes
    Tool: Bash
    Steps:
      1. Run: ansible-playbook playbooks/main.yml --syntax-check
      2. Assert: exit code 0
    Expected Result: Playbook is syntactically valid
  ```

  **Commit**: YES
  - Message: `refactor(playbook): reorder roles to canonical best-practice sequence`
  - Files: `playbooks/main.yml`
  - Pre-commit: `ansible-playbook playbooks/main.yml --syntax-check`

---

- [x] 3. Variable Namespace — Phase 1: Add Compatibility Shims

  **What to do**:
  - For EACH role with non-conforming variable names, add compatibility shim in role defaults:
    ```yaml
    # New name with backward-compatible fallback
    vps_docker_install: "{{ install_docker | default(true) }}"
    ```
  - Roles to process (in order): `docker`, `development`, `editors`, `fonts`, `terminal`, `tui-tools`, `catppuccin-theme`, `desktop`, `network-tools`, `system-performance`, `text-processing`, `productivity`, `code-quality`, `cloud-native`, `ai-devtools`, `dev-debugging`, `log-visualization`, `file-management`
  - Update ALL task files within each role to use the NEW variable name
  - Keep OLD variable names in `group_vars/all.yml` for now (Phase 2 removes them)
  - Handle shared variables: `default_font_size` → `vps_default_font_size` (shared), `default_monospace_font` → `vps_default_monospace_font` (shared)
  - For each role: use `grep` to find ALL references to old variable names before renaming, ensure zero misses

  **Must NOT do**:
  - Do NOT remove old variable names from `group_vars/all.yml` yet (that's Phase 2)
  - Do NOT rename `vps_username`, `vps_timezone`, `vps_hostname` or other correctly-prefixed shared variables
  - Do NOT change variable VALUES — only names
  - Do NOT rename variables in `setup.sh` (out of scope)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: [`clean-code`]
    - `clean-code`: Variable naming conventions and systematic renaming

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Task 5)
  - **Blocks**: Task 4
  - **Blocked By**: Task 2

  **References**:
  - `roles/docker/defaults/main.yml` — `install_docker`, `docker_log_max_size`, `docker_log_max_file`, `docker_storage_driver` → prefix with `vps_docker_`
  - `roles/development/defaults/main.yml` — `install_nodejs`, `nodejs_version`, `npm_global_packages`, `install_python`, `python_pipx_packages`, `install_php`, `php_extensions`, `install_composer` → prefix with `vps_development_`
  - `roles/editors/defaults/main.yml` — `install_vscode`, `vscode_extensions`, `install_opencode`, `install_antigravity` → prefix with `vps_editors_`
  - `roles/fonts/defaults/main.yml` — `install_nerd_fonts`, `install_powerline_fonts`, `default_monospace_font`, `default_font_size` → prefix with `vps_fonts_` or `vps_` for shared
  - `roles/tui-tools/defaults/main.yml` — `lazygit_version`, `lazygit_checksum` → prefix with `vps_tui_`
  - `roles/catppuccin-theme/defaults/main.yml` — `catppuccin_*` (6+ vars) → prefix with `vps_catppuccin_`
  - `roles/terminal/defaults/main.yml` — `default_font_size` duplicate → use shared `vps_default_font_size`
  - `inventory/group_vars/all.yml` — Central variable definitions (keep OLD names for now)
  - Metis finding: ~50+ variables need renaming

  **Acceptance Criteria**:
  - [ ] All role defaults use `vps_<role>_` prefix (grep verification)
  - [ ] Old variable names still work via compatibility shims (dry run succeeds)
  - [ ] `ansible-playbook playbooks/main.yml --syntax-check` → exit 0
  - [ ] `yamllint . && ansible-lint playbooks/ roles/` → exit 0

  **Agent-Executed QA Scenarios**:
  ```
  Scenario: Verify all role defaults use vps_ prefix
    Tool: Bash
    Steps:
      1. Run: grep -rP '^\w' roles/*/defaults/main.yml | grep -vP '^\S+:\s*(vps_|#|---|$|\s)' | head -20
      2. Assert: empty output (all variable definitions start with vps_)
    Expected Result: Zero non-vps_ prefixed variables in role defaults

  Scenario: Verify backward compatibility
    Tool: Bash
    Steps:
      1. Run: ansible-playbook playbooks/main.yml --syntax-check
      2. Assert: exit code 0
      3. Run: ansible-lint playbooks/ roles/ 2>&1 | grep -c 'error'
      4. Assert: 0 errors
    Expected Result: Playbook still valid with shims in place
  ```

  **Commit**: YES
  - Message: `refactor(vars): add vps_ prefix compatibility shims to all role defaults`
  - Files: `roles/*/defaults/main.yml`, `roles/*/tasks/main.yml`
  - Pre-commit: `yamllint . && ansible-lint playbooks/ roles/`

---

- [x] 4. Variable Namespace — Phase 2: Remove Old Names from group_vars

  **What to do**:
  - Remove ALL old (non-prefixed) variable names from `inventory/group_vars/all.yml`
  - Replace with new `vps_<role>_` prefixed names and their values
  - Remove compatibility shims from role defaults (change `vps_docker_install: "{{ install_docker | default(true) }}"` to `vps_docker_install: true`)
  - Update `tests/strict_vars.yml` if it exists — replace old variable names
  - Run full lint + syntax check to verify

  **Must NOT do**:
  - Do NOT change variable values — only complete the name migration
  - Do NOT remove shims until group_vars is updated

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: [`clean-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Task 6)
  - **Blocks**: Tasks 7, 8
  - **Blocked By**: Task 3

  **References**:
  - `inventory/group_vars/all.yml` — Central variable definitions to rename
  - `tests/strict_vars.yml` — Test variable overrides to rename
  - All `roles/*/defaults/main.yml` — Remove backward-compat shims
  - Task 3 output — Exact mapping of old → new names

  **Acceptance Criteria**:
  - [ ] `grep -P '^(install_|docker_|nodejs_|npm_|python_|php_|vscode_|lazygit_|catppuccin_|default_font)' inventory/group_vars/all.yml | wc -l` → 0
  - [ ] `grep -rP '\{\{ (install_|docker_log|nodejs_ver|npm_global|install_python|python_pipx|install_php|php_ext|install_composer|install_vscode|vscode_ext|install_opencode|install_antigravity|install_nerd|lazygit_ver|catppuccin_|default_font)' roles/ | wc -l` → 0 (no remaining old-name references)
  - [ ] `ansible-playbook playbooks/main.yml --syntax-check` → exit 0
  - [ ] `yamllint . && ansible-lint playbooks/ roles/` → exit 0

  **Agent-Executed QA Scenarios**:
  ```
  Scenario: Verify old variable names fully removed
    Tool: Bash
    Steps:
      1. Run: grep -rP '(install_docker|docker_log_max|install_nodejs|nodejs_version|npm_global|install_python|python_pipx|install_php|php_extensions|install_composer|install_vscode|vscode_extensions|install_opencode|install_antigravity|install_nerd_fonts|lazygit_version|catppuccin_)' inventory/group_vars/all.yml roles/*/defaults/main.yml roles/*/tasks/main.yml | grep -v '#' | head -20
      2. Assert: empty output
    Expected Result: Zero references to old variable names
  ```

  **Commit**: YES
  - Message: `refactor(vars): complete vps_ prefix migration, remove old variable names`
  - Files: `inventory/group_vars/all.yml`, `roles/*/defaults/main.yml`, `tests/strict_vars.yml`
  - Pre-commit: `yamllint . && ansible-lint playbooks/ roles/`

---

- [x] 5. Code Quality: FQCN + Tags + Block/Rescue + Idempotency

  **What to do**:
  - **FQCN**: Find and replace all short module names with FQCN across all roles. Common replacements: `apt` → `ansible.builtin.apt`, `copy` → `ansible.builtin.copy`, `template` → `ansible.builtin.template`, `file` → `ansible.builtin.file`, `command` → `ansible.builtin.command`, `shell` → `ansible.builtin.shell`, `service` → `ansible.builtin.service`, `git` → `ansible.builtin.git`, `get_url` → `ansible.builtin.get_url`, `user` → `ansible.builtin.user`, `group` → `ansible.builtin.group`, `lineinfile` → `ansible.builtin.lineinfile`, `stat` → `ansible.builtin.stat`, `debug` → `ansible.builtin.debug`, `set_fact` → `ansible.builtin.set_fact`, `include_tasks` → `ansible.builtin.include_tasks`, `pip` → `ansible.builtin.pip`, `systemd` → `ansible.builtin.systemd`, `ini_file` → `community.general.ini_file`
  - **Tags**: Ensure every task in every role has appropriate tags following `[role, feature]` pattern. Verify tags in `playbooks/main.yml` follow `[phase, role]` pattern
  - **Block/Rescue**: Add `block/rescue/always` error handling to critical roles: `common` (package installation), `security` (firewall + SSH), `desktop` (KDE install), `xrdp` (service setup), `docker` (engine install). Rescue blocks should log the error and optionally set a failure fact
  - **Idempotency**: Add `changed_when: false` to command/shell tasks that are read-only queries. Add `creates:` or `removes:` arguments where appropriate. Add explicit `state: present` where currently implicit

  **Must NOT do**:
  - Do NOT change task logic or behavior
  - Do NOT add block/rescue to simple tool-install roles (low risk)
  - Do NOT add tags that would break existing `--tags` usage

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: [`clean-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3 (with Task 3)
  - **Blocks**: Task 7
  - **Blocked By**: Task 2

  **References**:
  - All `roles/*/tasks/main.yml` and sub-task files — FQCN and tags
  - `roles/common/tasks/main.yml` — block/rescue for package install
  - `roles/security/tasks/main.yml` — block/rescue for firewall/SSH
  - `roles/desktop/tasks/main.yml` — block/rescue for KDE install
  - `roles/xrdp/tasks/main.yml` — block/rescue for XRDP service
  - `roles/docker/tasks/main.yml` — block/rescue for Docker engine
  - `.ansible-lint` — Lint configuration (FQCN rules)
  - `ansible-lint -R playbooks/ roles/ 2>&1 | grep fqcn` — Find FQCN violations

  **Acceptance Criteria**:
  - [ ] `ansible-lint -R playbooks/ roles/ 2>&1 | grep -c 'fqcn'` → 0
  - [ ] `ansible-lint playbooks/ roles/` → exit 0, zero warnings
  - [ ] `grep -rP '^\s+block:' roles/{common,security,desktop,xrdp,docker}/tasks/main.yml | wc -l` → ≥5 (one block per critical role)

  **Agent-Executed QA Scenarios**:
  ```
  Scenario: FQCN compliance check
    Tool: Bash
    Steps:
      1. Run: ansible-lint -R playbooks/ roles/ 2>&1 | grep -i 'fqcn'
      2. Assert: empty output (zero FQCN violations)
    Expected Result: All modules use fully qualified collection names

  Scenario: Block/rescue on critical roles
    Tool: Bash
    Steps:
      1. Run: grep -l 'block:' roles/common/tasks/main.yml roles/security/tasks/main.yml roles/desktop/tasks/main.yml roles/xrdp/tasks/main.yml roles/docker/tasks/main.yml
      2. Assert: 5 files listed
      3. Run: grep -l 'rescue:' roles/common/tasks/main.yml roles/security/tasks/main.yml roles/desktop/tasks/main.yml roles/xrdp/tasks/main.yml roles/docker/tasks/main.yml
      4. Assert: 5 files listed
    Expected Result: All 5 critical roles have block/rescue
  ```

  **Commit**: YES
  - Message: `refactor(quality): enforce FQCN, add hierarchical tags, block/rescue on critical roles`
  - Files: All `roles/*/tasks/*.yml`, `playbooks/main.yml`
  - Pre-commit: `yamllint . && ansible-lint playbooks/ roles/`

---

- [x] 6. Add Kitty Terminal as Backup

  **What to do**:
  - Add Kitty installation tasks to `roles/terminal/tasks/main.yml`:
    - Install kitty package via apt
    - Create `~/.config/kitty/` directory
    - Deploy `kitty.conf.j2` template with font, theme, and behavior settings matching the existing Konsole setup
  - Create `roles/terminal/templates/kitty.conf.j2` template:
    - Font: `{{ vps_default_monospace_font }}` at `{{ vps_default_font_size }}pt`
    - Color scheme: Match Catppuccin Mocha if `vps_theme_variant == 'catppuccin-mocha'` (existing project pattern)
    - Terminal behavior: scrollback, cursor, bell settings
  - Add variables to `roles/terminal/defaults/main.yml`:
    - `vps_terminal_install_kitty: true`
    - `vps_terminal_kitty_theme: "catppuccin-mocha"` (used when `vps_theme_variant == 'catppuccin-mocha'`)
  - Gate Kitty tasks with `when: vps_terminal_install_kitty | default(true)`
  - Konsole remains primary — do NOT change Konsole configuration

  **Must NOT do**:
  - Do NOT remove or modify Konsole tasks
  - Do NOT set Kitty as default terminal
  - Do NOT create a separate kitty role — add to existing terminal role

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`clean-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 4 (with Task 4)
  - **Blocks**: Task 8
  - **Blocked By**: Task 3

  **References**:
  - `roles/terminal/tasks/main.yml` — Existing terminal setup (Konsole tasks as pattern)
  - `roles/terminal/defaults/main.yml` — Add kitty variables
  - `roles/terminal/templates/konsole-profile.j2` — Pattern for template structure
  - `roles/catppuccin-theme/files/` — Catppuccin color values for Kitty config
  - Kitty docs: `https://sw.kovidgoyal.net/kitty/conf/` — Official config reference

  **Acceptance Criteria**:
  - [ ] `grep -c 'kitty' roles/terminal/tasks/main.yml` → ≥3 (install + dir + template tasks)
  - [ ] `test -f roles/terminal/templates/kitty.conf.j2` → exit 0
  - [ ] `grep 'vps_terminal_install_kitty' roles/terminal/defaults/main.yml` → found
  - [ ] `yamllint roles/terminal/ && ansible-lint roles/terminal/` → exit 0

  **Agent-Executed QA Scenarios**:
  ```
  Scenario: Kitty tasks exist and are well-formed
    Tool: Bash
    Steps:
      1. Run: grep -A5 'Install Kitty\|kitty' roles/terminal/tasks/main.yml
      2. Assert: tasks for install, directory creation, and template deployment exist
      3. Run: grep 'when:.*vps_terminal_install_kitty' roles/terminal/tasks/main.yml
      4. Assert: conditional gate exists
    Expected Result: Kitty tasks properly gated and structured

  Scenario: Kitty config template is valid
    Tool: Bash
    Steps:
      1. Run: cat roles/terminal/templates/kitty.conf.j2 | head -20
      2. Assert: contains font_family, font_size, and color settings
    Expected Result: Template contains expected configuration sections
  ```

  **Commit**: YES
  - Message: `feat(terminal): add Kitty as backup terminal emulator with Catppuccin theme`
  - Files: `roles/terminal/tasks/main.yml`, `roles/terminal/templates/kitty.conf.j2`, `roles/terminal/defaults/main.yml`
  - Pre-commit: `yamllint . && ansible-lint playbooks/ roles/`

---

- [x] 7. KDE Manual Config Templates (Hybrid Approach)

  **What to do**:
  - **Theme/Appearance** (`kdeglobals`): The existing `roles/catppuccin-theme/templates/kdeglobals.j2` already handles this. Verify it is variable-driven and add any missing appearance settings (icon theme, cursor theme, color scheme). Add variables to control: `vps_kde_theme`, `vps_kde_icon_theme`, `vps_kde_cursor_theme`
  - **Keybindings** (`kglobalshortcutsrc`): Create `roles/kde-optimization/templates/kglobalshortcutsrc.j2` template. Use `community.general.ini_file` for granular shortcut overrides OR deploy a full template depending on scope. Add variables for common shortcuts (terminal open, window tiling, workspace switching)
  - **Autostart**: Create task in `roles/desktop/tasks/main.yml` (or `roles/kde-optimization/tasks/main.yml`) that deploys `.desktop` files to `~/.config/autostart/`. Add variable `vps_kde_autostart_apps` as a list of dicts `[{name, exec, comment}]`
  - **Panel/Taskbar Layout**: KEEP the existing git clone approach (`shalva97/kde-configuration-files`). Panel layout XML is too complex for Jinja2 templates. Ensure the clone task has proper `changed_when` and is gated with a variable `vps_kde_clone_config: true`
  - Add all new variables to `inventory/group_vars/all.yml` with sensible defaults

  **Must NOT do**:
  - Do NOT template KDE panel layout — it stays as git clone
  - Do NOT remove the `shalva97/kde-configuration-files` clone
  - Do NOT modify the `fish` dependency (needed by the clone's setupKDE.fish)
  - Do NOT duplicate theme configuration — work WITH existing catppuccin-theme role

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: [`clean-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Task 8)
  - **Blocks**: Task 9
  - **Blocked By**: Tasks 4, 5

  **References**:
  - `roles/catppuccin-theme/templates/kdeglobals.j2` — Existing KDE theme template (PATTERN — extend, don't replace)
  - `roles/kde-optimization/tasks/main.yml` — Existing KDE tuning via `community.general.ini_file` (lines 39-99 are canonical pattern)
  - `roles/desktop/tasks/main.yml` — Git clone of `shalva97/kde-configuration-files` and autostart setup
  - `roles/kde-optimization/defaults/main.yml` — Existing KDE optimization defaults
  - KDE config docs: `~/.config/kdeglobals` (theme), `~/.config/kglobalshortcutsrc` (keybindings), `~/.config/autostart/` (autostart apps)

  **Acceptance Criteria**:
  - [ ] `test -f roles/kde-optimization/templates/kglobalshortcutsrc.j2 || grep -c 'kglobalshortcutsrc' roles/kde-optimization/tasks/main.yml` → ≥1
  - [ ] `grep 'vps_kde_autostart_apps' roles/*/defaults/main.yml | wc -l` → ≥1
  - [ ] `grep 'vps_kde_theme\|vps_kde_icon_theme\|vps_kde_cursor_theme' inventory/group_vars/all.yml | wc -l` → ≥3
  - [ ] `grep 'shalva97/kde-configuration-files' roles/desktop/tasks/main.yml | wc -l` → ≥1 (clone preserved)
  - [ ] `yamllint . && ansible-lint playbooks/ roles/` → exit 0

  **Agent-Executed QA Scenarios**:
  ```
  Scenario: KDE keybinding configuration exists
    Tool: Bash
    Steps:
      1. Run: grep -r 'kglobalshortcutsrc' roles/kde-optimization/
      2. Assert: at least one reference (template or ini_file task)
      3. Run: grep 'vps_kde_' roles/kde-optimization/defaults/main.yml | wc -l
      4. Assert: ≥3 (multiple KDE config variables)
    Expected Result: Keybinding configuration is variable-driven

  Scenario: Autostart apps are configurable
    Tool: Bash
    Steps:
      1. Run: grep -A10 'autostart' roles/desktop/tasks/main.yml roles/kde-optimization/tasks/main.yml | grep -i 'vps_kde_autostart'
      2. Assert: variable-driven autostart entries exist
    Expected Result: Autostart applications controlled by variables

  Scenario: Git clone preserved for panel layout
    Tool: Bash
    Steps:
      1. Run: grep 'shalva97/kde-configuration-files' roles/desktop/tasks/main.yml
      2. Assert: clone task exists
      3. Run: grep 'vps_kde_clone_config\|when:' roles/desktop/tasks/main.yml | head -5
      4. Assert: clone is gated with a variable
    Expected Result: Panel layout still comes from external clone
  ```

  **Commit**: YES
  - Message: `feat(kde): add hybrid manual config (templates for theme/keys/autostart, clone for panels)`
  - Files: `roles/kde-optimization/tasks/main.yml`, `roles/kde-optimization/templates/`, `roles/kde-optimization/defaults/main.yml`, `roles/desktop/tasks/main.yml`, `inventory/group_vars/all.yml`
  - Pre-commit: `yamllint . && ansible-lint playbooks/ roles/`

---

- [x] 8. Update Tests (validate.sh + Molecule)

  **What to do**:
  - Update `tests/validate.sh`:
    - Replace old variable names in any assertions that reference them
    - Add FR-XX check for Kitty: `command -v kitty` and config file existence
    - Verify existing KDE checks (FR-12, FR-14, FR-15, FR-16) still pass with refactored code
    - Ensure all 30+ existing criteria still work
  - Update `molecule/default/converge.yml`:
    - Update role names if any were renamed
    - Ensure role order matches new `playbooks/main.yml` order
    - Keep desktop role commented out (CI timeout issue, pre-existing)
  - Update `tests/strict_vars.yml` if variable names changed
  - Run `molecule test` to verify full pipeline

  **Must NOT do**:
  - Do NOT add new Molecule scenarios
  - Do NOT uncomment the desktop role in molecule converge (pre-existing CI timeout)
  - Do NOT change test logic — only update references

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: [`clean-code`, `testing-patterns`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 5 (with Task 7)
  - **Blocks**: Task 10
  - **Blocked By**: Tasks 4, 6

  **References**:
  - `tests/validate.sh` — All 30+ criteria (FR-*, SR-*, QR-*, DR-*)
  - `molecule/default/converge.yml` — Role list to update
  - `molecule/default/verify.yml` — Runs validate.sh
  - `tests/strict_vars.yml` — Variable overrides
  - Test assessment findings (from explore agent): FR-12 (KDE), FR-14 (Karousel), FR-15 (Spectacle), FR-16 (Yakuake) — keep as-is since KDE stays

  **Acceptance Criteria**:
  - [ ] `shellcheck tests/validate.sh` → exit 0
  - [ ] `grep 'kitty' tests/validate.sh | wc -l` → ≥1 (Kitty check added)
  - [ ] `yamllint molecule/default/converge.yml` → exit 0
  - [ ] `ansible-lint molecule/default/converge.yml` → exit 0

  **Agent-Executed QA Scenarios**:
  ```
  Scenario: validate.sh includes Kitty check
    Tool: Bash
    Steps:
      1. Run: grep -A3 'kitty\|Kitty' tests/validate.sh
      2. Assert: check for kitty binary exists
    Expected Result: Kitty validation added to test suite

  Scenario: molecule converge.yml is valid
    Tool: Bash
    Steps:
      1. Run: yamllint molecule/default/converge.yml
      2. Assert: exit 0
      3. Run: grep -c 'role:' molecule/default/converge.yml
      4. Assert: ≥10 roles listed
    Expected Result: Molecule converge is valid YAML with correct roles
  ```

  **Commit**: YES
  - Message: `test(validate): update tests for refactored variable names, add Kitty check`
  - Files: `tests/validate.sh`, `molecule/default/converge.yml`, `tests/strict_vars.yml`
  - Pre-commit: `shellcheck tests/validate.sh && yamllint molecule/`

---

- [x] 9. Update Documentation

  **What to do**:
  - Update `README.md`: reflect new role ordering, mention Kitty as backup terminal, update project structure diagram
  - Update `AGENTS.md`: update execution order, note refactored variable naming convention
  - Update `CLAUDE.md`: update commands section, variable naming convention
  - Update `.github/copilot-instructions.md`: update 10-phase execution order, variable naming examples
  - Update `.github/AI_AGENT_GUIDE.md`: comprehensive update for new conventions
  - Update `docs/CONFIGURATION.md`: list new variables and their defaults
  - Update all `roles/*/AGENTS.md` files: reflect any renamed variables or new features in each role

  **Must NOT do**:
  - Do NOT create new documentation files
  - Do NOT change code — documentation only

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: [`clean-code`]

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 6 (with Task 10)
  - **Blocks**: Task 10
  - **Blocked By**: Task 7

  **References**:
  - `README.md` — Feature list, role ordering, project structure
  - `AGENTS.md` — Knowledge base with execution order
  - `CLAUDE.md` — AI agent guide with commands and conventions
  - `.github/copilot-instructions.md` — Copilot instructions
  - `.github/AI_AGENT_GUIDE.md` — Detailed architecture guide
  - `docs/CONFIGURATION.md` — Configuration variable reference
  - All `roles/*/AGENTS.md` — Per-role documentation

  **Acceptance Criteria**:
  - [ ] `grep -c 'XFCE\|xfce' README.md` → 0 (no XFCE references in KDE project)
  - [ ] `grep 'Kitty\|kitty' README.md | wc -l` → ≥1
  - [ ] `grep 'vps_<role>_\|vps_docker_\|vps_dev_' AGENTS.md | wc -l` → ≥1 (naming convention documented)

  **Commit**: YES
  - Message: `docs: update documentation for refactored role order, variables, and Kitty terminal`
  - Files: `README.md`, `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, `.github/AI_AGENT_GUIDE.md`, `docs/CONFIGURATION.md`

---

- [x] 10. Final Verification Gate

  **What to do**:
  - Run the complete verification suite:
    1. `yamllint .` — YAML lint
    2. `ansible-lint playbooks/ roles/` — Ansible lint
    3. `shellcheck tests/validate.sh tests/remote_test.sh setup.sh` — Shell lint
    4. `ansible-playbook playbooks/main.yml --syntax-check` — Syntax validation
    5. `grep -rh 'name:' roles/*/handlers/main.yml | sort | uniq -d` — Handler uniqueness
    6. `grep -rP '^\w' roles/*/defaults/main.yml | grep -vP '^\S+:\s*(vps_|#|---|$|\s)'` — Variable naming compliance
    7. Verify role ordering constraints (common < security < desktop < xrdp, etc.)
    8. `molecule test` — Full molecule run (if CI environment available)
  - If any check fails: fix and re-verify before marking complete
  - Produce a final summary report of all changes made

  **Must NOT do**:
  - Do NOT skip any verification step
  - Do NOT mark complete if any check fails

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: [`clean-code`, `testing-patterns`]

  **Parallelization**:
  - **Can Run In Parallel**: NO (final gate)
  - **Parallel Group**: Wave 6 (after all tasks)
  - **Blocks**: None (final)
  - **Blocked By**: Tasks 8, 9

  **References**:
  - All files modified in Tasks 1-9
  - `.yamllint` — yamllint configuration
  - `.ansible-lint` — ansible-lint configuration
  - `.pre-commit-config.yaml` — Pre-commit hooks

  **Acceptance Criteria**:
  - [ ] ALL 8 verification commands above pass with zero errors
  - [ ] `git diff --stat HEAD` shows expected file changes
  - [ ] No orphaned files (stale templates, unused defaults)

  **Agent-Executed QA Scenarios**:
  ```
  Scenario: Full lint suite passes
    Tool: Bash
    Steps:
      1. Run: yamllint . 2>&1 | tail -3
      2. Assert: exit 0
      3. Run: ansible-lint playbooks/ roles/ 2>&1 | tail -3
      4. Assert: exit 0
      5. Run: shellcheck tests/validate.sh 2>&1 | tail -3
      6. Assert: exit 0
    Expected Result: Zero lint errors across all tools

  Scenario: Variable naming compliance
    Tool: Bash
    Steps:
      1. Run: grep -rP '^\w' roles/*/defaults/main.yml | grep -vP '^\S+:\s*(vps_|#|---|$|\s)' | wc -l
      2. Assert: 0
    Expected Result: All role defaults use vps_ prefix

  Scenario: Handler uniqueness
    Tool: Bash
    Steps:
      1. Run: grep -rh 'name:' roles/*/handlers/main.yml | sort | uniq -d | wc -l
      2. Assert: 0
    Expected Result: No duplicate handler names

  Scenario: Playbook syntax valid
    Tool: Bash
    Steps:
      1. Run: ansible-playbook playbooks/main.yml --syntax-check
      2. Assert: exit 0
    Expected Result: Playbook is syntactically valid
  ```

  **Commit**: YES
  - Message: `chore: final verification gate — all lint, syntax, and compliance checks pass`
  - Files: any remaining fixes
  - Pre-commit: `yamllint . && ansible-lint playbooks/ roles/ && shellcheck tests/validate.sh`

---

## Commit Strategy

| After Task | Message | Verification |
|------------|---------|--------------|
| 1 | `refactor(cleanup): remove stale XRDP templates, deduplicate handlers, standardize meta` | yamllint + ansible-lint |
| 2 | `refactor(playbook): reorder roles to canonical best-practice sequence` | syntax-check |
| 3 | `refactor(vars): add vps_ prefix compatibility shims to all role defaults` | syntax-check + lint |
| 4 | `refactor(vars): complete vps_ prefix migration, remove old variable names` | syntax-check + lint |
| 5 | `refactor(quality): enforce FQCN, add hierarchical tags, block/rescue on critical roles` | ansible-lint |
| 6 | `feat(terminal): add Kitty as backup terminal emulator with Catppuccin theme` | lint |
| 7 | `feat(kde): add hybrid manual config (templates for theme/keys/autostart, clone for panels)` | lint |
| 8 | `test(validate): update tests for refactored variable names, add Kitty check` | shellcheck + yamllint |
| 9 | `docs: update documentation for refactored role order, variables, and Kitty terminal` | — |
| 10 | `chore: final verification gate — all lint, syntax, and compliance checks pass` | full suite |

---

## Success Criteria

### Verification Commands
```bash
yamllint .                                    # Expected: exit 0
ansible-lint playbooks/ roles/                # Expected: exit 0
shellcheck tests/validate.sh                  # Expected: exit 0
ansible-playbook playbooks/main.yml --syntax-check  # Expected: exit 0
grep -rh 'name:' roles/*/handlers/main.yml | sort | uniq -d  # Expected: empty
grep -rP '^\w' roles/*/defaults/main.yml | grep -vP '^\S+:\s*(vps_|#|---|$|\s)'  # Expected: empty
molecule test                                 # Expected: exit 0
```

### Final Checklist
- [x] All "Must Have" requirements present
- [x] All "Must NOT Have" guardrails respected
- [x] All 30+ validate.sh criteria pass
- [x] Kitty installed and configured
- [x] KDE manual config templates deployed
- [x] Role ordering matches target order
- [x] All variables use vps_ prefix
- [x] Zero duplicate handlers
- [x] All documentation updated
