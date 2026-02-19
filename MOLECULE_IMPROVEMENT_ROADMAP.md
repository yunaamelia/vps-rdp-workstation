# Molecule Test Improvement Roadmap

## Overview
This document outlines recommended improvements to the VPS-RDP-Workstation test suite based on the comprehensive test execution and analysis performed on 2026-02-19.

---

## Critical Fixes (Do First)

### 1. Fix Desktop Role Idempotence ⚡ URGENT

**Issue:** Desktop role fails idempotence check due to non-idempotent file operations

**Location:** `roles/desktop/tasks/main.yml`

**Tasks Affected:**
- Create Kvantum config directory
- Set Kvantum theme to WhiteSurDark

**Solution A: Remove Recurse (Simplest)**
```yaml
- name: Create Kvantum config directory
  ansible.builtin.file:
    path: '/home/{{ vps_username }}/.config/Kvantum'
    state: directory
    owner: '{{ vps_username }}'
    group: '{{ vps_username }}'
    mode: '0755'
    # Remove: recurse: true
  tags: [desktop, theme]
```

**Solution B: Add Changed_When (More Robust)**
```yaml
- name: Create Kvantum config directory
  ansible.builtin.file:
    path: '/home/{{ vps_username }}/.config/Kvantum'
    state: directory
    owner: '{{ vps_username }}'
    group: '{{ vps_username }}'
    mode: '0755'
  register: kvantum_dir_result
  changed_when: kvantum_dir_result.changed and kvantum_dir_result.state == 'directory'
  tags: [desktop, theme]

- name: Set Kvantum theme to WhiteSurDark
  community.general.ini_file:
    path: '/home/{{ vps_username }}/.config/Kvantum/kvantum.kvconfig'
    section: General
    option: theme
    value: WhiteSurDark
    owner: '{{ vps_username }}'
    group: '{{ vps_username }}'
    mode: '0644'
  tags: [desktop, theme]
```

**Verification:**
```bash
# Test the fix
molecule test -s default

# Should see:
# INFO     default ➜ idempotence: Executed: Successful
# INFO     Molecule executed 1 scenario (1 successful)
```

**Effort:** 5 minutes
**Impact:** Critical - Unblocks default scenario testing

---

## Short-term Improvements (Next 2 Weeks)

### 2. Add Missing Role Tests

**Priority Roles to Test:**

#### A. Editors Scenario
**Purpose:** Test VSCode, code editors installation and configuration

```yaml
# Create: molecule/editors/molecule.yml
# Create: molecule/editors/converge.yml
# Create: molecule/editors/verify.yml

# Test:
- VSCode installation
- Extensions installation
- Configuration files
- Editor binaries accessible
```

**Assertions Needed:**
- [ ] VSCode binary exists
- [ ] Config directory created
- [ ] Extensions installed
- [ ] Settings.json deployed

**Effort:** 2-3 hours
**Priority:** High (editors are core developer tool)

#### B. Fonts Scenario
**Purpose:** Test font installation and configuration

```yaml
# Create: molecule/fonts/molecule.yml
# Create: molecule/fonts/converge.yml
# Create: molecule/fonts/verify.yml

# Test:
- Nerd Fonts installation
- Font cache updates
- Font configuration
```

**Assertions Needed:**
- [ ] Font files exist in /usr/share/fonts
- [ ] fc-cache executed
- [ ] Fonts listed in fc-list output

**Effort:** 1-2 hours
**Priority:** Medium

#### C. KDE-Apps Scenario
**Purpose:** Test KDE application suite

```yaml
# Test:
- Dolphin file manager
- Konsole terminal
- Kate editor
- Spectacle screenshot tool
- KDE utilities
```

**Assertions Needed:**
- [ ] Application binaries exist
- [ ] .desktop files present
- [ ] Default configurations deployed

**Effort:** 2-3 hours
**Priority:** Medium

### 3. Enhance Existing Verification Tests

