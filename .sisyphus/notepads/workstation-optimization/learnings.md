# Workstation Optimization Learnings

## System Architecture
- Debian-based workstation (likely Debian 12/13)
- Ansible-managed configuration
- Roles split by function (desktop, terminal, performance, etc.)

## Critical Conventions
- **Idempotency**: All playbooks must be re-runnable without side effects.
- **Variables**: Use `inventory/group_vars/all.yml` for globals.
- **Tags**: Use specific tags for selective execution (e.g., `tags: [tools, performance]`).
- **Security**: Don't downgrade security posture unless explicitly required.

## Known Constraints
- Terminal role structure should be patched, not rewritten.
- Polonium conflicts with Karousel (Karousel is preferred).
