# COMPONENT: ORCHESTRATION

**Scope**: Master playbooks for 25-role Debian 13 workstation setup.

## STRUCTURE

| File                       | Purpose                                    |
| -------------------------- | ------------------------------------------ |
| `main.yml`                 | Master orchestration (25 roles, 14 phases) |
| `rollback.yml`             | Destructive recovery playbook              |
| `templates/summary-log.j2` | Post-install report template               |

## MECHANISMS

- **Progress Tracking**: `/var/lib/vps-setup/progress.json`
  - `pre_tasks`: Initialize state with timestamp
  - `post_tasks`: Mark role `completed`
- **Resume**: `--resume` flag reads `progress.json` to skip finished roles.
- **Safety**: `no_log: true` on all secret-sensitive tasks.
- **Tagging**: 3-level schema `[phase, role, feature]` for granular execution.

## EXECUTION FLOW

1. `pre_tasks`: Validate environment, init progress.json
2. Phase 1-14: Role execution in strict order
3. `post_tasks`: Generate summary, mark completion
4. ARA: Auto-record to SQLite (`/var/log/ara-database.sqlite`)

## ANTI-PATTERNS

- **Reordering**: NEVER move `security` after service roles (`desktop`, `xrdp`, `docker`).
- **Direct Invocation**: NEVER run `ansible-playbook` directly; use `setup.sh`.
- **Missing Progress**: Skipping progress tracking breaks `--resume`.

[Root Guidelines](../AGENTS.md)
