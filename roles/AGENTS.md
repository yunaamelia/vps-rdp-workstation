# COMPONENT: ANSIBLE ROLES

**Purpose**: Independent roles for the 10-phase Debian 13 workstation automation.

## STRUCTURE
*   **Flat Architecture**: Exactly 25 roles in `roles/<name>/`. No nesting.
*   **Role Layout**: Standard `tasks/`, `defaults/`, `handlers/`, `templates/`, `meta/`.
*   **Entry Point**: `tasks/main.yml`.
*   **Variable Hierarchy**: `defaults/main.yml` (role) vs `inventory/group_vars/all.yml` (global).

## CONVENTIONS
*   **Naming**: Prefix `vps_<role>_` (Exception: `docker_`).
*   **Tagging**: Schema `[phase, role, feature]`.
*   **Check Mode**: Support `--check --diff`. Use `ignore_errors: "{{ ansible_check_mode }}"` where needed.
*   **External Content**: Use `ansible.builtin.get_url` with `creates`.
*   **FQCN**: Mandatory.

## ANTI-PATTERNS
*   **Global Handlers**: Forbidden.
*   **Hardcoded Users**: Use `{{ vps_username }}`.
*   **Logic Guards**: Use `when: vps_<role>_install_feature | default(true)`.

[Root Guidelines](../AGENTS.md)