**Default Scenario Enhancements:**
```yaml
# Add to molecule/default/verify.yml

- name: Verify SSH port is 22
  ansible.builtin.command: grep "^Port " /etc/ssh/sshd_config
  register: ssh_port
  failed_when: "'22' not in ssh_port.stdout"

- name: Verify UFW is active (if systemd available)
  ansible.builtin.command: ufw status
  register: ufw_status
  changed_when: false
  failed_when: false

- name: Verify fail2ban configuration
  ansible.builtin.stat:
    path: /etc/fail2ban/jail.local
  register: fail2ban_conf
  failed_when: not fail2ban_conf.stat.exists

- name: Verify sudoers permissions
  ansible.builtin.stat:
    path: /etc/sudoers.d/{{ vps_username }}
  register: sudoers_perms
  failed_when: sudoers_perms.stat.mode != '0440'
```

**DevTools Scenario Enhancements:**
```yaml
# Add to molecule/devtools/verify.yml

- name: Verify npm global directory configuration
  ansible.builtin.command: npm config get prefix
  become_user: testuser
  register: npm_prefix
  failed_when: "'.npm-global' not in npm_prefix.stdout"

- name: Verify Docker daemon is configured
  ansible.builtin.command: cat /etc/docker/daemon.json
  register: docker_config
  failed_when: "'log-driver' not in docker_config.stdout"

- name: Verify user in docker group
  ansible.builtin.command: groups testuser
  register: user_groups
  failed_when: "'docker' not in user_groups.stdout"

- name: Verify pipx packages installed
  ansible.builtin.command: pipx list
  become_user: testuser
  register: pipx_list
  failed_when: "'black' not in pipx_list.stdout or 'pylint' not in pipx_list.stdout"
```

**Shell Scenario Enhancements:**
```yaml
# Add to molecule/shell/verify.yml

- name: Verify zsh plugins loaded in .zshrc
  ansible.builtin.shell: |
    grep -E 'zsh-autosuggestions|zsh-syntax-highlighting' /home/testuser/.zshrc
  register: plugins_check
  failed_when: plugins_check.rc != 0

- name: Verify Starship in PATH
  ansible.builtin.command: which starship
  become_user: testuser
  register: starship_path
  failed_when: starship_path.rc != 0

- name: Verify TPM installed
  ansible.builtin.stat:
    path: /home/testuser/.tmux/plugins/tpm
  register: tpm_check
  failed_when: not tpm_check.stat.exists

- name: Verify fzf available
  ansible.builtin.command: which fzf
  register: fzf_check
  failed_when: fzf_check.rc != 0
```

**Effort:** 2-3 hours
**Priority:** High

### 4. Add Negative Test Cases

**Purpose:** Verify that incorrect configurations are rejected

```yaml
# Example: molecule/security/verify.yml

- name: Verify SSH root login is disabled
  ansible.builtin.command: grep "^PermitRootLogin" /etc/ssh/sshd_config
  register: root_login
  failed_when: "'no' not in root_login.stdout"

- name: Verify password authentication policy
  ansible.builtin.command: grep "^PasswordAuthentication" /etc/ssh/sshd_config
  register: pwd_auth
  # Adjust based on your security policy

- name: Verify UFW denies incoming by default
  ansible.builtin.command: ufw status verbose
  register: ufw_policy
  failed_when: "'deny (incoming)' not in ufw_policy.stdout.lower()"
```

**Effort:** 1-2 hours
**Priority:** Medium

---

## Medium-term Improvements (Next Month)

### 5. Integration Test Scenario

**Purpose:** Test complete workflow with multiple roles

```yaml
# Create: molecule/integration/molecule.yml
# molecule/integration/converge.yml

- name: Full Stack Integration Test
  hosts: all
  become: true
  vars:
    vps_username: "integrationuser"
    # ... full configuration
  roles:
    - common
    - security
    - development
    - docker
    - terminal
    - tmux
    - shell-styling
    - zsh-enhancements
    - editors
    - fonts
```

**Verification Focus:**
- Role interaction
- No conflicts between roles
- Complete user environment functional
- End-to-end workflow

**Effort:** 4-6 hours
**Priority:** High

### 6. Parallel Test Execution

**Goal:** Reduce total test time from 15 minutes to <5 minutes

**Implementation:**
```bash
# Run all scenarios in parallel
molecule test --all --parallel

# Or manually:
molecule test -s default & \
molecule test -s devtools & \
molecule test -s shell & \
wait
```

**Requirements:**
- Ensure no shared state between scenarios
- Unique container names
- Independent Docker networks

