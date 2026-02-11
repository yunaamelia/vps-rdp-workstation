# COMPONENT: ORCHESTRATION

**Core Logic**: `main.yml` defines the execution order and state tracking.

## STRUCTURE
```
playbooks/
├── main.yml          # Master orchestration (Phases 1-7)
└── rollback.yml      # Destructive recovery logic
```

## ORCHESTRATION PHASES
1.  **Foundation**: `common` (System base)
2.  **Security**: `security` (Lockdown BEFORE services)
3.  **Visual**: `fonts`, `terminal`
4.  **Desktop**: `desktop` (GUI layer)
5.  **Dev/Services**: `dev`, `docker`
6.  **Tools**: Optional utility roles

## CONVENTIONS
*   **State Tracking**: `pre_tasks` and `post_tasks` manage `/var/lib/vps-setup/progress.json`.
*   **Conditionals**: Optional roles guarded by `when: install_feature | default(true)`.
*   **Order**: Security ALWAYS precedes service exposure.

## ANTI-PATTERNS
*   **Reordering**: Changing phase order risks dependency breaks (e.g., firewall blocking download).
*   **Direct Execution**: Do not run without `setup.sh` (missing secrets/mitogen).
