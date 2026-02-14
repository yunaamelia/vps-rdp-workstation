# Refactor WhiteSur Theme & Remove Catppuccin

## Goal
Consolidate WhiteSur theme, icons, and cursors into a single role (`whitesur-theme`) and remove all Catppuccin theme dependencies/artifacts.

## Tasks
- [ ] **Verify WhiteSur Role Consolidation**
    - Check `roles/whitesur-theme/defaults/main.yml` includes icon/cursor variables.
    - Check `roles/whitesur-theme/tasks/main.yml` includes icon/cursor installation tasks.
    - Verify `roles/whitesur-icons` and `roles/whitesur-cursors` directories are removed.

- [ ] **Update Global Configuration**
    - [ ] Update `inventory/group_vars/all.yml`:
        - Set `vps_theme_variant: "whitesur"`.
        - Remove `vps_catppuccin_*` variables.
        - Ensure `vps_cursor_theme` is "WhiteSur-cursors".

- [ ] **Update Terminal Role**
    - [ ] Update `roles/terminal/tasks/main.yml`:
        - Remove task copying catppuccin files.
        - Ensure Konsole uses Nordic profile.
    - [ ] Update `roles/terminal/templates/kitty.conf.j2`:
        - Set theme to Nordic (hardcoded or variable).

- [ ] **Update Playbook Orchestration**
    - [ ] Update `playbooks/main.yml`:
        - Remove `catppuccin-theme`.
        - Ensure `whitesur-theme` is present in Desktop phase.

- [ ] **Cleanup Artifacts**
    - [ ] Remove `roles/catppuccin-theme` directory.
    - [ ] Remove `roles/whitesur-icons` directory (if distinct).
    - [ ] Remove `roles/whitesur-cursors` directory (if distinct).
    - [ ] Grep for "catppuccin" in `docs/`, `tests/`, and `molecule/` and update/remove references.
    - [ ] Update `AGENTS.md` in root and subdirectories to reflect role changes.

## Done When
- [ ] `ansible-playbook playbooks/main.yml --check` runs without errors.
- [ ] No "catppuccin" references remain in active configuration files.
- [ ] `whitesur-theme` role handles theme, icons, and cursors in a single pass.
