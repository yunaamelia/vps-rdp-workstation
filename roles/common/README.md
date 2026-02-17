# Ansible Role: common

## Description
[CUSTOMIZE: Brief description of what this role does]

## Requirements
- Ansible >= 2.9
- Supported OS: Ubuntu 20.04+, Debian 11+

## Role Variables

Available variables are listed below, along with default values (see `defaults/main.yml`):

```yaml
# [CUSTOMIZE: Document key variables from defaults/main.yml]
```

## Dependencies

See `meta/main.yml` for role dependencies.

## Example Playbook

```yaml
---
- hosts: workstations
  become: yes
  roles:
    - role: common
      vars:
        # [CUSTOMIZE: Add example variable overrides]
```

## License
MIT

## Author Information
Created by racoondev for VPS RDP Workstation automation project.
