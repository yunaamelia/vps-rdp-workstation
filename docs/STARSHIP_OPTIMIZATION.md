# Starship Configuration Optimization - Implementation Guide

## Overview

This guide explains how to implement Starship prompt optimization in the VPS RDP Workstation project using the AI-assisted configuration optimizer.

## Files Created

1. **`.github/prompts/starship-optimizer.prompt.md`** - AI prompt for Starship optimization
2. **`docs/STARSHIP_OPTIMIZATION.md`** - This implementation guide
3. **Future**: `roles/starship/` - Ansible role for Starship configuration deployment

## Current Starship Configuration

Your current configuration at `~/.config/starship.toml`:

- Custom format with powerline-style separators
- Modules: directory, git, nodejs, rust, golang, php, time
- No performance optimizations applied
- No backup mechanism

## Implementation Plan

### Phase 1: Manual Optimization (Immediate)

Use the AI prompt to optimize your current configuration:

```bash
# 1. Backup current config
cp ~/.config/starship.toml ~/.config/starship.toml.backup.$(date +%Y%m%d_%H%M%S)

# 2. Use AI assistant with this prompt:
# "Using .github/prompts/starship-optimizer.prompt.md, optimize my Starship config at ~/.config/starship.toml
#  with theme_preference='catppuccin-mocha', performance_target=250,
#  modules_enabled=['directory', 'git', 'nodejs', 'rust', 'golang', 'php', 'character', 'cmd_duration']"

# 3. Test the new configuration
starship config  # Validate TOML syntax
time starship prompt  # Measure performance (should be <250ms)

# 4. Reload shell
source ~/.zshrc
```

### Phase 2: Ansible Role Creation (Recommended)

Create a dedicated Ansible role for Starship configuration:

```bash
# Create role structure
ansible-galaxy role init roles/starship

# Structure:
roles/starship/
├── defaults/
│   └── main.yml          # Default variables (theme, performance targets)
├── templates/
│   ├── starship.toml.j2  # Jinja2 template for config
│   └── presets/          # Theme presets
├── tasks/
│   └── main.yml          # Installation and configuration tasks
└── meta/
    └── main.yml          # Dependencies (requires: terminal role)
```

**Role Variables** (`roles/starship/defaults/main.yml`):

```yaml
---
# Starship Configuration
starship_version: "latest"
starship_config_dir: "{{ ansible_user_dir }}/.config"
starship_config_file: "{{ starship_config_dir }}/starship.toml"

# Performance Settings
starship_command_timeout: 250 # milliseconds
starship_scan_timeout: 10 # milliseconds

# Theme Configuration
starship_theme: "catppuccin-mocha" # or: tokyo-night, nord, gruvbox
starship_custom_palette: {} # Override colors

# Module Configuration
starship_modules_enabled:
  - directory
  - git_branch
  - git_status
  - character
  - cmd_duration
  - nodejs
  - python
  - rust
  - golang
  - php

starship_modules_disabled:
  - package # Expensive version scanning

# Backup Settings
starship_create_backup: true
starship_backup_dir: "{{ ansible_user_dir }}/.config/starship-backups"
```

**Tasks Example** (`roles/starship/tasks/main.yml`):

```yaml
---
# =============================================================================
#  Starship Prompt Configuration
# =============================================================================

- name: Create Starship config directory
  ansible.builtin.file:
    path: "{{ starship_config_dir }}"
    state: directory
    mode: "0755"
  tags: [starship, config]

- name: Create backup directory
  ansible.builtin.file:
    path: "{{ starship_backup_dir }}"
    state: directory
    mode: "0755"
  when: starship_create_backup
  tags: [starship, backup]

- name: Backup existing Starship config
  ansible.builtin.copy:
    src: "{{ starship_config_file }}"
    dest: "{{ starship_backup_dir }}/starship.toml.{{ ansible_date_time.iso8601_basic_short }}"
    mode: "0644"
    remote_src: true
  when: starship_create_backup
  ignore_errors: true
  tags: [starship, backup]

- name: Deploy optimized Starship configuration
  ansible.builtin.template:
    src: starship.toml.j2
    dest: "{{ starship_config_file }}"
    mode: "0644"
    backup: yes
  tags: [starship, config]

- name: Validate Starship configuration
  ansible.builtin.command:
    cmd: starship config
  changed_when: false
  failed_when: false
  register: starship_validation
  tags: [starship, validate]

- name: Display validation results
  ansible.builtin.debug:
    msg: "Starship config validation: {{ 'PASSED' if starship_validation.rc == 0 else 'FAILED' }}"
  tags: [starship, validate]
```

**Template Example** (`roles/starship/templates/starship.toml.j2`):

