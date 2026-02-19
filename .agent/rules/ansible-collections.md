---
trigger: glob
globs: ["collections/**"]
---

# Ansible Collections Rules

> Source: [Red Hat Automation Good Practices §4](https://redhat-cop.github.io/automation-good-practices/#_collections_good_practices)
> FQCN usage and YAML style: @ansible-coding-style.md (authoritative)

## Violation Response Protocol

When reviewing or modifying collection content:
1. **MUST** flag collection dependencies in `requirements.yml` that lack a pinned version.
2. **MUST** flag module references without FQCN — defer to `@ansible-coding-style.md [CS-FQCN-01]`.
3. **SHOULD** warn if a collection `README.md` is absent or missing installation instructions.
4. **MUST NOT** add new collection dependencies without updating `requirements.yml`.

## Severity Levels (RFC 2119)

- **MUST / MUST NOT**: Enforced — block or flag every occurrence.
- **SHOULD / SHOULD NOT**: Strongly encouraged — flag and suggest fix.
- **MAY**: Optional — mention only if directly relevant.

## Project Context: Collections in this Workspace

This project uses the following pinned collections (see `requirements.yml`):
```yaml
collections:
  - name: community.general
    version: "12.3.0"
  - name: ansible.posix
    version: "2.1.0"
  - name: community.docker
    version: "5.0.6"
```

- **MUST NOT** upgrade collection versions without testing in molecule first.
- Collections are installed to `collections/ansible_collections/` — do not edit files there directly.

## Collection Structure

- **SHOULD** structure collections at the **type or landscape level** — not per application or team.  `[COL-STRUCT-01]`
- **MUST** group only logically related roles, modules, and plugins in a single collection.  `[COL-STRUCT-02]`

## Variables

- **SHOULD** create implicit collection-level variables and reference them in roles' `defaults/main.yml`:  `[COL-VAR-01]`
  ```yaml
  # collection-level defaults
  my_namespace.my_collection.timeout: 30

  # role defaults/main.yml
  role_timeout: "{{ my_namespace.my_collection.timeout | default(30) }}"
  ```

## Documentation

- **MUST** include a `README.md` at the collection root with:  `[COL-DOC-01]`
  - Purpose and scope
  - Included roles, modules, and plugins
  - Installation: `ansible-galaxy collection install <namespace>.<collection>`
  - Usage examples
- **MUST** include a `LICENSE` file at the collection root.  `[COL-DOC-02]`

## Requirements File

- **MUST** declare all collection dependencies in `requirements.yml` with **pinned versions**.  `[COL-REQ-01]`
  ```yaml
  collections:
    - name: community.general
      version: "12.3.0"
    - name: ansible.posix
      version: "2.1.0"
  ```
- **MUST NOT** use version ranges (`>=`, `*`) — lock exact versions to prevent breakage.  `[COL-REQ-02]`

## FQCN Usage

- **MUST** reference all modules and roles using their FQCN inside collection content.  `[COL-FQCN-01]`
  - ✅ `community.general.ini_file`, `ansible.builtin.template`
  - ❌ `ini_file`, `template`
- See `@ansible-coding-style.md [CS-FQCN-01]` for the authoritative FQCN rule.
