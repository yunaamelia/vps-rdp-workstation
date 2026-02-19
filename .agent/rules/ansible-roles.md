---
trigger: glob
globs: ["roles/**"]
---

# Ansible Roles Rules

> Source: [Red Hat Automation Good Practices §3](https://redhat-cop.github.io/automation-good-practices/#_roles_good_practices_for_ansible)
> Coding style rules: @ansible-coding-style.md (authoritative for FQCN, YAML syntax, Jinja2)

## Violation Response Protocol

When reviewing or generating role code:
1. **MUST** validate all required files in role structure exist before accepting changes.
2. **MUST** flag non-idempotent tasks and refuse to generate them without `changed_when:`.
3. **MUST** warn if `set_fact` overrides a variable defined in `defaults/` or `vars/`.
4. **SHOULD** suggest `meta/argument_specs.yml` when new public variables are added without validation.
5. **MUST NOT** generate tasks without a `name:` field.

## Severity Levels (RFC 2119)

- **MUST / MUST NOT**: Enforced — block or flag every occurrence.
- **SHOULD / SHOULD NOT**: Strongly encouraged — flag and suggest fix.
- **MAY**: Optional — mention only if directly relevant.

## Project Context: Roles in this Workspace

This project contains **25 roles** executed in strict dependency order:
```
01 common → 02 security → 03 fonts → 04 desktop → 05 xrdp →
06 kde-optimization → 07 kde-apps → 08 whitesur-theme → 09 terminal →
10 shell-styling → 11 zsh-enhancements → 12 development → 13 docker →
14 editors → 15 tui-tools → 16 network-tools → 17 system-performance →
18 text-processing → 19 file-management → 20 dev-debugging →
21 code-quality → 22 productivity → 23 log-visualization →
24 ai-devtools → 25 cloud-native
```

- **MUST NOT** move `security` before `common` or after `fonts` — security hardens the system before any service is exposed.
- New roles **MUST** be inserted at a logical phase; do not append blindly at the end.

## Design Principles

- **MUST** design role interfaces focused on **functionality**, not software implementation.  `[RL-DESIGN-01]`
- **MUST** place content common to multiple roles in the `common` role.  `[RL-DESIGN-02]`
- **MUST** author loosely coupled content — roles MUST NOT directly reference other role variables.  `[RL-DESIGN-03]`
- **MUST** prefix all role variables with the role name: `rolename_variable`.  `[RL-DESIGN-04]`
- In this project: **MUST** use `vps_<rolename>_` prefix (e.g., `vps_docker_install`, `vps_terminal_install_kitty`).  `[RL-DESIGN-05]`

## Role Structure

**MUST** contain at minimum:  `[RL-STRUCT-01]`
```
roles/<role-name>/
├── tasks/main.yml       # Entry point — REQUIRED
├── handlers/main.yml    # Service restarts — REQUIRED
├── templates/           # Jinja2 .j2 templates
├── files/               # Static files and binary blobs
├── defaults/main.yml    # Default variables (lowest precedence) — REQUIRED
├── vars/main.yml        # Role-internal constants (higher precedence)
└── meta/main.yml        # Dependencies and galaxy metadata — REQUIRED
```

- **MUST** add a `tags:` field to all tasks using the `[phase, role, feature]` pattern.  `[RL-STRUCT-02]`
- **MUST** include a `README.md` in every role.  `[RL-STRUCT-03]`

## Idempotency

- **MUST** ensure ALL tasks are idempotent — two consecutive runs produce zero changes on the second.  `[RL-IDEM-01]`
- **MUST** add `changed_when:` to `command`/`shell` tasks.  `[RL-IDEM-02]`
- **SHOULD** use `check_mode: false` only when a task must run even during dry-runs.  `[RL-IDEM-03]`
- **MUST NOT** use `ignore_errors: true` in tests — it silently masks assertion failures.  `[RL-IDEM-04]`

## Check Mode

- **MUST** support `--check` (dry-run) mode for all tasks unless explicitly disabled.  `[RL-CHK-01]`
- **MUST** set both `check_mode: false` AND `changed_when:` for `command`/`shell` tasks that are not check-mode safe.  `[RL-CHK-02]`

## Variables: Defaults vs Vars

- `defaults/main.yml`: **MUST** document every variable with inline comment.  `[RL-VAR-01]`
- `vars/main.yml`: private constants — **MUST NOT** be overridden by users.  `[RL-VAR-02]`
- **MUST NOT** override `defaults/` or `vars/` values using `set_fact` — use a different variable name.  `[RL-VAR-03]`
- **MUST** use the smallest variable scope: task > block > role > play > global.  `[RL-VAR-04]`
- **SHOULD** avoid `set_fact` — facts are global for the whole playbook run.  `[RL-VAR-05]`

## Argument Validation

- **SHOULD** add `tasks/validate.yml` using `ansible.builtin.assert` or `meta/argument_specs.yml`.  `[RL-VALID-01]`
- **MUST** validate types, allowed values, and required fields at role entry point if the role is user-facing.  `[RL-VALID-02]`

## Error Handling

- **SHOULD** wrap critical sections in `block`/`rescue`/`always` for recovery.  `[RL-ERR-01]`
  ```yaml
  block:
    - name: "Install | Ensure package is present"
      ansible.builtin.apt:
        name: "{{ package }}"
  rescue:
    - name: "Install | Handle package failure"
      ansible.builtin.fail:
        msg: "Failed to install {{ package }}: {{ ansible_failed_result.msg }}"
  ```
- **MUST** provide meaningful `fail_msg` in all `assert` tasks.  `[RL-ERR-02]`

## Sub-task File Naming

- **MUST** prefix task names in sub-task files with the file's purpose:  `[RL-NAME-01]`
  ```yaml
  # tasks/configure.yml
  - name: "Configure | Ensure sshd_config has correct permissions"
  # tasks/install.yml
  - name: "Install | Ensure openssh-server is present"
  ```

## Platform Support

- **SHOULD** store platform-specific variables in `vars/<os_family>.yml` loaded via `include_vars`.  `[RL-PLAT-01]`
- **SHOULD** store platform-specific tasks in `tasks/<os_family>.yml` loaded via `include_tasks`.  `[RL-PLAT-02]`
- **MUST NOT** hardcode host group names — always make them role parameters.  `[RL-PLAT-03]`

## Documentation

- **MUST** comment every variable in `defaults/main.yml` with its purpose and valid values.  `[RL-DOC-01]`
- **MUST** use the `.j2` extension for all template files.  `[RL-DOC-02]`
- **SHOULD** keep template filenames close to their destination path on the target system.  `[RL-DOC-03]`
