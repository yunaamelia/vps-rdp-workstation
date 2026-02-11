# ROLE: COMMON (FOUNDATION)

**Criticality**: High. Dependency for 20+ roles.

## RESPONSIBILITIES
1.  **User**: Create `vps_username` (WARNING: Handles password hash).
2.  **State**: Create `/var/lib/vps-setup/`.
3.  **Base**: Install curl, git, build-essential.

## CONVENTIONS
*   **Secret Handling**: User creation task MUST use `no_log: true` for password hash.
*   **Variables**: `vps_username` defined here, used globally.
*   **Apt**: Only this role runs `update_cache: yes`.

## ANTI-PATTERNS
*   **Renaming Variables**: Changing `vps_username` breaks everything.
*   **Skipping**: This role cannot be skipped; it establishes the execution user.
