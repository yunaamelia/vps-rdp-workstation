---
trigger: glob
globs: ["inventory/**"]
---

# Ansible Inventories and Variables Rules

> Source: [Red Hat Automation Good Practices §6](https://redhat-cop.github.io/automation-good-practices/#_inventories_and_variables_good_practices_for_ansible)
> Variable naming convention and casting: @ansible-coding-style.md

## Violation Response Protocol

When reviewing or modifying inventory files:
1. **MUST** flag any plaintext secret found in `group_vars/`, `host_vars/`, or inventory files.
2. **MUST** flag variables that don't follow the `vps_<role>_` prefix convention.
3. **MUST** warn if `host_vars/`, `group_vars/`, and `--extra-vars` are all used for the same variable.
4. **SHOULD** suggest `| default(value)` when optional variables lack a fallback.
5. **MUST NOT** generate inventory entries that contain passwords or API tokens.

## Severity Levels (RFC 2119)

- **MUST / MUST NOT**: Enforced — block or flag every occurrence.
- **SHOULD / SHOULD NOT**: Strongly encouraged — flag and suggest fix.
- **MAY**: Optional — mention only if directly relevant.

## Inventory Structure

- **MUST** define inventory as a **structured directory**, not a single flat file.  `[INV-STRUCT-01]`
  ```
  inventory/
  ├── hosts.yml          # Localhost definitions
  ├── staging.yml        # Staging-specific hosts
  ├── remote_hosts.yml   # Remote VPS template
  └── group_vars/
      └── all.yml        # 220+ global variables (all prefixed vps_)
  ```
- **MUST NOT** create flat lists of hosts to loop over — rely on inventory groups:  `[INV-STRUCT-02]`
  ```yaml
  # CORRECT
  loop: "{{ groups['webservers'] }}"
  ```

## Variable Conventions

- **MUST** restrict variable types — do not mix `host_vars`, `group_vars`, and `--extra-vars` for the same datum.  `[INV-VAR-01]`
- **SHOULD** prefer **inventory variables** over `--extra-vars` to describe desired state.  `[INV-VAR-02]`
- **MUST** prefix all project variables with `vps_<role>_` (e.g., `vps_docker_log_max_size`).  `[INV-VAR-03]`
- **MUST** use `vps_<variable>` for system-wide shared vars (e.g., `vps_username`, `vps_timezone`).  `[INV-VAR-04]`
- **MUST** add `| default(value)` to optional variables to prevent undefined variable errors.  `[INV-VAR-05]`
- **MUST** cast variables where type matters: `| bool`, `| int`, `| float`.  `[INV-VAR-06]`
- **MUST** use bracket notation, not dot notation: `item['key']` not `item.key`.  `[INV-VAR-07]`

## Single Source of Truth

- **MUST** identify and document the Single Source of Truth for each class of data.  `[INV-SSOT-01]`
- **SHOULD** differentiate variable names between **As-Is** (current state) and **To-Be** (desired state).  `[INV-SSOT-02]`

## Secrets Management

- **MUST NOT** store passwords, tokens, or API keys in inventory files or `group_vars/`.  `[INV-SEC-01]`
- **MUST** load secrets from environment variables (`VPS_*`) or a secrets file with permissions `0600`.  `[INV-SEC-02]`
- **MUST** add `no_log: true` to all tasks that handle sensitive variables.  `[INV-SEC-03]`
- **MUST** shadow/overwrite plain-text password variables immediately after hashing.  `[INV-SEC-04]`
- **SHOULD** consider Ansible Vault for secrets that must be stored in version control.  `[INV-SEC-05]`
  ```bash
  # Encrypt a variable file
  ansible-vault encrypt inventory/group_vars/vault.yml
  # Reference in group_vars/all.yml
  vps_user_password_hash: "{{ vault_vps_user_password_hash }}"
  ```

## Fact Caching

- **SHOULD** use `gather_facts: smart` with a cache backend.  `[INV-FACT-01]`
- **SHOULD** configure cache TTL based on how often host facts change (recommended: 24h).  `[INV-FACT-02]`
