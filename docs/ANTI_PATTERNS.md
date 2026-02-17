# Anti-Patterns Reference

## Purpose

This document catalogs **forbidden patterns, strict rules, and critical constraints** extracted from the VPS-RDP-Workstation codebase. These patterns represent hard-learned lessons, security requirements, and architectural decisions that must be respected.

**When to consult this document:**
- Before implementing new roles or tasks
- During code review
- When troubleshooting unexpected behavior
- When onboarding new contributors

## Pattern Categories

### 🔒 Security Anti-Patterns

#### 1. Root RDP Access in Production
**Pattern:** Enabling root login via RDP
**Rule:** `NEVER in production`
**Source:** `inventory/group_vars/all.yml:116`

```yaml
# ❌ FORBIDDEN IN PRODUCTION
vps_xrdp_allow_root: true

# ✅ CORRECT
vps_xrdp_allow_root: false  # NEVER in production
```

**Rationale:** Root RDP access creates unnecessary attack surface. Remote desktop should always be accessed through non-privileged accounts with sudo elevation when needed.

**Related Variables:**
- `vps_xrdp_allow_root` - MUST be `false` in production inventories

---

#### 2. Secrets in Version Control
**Pattern:** Committing sensitive data to Git
**Rule:** `NEVER commit passwords, API keys, or secrets to version control`
**Source:** `CLAUDE.md:276`

```yaml
# ❌ FORBIDDEN
vars:
  database_password: "MySecretPass123"  # pragma: allowlist secret
  api_key: "sk-proj-abc123..."          # pragma: allowlist secret

# ✅ CORRECT
vars:
  database_password: "{{ lookup('env', 'DB_PASSWORD') }}"
  api_key: "{{ lookup('ansible.builtin.password', '/dev/null') }}"
```

**Rationale:** Secrets in VCS are accessible to anyone with repository access (now or in the future), can be scraped by bots, and violate compliance standards.

**Mitigation:**
- Use Ansible Vault for sensitive variables
- Use environment variables for runtime secrets
- Never store plaintext secrets in `inventory/` or `group_vars/`

---

#### 3. Sensitive Data Logging
**Pattern:** Logging secrets, passwords, or tokens
**Rule:** `NEVER log sensitive data - use no_log: true`
**Source:** `CLAUDE.md:277`

```yaml
# ❌ FORBIDDEN
- name: Configure database password
  ansible.builtin.lineinfile:
    path: /etc/app/config
    line: "DB_PASS={{ db_password }}"

# ✅ CORRECT
- name: Configure database password
  ansible.builtin.lineinfile:
    path: /etc/app/config
    line: "DB_PASS={{ db_password }}"
  no_log: true  # Prevents password exposure in logs
```

**Rationale:** Ansible logs are stored in multiple locations (controller, targets, CI/CD systems). Sensitive data in logs can be exfiltrated through log aggregation systems.

**Applies to:**
- Password configuration
- API key injection
- Certificate/token handling
- Any task with `{{ *_password }}`, `{{ *_key }}`, `{{ *_token }}` variables

---

#### 4. Plaintext Password Storage
**Pattern:** Storing user passwords without hashing
**Rule:** `NEVER store user passwords in plaintext - always use SHA-512 hash`
**Source:** `CLAUDE.md:278`

```yaml
# ❌ FORBIDDEN
vps_user_password: "MyPassword123"  # pragma: allowlist secret

# ✅ CORRECT
vps_user_password_hash: "$6$rounds=656000$..."  # SHA-512 hash
```

**Rationale:** Plaintext passwords in configuration files violate security fundamentals. Linux systems require hashed passwords for `/etc/shadow`.

**Implementation:**
- Use `mkpasswd -m sha-512` to generate hashes
- Store only `vps_user_password_hash`, never `vps_user_password`
- Document hash generation process in inventory README

---

#### 5. Public Vulnerability Disclosure
**Pattern:** Reporting security issues via public GitHub
**Rule:** `DO NOT open public GitHub issues for vulnerabilities`
**Source:** `docs/SECURITY.md:5`

