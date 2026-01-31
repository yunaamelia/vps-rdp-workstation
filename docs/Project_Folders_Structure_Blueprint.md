# Project Folders Structure Blueprint

**Generated:** 2026-01-31
**Classification:** ⚠️ INTERNAL USE ONLY
**Project:** VPS RDP Developer Workstation
**Project Type:** Ansible Automation (YAML + Jinja2 + Bash)

---

## Structural Overview

This project follows a **layered Ansible architecture** organized by:
- **Execution Layer:** `playbooks/` - Orchestration and phase tasks
- **Reusability Layer:** `roles/` - Modular, reusable components
- **Configuration Layer:** `inventory/` - Host and variable definitions
- **Template Layer:** `templates/` - Dynamic configuration files
- **Validation Layer:** `tests/` - Phase-specific test scripts
- **Utility Layer:** `scripts/` - Helper scripts for deployment

**Organizational Principle:** Phase-based deployment (10 phases) with corresponding rollback capabilities.

---

## Directory Visualization (ASCII)

```
vps-rdp-workstation/
├── .agent/                    # AI agent configuration (2515 files)
├── .github/                   # GitHub workflows and prompts
│   └── prompts/               # Copilot prompt templates
├── ansible.cfg                # Ansible configuration
├── requirements.yml           # Ansible collection dependencies
├── setup.sh                   # Main entry point script
│
├── inventory/                 # Host and variable configuration
│   ├── hosts.yml              # Target host definitions
│   ├── group_vars/
│   │   └── all.yml            # Global configuration variables
│   └── test_server.yml        # Test environment config
│
├── playbooks/                 # Ansible playbooks
│   ├── main.yml               # Primary orchestration (10 phases)
│   ├── rollback.yml           # Rollback orchestration
│   ├── provision_user.yml     # Standalone user provisioning
│   ├── handlers/
│   │   └── main.yml           # Service restart handlers
│   ├── tasks/                 # Phase implementations
│   │   ├── phase1-preparation.yml
│   │   ├── phase2-user-management.yml
│   │   ├── phase3-dependencies.yml
│   │   ├── phase4-desktop-environment.yml
│   │   ├── phase5-development-tools.yml
│   │   ├── phase6-validation.yml
│   │   ├── phase7-optimization.yml
│   │   ├── phase8-enhancements.yml
│   │   ├── phase9-enhancements.yml
│   │   └── phase8-final-validation.yml
│   └── rollback/              # Phase-specific rollback tasks
│       ├── phase1-rollback.yml ... phase9-rollback.yml
│
├── roles/                     # Reusable Ansible roles (12 roles)
│   ├── checkpoint/            # Deployment state management
│   ├── common/                # Base system configuration
│   ├── desktop/               # KDE/XRDP desktop setup
│   ├── development/           # Git, global packages
│   ├── docker/                # Docker CE installation
│   ├── editors/               # VS Code, IDEs
│   ├── enhancements/          # Terminal tools, plugins (24 files)
│   ├── fonts/                 # Nerd fonts
│   ├── security/              # UFW, Fail2ban, SSH hardening
│   ├── terminal/              # Zsh, Starship
│   ├── user_config/           # User-specific settings
│   └── validation/            # Deployment validation
│
├── templates/                 # Jinja2 configuration templates
│   ├── starship.toml.j2       # Prompt configuration
│   ├── zshrc.j2               # Shell configuration
│   ├── xrdp.ini.j2            # RDP server config
│   └── docker-daemon.json.j2  # Docker settings
│
├── files/                     # Static files
│   └── scripts/               # User utility scripts
│       ├── auto-backup.sh
│       ├── daily-dev-start.sh
│       └── setup-github-ssh.sh
│
├── scripts/                   # Deployment helper scripts
│   ├── pre-flight-checks.sh   # System requirements validation
│   ├── create-checkpoint.sh   # Snapshot creation
│   └── rollback-to-checkpoint.sh
│
├── tests/                     # Validation test scripts
│   ├── comprehensive-validation.sh
│   ├── phase1-tests.sh ... phase8-tests.sh
│
└── docs/                      # Documentation
    ├── PROJECT-WORKFLOW-DOCUMENTATION.md
    ├── EXEMPLARS.md
    └── Technology_Stack_Blueprint.md
```

---

## Key Directory Analysis

### `playbooks/` - Orchestration Layer

