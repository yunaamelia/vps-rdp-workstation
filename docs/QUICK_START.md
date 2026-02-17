# Quick Start Guide

**New to this project? Start here.** This guide gets you from zero to your first successful playbook run in under 10 minutes.

## Prerequisites Checklist

Before you begin, ensure you have:

- [ ] **Ansible 2.9+** installed (`ansible --version`)
- [ ] **Python 3.8+** installed (`python3 --version`)
- [ ] **SSH access** to target Debian 13 (Trixie) servers
- [ ] **Root access** or sudo privileges on target servers

## First 5 Minutes: Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd vps-rdp-workstation
```

### 2. Install Dependencies

```bash
# Install Python dependencies (validation tools)
pip install -r requirements-dev.txt

# Install Ansible Galaxy collections
ansible-galaxy collection install -r requirements.yml

# Install pre-commit hooks (optional but recommended)
pip install pre-commit
pre-commit install
```

### 3. Configure Your Inventory

Edit `inventory/hosts.yml` with your target servers:

```yaml
---
all:
  children:
    vps_servers:
      hosts:
        vps-prod-01:
          ansible_host: 192.168.1.100
          ansible_user: root
          vps_hostname: dev-workstation-01

        vps-prod-02:
          ansible_host: 192.168.1.101
          ansible_user: root
          vps_hostname: dev-workstation-02
```

### 4. Test Connectivity

```bash
# Ping all hosts to verify SSH access
ansible all -m ansible.builtin.ping

# Expected output:
# vps-prod-01 | SUCCESS => {
#     "changed": false,
#     "ping": "pong"
# }
```

## Your First Playbook Run

### Dry Run (Recommended First Step)

```bash
# Check what would happen without making changes
ansible-playbook site.yml --check --diff
```

**What to look for:**
- ✅ Green `ok` statuses = Host is reachable
- ⚠️  Yellow `changed` = Changes would be made
- ❌ Red `failed` = Something is wrong (check error message)

### Execute the Full Playbook

```bash
# Run the complete VPS setup (all 10 phases)
ansible-playbook site.yml

# Expected duration: 15-30 minutes (depending on network speed)
```

### Run Specific Phases

```bash
# Phase 1: Security hardening only
ansible-playbook site.yml --tags security

# Phase 3: Window Manager (Openbox) only
ansible-playbook site.yml --tags wm

# Phase 5: Development tools only
ansible-playbook site.yml --tags devtools
```

**Available tags**: `security`, `wm`, `rdp`, `themes`, `devtools`, `docker`, `browsers`, `multimedia`, `services`, `finalize`

## Common Commands Cheat Sheet

### Inventory Management

```bash
# List all hosts
ansible all --list-hosts

# List hosts in specific group
ansible vps_servers --list-hosts

# View host variables
ansible-inventory --host vps-prod-01 --yaml
```

### Playbook Execution

```bash
# Limit execution to specific host
ansible-playbook site.yml --limit vps-prod-01

# Increase verbosity for debugging
ansible-playbook site.yml -vvv

# Start from specific task
ansible-playbook site.yml --start-at-task="Install Docker Engine"

# Step through tasks one-by-one
ansible-playbook site.yml --step
```

### Validation & Testing

```bash
# Validate YAML formatting
yamllint .

# Check Ansible best practices
ansible-lint

# Run custom convention checks
./scripts/validate-playbook.py --all

# Syntax check only (fast)
ansible-playbook site.yml --syntax-check
```

### Configuration Override

```bash
# Disable SSH host key checking (use with caution)
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook site.yml

# Use different inventory
ansible-playbook site.yml -i inventory/staging.yml

# Run with 5 parallel forks (default is 10)
ansible-playbook site.yml --forks=5
```

## Understanding Project Structure

```
vps-rdp-workstation/
├── site.yml                    # Main playbook entry point
├── ansible.cfg                 # Ansible behavior settings ⚙️
├── .yamllint                   # YAML formatting rules 📏
├── requirements.yml            # Ansible Galaxy collections 📦
│
├── inventory/
│   └── hosts.yml              # Your target servers 🎯
│
├── roles/                     # 10 sequential roles (phases)
│   ├── 01-common/            # Base system setup
│   ├── 02-security/          # Security hardening 🔒
│   ├── 03-windowmanager/     # Openbox WM
│   ├── 04-rdp/              # xRDP configuration
│   ├── 05-themes/           # UI themes & customization
│   ├── 06-devtools/         # Developer tooling
│   ├── 07-docker/           # Docker Engine
│   ├── 08-browsers/         # Chromium & Firefox
│   ├── 09-multimedia/       # Audio/video support
│   └── 10-finalize/         # System optimization
│
├── scripts/
│   ├── validate-playbook.py  # Convention validator ✅
│   └── README.md             # Script documentation
│
└── docs/
    ├── CONFIGURATION_ANALYSIS.md  # Configuration deep-dive 📖
    └── QUICK_START.md            # This file
```

## Configuration Deep-Dive

For detailed explanations of **why** settings are configured the way they are, see:

📖 **[CONFIGURATION_ANALYSIS.md](../CONFIGURATION_ANALYSIS.md)**

Key highlights:
- **Performance**: 10 parallel forks, SSH multiplexing, 24-hour fact caching
- **Security**: Host key checking disabled (internal VPS), privilege escalation via sudo
- **Reliability**: Smart fact gathering, 300-second SSH persistence, 60-second keepalive
- **Code Quality**: 180-char line limit, 2-space indentation, FQCN modules required

## Troubleshooting

### "SSH connection timeout"

**Cause**: Firewall blocking SSH or incorrect host IP

**Solution**:
```bash
# Test SSH directly
ssh root@<host-ip>

