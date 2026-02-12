# COMPONENT: ORCHESTRATION

**Core Logic**: `main.yml` defines 10-phase execution order with progress tracking.

## STRUCTURE
```
playbooks/
├── main.yml          # Master orchestration (10 phases, 25 roles)
├── rollback.yml      # Destructive recovery logic
└── templates/
    └── summary-log.j2 # Post-install summary report
```

## ORCHESTRATION PHASES (actual order in main.yml)
| Phase | Roles | Guard |
|-------|-------|-------|
| 1. Foundation | `common` | Always |
| 2. Security | `security` | Always |
| 3. Desktop | `desktop`, `xrdp`, `kde-optimization`, `kde-apps` | `vps_install_desktop`, `vps_install_xrdp` |
| 4. Visual | `fonts`, `catppuccin-theme`, `terminal`, `shell-styling`, `zsh-enhancements` | `vps_install_zsh_external_plugins` |
| 5. Dev Languages | `development` | Always |
| 6. Containers | `docker` | `install_docker` |
| 7. Editors | `editors` | Always |
| 8. Dev Tools | `tui-tools` → `network-tools` → `system-performance` → 7 more | `install_<tool>` toggles |
| 10. Cloud | `cloud-native` | `install_cloud_native_tools` (default: false) |

## CONVENTIONS
*   **State Tracking**: `pre_tasks` init + `post_tasks` finalize `/var/lib/vps-setup/progress.json`.
*   **Resume**: `--resume` continues from last failed role via progress.json state.
*   **Conditionals**: Optional roles guarded by `when: install_feature | default(true)`.
*   **pre_tasks**: Validates required vars (`vps_username`, `vps_user_password_hash`) with `no_log: true`.
*   **post_tasks**: Generates summary log via `summary-log.j2` template.

## ANTI-PATTERNS
*   **Reordering**: Changing phase order risks dependency breaks (e.g., XRDP before desktop packages).
*   **Direct Execution**: Do not run without `setup.sh` (missing secrets/mitogen).
*   **Skipping pre_tasks**: Progress tracking and variable validation live there.