**Configuration Update:**
```yaml
# molecule/*/molecule.yml
platforms:
  - name: "debian-${SCENARIO_NAME}-${RANDOM_ID}"  # Unique naming
```

**Effort:** 2-3 hours
**Priority:** Medium

### 7. Test Matrix Implementation

**Goal:** Test against multiple OS versions and configurations

```yaml
# .github/workflows/molecule.yml or similar

strategy:
  matrix:
    scenario: [default, devtools, shell]
    os: [debian:trixie, debian:bookworm, ubuntu:24.04]
    python: ['3.11', '3.12']

steps:
  - name: Test ${{ matrix.scenario }} on ${{ matrix.os }}
    run: molecule test -s ${{ matrix.scenario }}
    env:
      MOLECULE_IMAGE: ${{ matrix.os }}
```

**Effort:** 3-4 hours
**Priority:** Medium

### 8. Performance Benchmarking

**Goal:** Track and optimize test performance

```yaml
# Create: molecule/performance/verify.yml

- name: Benchmark package installation time
  ansible.builtin.command: |
    time apt-get install -y nodejs
  register: install_time

- name: Verify installation completed under threshold
  ansible.builtin.assert:
    that: install_time.delta < timedelta(seconds=60)
    fail_msg: "Installation too slow: {{ install_time.delta }}"

- name: Benchmark Docker image pull
  ansible.builtin.command: |
    time docker pull hello-world
  register: pull_time
```

**Effort:** 2-3 hours
**Priority:** Low

---

## Long-term Improvements (Next Quarter)

### 9. Mutation Testing

**Goal:** Verify tests actually catch regressions

**Tool:** `mutmut` or custom mutation framework

**Process:**
1. Introduce intentional bugs in roles
2. Verify tests fail
3. Improve tests if mutations not caught

**Example Mutations:**
```yaml
# Original
- name: Install git
  ansible.builtin.apt:
    name: git
    state: present

# Mutation 1: Wrong package
- name: Install git
  ansible.builtin.apt:
    name: NOT_GIT  # Should be caught by verify
    state: present

# Mutation 2: Wrong state
- name: Install git
  ansible.builtin.apt:
    name: git
    state: absent  # Should be caught by verify
```

**Effort:** 8-10 hours
**Priority:** Low

### 10. Continuous Test Improvement

**Goal:** Maintain and improve test quality over time

**Metrics to Track:**
- Test coverage percentage
- Number of assertions
- Test execution time
- Flaky test count
- Mean time to detect failures

**Dashboard:**
```markdown
# Test Quality Dashboard

| Metric | Current | Target | Trend |
|--------|---------|--------|-------|
| Coverage | 37% | 80% | ↗️ |
| Assertions | 36 | 100+ | ↗️ |
| Duration | 15min | <10min | → |
| Flaky Tests | 0 | 0 | ✅ |
| MTTR | N/A | <2h | - |
```

**Effort:** Ongoing
**Priority:** Medium

---

## Test Data and Fixtures

### 11. Create Reusable Test Data

**Goal:** Consistent test configurations across scenarios

```yaml
# Create: molecule/shared/vars.yml

# Shared test user
test_user:
  username: "molecule_test"
  password_hash: "$6$rounds=4096$testsalt$..."
  shell: "/bin/bash"
  groups: ["sudo", "docker"]

# Shared packages
test_packages:
  essential: [git, curl, wget, vim]
  development: [nodejs, python3, docker.io]
  shell: [zsh, tmux, fzf]

# Shared paths
test_paths:
  home: "/home/molecule_test"
  config: "/home/molecule_test/.config"
  local: "/home/molecule_test/.local"
```

**Usage:**
```yaml
# molecule/*/converge.yml
vars_files:
  - ../../shared/vars.yml

tasks:
  - name: Create test user
    ansible.builtin.user:
      name: "{{ test_user.username }}"
      password: "{{ test_user.password_hash }}"
      shell: "{{ test_user.shell }}"
```

**Effort:** 2-3 hours
**Priority:** Medium

---

## Testing Best Practices to Adopt

### 12. AAA Pattern Enhancement

**Current State:** Basic assertions
**Goal:** Structured test organization

