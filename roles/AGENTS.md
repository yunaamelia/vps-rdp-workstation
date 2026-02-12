# COMPONENT: ANSIBLE ROLES

**Purpose**: 25 flat roles implementing the 10-phase execution pipeline.

## STRUCTURE
*   **Layout**: Flat — `roles/<name>/` with `tasks/`, `defaults/`, `handlers/`, `templates/`, `meta/`.
*   **Entry**: `tasks/main.yml` is the sole entry point per role.
*   **Variables**: `defaults/main.yml` for tunable defaults. Overridden via `group_vars/all.yml`.

## ROLE CATEGORIES
| Phase | Roles | Notes |
|-------|-------|-------|
| Foundation | common | Creates user, state dir, base packages |
| Security | security | UFW, fail2ban, SSH hardening |
| Visual | fonts, terminal, shell-styling, zsh-enhancements, catppuccin-theme | Shell + font stack |
| Desktop | desktop, kde-optimization, kde-apps | KDE Plasma + XRDP |
| Dev | development, docker, editors | Languages, containers, IDEs |
| Tools | ai-devtools, cloud-native, code-quality, dev-debugging, file-management, log-visualization, network-tools, productivity, system-performance, text-processing, tui-tools, xrdp | Package-install roles |

## CONVENTIONS
*   **Namespacing**: Variables MUST use `vps_<role>_` prefix (legacy exception: `docker_` in docker role).
*   **Tags**: Mandatory `[phase, role, feature]` schema.
*   **Idempotency**: All tasks MUST be safe to re-run. Second run = zero changes.
*   **Check Mode**: Full support for `--check` REQUIRED. Use `ignore_errors: "{{ ansible_check_mode }}"` for service tasks.
*   **External Downloads**: Use `creates` parameter to avoid re-fetching. Prefer `ansible.builtin.get_url` over shell curl.
*   **User Paths**: Install to `/home/{{ vps_username }}/`, never system-wide unless required.

## ANTI-PATTERNS
*   **Global Handlers**: NEVER rely on them; keep handlers within roles.
*   **Hardcoded Users**: NEVER use root/fixed names; use `{{ vps_username }}`.
*   **Sequence Violation**: NEVER move `security` role after services.
*   **Short Module Names**: NEVER use `apt`, always `ansible.builtin.apt` (FQCN).
*   **Missing `when`**: Optional roles MUST be guarded by `when: install_feature | default(true)`.
