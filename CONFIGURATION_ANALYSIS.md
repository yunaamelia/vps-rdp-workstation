# Configuration Analysis: VPS RDP Workstation Project

**Version:** 3.0.0
**Target Platform:** Debian 13 (Trixie)
**Last Updated:** 2025-01-20

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Ansible Configuration Analysis](#ansible-configuration-analysis)
3. [YAML Linting Configuration Analysis](#yaml-linting-configuration-analysis)
4. [Developer Conventions Summary](#developer-conventions-summary)
5. [Configuration Philosophy](#configuration-philosophy)
6. [Common Pitfalls and Best Practices](#common-pitfalls-and-best-practices)

---

## Executive Summary

This VPS RDP Workstation project uses two primary configuration files to enforce consistent, secure, and performant Ansible automation:

- **`ansible.cfg`**: Controls Ansible execution behavior with security-first settings and performance optimizations
- **`.yamllint`**: Enforces YAML code quality and formatting standards compatible with ansible-lint

**Key Philosophy:**
- **Security First**: Host key checking disabled for automated VPS provisioning, but privilege escalation strictly controlled
- **Performance Optimized**: SSH pipelining, fact caching, and 10 parallel forks for 2-7x speedup (enhanced by Mitogen plugin)
- **Developer Friendly**: Clear warnings, verbose output, and relaxed line length (180 chars) for readability

---

## Ansible Configuration Analysis

### 1.1 Core Paths and Execution

#### **Inventory Location**
```ini
inventory = inventory/hosts.yml
```

**WHY:** Single source of truth for target hosts. This project uses a structured YAML inventory file instead of INI format for better readability and support for complex host variables. All VPS targets are defined here with their SSH connection details.

**Impact on Developers:** Always modify `inventory/hosts.yml` when adding new VPS targets. Never create ad-hoc inventory files.

---

#### **Roles Path**
```ini
roles_path = roles
```

**WHY:** Standard Ansible convention. Roles are the building blocks of this automation, organized by function (common, security, kde-plasma, desktop, services, monitoring, observability, backup, cleanup, verification).

**Impact on Developers:** All custom roles must be placed in the `roles/` directory. External roles from Ansible Galaxy are stored in `collections/`.

---

#### **Collections Path**
```ini
collections_path = collections
```

**WHY:** Separates external dependencies from custom code. Collections provide reusable, community-maintained modules and plugins.

**Impact on Developers:** Use `ansible-galaxy collection install` to add dependencies. Always use FQCN (Fully Qualified Collection Names) like `ansible.builtin.apt` instead of bare module names.

---

#### **Temporary Directories**
```ini
remote_tmp = /tmp/.ansible-${USER}/tmp
local_tmp = ~/.ansible/tmp
```

**WHY Remote /tmp:** Avoids permission issues when Ansible switches between users (root → vps_user). The `/tmp` directory is world-writable but isolated per user via `${USER}` variable substitution.

**WHY Local ~/.ansible:** Keeps local temporary files in user space, preventing conflicts in multi-user development environments.

**Impact on Developers:** If you see "permission denied" errors on remote hosts, check that `/tmp` is writable. Never hardcode temp paths in playbooks.

---

### 1.2 Output and Logging

#### **Stdout Callback**
```ini
stdout_callback = ansible.builtin.default
callback_result_format = yaml
```

**WHY:** Originally set to `community.general.yaml`, but this callback was removed in Ansible 12. The project migrated to `ansible.builtin.default` with `callback_result_format = yaml` to maintain YAML-formatted output while ensuring compatibility with modern Ansible versions.

**Impact on Developers:** Task results are displayed in YAML format, making it easy to copy-paste variable structures. Expect clean, structured output instead of one-line summaries.

---

#### **Display Settings**
```ini
display_skipped_hosts = True
deprecation_warnings = True
command_warnings = True
system_warnings = True
bin_ansible_callbacks = True
```

**WHY Show Everything:** This is a security-critical automation that transforms production VPS infrastructure. Skipped tasks, deprecated features, and risky commands must be visible to prevent silent failures or security gaps.

**Impact on Developers:**
- **Skipped hosts**: Helps debug conditional logic in playbooks
- **Deprecation warnings**: Alerts you to update playbooks before Ansible version upgrades break them
- **Command warnings**: Warns when using `shell`/`command` modules instead of idiomatic Ansible modules
- **System warnings**: Critical system-level issues (e.g., Python interpreter problems)
- **Binary callbacks**: Enables performance plugins like Mitogen

---

### 1.3 Performance Optimizations

#### **Parallel Execution**
```ini
forks = 10
```

**WHY 10 Forks:** Balances parallelism with resource constraints. With 10 forks, Ansible can configure 10 VPS instances simultaneously. Lower values (e.g., 5) would be safer for memory-constrained control nodes; higher values (e.g., 50) risk overwhelming SSH connection limits.

**Impact on Developers:** When running playbooks against large inventories, tasks execute on 10 hosts at a time. Serial execution can be forced per-playbook with `serial: 1` if needed.

---

#### **SSH Pipelining**
```ini
pipelining = True
```

**WHY:** Reduces the number of SSH operations by sending module code and parameters in a single connection instead of separate file transfers. Provides 2-3x speedup for tasks that don't require `become`.

**Requirements:**
- `requiretty` must be disabled in `/etc/sudoers` on target hosts (handled by `security` role)
- SSH users must have valid shells (not `/bin/false`)

**Impact on Developers:** Tasks run faster, but debugging is harder (no intermediate files left on remote hosts). Disable pipelining if you need to inspect module code on the target.

---

#### **Fact Gathering and Caching**
```ini
gathering = smart
fact_caching = jsonfile
fact_caching_connection = /tmp/ansible_facts_cache
fact_caching_timeout = 86400
```

**WHY Smart Gathering:** Only gathers facts if they're not already cached. Avoids the 2-5 second setup overhead on every playbook run.

**WHY JSON File Caching:** Simple, fast, no external dependencies (unlike Redis/Memcached). Cache persists for 24 hours (86400 seconds), covering typical development/deployment cycles.

**WHY /tmp Location:** Facts are transient data. Using `/tmp` means they're automatically cleaned up on system reboot, preventing stale cache issues.

**Impact on Developers:**
- First run against a host: ~5 seconds for fact gathering
- Subsequent runs (within 24h): Facts retrieved from cache in milliseconds
- To force fresh facts: `ansible-playbook playbook.yml --flush-cache`
- To disable fact gathering: Use `gather_facts: false` in playbooks

---

### 1.4 Security and Connection

#### **Host Key Checking**
```ini
host_key_checking = False
```

**WHY DISABLED:** This project automates provisioning of fresh VPS instances with dynamic IPs. Strict SSH host key checking would require manual intervention to accept keys for every new VPS.

**SECURITY TRADE-OFF:** Disabling host key checking opens risk of MITM attacks. This is acceptable because:
1. VPS provisioning happens in trusted networks (VPS provider infrastructure)
2. Immediate security hardening happens in Phase 2 (security role)
3. Alternative would be pre-populating `known_hosts`, which is impractical for dynamic VPS fleets

**Impact on Developers:** You won't be prompted to accept SSH keys. If you need strict checking for production environments, override with `ansible-playbook -e 'ansible_host_key_checking=True'`.

---

#### **Connection Timeout**
```ini
timeout = 30
```

**WHY 30 Seconds:** Balances patience with failure detection. VPS instances with poor network connectivity get 30 seconds to respond before Ansible considers them unreachable.

**Impact on Developers:** Increase this value (`-e 'timeout=60'`) when provisioning VPS instances in regions with high latency. Decrease for local testing.

---

#### **Remote User**
```ini
remote_user = root
```

**WHY Root:** Fresh VPS instances typically provide root SSH access only. This setting establishes the initial connection. Later tasks use `become` to switch to the unprivileged `vps_user` account for desktop environment setup.

**Impact on Developers:** Ensure your VPS provider grants root SSH access. If your VPS uses a different initial user (e.g., `ubuntu`), override with `-u ubuntu`.

---

#### **Retry Files**
```ini
retry_files_enabled = False
```

**WHY Disabled:** Retry files (`.retry`) clutter the project directory and create confusion in version control. Modern Ansible provides better failure handling through `--limit @/path/to/retry/file` and the `--start-at-task` flag.

**Impact on Developers:** Failed hosts won't generate `.retry` files. To retry only failed hosts, use `--limit @/tmp/failed_hosts` manually.

---

### 1.5 Privilege Escalation

```ini
[privilege_escalation]
become = True
become_method = sudo
become_user = root
become_ask_pass = False
```

**WHY Always Become:** Most tasks require elevated privileges (installing packages, configuring services, modifying system files). Enabling `become` by default reduces boilerplate in playbooks.

**WHY Sudo:** Standard privilege escalation method on Debian/Ubuntu. Alternatives (`su`, `doas`) are less common and less tested with Ansible.

**WHY No Password:** SSH key-based authentication is assumed. The `vps_user` is configured with passwordless sudo for Ansible tasks (restricted by `sudoers.d/` rules).

**Impact on Developers:**
- Tasks run as root unless you explicitly set `become: false`
- Use `become_user: vps_user` for tasks that should run as the unprivileged user
- Never hardcode passwords; use Ansible Vault for sensitive variables

---

### 1.6 SSH Connection Tuning

```ini
[ssh_connection]
ssh_args = -o ControlMaster=auto -o ControlPersist=300s -o ServerAliveInterval=60
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
pipelining = True
```

#### **ControlMaster and ControlPersist**

**WHY ControlMaster=auto:** Reuses a single SSH connection for multiple tasks instead of creating a new TCP connection for every module execution. Provides 3-5x speedup for playbooks with many tasks.

**WHY ControlPersist=300s:** Keeps the master connection alive for 5 minutes after the playbook finishes. This allows rapid re-runs during development without re-establishing SSH connections.

**Impact on Developers:**
- First task to a host: ~500ms SSH handshake
- Subsequent tasks (within 5min): <10ms connection reuse
- Stale connections: If you see "SSH connection closed unexpectedly," increase `ControlPersist` or manually kill control sockets in `/tmp/ansible-ssh-*`

---

#### **ServerAliveInterval**

**WHY 60 Seconds:** Prevents SSH connections from timing out due to idle TCP sessions. Sends a keepalive packet every 60 seconds to maintain the connection during long-running tasks (e.g., large package downloads, system updates).

**Impact on Developers:** Long-running tasks (>5 minutes) won't disconnect. If you're behind a strict firewall that kills idle connections faster, decrease this value to 30 seconds.

---

#### **Control Path**

```ini
control_path = /tmp/ansible-ssh-%%h-%%p-%%r
```

**WHY /tmp:** World-writable, automatically cleaned on reboot. The `%%h-%%p-%%r` placeholders (hostname, port, remote user) ensure unique sockets for different connections.

**Impact on Developers:** If you see "ControlPath too long" errors, shorten your hostnames or set `ANSIBLE_SSH_CONTROL_PATH_DIR` to a shorter directory like `/tmp/a`.

---

## YAML Linting Configuration Analysis

### 2.1 Base Configuration

```yaml
extends: default
```

**WHY Extend Default:** yamllint's default ruleset covers 95% of YAML best practices. This project customizes only the rules that conflict with Ansible's idiomatic style (line length, truthy values).

**Impact on Developers:** You inherit all standard YAML rules (indentation, trailing spaces, key ordering) unless explicitly overridden below.

---

### 2.2 Line Length

```yaml
rules:
  line-length:
    max: 180
    level: warning
```

**WHY 180 Characters:** Standard 80-character limits are impractical for Ansible playbooks with long module names (`community.general.ufw`), descriptive task names, and conditional logic (`when: ansible_distribution == "Debian" and ansible_distribution_major_version == "13"`).

**WHY Warning (not Error):** Allows flexibility for genuinely long lines while still alerting developers to potential readability issues. CI/CD pipelines don't fail on line length, but pre-commit hooks highlight violations.

**Impact on Developers:**
- **Soft limit**: Aim for <120 characters when possible
- **Hard limit**: Never exceed 180 characters
- **Violations show as warnings** in editors with yamllint integration (VS Code, vim)

**Examples of Acceptable 180-Char Lines:**
```yaml
- name: Configure UFW to allow RDP from trusted IPs only and deny all other incoming traffic
  community.general.ufw:
    rule: allow
    port: 3389
    proto: tcp
    src: "{{ item }}"
  loop: "{{ vps_security_trusted_ips }}"
```

---

### 2.3 Truthy Values

```yaml
truthy:
  level: warning
```

**WHY Warning:** YAML allows `yes/no`, `true/false`, `on/off`, and `1/0` as boolean values. Ansible prefers `true/false` for clarity, but legacy playbooks may use `yes/no`.

**Impact on Developers:**
- **Preferred**: `become: true`, `no_log: true`
- **Accepted (with warning)**: `become: yes`, `no_log: no`
- **Avoid**: `become: 1`, `no_log: off` (confusing and error-prone)

**Example:**
```yaml
# ✅ Preferred
- name: Ensure SSH service is enabled
  ansible.builtin.service:
    name: ssh
    enabled: true

# ⚠️ Warning (but valid)
- name: Ensure SSH service is enabled
  ansible.builtin.service:
    name: ssh
    enabled: yes
```

---

### 2.4 Comment Rules

```yaml
comments:
  min-spaces-from-content: 1
comments-indentation: false
```

**WHY 1 Space Minimum:** Prevents comments from blending into code. Requires at least one space between code and inline comments:

```yaml
# ✅ Valid
name: Install packages  # Security hardening

# ❌ Invalid
name: Install packages# No space before comment
```

**WHY Disable Indentation Checking:** Ansible playbooks use complex nested structures (tasks, blocks, handlers). Enforcing strict comment indentation would be overly rigid and reduce readability.

**Impact on Developers:** Comments can be indented flexibly, but must have at least 1 space before inline comments.

---

### 2.5 Bracing

```yaml
braces:
  max-spaces-inside: 1
```

**WHY Allow 1 Space:** Improves readability in Jinja2 templates and inline YAML dictionaries:

```yaml
# ✅ Valid
msg: "{{ vps_user_name }}"          # 0 spaces (compact)
msg: "{{ vps_user_name }}"          # 1 space (readable)

# ❌ Invalid
msg: "{{  vps_user_name  }}"        # 2+ spaces (excessive)
```

**Impact on Developers:** Use 0 or 1 space inside braces. Consistent spacing improves git diffs.

---

### 2.6 Octal Values

```yaml
octal-values:
  forbid-implicit-octal: true
  forbid-explicit-octal: true
```

**WHY Forbid All Octals:** YAML 1.1 interprets `0755` as octal (493 in decimal), but YAML 1.2 treats it as a decimal integer. This ambiguity causes bugs in file permissions.

**Solution:** Always quote octal file modes:

```yaml
# ✅ Correct
- name: Set SSH private key permissions
  ansible.builtin.file:
    path: /home/vps_user/.ssh/id_ed25519
    mode: '0600'  # Quoted string

# ❌ Invalid
- name: Set SSH private key permissions
  ansible.builtin.file:
    path: /home/vps_user/.ssh/id_ed25519
    mode: 0600  # Interpreted as decimal 600 = octal 1130
```

**Impact on Developers:** **ALWAYS QUOTE FILE MODES.** This is the most common source of permission bugs in Ansible.

---

### 2.7 Ignored Paths

```yaml
ignore: |
  collections/
  .github/workflows/vps-setup.yml
  venv/
  .git/
```

**WHY Ignore Collections:** External dependencies have their own linting rules. Enforcing project-specific rules on third-party code creates noise.

**WHY Ignore vps-setup.yml:** GitHub Actions workflow file uses GitHub-specific YAML extensions that conflict with yamllint rules.

**WHY Ignore venv/:** Python virtual environment for development tools (ansible-lint, molecule). Not part of the automation itself.

**WHY Ignore .git/:** Git internal files use YAML-like formats but aren't meant for human editing.

**Impact on Developers:** These paths are excluded from pre-commit hooks and CI/CD linting. Modify them without worrying about yamllint violations.

---

## Developer Conventions Summary

### 3.1 Critical Rules for Contributors

#### **YAML Formatting**
- **Indentation**: 2 spaces (never tabs)
- **Line Length**: Maximum 180 characters (warning level)
- **Syntax**: Expanded format only, no one-liners
  ```yaml
  # ✅ Correct
  - name: Install package
    ansible.builtin.apt:
      name: firefox-esr
      state: present

  # ❌ Wrong
  - name: Install package
    ansible.builtin.apt: name=firefox-esr state=present
  ```

---

#### **Module Naming**
Always use **Fully Qualified Collection Names (FQCN)**:

```yaml
# ✅ Correct
- name: Update apt cache
  ansible.builtin.apt:
    update_cache: true

# ❌ Wrong (deprecated bare module names)
- name: Update apt cache
  apt:
    update_cache: true
```

**WHY:** Future Ansible versions will remove support for bare module names. FQCN prevents namespace collisions and makes dependencies explicit.

---

#### **Task Naming**
Use **imperative present tense** (like git commit messages):

```yaml
# ✅ Correct
- name: Install KDE Plasma desktop environment
- name: Configure UFW firewall rules
- name: Enable RDP service on port 3389

# ❌ Wrong
- name: Installing KDE Plasma...
- name: UFW Configuration
- name: RDP service enabled
```

**WHY:** Describes what the task **does**, not what it's doing or what state it achieves. Improves log readability.

---

#### **Secrets Management**
**NEVER log passwords or sensitive data:**

```yaml
# ✅ Correct
- name: Set user password
  ansible.builtin.user:
    name: "{{ vps_user_name }}"
    password: "{{ vps_user_password_hash }}"
  no_log: true  # ← Critical for security

# ❌ Wrong (password appears in logs)
- name: Set user password
  ansible.builtin.user:
    name: "{{ vps_user_name }}"
    password: "{{ vps_user_password_hash }}"
```

**WHY:** Ansible logs are stored in CI/CD systems, local files, and terminal scrollback. Leaked credentials are a critical security risk.

**Impact on Developers:** Use `no_log: true` for any task handling `password`, `api_key`, `token`, or similar variables.

---

#### **Variable Naming Convention**
All role variables use the **`vps_<role>_` prefix**:

```yaml
# ✅ Correct
vps_common_packages: [...]
vps_security_fail2ban_enabled: true
vps_kde_plasma_theme: breeze-dark
vps_user_name: developer
vps_user_password_hash: "$6$rounds=..."

# ❌ Wrong (pollutes global namespace)
packages: [...]
fail2ban_enabled: true
theme: breeze-dark
```

**WHY:** Prevents variable collisions across roles. Makes it clear which role owns each variable when debugging.

---

### 3.2 Integration Points

#### **How ansible.cfg Affects Playbook Execution**

| Setting | Developer Impact |
|---------|------------------|
| `forks = 10` | Tasks run on 10 hosts in parallel |
| `pipelining = True` | 2-3x speedup, but harder to debug |
| `gathering = smart` | Facts cached for 24h; use `--flush-cache` to refresh |
| `host_key_checking = False` | No SSH key prompts; MITM risk accepted |
| `become = True` | Tasks default to root; override with `become: false` |
| `stdout_callback` | YAML-formatted output for easy copy-paste |

---

#### **How .yamllint Enforces Code Quality**

| Rule | Enforcement | Fix |
|------|-------------|-----|
| Line length > 180 | ⚠️ Warning | Break long lines, use YAML multiline strings |
| Truthy values (`yes/no`) | ⚠️ Warning | Replace with `true/false` |
| Octal without quotes | ❌ Error | Quote file modes: `mode: '0644'` |
| Comments without spaces | ❌ Error | Add space: `# comment` not `#comment` |

---

#### **Pre-Commit Hook Integration**

The project likely uses pre-commit hooks to run yamllint before commits:

```yaml
# .pre-commit-config.yaml (hypothetical)
repos:
  - repo: https://github.com/adrienverge/yamllint
    rev: v1.35.1
    hooks:
      - id: yamllint
        args: [--strict]  # Fail on warnings
```

**Impact on Developers:** Commits are blocked if yamllint finds errors. Warnings are displayed but don't block commits.

---

#### **CI/CD Pipeline Integration**

GitHub Actions workflow (`.github/workflows/vps-setup.yml`) likely includes:

```yaml
- name: Lint Ansible playbooks
  run: |
    ansible-lint playbooks/
    yamllint .
```

**Impact on Developers:** Pull requests fail CI checks if linting errors exist. Fix violations locally before pushing.

---

## Configuration Philosophy

### 4.1 Performance vs. Readability Trade-offs

| Optimization | Speedup | Developer Cost |
|--------------|---------|----------------|
| SSH pipelining | 2-3x | Harder to debug (no files on remote) |
| Fact caching | 5-10x | Stale cache issues (cleared with `--flush-cache`) |
| 10 parallel forks | 10x (with 10 hosts) | Interleaved logs harder to read |
| ControlMaster | 3-5x | Stale SSH sockets require manual cleanup |

**Project Choice:** Prioritize performance because VPS provisioning is a batch operation, not interactive development. Developers can disable optimizations during debugging:

```bash
# Disable all performance features for debugging
ANSIBLE_PIPELINING=False \
ANSIBLE_GATHERING=explicit \
ANSIBLE_FORKS=1 \
ansible-playbook playbook.yml -vvv
```

---

### 4.2 Security-First Approach

**Configuration Reflects Security Priorities:**

1. **Phase 2 is Security Hardening** - Must complete before desktop/services
2. **Privilege Escalation Always Explicit** - `become: true` makes privilege usage visible
3. **Secrets Never Logged** - `no_log: true` convention enforced in code reviews
4. **Host Key Checking Trade-off** - Disabled for automation, but acknowledged as a risk

**Why This Matters:**
- VPS instances are publicly accessible (3389/RDP, 22/SSH)
- Security misconfigurations can lead to unauthorized access
- Hardening must happen **before** exposing services

---

### 4.3 Why Certain Defaults Were Chosen

#### **Why Root User by Default?**

Fresh VPS instances from providers (DigitalOcean, Linode, Vultr) grant root SSH access as the initial connection method. Non-root users are created during provisioning.

#### **Why /tmp for Everything?**

Temporary files, SSH control sockets, and fact caches are inherently ephemeral. Using `/tmp` prevents:
- Permission conflicts (world-writable)
- Disk space leaks (cleaned on reboot)
- Security risks (sensitive data persists indefinitely)

#### **Why 24-Hour Fact Cache?**

Balances performance with freshness. VPS system facts (CPU, memory, OS version) rarely change within a day, but they do change after kernel upgrades or resizes.

---

### 4.4 When to Override vs. When to Follow Conventions

#### **Override in These Cases:**

| Scenario | Override Command |
|----------|------------------|
| Strict SSH security required | `ansible-playbook -e 'ansible_host_key_checking=True'` |
| Debugging single host | `ansible-playbook --limit host1 -e 'ansible_forks=1'` |
| Slow network connections | `ansible-playbook -e 'timeout=120'` |
| Force fresh facts | `ansible-playbook --flush-cache` |
| Non-root initial user | `ansible-playbook -u ubuntu` |

#### **Always Follow (Never Override):**

- **Variable naming**: `vps_<role>_` prefix (prevents namespace collisions)
- **FQCN modules**: `ansible.builtin.*` (future-proofing)
- **Secrets handling**: `no_log: true` (security requirement)
- **Role execution order**: `security` before `desktop`/`services` (security-first mandate)

---

## Common Pitfalls and Best Practices

### 5.1 Line Length Violations

**Pitfall:**
```yaml
- name: Install and configure Firefox ESR with specific preferences for security hardening and user experience optimization including privacy settings
  ansible.builtin.apt:
    name: firefox-esr
    state: present
```
(240 characters - exceeds 180 limit)

**Fix:**
```yaml
- name: Install Firefox ESR with security hardening and privacy settings
  ansible.builtin.apt:
    name: firefox-esr
    state: present
```
(90 characters - within limit)

---

### 5.2 Truthy Value Misuse

**Pitfall:**
```yaml
- name: Enable service
  ansible.builtin.service:
    name: xrdp
    enabled: 1  # Numeric boolean - confusing
```

**Fix:**
```yaml
- name: Enable service
  ansible.builtin.service:
    name: xrdp
    enabled: true  # Explicit boolean
```

---

### 5.3 Hardcoded Secrets

**Pitfall:**
```yaml
- name: Create database user
  community.postgresql.postgresql_user:
    name: appuser
    password: "SuperSecret123"  # ← LOGGED IN PLAIN TEXT # pragma: allowlist secret
```

**Fix:**
```yaml
- name: Create database user
  community.postgresql.postgresql_user:
    name: appuser
    password: "{{ db_password }}"  # Variable from Ansible Vault
  no_log: true  # ← Prevents logging
```

Store `db_password` in `group_vars/all/vault.yml` encrypted with `ansible-vault encrypt`.

---

### 5.4 Missing FQCN

**Pitfall:**
```yaml
- name: Install package
  apt:  # ← Bare module name (deprecated)
    name: vim
```

**Fix:**
```yaml
- name: Install package
  ansible.builtin.apt:  # ← FQCN (future-proof)
    name: vim
```

**WHY:** Ansible 2.10+ deprecates bare module names. Future versions will require FQCN.

---

### 5.5 Incorrect File Permissions

**Pitfall:**
```yaml
- name: Set SSH key permissions
  ansible.builtin.file:
    path: /home/vps_user/.ssh/id_ed25519
    mode: 0600  # ← Unquoted octal (parsed as decimal 600)
```

**Result:** File gets mode `0001130` (octal 600 = decimal 384 = octal 1130), breaking SSH.

**Fix:**
```yaml
- name: Set SSH key permissions
  ansible.builtin.file:
    path: /home/vps_user/.ssh/id_ed25519
    mode: '0600'  # ← Quoted string (interpreted correctly)
```

**WHY:** yamllint's `forbid-implicit-octal` and `forbid-explicit-octal` rules prevent this bug.

---

### 5.6 Incorrect Variable Naming

**Pitfall:**
```yaml
# roles/kde-plasma/defaults/main.yml
theme: breeze-dark  # ← No role prefix
wallpaper_url: https://...  # ← Conflicts with other roles
```

**Fix:**
```yaml
# roles/kde-plasma/defaults/main.yml
vps_kde_plasma_theme: breeze-dark  # ← Prefixed
vps_kde_plasma_wallpaper_url: https://...  # ← Unique
```

**WHY:** Multiple roles might define `theme` or `wallpaper_url`, causing unpredictable behavior.

---

### 5.7 Violating Role Execution Order

**Pitfall:**
```yaml
# playbooks/main.yml
- name: Provision VPS
  hosts: all
  roles:
    - desktop  # ← Exposes services before hardening
    - security  # ← Too late!
```

**Fix:**
```yaml
# playbooks/main.yml
- name: Provision VPS
  hosts: all
  roles:
    - common
    - security  # ← ALWAYS before desktop/services
    - kde-plasma
    - desktop
    - services
```

**WHY:** Opening ports (RDP 3389, SSH 22) before configuring UFW, fail2ban, and SSH hardening creates an attack window.

---

## Best Practices Summary

### **YAML Style**
- ✅ Use 2-space indentation (never tabs)
- ✅ Keep lines under 180 characters (aim for <120)
- ✅ Use expanded syntax (no one-liners)
- ✅ Quote all file modes (`mode: '0644'`)
- ✅ Use `true/false` for booleans (avoid `yes/no`)
- ✅ Add space before inline comments (`# comment`)

### **Ansible Conventions**
- ✅ Always use FQCN for modules (`ansible.builtin.apt`)
- ✅ Name tasks with imperative present tense
- ✅ Use `no_log: true` for secrets
- ✅ Prefix variables with `vps_<role>_`
- ✅ Respect role execution order (security before services)

### **Performance Optimization**
- ✅ Leverage fact caching (lasts 24 hours)
- ✅ Use `--limit` for single-host testing
- ✅ Disable pipelining only when debugging
- ✅ Trust ControlMaster for connection reuse

### **Security Requirements**
- ✅ Never commit unencrypted secrets
- ✅ Use Ansible Vault for sensitive variables
- ✅ Run `security` role before exposing services
- ✅ Audit `no_log: true` usage in code reviews

---

## Configuration File Locations

- **Ansible Configuration**: `/home/racoondev/vps-rdp-workstation/ansible.cfg`
- **YAML Linting**: `/home/racoondev/vps-rdp-workstation/.yamllint`
- **Project Guidelines**: `/home/racoondev/vps-rdp-workstation/.github/copilot-instructions.md`
- **Detailed Instructions**: `/home/racoondev/vps-rdp-workstation/.github/instructions/`

---

## Quick Reference: Ansible Overrides

```bash
# Disable host key checking (default: disabled)
ansible-playbook -e 'ansible_host_key_checking=True' playbook.yml

# Change remote user (default: root)
ansible-playbook -u ubuntu playbook.yml

# Disable pipelining for debugging (default: enabled)
ANSIBLE_PIPELINING=False ansible-playbook playbook.yml

# Increase timeout for slow networks (default: 30s)
ansible-playbook -e 'timeout=120' playbook.yml

# Force fact gathering (default: smart/cached)
ansible-playbook --flush-cache playbook.yml

# Run on single host (default: all)
ansible-playbook --limit vps1.example.com playbook.yml

# Serial execution (default: 10 forks)
ansible-playbook -e 'ansible_forks=1' playbook.yml
```

---

## Conclusion

These configurations reflect a **production-grade, security-first automation** designed for rapid VPS provisioning. The settings prioritize:

1. **Speed**: SSH optimizations, fact caching, parallel execution
2. **Security**: Explicit privilege escalation, secret protection, hardening-first workflow
3. **Maintainability**: FQCN modules, descriptive task names, consistent variable naming
4. **Developer Experience**: Relaxed line length, verbose warnings, YAML-formatted output

Contributors should treat these conventions as **non-negotiable for security rules** (secrets, role order) but **flexible for style preferences** (line length, truthy values).

---

**For Questions or Clarifications:**
Refer to `.github/copilot-instructions.md` and `.github/instructions/` for detailed development guidelines.