```yaml
# molecule/*/verify.yml

# ARRANGE
- name: Set up test preconditions
  ansible.builtin.set_fact:
    expected_packages: [git, curl, wget]

# ACT
- name: Check installed packages
  ansible.builtin.command: dpkg -l {{ item }}
  loop: "{{ expected_packages }}"
  register: package_check

# ASSERT
- name: Verify all packages installed
  ansible.builtin.assert:
    that: item.rc == 0
    fail_msg: "Package {{ item.item }} not installed"
  loop: "{{ package_check.results }}"
```

### 13. Test Isolation

**Goal:** Each test independent and repeatable

**Principles:**
- No shared state between scenarios
- Clean up after tests
- Idempotent setup/teardown

```yaml
# molecule/*/prepare.yml
- name: Ensure clean state
  ansible.builtin.file:
    path: "{{ item }}"
    state: absent
  loop:
    - /tmp/test_artifacts
    - /var/lib/test_state

# molecule/*/cleanup.yml
- name: Remove test artifacts
  ansible.builtin.file:
    path: "{{ item }}"
    state: absent
  loop:
    - /tmp/test_artifacts
    - /var/lib/test_state
```

### 14. Descriptive Test Naming

**Current:** Generic names
**Goal:** Self-documenting tests

```yaml
# ❌ Bad
- name: Check file
  ansible.builtin.stat:
    path: /etc/config

# ✅ Good
- name: Verify SSH configuration backup exists before applying security hardening
  ansible.builtin.stat:
    path: /var/backups/vps-setup/sshd_config.backup
  register: ssh_backup

- name: Assert SSH backup was created by security role for rollback capability
  ansible.builtin.assert:
    that: ssh_backup.stat.exists
    fail_msg: "SSH config backup not found - rollback not possible"
```

---

## Effort Summary

| Priority | Tasks | Total Effort | ROI |
|----------|-------|--------------|-----|
| Critical | 1 | 0.5 hours | ⭐⭐⭐⭐⭐ |
| High | 5 | 15-20 hours | ⭐⭐⭐⭐ |
| Medium | 7 | 20-25 hours | ⭐⭐⭐ |
| Low | 2 | 10-13 hours | ⭐⭐ |

**Total Estimated Effort:** 45-58 hours

---

## Implementation Phases

### Phase 1: Critical (Week 1)
- [ ] Fix desktop role idempotence
- [ ] Verify all current tests pass

### Phase 2: High Priority (Weeks 2-3)
- [ ] Add editors scenario
- [ ] Add fonts scenario
- [ ] Enhance verification assertions
- [ ] Create integration test

### Phase 3: Medium Priority (Weeks 4-6)
- [ ] Add KDE-apps scenario
- [ ] Implement parallel testing
- [ ] Create test matrix
- [ ] Add negative tests

### Phase 4: Continuous (Ongoing)
- [ ] Monitor test quality metrics
- [ ] Refactor as needed
- [ ] Add new scenarios for new roles
- [ ] Update documentation

---

## Success Metrics

**By End of Phase 2:**
- ✅ 100% idempotence (all scenarios pass)
- ✅ 60%+ role coverage (16/27 roles)
- ✅ 75+ assertions across all scenarios
- ✅ <10 minute total test time

**By End of Phase 3:**
- ✅ 80%+ role coverage (22/27 roles)
- ✅ 100+ assertions
- ✅ <5 minute parallel test time
- ✅ Test matrix implemented

**By End of Phase 4:**
- ✅ 90%+ role coverage (24/27 roles)
- ✅ Mutation testing implemented
- ✅ Continuous monitoring active
- ✅ Test quality dashboard

---

## Resources and References

### Molecule Documentation
- [Molecule Docs](https://molecule.readthedocs.io/)
- [Ansible Testing Guide](https://docs.ansible.com/ansible/latest/dev_guide/testing.html)

### Testing Best Practices
- [Test-Driven Development for Ansible](https://www.ansible.com/blog/testing-ansible-roles-with-molecule)
- [Idempotence in Ansible](https://docs.ansible.com/ansible/latest/reference_appendices/test_strategies.html)

### CI/CD Integration
- [GitHub Actions + Molecule](https://github.com/ansible-community/molecule-action)
- [GitLab CI + Molecule](https://gitlab.com/ansible-community/molecule-gitlab-ci)

---

**Document Version:** 1.0
**Last Updated:** 2026-02-19
**Next Review:** After Phase 2 completion
