# COMPONENT: UTILITY SCRIPTS

**Scope**: Auxiliary automation for system lifecycle management.

## KEY SCRIPTS

| Script                  | Purpose                                                             |
| ----------------------- | ------------------------------------------------------------------- |
| `reset_vps.sh`          | Destructive cleanup; reverts OS to "fresh" state. Use with caution. |
| `strict-validate.sh`    | Fails if warnings/skipped tasks exceed thresholds.                  |
| `validate-playbook.py`  | Python linter for playbook structure + best practices.              |
| `apply-whitesur-kde.sh` | Post-deployment macOS-style theming for KDE.                        |
| `generate-cmdb.sh`      | Extracts host metadata to JSON/CSV inventory.                       |

## CONVENTIONS

- **Shebangs**: `#!/bin/bash` for shell, `#!/usr/bin/env python3` for Python.
- **Safety**: Shell scripts MUST start with `set -euo pipefail`.
- **Permissions**: All scripts must have executable bit (`+x`).
- **Arguments**: Use `getopts` or standard long-flag patterns.
- **Logs**: Background output to `/tmp/vps-script-<name>.log`.

## VALIDATION PROTOCOL (`strict-validate.sh`)

1. Zero Ansible errors
2. Zero unreachable hosts
3. Warning count < 5
4. Changed count matches expected scope

## ANTI-PATTERNS

- **Hardcoded Paths**: Never use `/home/user`. Use `$HOME` or dynamic resolution.
- **Sudo in Scripts**: Don't embed `sudo`; `setup.sh` handles escalation.
- **Interactive Prompts**: Scripts must be non-interactive (flags/env vars).
- **Global Installs**: Python scripts must not `pip install` globally.

[Root Guidelines](../AGENTS.md)
