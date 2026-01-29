# Project Plan: Ansible Idempotency Best Practices

## 1. Goal
Refactor existing Ansible playbooks (`phase*.yml`) to ensure **idempotency**. This means running the playbooks multiple times should not produce different results or side effects (like restarting services unnecessarily, re-appending lines to files, or re-downloading existing artifacts).

## 2. Best Practices Standard

Based on research from `ansible` documentation:

### A. Module Preference
*   **Rule**: Always prefer specialized modules (`apt`, `user`, `git`, `service`) over `shell` or `command`.
*   **Why**: Native modules handle state checking automatically.

### B. Handling Shell/Command
*   **Rule**: When `shell` or `command` is unavoidable (e.g., custom scripts, `curl | gpg`), MUST use:
    *   `args.creates`: To prevent running if artifact exists.
    *   `args.removes`: To only run if something exists.
    *   `changed_when`: To explicitly define what constitutes a "change" (or `false` if it's just a read operation).

### C. File Management
*   **Rule**: Use `template` or `copy` for configuration files instead of multiple `lineinfile` tasks.
*   **Why**: `lineinfile` is fragile and can lead to duplicate lines if regex is poor. `template` ensures the file exactly matches the desired state.

### D. Service Restarts
*   **Rule**: Use **Handlers**. NEVER restart services directly in the task loop unless absolutely necessary for the immediate next step.
*   **Why**: Prevents multiple restarts if multiple config files change.

### E. Task idempotency
*   **Rule**: All download tasks (`get_url`) must have `checksum` validation if possible, or at least check for destination presence.

## 3. Analysis of Current State & Action Plan

### Playbook: `phase3-dependencies.yml`
*   [ ] **Audit**: `get_url` tasks for GPG keys.
    *   *Improvement*: Ensure `timeout` and `retries` are consistent (already improved in previous step, but check for others).
*   [ ] **Audit**: `shell` tasks for `dearmor`.
    *   *Improvement*: Ensure `creates` argument is accurate.

### Playbook: `phase4-rdp-packages.yml`
*   [ ] **Audit**: `shell` tasks for `code --install-extension`.
    *   *Issue*: Currently ignores errors (`ignore_errors: yes`) and force installs.
    *   *Fix*: Check if extension list can be fetched first, or accept that `code` handles its own idempotency (but `ansible` will always report "changed"). Ideally, use `changed_when`.
*   [ ] **Audit**: `curl | sh` for Oh My Zsh.
    *   *Issue*: Complex shell script.
    *   *Fix*: Ensure `creates: ~/.oh-my-zsh` is strictly respected.

### Playbook: `phase6-optimization.yml`
*   [ ] **Audit**: `kwriteconfig5` commands.
    *   *Issue*: `command` module always reports "changed".
    *   *Fix*: Since these are simple one-liners, it's hard to check state easily without complex logic.
    *   *Strategy*: Might wrap in a `block` with a check, or leave as-is but mark `changed_when: false` if we don't care about the status, OR (better) find a module or config file edits (`lineinfile` on `kwinrc`) if possible.

## 4. Execution Roadmap

1.  **Review Phase**: Scan all playbooks for `command` and `shell` modules.
2.  **Handlers Phase**: Extract `systemd` restarts into a standard `handlers/main.yml`.
3.  **Refactor Phase**:
    *   Convert `curl | gpg` to `get_url` + `dearmor` (Standardize across all).
    *   Add `changed_when` to all informational commands.
    *   Add `creates` to all installation commands.
4.  **Validation**: Run playbooks twice. Second run should have `changed=0` (ideal) or minimal changes.

## 5. Verification
*   Run `ansible-playbook site.yml`.
*   Run it again immediately.
*   Compare output. The goal is "Green" (OK), not "Yellow" (Changed).