**Rationale:** Public disclosure before patching creates exploitation windows. Responsible disclosure protocols protect users.

**Correct Process:**
1. Email security contact (from SECURITY.md)
2. Wait for acknowledgment
3. Allow reasonable remediation time
4. Coordinate public disclosure

---

### ⚙️ Operational Anti-Patterns

#### 6. Validation Skipping
**Pattern:** Bypassing validation checks during deployment
**Rule:** `NEVER skip validation unless debugging`
**Source:** `CLAUDE.md:279`

```bash
# ❌ FORBIDDEN (except during debugging)
./setup.sh --skip-validation

# ✅ CORRECT
./setup.sh  # Always validate inventory/playbook syntax
```

**Rationale:** Validation prevents misconfigurations that can break systems or create security gaps. Skipping validation trades safety for speed.

**When debugging is justified:**
- Iterating on validation logic itself
- Testing with known-invalid configurations
- Must be documented in commit message

---

#### 7. Production Testing
**Pattern:** Running test suites against live systems
**Rule:** `NEVER run remote_test.sh on live systems`
**Source:** `tests/AGENTS.md:16`

**Rationale:** Test scripts may:
- Restart critical services
- Modify system state
- Generate excessive load
- Expose sensitive information in test output

**Correct Usage:**
- Only run against disposable VPS instances
- Use staging/development inventories
- Mark test systems clearly in inventory

---

#### 8. Direct Ansible Invocation
**Pattern:** Running `ansible-playbook` directly without wrapper
**Rule:** `Avoid ansible-playbook directly; use setup.sh wrapper`
**Source:** `playbooks/AGENTS.md:19`

```bash
# ⚠️ DISCOURAGED
ansible-playbook -i inventory/production playbooks/setup.yml

# ✅ PREFERRED
./setup.sh production
```

**Rationale:** `setup.sh` provides:
- Syntax validation
- Inventory verification
- Consistent argument handling
- Environment preparation

**Exception:** Direct invocation acceptable when:
- Running tags: `ansible-playbook -i ... --tags desktop`
- Testing individual roles
- Advanced debugging

---

### 💻 Development Anti-Patterns

#### 9. Security Role Ordering
**Pattern:** Moving `security` role after service roles
**Rule:** `NEVER move security after service roles (desktop, xrdp)`
**Source:** `playbooks/AGENTS.md:18`

```yaml
# ❌ FORBIDDEN
roles:
  - desktop
  - xrdp
  - security  # TOO LATE - services already exposed

# ✅ CORRECT (10-phase order)
roles:
  - common       # Phase 1
  - security     # Phase 2 - MUST run before services
  - fonts        # Phase 3
  - desktop      # Phase 4
  - xrdp         # Phase 5
```

**Rationale:** Security hardening (firewall, SSH config, fail2ban) must be applied before network services start. Reversing this order creates a window where services are exposed without protection.

**Critical Dependency Chain:**
1. `security` configures UFW → blocks all ports except SSH
2. `xrdp` starts RDP service → needs firewall rules pre-configured
3. `desktop` may start additional services → requires security baseline

---

#### 10. Wrapper Script Usage
**Pattern:** Bypassing automation wrappers
**Rule:** `ALWAYS use setup.sh. Skips direct ansible-playbook`
**Source:** `AGENTS.md:19`

**Rationale:** Wrapper scripts encode institutional knowledge:
- Pre-flight validation
- Error handling
- Logging configuration
- Environment consistency

**Related:** See Anti-Pattern #8 (Direct Ansible Invocation)

---

#### 11. User ID Assumptions
**Pattern:** Hardcoding user IDs or assuming default accounts
**Rule:** `ALWAYS use {{ vps_username }}. Never assume root or 1000`
**Source:** `roles/desktop/AGENTS.md:22`

