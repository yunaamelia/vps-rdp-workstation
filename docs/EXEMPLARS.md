# Code Exemplars Blueprint

**Generated:** 2026-01-31
**Classification:** INTERNAL USE ONLY
**Project:** VPS RDP Developer Workstation (Ansible)

---

## Introduction

This document identifies high-quality, representative code examples from our codebase to serve as templates for new implementations. Each exemplar demonstrates our coding standards and patterns to maintain consistency.

**Technologies Detected:** Ansible (YAML), Jinja2 Templates, Bash Scripts, Python

---

## Table of Contents

- [1. Orchestration Patterns](#1-orchestration-patterns)
- [2. Ansible Task Patterns](#2-ansible-task-patterns)
- [3. Role Architecture](#3-role-architecture)
- [4. Configuration Management](#4-configuration-management)
- [5. Testing Patterns](#5-testing-patterns)
- [6. Template Patterns](#6-template-patterns)

---

## 1. Orchestration Patterns

### 1.1 Main Playbook Structure

**File:** [`playbooks/main.yml`](playbooks/main.yml)

**Why Exemplary:**
- Clean phase-based orchestration with 10 sequential deployment phases
- Consistent tagging strategy for selective execution
- Proper `gather_facts` optimization (only where needed)
- Clear banner comments for phase identification

```yaml
- name: "Phase 1: System Preparation & Checkpoint Creation"
  hosts: localhost
  become: true
  gather_facts: true
  tags:
    - phase1
    - preparation
  tasks:
    - name: Include Phase 1 playbook
      ansible.builtin.include_tasks: tasks/phase1-preparation.yml
```

**Key Principles:**
- Each phase is a separate play for isolation
- Tags enable `--tags phase5` execution
- `include_tasks` keeps main playbook readable

---

### 1.2 Role Orchestration

**File:** [`roles/enhancements/tasks/main.yml`](roles/enhancements/tasks/main.yml)

**Why Exemplary:**
- Modular sub-task inclusion with conditional execution
- Clear section dividers with sub-phase numbering
- Feature flags (`enable_*`) for optional components
- Summary generation at completion

```yaml
- name: Install Modern CLI Tools
  ansible.builtin.include_tasks: modern-cli.yml
  when: enable_modern_cli | default(true)

- name: Install Zsh Plugins
  ansible.builtin.include_tasks: zsh-plugins.yml
  when: enable_zsh_plugins | default(true)
```

**Key Principles:**
- Feature toggles with sensible defaults
- Logical grouping of related tasks
- Clear naming convention: `Phase 9.X: Feature Name`

---

## 2. Ansible Task Patterns

### 2.1 Repository Setup Pattern

**File:** [`playbooks/tasks/phase3-dependencies.yml`](playbooks/tasks/phase3-dependencies.yml)

**Why Exemplary:**
- Complete GPG key download → dearmor → repository add workflow
- Retry logic with exponential backoff
- Idempotent with `creates:` argument

```yaml
- name: Add NodeSource GPG key
  ansible.builtin.get_url:
    url: https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key
    dest: /tmp/nodesource.gpg.key
    mode: '0644'
    timeout: 30
  register: nodesource_key_download
  retries: 3
  delay: 10
  until: nodesource_key_download is succeeded

- name: Dearmor NodeSource GPG key
  ansible.builtin.shell: |
    gpg --dearmor --yes -o /usr/share/keyrings/nodesource.gpg /tmp/nodesource.gpg.key
  args:
    creates: /usr/share/keyrings/nodesource.gpg

- name: Add NodeSource repository
  ansible.builtin.apt_repository:
    repo: "deb [signed-by=/usr/share/keyrings/nodesource.gpg] https://deb.nodesource.com/node_{{ nodejs_version }}.x nodistro main"
    filename: nodesource
    state: present
    update_cache: true
```

**Key Principles:**
- Network operations have retries and timeouts
- `creates:` ensures idempotency for shell commands
- Signed-by pattern for modern apt security

---

### 2.2 GitHub Release API Pattern

**File:** [`playbooks/tasks/phase3-dependencies.yml`](playbooks/tasks/phase3-dependencies.yml) (lines 144-188)

**Why Exemplary:**
- Fetches latest version from GitHub API
- Conditional execution based on installation status
- Fallback default version if API fails

```yaml
- name: Check if Lazygit is installed
  ansible.builtin.command: which lazygit
  register: lazygit_check
  changed_when: false
  failed_when: false

- name: Get latest Lazygit release
  ansible.builtin.uri:
    url: https://api.github.com/repos/jesseduffield/lazygit/releases/latest
    return_content: true
  register: lazygit_release
  retries: 3
  delay: 5
  until: lazygit_release.status == 200
  when: lazygit_check.rc != 0

- name: Set Lazygit version
  ansible.builtin.set_fact:
    lazygit_version: "{{ lazygit_release.json.tag_name | default('v0.44.1') | regex_replace('^v', '') }}"
  when: lazygit_check.rc != 0
```

**Key Principles:**
- Pre-check prevents unnecessary downloads
- API retry with status code validation
- Fallback version for offline scenarios

---

### 2.3 Security Hardening Pattern

**File:** [`playbooks/tasks/phase7-optimization.yml`](playbooks/tasks/phase7-optimization.yml)

**Why Exemplary:**
- Complete UFW + Fail2ban + SSH hardening stack
- Loop-based configuration for maintainability
- Inline Jinja2 templating for dynamic config

```yaml
- name: Harden SSH configuration
  ansible.builtin.lineinfile:
    path: /etc/ssh/sshd_config
    regexp: "{{ item.regexp }}"
    line: "{{ item.line }}"
    state: present
    validate: 'sshd -t -f %s'
  loop:
    - { regexp: '^#?PermitRootLogin', line: "PermitRootLogin {{ ssh_permit_root_login | bool | ternary('yes', 'no') }}" }
    - { regexp: '^#?MaxAuthTries', line: "MaxAuthTries {{ ssh_max_auth_tries }}" }
  notify: Restart SSH
```

**Key Principles:**
- `validate:` ensures config is valid before applying
- `notify:` triggers handler only on change
- Boolean ternary for clean conditional values

---

## 3. Role Architecture

### 3.1 Standard Role Structure

**Directory:** [`roles/enhancements/`](roles/enhancements/)

```
roles/enhancements/
├── defaults/main.yml      # Default variables
├── files/                  # Static files
├── handlers/main.yml      # Service restarts
├── meta/main.yml          # Role metadata
├── tasks/
│   ├── main.yml           # Orchestrator (includes sub-tasks)
│   ├── modern-cli.yml     # Feature-specific tasks
│   ├── zsh-plugins.yml
│   └── ...
├── templates/             # Jinja2 templates
└── vars/                  # Role-specific variables
```

**Key Principles:**
- `main.yml` orchestrates, feature files implement
- Defaults provide safe fallback values
- Handlers centralize service management

---

## 4. Configuration Management

### 4.1 Variable Organization

**File:** [`inventory/group_vars/all.yml`](inventory/group_vars/all.yml)

**Why Exemplary:**
- Logical section grouping with clear headers
- Inline documentation for each variable
- Complex data structures for related settings

```yaml
# === Security Configuration ===
ssh_port: 22
ufw_enabled: true
ufw_allowed_ports:
  - { port: 22, proto: tcp, comment: "SSH" }
  - { port: 3389, proto: tcp, comment: "XRDP" }

fail2ban_jails:
  sshd:
    enabled: true
    port: 22
    logpath: /var/log/auth.log
    maxretry: 5
    bantime: 3600
```

**Key Principles:**
- Section headers with `# === Name ===`
- Related settings grouped together
- Complex structures enable loop iteration

---

### 4.2 Feature Flags Pattern

**File:** [`inventory/group_vars/all.yml`](inventory/group_vars/all.yml) (lines 46-58)

**Why Exemplary:**
- Boolean flags for optional components
- Consistent naming: `install_*`, `enable_*`
- Sensible defaults

```yaml
# === Development Tools ===
install_nodejs: true
install_python: true
install_docker: true
install_vscode: true
install_opencode: true
install_antigravity: true
```

---

## 5. Testing Patterns

### 5.1 Test Framework

**File:** [`tests/comprehensive-validation.sh`](tests/comprehensive-validation.sh)

**Why Exemplary:**
- Colored output with pass/fail/warn counters
- Exit code for CI/CD integration
- Categorized test sections

```bash
#!/bin/bash
set -uo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASSED=0
FAILED=0
WARNINGS=0

pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    ((PASSED++))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    ((FAILED++))
}

# Service check
if systemctl is-active --quiet xrdp; then
    pass "XRDP service is running"
else
    fail "XRDP service is not running"
fi

# Summary
if [ $FAILED -eq 0 ]; then
    exit 0
else
    exit 1
fi
```

**Key Principles:**
- Helper functions for consistent output
- Counter-based summary reporting
- Exit code 0/1 for automation

---

### 5.2 Phase-Specific Tests

**File:** [`tests/phase1-tests.sh`](tests/phase1-tests.sh)

**Why Exemplary:**
- Focused scope per phase
- File/directory existence checks
- Clear test numbering

```bash
# Test 1: Log directory exists
echo "Test 1: Checking log directory..."
if [ -d "$LOG_DIR" ]; then
    echo "  ✅ Log directory exists: $LOG_DIR"
else
    echo "  ❌ Log directory missing"
    ((FAILED++))
fi
```

---

## 6. Template Patterns

### 6.1 Jinja2 Configuration Template

**File:** [`templates/fail2ban-jail.local.j2`](templates/fail2ban-jail.local.j2)

**Pattern:** Use Jinja2 loops for dynamic configuration generation.

```jinja2
[DEFAULT]
bantime = {{ fail2ban_bantime }}
findtime = {{ fail2ban_findtime }}
maxretry = {{ fail2ban_maxretry }}

{% for jail_name, jail_config in fail2ban_jails.items() %}
[{{ jail_name }}]
enabled = {{ jail_config.enabled | string | lower }}
port = {{ jail_config.port }}
{% endfor %}
```

---

## Naming Conventions Summary

| Component | Pattern | Example |
|-----------|---------|---------|
| Playbook | `{function}.yml` | `main.yml`, `rollback.yml` |
| Phase Task | `phase{N}-{name}.yml` | `phase1-preparation.yml` |
| Role | `{feature}` (lowercase) | `common`, `desktop`, `security` |
| Role Task | `{feature}.yml` | `modern-cli.yml`, `zsh-plugins.yml` |
| Template | `{config}.j2` | `docker-daemon.json.j2` |
| Variable | `snake_case` | `vps_username`, `xrdp_port` |
| Feature Flag | `install_*` / `enable_*` | `install_docker`, `enable_atuin` |
| Test Script | `phase{N}-tests.sh` | `phase1-tests.sh` |

---

## Recommendations

1. **New Phase:** Copy `phase1-preparation.yml` structure (banner, block/rescue, completion marker)
2. **New Role:** Use `roles/enhancements/` as template for modular sub-task structure
3. **New Tool:** Follow `phase3-dependencies.yml` GitHub API pattern for version fetching
4. **New Test:** Follow `comprehensive-validation.sh` pass/fail/warn framework
5. **Variables:** Add to `inventory/group_vars/all.yml` with section grouping

---

*Total Exemplars: 12 | Categories: 6*
