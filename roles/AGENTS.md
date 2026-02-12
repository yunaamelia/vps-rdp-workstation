# COMPONENT: ANSIBLE ROLES

**Purpose**: General role development standards.

## STRUCTURE
*   **Hierarchy**: Flat (e.g., `roles/common`, `roles/security`).
*   **Logic**: `tasks/main.yml` (Entry point).
*   **Variables**: `defaults/main.yml` (Default vars).

## CONVENTIONS
*   **Namespacing**: Variables MUST use `vps_<role>_` prefix.
*   **Tags**: Mandatory `[phase, role, feature]` schema.
*   **Idempotency**: All tasks MUST be safe to re-run.
*   **Check Mode**: Full support for `--check` REQUIRED.

## ANTI-PATTERNS
*   **Global Handlers**: NEVER rely on them; keep handlers within roles.
*   **Hardcoded Users**: NEVER use root/fixed names; use `{{ vps_username }}`.
*   **Sequence Violation**: NEVER move `security` role after services.