```yaml
# ❌ FORBIDDEN
- name: Configure user desktop
  ansible.builtin.file:
    path: /home/root/.config
    owner: root  # Assumes root user

- name: Set permissions
  ansible.builtin.file:
    path: /home/user/.bashrc
    owner: user
    group: user
    # Assumes UID 1000 exists

# ✅ CORRECT
- name: Configure user desktop
  ansible.builtin.file:
    path: "/home/{{ vps_username }}/.config"
    owner: "{{ vps_username }}"
    group: "{{ vps_username }}"
```

**Rationale:** Different distributions and configurations use different default users:
- Ubuntu: `ubuntu` (UID 1000)
- Debian: `debian` or custom
- Custom installs: Any username

**Impact of Violation:**
- Permission errors (files owned by wrong user)
- Service failures (processes can't access config)
- Security issues (files readable by unintended users)

---

## Quick Reference Table

| # | Category | Rule | Keyword | Severity |
|---|----------|------|---------|----------|
| 1 | Security | No root RDP | `NEVER` | 🔴 Critical |
| 2 | Security | No secrets in VCS | `NEVER` | 🔴 Critical |
| 3 | Security | No sensitive logging | `NEVER` | 🔴 Critical |
| 4 | Security | Hash passwords | `ALWAYS` | 🔴 Critical |
| 5 | Security | Private vuln reports | `DO NOT` | 🔴 Critical |
| 6 | Operational | Validate configs | `NEVER skip` | 🟡 High |
| 7 | Operational | No prod testing | `NEVER` | 🔴 Critical |
| 8 | Operational | Use wrappers | `Avoid` | 🟢 Medium |
| 9 | Development | Security role first | `NEVER move` | 🔴 Critical |
| 10 | Development | Use setup.sh | `ALWAYS` | 🟡 High |
| 11 | Development | Parameterize users | `ALWAYS use var` | 🟡 High |

---

## Related Documentation

- **Security Policy:** `docs/SECURITY.md` - Vulnerability reporting procedures
- **Development Guide:** `CLAUDE.md` - Complete development guidelines
- **Agent Instructions:** `AGENTS.md` - AI agent behavioral constraints
- **Code Review:** `.github/instructions/code-review-generic.instructions.md` - Review checklist

---

## Enforcement

### Pre-Commit Checks
```bash
# Check for plaintext password vars
grep -r "vps_user_password:" inventory/ && echo "ERROR: Use vps_user_password_hash"

# Check for secrets in vars
grep -rE "(password|api_key|token):\s*['\"]" group_vars/ && echo "ERROR: Secrets detected"

# Check no_log on sensitive tasks
grep -A5 "_password\|_key\|_token" roles/*/tasks/*.yml | grep -v "no_log: true" && echo "WARNING: Missing no_log"
```

### CI/CD Integration
- Validation runs on all PRs (via `.github/workflows/`)
- Security scans check for Anti-Patterns #2, #3, #4
- Role order verification enforces Anti-Pattern #9

### Code Review Checklist
**Before approving PRs, verify:**
- [ ] No plaintext secrets (AP #2, #4)
- [ ] `no_log: true` on sensitive tasks (AP #3)
- [ ] Security role runs before services (AP #9)
- [ ] Variables use `{{ vps_username }}` not hardcoded users (AP #11)
- [ ] Production configs have `vps_xrdp_allow_root: false` (AP #1)

---

## Contributing

Found a new anti-pattern? Add it by:
1. Documenting in the affected file with `NEVER`/`ALWAYS`/`DO NOT` keyword
2. Adding entry to this document with source reference
3. Updating enforcement scripts if automatable

**Template:**
```markdown
#### N. Pattern Name
**Pattern:** Brief description
**Rule:** `KEYWORD from source`
**Source:** `path/to/file:line`

[Code Examples]

**Rationale:** Why this is forbidden

**Mitigation:** How to do it correctly
```

---

*Last Updated: 2025-01-29*
*Auto-generated from codebase keyword search*
*For questions, see CLAUDE.md or open a non-security issue*
