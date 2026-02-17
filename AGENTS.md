# PROJECT KNOWLEDGE BASE

**Scope**: Ansible IaC — Debian 13 VPS → security-hardened RDP developer workstation.

## STRUCTURE
*   `setup.sh`: CANONICAL ENTRY POINT. Handles secrets, Mitogen, validation.
*   `ansible.cfg`: Pipelining, Mitogen, ARA.
*   `inventory/group_vars/all.yml`: Global variable root.
*   `playbooks/main.yml`: 10-phase orchestration. [Details](playbooks/AGENTS.md)
*   `roles/`: 25 independent roles. [Details](roles/AGENTS.md)
*   `tests/validate.sh`: 30+ criteria guest validation. [Details](tests/AGENTS.md)

## EXECUTION ORDER
1. common → 2. security → 3. fonts → 4. desktop → 5. xrdp → 6. kde-optimization → 7. kde-apps →
8. whitesur-theme → 9. terminal → 10. shell-styling → 11. zsh-enhancements → 12. development →
13. docker → 14. editors → 15-25. specialized tool roles.

## CONVENTIONS
*   **Wrapper**: ALWAYS use `setup.sh`. Skips direct `ansible-playbook`.
*   **Vars**: Prefix `vps_<role>_`. `vps_username` for system-wide.
*   **FQCN**: Mandatory `ansible.builtin.*`.
*   **Idempotency**: Safe for repeat runs.
*   **Security**: MUST run before service exposure.

## ANTI-PATTERNS
*   **Plaintext**: NEVER store passwords in vars/logs.
*   **Root Login**: Disabled by default.
*   **Hardcoded Users**: Use `{{ vps_username }}` only.

## UNIQUE PATTERNS
*   **Mitogen**: Strategy injection for 2-7x speedup.
*   **ARA**: Auto-recording runs to SQLite.
*   **Progress**: `/var/lib/vps-setup/progress.json` for `--resume`.
