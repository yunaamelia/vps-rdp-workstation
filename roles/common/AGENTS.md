# Component: Common Role

## Critical Mission
The foundation layer. Establishes the environment, creates users, and manages state. Dependency for 20+ other roles.

## Key Responsibilities
- **User Creation**: Creates `vps_username`.
  - **WARNING**: Handles `vps_user_password_hash`. MUST use `no_log: true` to prevent leaking the hash.
- **State Tracking**: Creates `/var/lib/vps-setup/` directory.
- **Package Base**: Installs `curl`, `git`, `build-essential`, `python3-pip`.

## Shared Variables
- `vps_username`: Used globally. Defined here.
- `vps_user_group`: Primary group for the user.

## Modification Risks
- Changing variable names here breaks the entire playbook.
- Ensure `update_cache: yes` is maintained in the initial apt task.
