# ROLE: dev-debugging

**Purpose**: System debugging and tracing tools (strace, ltrace, gdb).
**Phase**: 15-25

## TASKS

- `main.yml`: Installs strace for system call tracing, ltrace for library call tracing.
- `uninstall.yml`: Removes strace, ltrace, and related debugging utilities.

## VARIABLES

- `vps_dev_debugging_install`: Boolean to enable/disable installation (default: true).
- `vps_dev_debugging_strace_install`: Install strace for system call debugging (default: true).
- `vps_dev_debugging_ltrace_install`: Install ltrace for library call tracing (default: true).
- `vps_dev_debugging_gdb_install`: Install gdb debugger (default: true).
- `vps_dev_debugging_enable_ptrace`: Allow unprivileged ptrace (may require sysctl changes).

## DEPENDENCIES

- Common (for base system packages)
- None for debugging workflow

## ANTI-PATTERNS

- Enabling ptrace globally without security review of implications.
- Forgetting to attach debugger to long-running processes with appropriate permissions.
- Not documenting that some tracing requires elevated privileges.

[Root Guidelines](../../AGENTS.md)
