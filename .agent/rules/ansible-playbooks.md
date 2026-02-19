---
trigger: glob
globs: ["playbooks/**"]
---

# Ansible Playbooks Rules

> Source: [Red Hat Automation Good Practices §5](https://redhat-cop.github.io/automation-good-practices/#_playbooks_good_practices)
> Coding style (FQCN, YAML, Jinja2): @ansible-coding-style.md (authoritative)
> Role error handling (block/rescue): @ansible-roles.md (authoritative)

## Violation Response Protocol

When reviewing or generating playbook code:
1. **MUST** flag any play using both `tasks:` and `roles:` simultaneously.
2. **MUST** flag unqualified module names (not FQCN) — defer to `@ansible-coding-style.md [CS-FQCN-01]`.
3. **MUST** flag bare `debug` tasks missing `verbosity:` parameter.
4. **MUST** warn if playbook role order violates the 10-phase execution sequence.
5. **SHOULD** suggest extracting inline task logic to a dedicated role when tasks grow beyond ~5 steps.

## Severity Levels (RFC 2119)

- **MUST / MUST NOT**: Enforced — block or flag every occurrence.
- **SHOULD / SHOULD NOT**: Strongly encouraged — flag and suggest fix.
- **MAY**: Optional — mention only if directly relevant.

## Project Context: 10-Phase Execution Order

The main playbook (`playbooks/main.yml`) **MUST** execute roles in this order:
```
Phase 1 — Bootstrap:   common
Phase 2 — Security:    security          ← MUST run before any service is exposed
Phase 3 — Base:        fonts
Phase 4 — Desktop:     desktop, xrdp, kde-optimization, kde-apps, whitesur-theme
Phase 5 — User config: terminal, shell-styling, zsh-enhancements
Phase 6 — Dev tools:   development, docker, editors
Phase 7 — CLI tools:   tui-tools, network-tools, system-performance,
                       text-processing, file-management, dev-debugging,
                       code-quality, productivity, log-visualization,
                       ai-devtools, cloud-native
```

- **MUST NOT** reorder phases — security hardens the system before desktop exposes RDP port 3389.
- **MUST** use `when: install_<feature> | default(true) | bool` guards for optional Phase 7 roles.

## Simplicity

- **MUST** keep playbooks as simple as possible — playbooks orchestrate, roles implement.  `[PB-SIMP-01]`
- **SHOULD** ensure a playbook is readable without deep Ansible knowledge.  `[PB-SIMP-02]`
- **MUST NOT** embed business logic in playbooks — delegate to roles.  `[PB-SIMP-03]`

## Structure

- **MUST** use **either** `tasks:` **or** `roles:` in a single play — never both.  `[PB-STRUCT-01]`
  ```yaml
  # CORRECT: roles only
  - hosts: all
    roles:
      - role: common
        tags: [common, bootstrap]
      - role: security
        tags: [security, hardening]

  # CORRECT: tasks only (simple one-off operations)
  - hosts: all
    tasks:
      - name: "Ensure hostname is set"
        ansible.builtin.hostname:
          name: "{{ inventory_hostname }}"
  ```
- **MUST NOT** use Jinja2 variables in play `name:` fields — they are not expanded properly.  `[PB-STRUCT-02]`

## Tags

- **SHOULD** use tags only for roles or complete functional purposes — not individual tasks.  `[PB-TAG-01]`
- **MUST** follow the `[phase, role, feature]` multi-level tagging pattern:  `[PB-TAG-02]`
  ```yaml
  - role: security
    tags: [security, hardening, ssh]
  ```
- **SHOULD** document all available tags in the playbook header comment or README.  `[PB-TAG-03]`

## Debugging

- **MUST** use the `verbosity:` parameter with all `ansible.builtin.debug` tasks.  `[PB-DBG-01]`
  ```yaml
  - name: "Debug | Show computed variable"
    ansible.builtin.debug:
      var: computed_result
      verbosity: 2
  ```
- **MUST NOT** leave bare `debug` tasks without `verbosity` in production playbooks.  `[PB-DBG-02]`

## Module Usage — Anti-patterns

- **MUST NOT** call `apt`/`dnf`/`package` iteratively with `{{ item }}` — pass the full list:  `[PB-MOD-01]`
  ```yaml
  # BAD — slow, triggers N apt calls
  - ansible.builtin.apt:
      name: "{{ item }}"
    loop: "{{ packages }}"

  # GOOD — single apt call
  - ansible.builtin.apt:
      name: "{{ packages }}"
  ```
- **MUST NOT** use `meta: end_play`.  `[PB-MOD-02]`
- **SHOULD NOT** use `lineinfile` — prefer `template` or `blockinfile`.  `[PB-MOD-03]`
- **SHOULD NOT** use `when: foo_result is changed` — use handlers and handler chains.  `[PB-MOD-04]`
- **SHOULD** prefer `template` over `copy` for all file pushes, even if not yet templated.  `[PB-MOD-05]`
