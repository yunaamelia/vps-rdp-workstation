<!-- Classification: INTERNAL USE ONLY -->
<!-- Contains: Architecture patterns, technology versions, coding standards -->
<!-- Generated: 2026-01-31 | Regenerate after major refactoring -->

# GitHub Copilot Instructions

## Priority Guidelines

When generating code for this repository:

1. **Version Compatibility**: This is an **Ansible automation project** targeting Debian 13 (Trixie)
2. **Context Files**: Prioritize patterns in `.github/copilot/` and `docs/` directories
3. **Codebase Patterns**: Follow established patterns from `playbooks/tasks/` and `roles/`
4. **Architectural Consistency**: Maintain **phased deployment architecture** (10 phases)
5. **Code Quality**: Prioritize maintainability, idempotency, and security

---

## Technology Stack

| Technology | Version | Configuration Source |
|------------|---------|---------------------|
| **Ansible** | 2.14+ | `ansible.cfg` |
| **Python** | 3.x | System interpreter |
| **Target OS** | Debian 13 (Trixie) | `inventory/hosts.yml` |
| **Node.js** | 20.x LTS | `inventory/group_vars/all.yml` |

### Required Ansible Collections
```yaml
# From requirements.yml
- community.general
- community.docker  
- ansible.posix
```

---

## Codebase Patterns

### Task File Structure

All phase tasks MUST follow this structure:

```yaml
---
#===============================================================================
# Phase N: Phase Name
#===============================================================================
# Brief description of what this phase does
#===============================================================================

- name: Task description
  ansible.builtin.MODULE:
    param: "{{ variable }}"
  when: condition | default(true)

# ... tasks ...

- name: Mark Phase N complete
  ansible.builtin.copy:
    content: |
      Phase N: Phase Name - COMPLETE
      Timestamp: {{ ansible_date_time.iso8601 }}
    dest: "{{ vps_setup_log_dir }}/phaseN-complete.txt"
    mode: '0644'

- name: Phase N completion notice
  ansible.builtin.debug:
    msg: "✅ Phase N: Phase Name Complete"
```

### Naming Conventions

| Component | Pattern | Example |
|-----------|---------|---------|
| Phase Task | `phase{N}-{name}.yml` | `phase1-preparation.yml` |
| Rollback | `phase{N}-rollback.yml` | `phase3-rollback.yml` |
| Role | lowercase single word | `desktop`, `security` |
| Variable | `snake_case` | `vps_username`, `xrdp_port` |
| Feature Flag | `install_*` / `enable_*` | `install_docker`, `enable_atuin` |
| Handler | `Restart {Service}` | `Restart XRDP` |
| Template | `{name}.j2` | `zshrc.j2`, `starship.toml.j2` |

### Module Usage

**Preferred modules** (use FQCNs):
```yaml
# File operations
ansible.builtin.file
ansible.builtin.copy
ansible.builtin.template
ansible.builtin.lineinfile

# Package management
ansible.builtin.apt
ansible.builtin.apt_repository
ansible.builtin.get_url

# Commands
ansible.builtin.command      # When command is safe
ansible.builtin.shell        # When shell features needed

# Services
ansible.builtin.systemd
ansible.builtin.service

# Community modules
community.general.ufw
community.general.npm
community.docker.docker_*
ansible.posix.sysctl
```

---

## Error Handling Patterns

### Block/Rescue Pattern

```yaml
- name: Task group with error handling
  block:
    - name: Primary task
      ansible.builtin.apt:
        name: package
        state: present
  rescue:
    - name: Log failure
      ansible.builtin.debug:
        msg: "Task failed - check logs at {{ vps_setup_log_dir }}"
    
    - name: Fail with message
      ansible.builtin.fail:
        msg: "Phase X failed. Manual intervention required."
```

### Retry Pattern

```yaml
- name: Download with retry
  ansible.builtin.get_url:
    url: https://example.com/file
    dest: /tmp/file
    timeout: 30
  register: download_result
  retries: 3
  delay: 10
  until: download_result is succeeded
```

### Idempotency Pattern

```yaml
- name: Run once using creates
  ansible.builtin.shell: |
    script_that_creates_file.sh
  args:
    creates: /path/to/created/file

- name: Check before action
  ansible.builtin.command: which binary
  register: binary_check
  changed_when: false
  failed_when: false

- name: Install only if missing
  ansible.builtin.get_url:
    url: https://example.com/binary
    dest: /usr/local/bin/binary
  when: binary_check.rc != 0
```

---

## Jinja2 Template Patterns

### Template Header

All templates MUST include:
```jinja2
# {{ ansible_managed }}
# Configuration for VPS Developer Workstation
# Generated: {{ ansible_date_time.iso8601 }}
```

### Loop Rendering

```jinja2
{% for item in collection %}
{{ item }}
{% endfor %}
```

### Conditional Sections

```jinja2
{% if variable | default(true) %}
# Section enabled
{% endif %}
```

---

## Test Script Patterns

### Validation Function Structure

```bash
#!/bin/bash
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASSED=0
FAILED=0

pass() { echo -e "${GREEN}✅ PASS${NC}: $1"; ((PASSED++)); }
fail() { echo -e "${RED}❌ FAIL${NC}: $1"; ((FAILED++)); }

# Tests
if systemctl is-active --quiet service; then
    pass "Service is running"
else
    fail "Service is not running"
fi

# Summary
echo "Passed: $PASSED | Failed: $FAILED"
[ $FAILED -eq 0 ] && exit 0 || exit 1
```

---

## Variable Organization

Variables in `inventory/group_vars/all.yml` follow section grouping:

```yaml
# === Section Name ===
variable_name: value
related_variable: value

# Complex structures for loop iteration
list_variable:
  - { key: value, another: value }
```

---

## Security Patterns

### UFW Firewall

```yaml
- name: Configure UFW allowed ports
  community.general.ufw:
    rule: allow
    port: "{{ item.port }}"
    proto: "{{ item.proto }}"
    comment: "{{ item.comment }}"
  loop: "{{ ufw_allowed_ports }}"
```

### SSH Hardening

```yaml
- name: Harden SSH configuration
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    validate: 'sshd -t -f %s'
  loop:
    - { regexp: '^#?PermitRootLogin', line: 'PermitRootLogin no' }
  notify: Restart SSH
```

---

## Boundaries and Limitations

- **Never generate** code that modifies `/etc/ssh/sshd_config` without the `validate` parameter
- **Never hardcode** passwords or secrets - use variables
- **Always use** `when: not ansible_check_mode` for destructive operations
- **Always include** `mode:` parameter for `copy`, `file`, and `template` modules
- **Follow** existing architectural boundaries (phases, roles, handlers)

---

## File Locations

| Purpose | Location |
|---------|----------|
| New phase task | `playbooks/tasks/phase{N}-{name}.yml` |
| New role | `roles/{name}/tasks/main.yml` |
| New template | `templates/{name}.j2` |
| New test | `tests/phase{N}-tests.sh` |
| Configuration | `inventory/group_vars/all.yml` |
| Handlers | `playbooks/handlers/main.yml` |

---

*Regenerate this file after major architectural changes or new technology additions.*
