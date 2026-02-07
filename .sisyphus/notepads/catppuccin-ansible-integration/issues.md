# Issues

## Catppuccin Theme Installation in Check Mode

### Problem
The "Install Catppuccin KDE theme" task in `roles/desktop/tasks/main.yml` failed during `ansible-playbook --check` (dry-run) with a fatal error: `sudo: unknown user testuser`.

### Cause
The task uses `become_user: "{{ vps_username }}"`. In a fresh dry-run, the user does not exist yet (as the `common` role creation task is also in check mode), causing sudo to fail when attempting to switch context.

### Solution
Added `and not ansible_check_mode` to the task's `when` condition. This ensures the task is skipped during dry-runs, preventing the error. The installation script `install.sh` modifies the system and should not be run in check mode regardless.

### Status
Fixed in `roles/desktop/tasks/main.yml`. Verified with `ansible-playbook --check`.
