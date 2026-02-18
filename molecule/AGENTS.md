# MOLECULE TESTING KNOWLEDGE BASE

## OVERVIEW
Container-based testing framework for validating Ansible roles and playbooks across multiple Debian environments.

## STRUCTURE
- **default**: Primary scenario for base system installation, security hardening, and RDP stack.
- **devtools**: Specialized scenario for IDEs, Docker, and development toolchain validation.
- **shell**: Scenario focused on ZSH enhancements, shell styling, and terminal configuration.
- **requirements.yml**: Collection dependencies required for testing execution.

## DRIVER
- **docker**: Uses `geerlingguy/docker-debian12-ansible` (or similar) to simulate the VPS environment.
- **privileged**: Required for systemd-based services like XRDP and UFW within containers.
- **cgroups**: Volumes mounted to host `/sys/fs/cgroup` to enable systemd control.

## PROVISIONER
- **ansible**: Core execution engine for converging roles onto test instances.
- **pipelining**: Enabled to minimize SSH/exec overhead during massive role applications.
- **env**: Environment variables control deprecation warnings and ANSIBLE_FORCE_COLOR.
- **config_options**: `defaults.interpreter_python` set to `/usr/bin/python3` for consistency.

## ANTI-PATTERNS
- **Privileged Mode Overuse**: Do not set `privileged: true` for roles that don't interact with kernel or systemd units.
- **State Leakage**: Avoid scenarios that depend on previous test execution state.
- **Slow Verification**: Prefer Ansible assertions over shell-scripted `verify.yml` where possible.
- **Missing Idempotency**: Failing to run the converge step twice to verify zero-change second runs.
