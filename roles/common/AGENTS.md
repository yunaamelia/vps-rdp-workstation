# ROLE: COMMON (FOUNDATION)

**Criticality**: High. Phase 1. Dependency for all other roles.

## RESPONSIBILITIES
1.  **User**: Create `vps_username` with sudo, groups (WARNING: Handles password hash).
2.  **State**: Create `/var/lib/vps-setup/` progress directory.
3.  **Base Packages**: Install curl, git, build-essential, software-properties-common.
4.  **Apt Cache**: This is the ONLY role that runs `update_cache: yes` (others inherit).

## CONVENTIONS
*   **Secret Handling**: User creation task MUST use `no_log: true` for password hash.
*   **Variables**: `vps_username` defined here, used globally across all 27 roles.
*   **Apt Cache**: Exclusive `update_cache: yes`. Other roles assume cache is fresh.
*   **Cannot Skip**: This role establishes the execution user and state directory.

## ANTI-PATTERNS
*   **Renaming Variables**: Changing `vps_username` breaks all downstream roles.
*   **Skipping**: This role cannot be skipped; it establishes the execution user.
*   **Duplicate Cache Update**: Do not add `update_cache: yes` in other roles.