```toml
# ============================================
# Starship Prompt Configuration
# Generated: {{ ansible_date_time.iso8601 }}
# Theme: {{ starship_theme }}
# Performance Target: {{ starship_command_timeout }}ms
# ============================================

"$schema" = 'https://starship.rs/config-schema.json'

# Performance Settings (Critical)
command_timeout = {{ starship_command_timeout }}
scan_timeout = {{ starship_scan_timeout }}

# Theme Palette
palette = "{{ starship_theme }}"

{% if starship_theme == 'catppuccin-mocha' %}
[palettes.catppuccin-mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
subtext0 = "#a6adc8"
overlay2 = "#9399b2"
overlay1 = "#7f849c"
overlay0 = "#6c7086"
surface2 = "#585b70"
surface1 = "#45475a"
surface0 = "#313244"
base = "#1e1e2e"
mantle = "#181825"
crust = "#11111b"
{% endif %}

# Prompt Format
format = """
[](bg:surface0)\
$username\
$hostname\
[](fg:surface0 bg:surface1)\
$directory\
[](fg:surface1 bg:surface2)\
$git_branch\
$git_status\
[](fg:surface2)\
$fill\
$cmd_duration\
$line_break\
$character\
"""

# ============================================
# Module Configurations
# ============================================

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"
vimcmd_symbol = "[❮](bold green)"

[directory]
format = "[ $path ]($style)"
style = "fg:blue bg:surface1"
truncation_length = 3
truncate_to_repo = true
truncation_symbol = "…/"

[git_branch]
format = "[ $symbol$branch ]($style)"
style = "fg:green bg:surface2"
symbol = " "

[git_status]
format = "[$all_status$ahead_behind ]($style)"
style = "fg:red bg:surface2"

{% for module in starship_modules_enabled %}
{% if module in ['nodejs', 'python', 'rust', 'golang', 'php'] %}
[{{ module }}]
format = "[ $symbol($version) ]($style)"
style = "fg:yellow bg:surface2"
{% endif %}
{% endfor %}

[cmd_duration]
min_time = 500
format = "[ $duration ]($style)"
style = "fg:yellow"

# ============================================
# Disabled Modules (Performance)
# ============================================
{% for module in starship_modules_disabled %}
[{{ module }}]
disabled = true  # Performance optimization
{% endfor %}
```

### Phase 3: Integration with Main Playbook

Add to `playbooks/main.yml`:

```yaml
- role: starship
  tags: [terminal, starship, optimization]
  when: vps_install_starship_optimization | default(true)
```

Add to `inventory/group_vars/all.yml`:

```yaml
# Starship Prompt Optimization
vps_install_starship_optimization: true
vps_starship_theme: "catppuccin-mocha" # tokyo-night, nord, gruvbox
vps_starship_performance_target: 250 # milliseconds
```

### Phase 4: Usage Examples

**Optimize existing configuration:**

```bash
ansible-playbook playbooks/main.yml --tags starship
```

**Change theme:**

```bash
ansible-playbook playbooks/main.yml --tags starship -e "vps_starship_theme=tokyo-night"
```

**Validate configuration:**

```bash
ansible-playbook playbooks/main.yml --tags starship,validate --check
```

## Performance Benchmarking

Before optimization:

```bash
# Benchmark current config
for i in {1..10}; do time starship prompt > /dev/null; done
```

After optimization:

```bash
# Should be consistently < 250ms
time starship prompt
```

## Testing Checklist

- [ ] Configuration validates with `starship config`
- [ ] Prompt renders correctly in terminal
- [ ] All symbols display properly (requires Nerd Fonts)
- [ ] Performance < 250ms (`time starship prompt`)
- [ ] Git status updates correctly in repositories
- [ ] Language version modules work (Node.js, Python, etc.)
- [ ] Backup created before changes
- [ ] Rollback instructions documented

## Troubleshooting

**Symbols not displaying:**

```bash
# Ensure Nerd Fonts are installed
fc-list | grep -i "JetBrains"
```

**Slow prompt:**

```bash
# Profile Starship modules
starship timings
```

**Configuration errors:**

```bash
# Validate TOML syntax
starship config
```

**Revert to backup:**

```bash
cp ~/.config/starship-backups/starship.toml.YYYYMMDD_HHMMSS ~/.config/starship.toml
source ~/.zshrc
```

## References

- [Starship Official Docs](https://starship.rs/config/)
- [Starship Presets](https://starship.rs/presets/)
- [Performance Guide](https://starship.rs/advanced-config/#command-duration)
- [Project AI Prompt: `.github/prompts/starship-optimizer.prompt.md`](../.github/prompts/starship-optimizer.prompt.md)

---

**Next Steps:**

1. ✅ Test AI prompt with current configuration
2. ⏳ Create Ansible role (`roles/starship/`)
3. ⏳ Add to main playbook
4. ⏳ Document in README.md
5. ⏳ Add to CI/CD validation
