# COMPONENT: ANSIBLE ROLES

**Role Architecture**: Flat hierarchy in `roles/`. Modular configuration units.

## STRUCTURE
```
roles/
├── common/           # Base system (apt, user, git)
├── security/         # UFW, fail2ban, SSH hardening
├── desktop/          # KDE Plasma, XRDP
├── development/      # Node, Python, PHP stack
├── docker/           # Engine + Compose
└── [feature]/        # (18+ other roles)
```

## WHERE TO LOOK
| Task | Location |
|------|----------|
| **Dependencies** | `meta/main.yml` (Explicit chain) |
| **Variables** | `defaults/main.yml` (Low precedence) |
| **Logic** | `tasks/main.yml` |
| **Handlers** | `handlers/main.yml` (Local scope) |

## CONVENTIONS
*   **Namespacing**: Variables MUST start with `vps_<role>_` (e.g., `vps_ssh_port`).
*   **Toggles**: Use `install_<feature>` booleans in `defaults/main.yml`.
*   **Tags**: Mandatory `[phase, role, feature]` structure.
*   **Apt**: `state: present`. Only `common` runs `update_cache: yes`.

## ANTI-PATTERNS
*   **Global Handlers**: Do not rely on them. Define handlers locally.
*   **Check Mode Failures**: Tasks breaking dry-run must handle `ansible_check_mode`.
*   **Hardcoded Users**: Always use `{{ vps_username }}`.
