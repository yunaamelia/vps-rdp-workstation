---
trigger: glob
globs:
  - "roles/**/*.yml"
  - "playbooks/**/*.yml"
  - "playbooks/templates/**/*.j2"
  - "inventory/**/*.yml"
  - "plugins/**/*.py"
---

# Ansible Coding Style Rules

> Source: [Red Hat Automation Good Practices §8](https://redhat-cop.github.io/automation-good-practices/#_coding_style_good_practices_for_ansible)
> Related rules: @ansible-roles.md · @ansible-playbooks.md · @ansible-inventories.md

> **Scope Note:** These rules apply to `roles/`, `playbooks/`, `inventory/`, and `plugins/` only.
> Do NOT apply to `molecule/`, `tests/`, `collections/`, or `requirements*.yml` files.

## Violation Response Protocol

When a violation is detected in an existing file:
1. **MUST** flag the violation with the rule reference (e.g., `[CS-YAML-01]`).
2. **MUST** show the corrected version inline as a diff or replacement.
3. **SHOULD** explain *why* the rule exists (`Rationale:`).
4. **MUST NOT** silently accept violations — always surface them to the user.

## Severity Levels (RFC 2119)

- **MUST / MUST NOT**: Enforced — block or flag every occurrence.
- **SHOULD / SHOULD NOT**: Strongly encouraged — flag and suggest fix.
- **MAY**: Optional — mention only if directly relevant.

## Naming Conventions

- **MUST** use `snake_case` for ALL YAML files, variables, arguments, repo names, and dictionary keys.  `[CS-NAME-01]`
- **MUST NOT** use special characters other than underscore in variable names.  `[CS-NAME-02]`
- **SHOULD** use the `object[_feature]_action` pattern for roles and playbooks (e.g., `security_ssh_configure`).  `[CS-NAME-03]`
- **MUST NOT** number roles or playbooks.  `[CS-NAME-04]`
- **MUST** name ALL tasks, plays, and task blocks — no anonymous tasks.  `[CS-NAME-05]`
- **MUST** write task names in the **imperative** form: `"Ensure service is running"`, `"Install required packages"`.  `[CS-NAME-06]`
- **SHOULD** avoid abbreviations; capitalize unavoidable ones (e.g., `SSH`, `UFW`).  `[CS-NAME-07]`

## YAML Syntax

- **MUST** indent with **2 spaces** — never tabs.  `[CS-YAML-01]`
- **MUST** indent list contents beyond their list definition marker.  `[CS-YAML-02]`
- **SHOULD** split long expressions across multiple lines.  `[CS-YAML-03]`
- **MUST** break long `when:` AND conditions into a YAML list:  `[CS-YAML-04]`
  ```yaml
  # CORRECT
  when:
    - condition_one
    - condition_two
  ```
- **MUST** use expanded YAML syntax — never `key=value` shorthand.  `[CS-YAML-05]`
- **MUST** use `true` / `false` for booleans — never `yes`/`no`/`on`/`off`.  `[CS-YAML-06]`
- **MUST** use the `.yml` extension, not `.yaml`.  `[CS-YAML-07]`
- **MUST** use **double quotes** for YAML strings; **single quotes** inside Jinja2 expressions.  `[CS-YAML-08]`
- **MUST NOT** quote bare module keywords: `present`, `absent`, `started`, `stopped`.  `[CS-YAML-09]`
- **SHOULD NOT** use JSON inline syntax in YAML unless auto-generated.  `[CS-YAML-10]`

## FQCN (Fully Qualified Collection Names)

- **MUST** use FQCN for all modules.  `[CS-FQCN-01]`
  - ✅ `ansible.builtin.apt`, `community.general.ini_file`
  - ❌ `apt`, `ini_file`
- This rule is the single authoritative source for FQCN; `@ansible-playbooks.md` defers here.

## Jinja2 Syntax

- **MUST** put a **single space** inside all template markers: `{{ variable_name }}`.  `[CS-J2-01]`
- **SHOULD** break lengthy Jinja templates at logical section boundaries.  `[CS-J2-02]`
- **MUST NOT** use Jinja templates to create structured data (dicts/lists) — use filter plugins.  `[CS-J2-03]`
- **MUST** cast public API variables: `{{ count | int }}`, `{{ flag | bool }}`, `{{ ratio | float }}`.  `[CS-J2-04]`

## Line Wrapping

- **SHOULD** wrap long Jinja expressions using multi-line Jinja.  `[CS-WRAP-01]`
- **SHOULD** use YAML block scalars (`>-`) for long strings that allow extra spaces.  `[CS-WRAP-02]`
- **MAY** use backslash escapes in double-quoted strings for URLs.  `[CS-WRAP-03]`
  ```yaml
  url: "https://example.com/very/long/\
       path/to/resource"
  ```

## Comments

- **SHOULD NOT** write comments in task files — the task `name` should be self-documenting.  `[CS-CMT-01]`
- **MUST** comment all variables in `defaults/main.yml` and `vars/main.yml`.  `[CS-CMT-02]`
- **MUST** add a justification comment when using `ansible.builtin.command` or `ansible.builtin.shell`.  `[CS-CMT-03]`
