# COMPONENT: ORCHESTRATION

**Core Logic**: `main.yml` master playbook.

## STRUCTURE
*   `main.yml`: Master orchestration (10 phases, 25 roles).
*   `rollback.yml`: Destructive recovery.
*   `templates/summary-log.j2`: Post-install report.

## MECHANISMS
*   **Progress Tracking**: `/var/lib/vps-setup/progress.json`.
    - `pre_tasks`: Initialize state.
    - `post_tasks`: Mark `completed`.
*   **Resume Capability**: `--resume` flag reads `progress.json` to skip finished roles.
*   **Safety**: `no_log: true` on secret-sensitive validations.

## ANTI-PATTERNS
*   **Reordering**: NEVER move `security` after service roles (`desktop`, `xrdp`).
*   **Direct Invocation**: Avoid `ansible-playbook` directly; use `setup.sh` wrapper.

[Root Guidelines](../AGENTS.md)
