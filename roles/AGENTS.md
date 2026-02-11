# Component: Ansible Roles

## Role Architecture
- **Structure**: Flat hierarchy in `roles/`. Each role MUST have `tasks/main.yml`, `defaults/main.yml`, `meta/main.yml`.
- **Naming**: Kebab-case (e.g., `zsh-enhancements`).
- **Dependencies**: Explicitly defined in `meta/main.yml`. `common` is the base for almost everything.

## Variable Conventions
- **Namespacing**: ALL variables must start with `vps_<role>_` (e.g., `vps_ssh_port`, `vps_kde_theme`) to prevent global collisions.
- **Defaults**: Defined in `defaults/main.yml`. Overrides go in `inventory/group_vars/all.yml`.
- **Booleans**: Use `install_<feature>` for role toggles (e.g., `install_docker`).

## Execution Logic
- **Tags**: Mandatory. Structure: `[phase, role, feature]`.
  - Ex: `tags: [security, ssh, config]`
- **Handlers**: Local to role. Do not rely on global handlers. Use `notify: Restart ServiceName`.
- **Check Mode**: Support `--check` everywhere. If a task breaks dry-run (e.g., shell command defining a variable), explicitly handle it or provide dummy defaults.

## Common Patterns
- **Apt**: Always update cache in `common`, then just `state: present` in roles.
- **Shell**: Prefer `ansible.builtin.shell` over `command` only when pipes/redirects are needed. Always use `changed_when`.
- **Templates**: Jinja2 files in `templates/` with `.j2` extension.
