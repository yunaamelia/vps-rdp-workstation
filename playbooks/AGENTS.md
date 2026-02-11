# Component: Playbooks & Orchestration

## Orchestration Logic
- **File**: `main.yml` is the master definition.
- **Phasing**: 10 strict phases.
  1. `common` (Base)
  2. `security` (Lockdown)
  3. `visual` (Fonts/Term)
  4. `desktop` (GUI)
  5. `dev` (Langs)
  6. `docker`
  7. `tools`
- **State Management**: `pre_tasks` read state; `post_tasks` write to `/var/lib/vps-setup/progress.json`.

## Modification Rules
- **Order**: DO NOT reorder phases without verifying dependency chain (especially Security vs Services).
- **Tags**: Ensure every role inclusion has appropriate tags.
- **Conditionals**: Use `when: install_feature | default(true)` for optional roles.

## Rollback
- `rollback.yml` exists but is destructive. Use with caution.