# If that works, test Ansible ping
ansible <hostname> -m ansible.builtin.ping -vvv
```

### "Host key verification failed"

**Cause**: SSH host key not in known_hosts

**Solution**:
```bash
# Add host key manually
ssh-keyscan -H <host-ip> >> ~/.ssh/known_hosts

# Or use host_key_checking=False (already set in ansible.cfg)
```

### "Permission denied (publickey)"

**Cause**: SSH key not authorized on target server

**Solution**:
```bash
# Copy your SSH public key to the server
ssh-copy-id root@<host-ip>

# Or manually append to authorized_keys
cat ~/.ssh/id_rsa.pub | ssh root@<host-ip> "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### "Module 'apt' not found"

**Cause**: Using short module name instead of FQCN

**Solution**:
```yaml
# ❌ WRONG
- apt:
    name: vim

# ✅ CORRECT
- ansible.builtin.apt:
    name: vim
```

### "yamllint errors on long lines"

**Cause**: Line exceeds 180 characters

**Solution**:
```yaml
# ❌ WRONG (too long)
- name: Install all development packages including compilers, debuggers, version control, editors, and utilities for comprehensive development environment setup
  ansible.builtin.apt: ...

# ✅ CORRECT (split description)
- name: Install comprehensive development environment packages
  ansible.builtin.apt: ...
```

### "Validation script fails"

**Cause**: Missing PyYAML dependency

**Solution**:
```bash
pip install PyYAML
```

## Next Steps

Once you've successfully run the playbook:

1. **Review the Results**:
   ```bash
   # SSH into your configured server
   ssh racoondev@<host-ip>

   # Verify services are running
   systemctl status xrdp
   docker --version
   ```

2. **Customize for Your Needs**:
   - Edit `group_vars/all.yml` for global variables
   - Modify role variables in `roles/<role>/defaults/main.yml`
   - Add custom tasks in role `tasks/main.yml` files

3. **Read the Documentation**:
   - 📖 [CONFIGURATION_ANALYSIS.md](../CONFIGURATION_ANALYSIS.md) - Understand the "why" behind settings
   - 📖 [README.md](../README.md) - Project overview and architecture
   - 📖 [.github/copilot-instructions.md](../.github/copilot-instructions.md) - Development conventions

4. **Set Up Your Workflow**:
   - Install pre-commit hooks: `pre-commit install`
   - Configure your editor with yamllint and ansible-lint plugins
   - Run validation before committing: `./scripts/validate-playbook.py --all`

## Getting Help

### Common Questions

**Q: Can I run this on Ubuntu/CentOS?**
A: No, this playbook is specifically designed for Debian 13 (Trixie). Package names, paths, and systemd configs are Debian-specific.

**Q: How do I add a new role?**
A: Create `roles/<phase>-<name>/` with `tasks/main.yml`, `defaults/main.yml`, and `handlers/main.yml`. Follow existing role structure.

**Q: Why are modules failing with "not found"?**
A: Ensure you've installed collections: `ansible-galaxy collection install -r requirements.yml`

**Q: Can I skip security hardening?**
A: Not recommended. If absolutely necessary: `ansible-playbook site.yml --skip-tags security` (but you'll have an insecure system).

**Q: How do I update the playbook?**
A: `git pull` to get latest changes, then `ansible-playbook site.yml` to apply updates.

### Need More Help?

- Review playbook output with verbose mode: `ansible-playbook site.yml -vvv`
- Check task logs in `/var/log/ansible.log` (if logging is enabled)
- Verify target system meets requirements in main README.md
- Consult Ansible documentation: https://docs.ansible.com/

## Pro Tips

1. **Use Mitogen** for 2-7x performance boost:
   ```bash
   pip install mitogen ansible==2.10.7
   # Already configured in ansible.cfg strategy_plugins path
   ```

2. **Cache Facts Across Runs**:
   - Already enabled with 24-hour cache (`ansible.cfg`)
   - Cached in `/tmp/ansible_facts_cache`
   - Clear cache: `rm -rf /tmp/ansible_facts_cache`

3. **SSH Connection Reuse**:
   - ControlMaster keeps connections alive for 5 minutes
   - Reduces overhead for multiple tasks to same host
   - Check active connections: `ls -la /tmp/ansible-ssh-*`

4. **Parallel Execution**:
   - Default: 10 forks (10 hosts in parallel)
   - Increase for large inventories: `ansible-playbook site.yml --forks=20`
   - Monitor with: `ansible-playbook site.yml --forks=10 -vv | grep TASK`

5. **Validation Workflow**:
   ```bash
   # Before committing changes
   yamllint .                              # Check YAML formatting
   ansible-lint                             # Check Ansible best practices
   ./scripts/validate-playbook.py --all    # Check project conventions
   ansible-playbook site.yml --check       # Dry run
   ```

## Welcome Aboard! 🚀

You're now ready to use and contribute to the VPS RDP Workstation project. The playbook is designed to be:

- **Idempotent**: Run it multiple times safely
- **Secure**: Security-first with hardening baked in
- **Fast**: Optimized with caching, pipelining, and parallelization
- **Maintainable**: Well-documented, linted, and validated

Happy automating! 🎉