| Directory | Purpose | Contents |
|-----------|---------|----------|
| `playbooks/` | Main execution | `main.yml`, `rollback.yml` |
| `playbooks/tasks/` | Phase implementations | `phase{1-9}-*.yml` files |
| `playbooks/rollback/` | Undo operations | `phase{1-9}-rollback.yml` |
| `playbooks/handlers/` | Service management | Restart triggers |

### `roles/` - Reusability Layer

| Role | Purpose | Complexity |
|------|---------|------------|
| `enhancements/` | Terminal tools, CLI utilities | 24 files (largest) |
| `desktop/` | KDE Plasma, XRDP optimization | 4 files |
| `security/` | UFW, Fail2ban, SSH hardening | 3 files |
| `common/` | Base packages, performance | 3 files |
| `docker/` | Docker CE installation | 2 files |

### `inventory/` - Configuration Layer

| File | Purpose |
|------|---------|
| `hosts.yml` | Target host (localhost) |
| `group_vars/all.yml` | **Primary configuration** (194 lines) |
| `test_server.yml` | Test environment overrides |

---

## Naming Conventions

| Component | Pattern | Example |
|-----------|---------|---------|
| **Phase Task** | `phase{N}-{name}.yml` | `phase1-preparation.yml` |
| **Rollback** | `phase{N}-rollback.yml` | `phase3-rollback.yml` |
| **Role** | `{feature}` (lowercase) | `desktop`, `security` |
| **Template** | `{config}.j2` | `zshrc.j2` |
| **Test Script** | `phase{N}-tests.sh` | `phase5-tests.sh` |
| **Handler** | `Restart {Service}` | `Restart XRDP` |
| **Variable** | `snake_case` | `vps_username`, `xrdp_port` |

---

## File Placement Patterns

### Adding a New Phase

```
playbooks/
├── tasks/phase{N}-{name}.yml     # Implementation
├── rollback/phase{N}-rollback.yml # Rollback logic
tests/
├── phase{N}-tests.sh              # Validation tests
```

### Adding a New Role

```
roles/{role_name}/
├── defaults/main.yml     # Default variables
├── tasks/main.yml        # Main tasks
├── handlers/main.yml     # Service handlers
├── templates/            # Jinja2 templates
├── files/                # Static files
└── meta/main.yml         # Role metadata
```

### Adding a New Template

```
templates/{service}.{ext}.j2
# Include header: # {{ ansible_managed }}
```

---

## Extension Templates

### New Feature Template

```yaml
# playbooks/tasks/phase{N}-{feature}.yml
---
#===============================================================================
# Phase N: Feature Name
#===============================================================================
# Brief description of what this phase does
#===============================================================================

- name: Task description
  ansible.builtin.MODULE:
    param: "{{ variable }}"
  when: condition | default(true)

- name: Mark Phase N complete
  ansible.builtin.copy:
    content: |
      Phase N: Feature Name - COMPLETE
      Timestamp: {{ ansible_date_time.iso8601 }}
    dest: "{{ vps_setup_log_dir }}/phaseN-complete.txt"
    mode: '0644'
```

### New Role Template

```
roles/new_role/
├── defaults/
│   └── main.yml          # new_role_enabled: true
├── tasks/
│   └── main.yml          # Primary tasks
├── handlers/
│   └── main.yml          # notify: Restart NewService
└── meta/
    └── main.yml          # dependencies: []
```

---

## File Statistics

| Directory | Files | Purpose |
|-----------|-------|---------|
| `roles/enhancements/` | 24 | Terminal enhancement tools |
| `playbooks/` | 23 | Orchestration + phase tasks |
| `scripts/` | 11 | Utility scripts |
| `templates/` | 9 | Configuration templates |
| `tests/` | 9 | Validation scripts |
| `.github/` | 2637 | Workflows, prompts, AI config |

**Total Project Files:** ~2,800+ (including `.agent/` and `.github/`)

---

## Navigation Guide

### Entry Points
1. **`setup.sh`** - Main deployment entry point
2. **`playbooks/main.yml`** - Ansible orchestration
3. **`inventory/group_vars/all.yml`** - Configuration

### Common Tasks

| Task | Location |
|------|----------|
| Add new software | `playbooks/tasks/phase5-development-tools.yml` |
| Change security settings | `playbooks/tasks/phase7-optimization.yml` |
| Modify desktop config | `roles/desktop/tasks/` |
| Add terminal tools | `roles/enhancements/tasks/` |
| Update tests | `tests/comprehensive-validation.sh` |

---

*Last Updated: 2026-01-31 | Maintain this blueprint when adding new phases or restructuring.*
