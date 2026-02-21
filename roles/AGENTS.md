# COMPONENT: ANSIBLE ROLES

**Scope**: 27 independent roles for Debian 13 workstation automation.

## STRUCTURE

```
roles/<name>/
├── tasks/main.yml      # Entry point
├── tasks/uninstall.yml # Rollback capability
├── defaults/main.yml   # Role-level variables
├── handlers/main.yml   # Role-local handlers only
├── templates/          # Jinja2 configs
├── meta/main.yml       # Dependencies (if any)
└── AGENTS.md           # Per-role context
```

## EXECUTION ORDER

1. **Phase 1**: common (foundation)
2. **Phase 2**: security (MUST run before services)
3. **Phase 3-4**: fonts → desktop
4. **Phase 5**: xrdp (exposes port 3389)
5. **Phase 6-8**: kde-optimization → kde-apps → whitesur-theme
6. **Phase 9-11**: terminal → shell-styling → zsh-enhancements
7. **Phase 12-14**: development → docker → editors
8. **Phase 15-27: tool roles (tui-tools → monitoring). See root AGENTS.md for full order.

## CONVENTIONS

- **Variable Prefix**: `vps_<role>_<feature>` (e.g., `vps_docker_install`).
- **Tagging**: Schema `[phase, role, feature]` for granular execution.
- **Check Mode**: Support `--check --diff`. Use `ignore_errors: "{{ ansible_check_mode }}"`.
- **FQCN**: Mandatory `ansible.builtin.*`, `community.general.*`.
- **Logic Guards**: `when: vps_<role>_install_feature | default(true)`.

## ANTI-PATTERNS

- **Global Handlers**: Forbidden. Use role-local handlers only.
- **Hardcoded Users**: ALWAYS use `{{ vps_username }}`.
- **Security Reordering**: NEVER move `security` after service roles.
- **Block/Rescue**: Critical roles include error handling for recovery.

[Root Guidelines](../AGENTS.md)
