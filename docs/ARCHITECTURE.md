# Architecture Overview

VPS RDP Workstation system architecture and design decisions.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    VPS RDP Workstation                      │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   setup.sh  │──│   Ansible   │──│      20 Roles       │  │
│  │  Entry Point│  │   Engine    │  │  (Ordered by deps)  │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│  PHASE 1: Foundation                                        │
│  ├── common (apt, timezone, locale)                         │
│  └── security (UFW, Fail2ban, SSH hardening)  ← CRITICAL   │
├─────────────────────────────────────────────────────────────┤
│  PHASE 2: Desktop Environment                               │
│  ├── fonts (JetBrains Mono, Powerline)                      │
│  ├── desktop (KDE Plasma, XRDP, Nordic theme)               │
│  └── terminal (Zsh, Oh My Zsh, Agnoster)                    │
├─────────────────────────────────────────────────────────────┤
│  PHASE 3: Development Stack                                 │
│  ├── development (Node.js, Python, PHP)                     │
│  ├── docker (Engine, Compose)                               │
│  └── editors (VS Code, extensions)                          │
├─────────────────────────────────────────────────────────────┤
│  PHASE 4: Tool Suites                                       │
│  ├── tui-tools, network-tools, system-performance           │
│  ├── text-processing, file-management, dev-debugging        │
│  └── code-quality, productivity, log-visualization          │
└─────────────────────────────────────────────────────────────┘
```

## Security-First Design

**Firewall-First Principle**: Security role runs BEFORE desktop role.

```
Role Order: common → security → fonts → desktop → ...
                        ↑
                    FIREWALL ACTIVE
                    before XRDP installed
```

## Role Dependencies

```
common (base)
    ↓
security (firewall, fail2ban)
    ↓
fonts ───────────────────────┐
    ↓                        │
desktop (depends: common,    │
         security, fonts) ←──┘
    ↓
development
    ↓
docker (depends: common)
    ↓
editors (depends: development)
    ↓
tool-roles (depends: common)
```

## Directory Structure

```
vps-rdp-workstation/
├── setup.sh                 # Entry point
├── ansible.cfg              # Ansible configuration
├── inventory/
│   ├── hosts.yml            # Target hosts
│   └── group_vars/all.yml   # Default variables
├── playbooks/
│   ├── main.yml             # Primary playbook
│   └── rollback.yml         # Rollback mechanism
├── roles/                   # 20 Ansible roles
├── plugins/callback/        # Custom output plugin
├── templates/               # Jinja2 templates
├── tests/                   # Validation scripts
└── docs/                    # Documentation
```

## Key Design Decisions

1. **Idempotent**: All roles can run multiple times safely
2. **Modular**: Each role is independent, tagged for selective runs
3. **Secure**: No plain-text passwords, checksums on downloads
4. **Beautiful**: Custom callback plugin for progress display
