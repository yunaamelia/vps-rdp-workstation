# SCRIPTS KNOWLEDGE BASE

## OVERVIEW
The `scripts/` directory contains auxiliary automation for system lifecycle management:
*   **Setup**: Initial configuration of specialized services (FluxCD, ArgoCD).
*   **Maintenance**: System reset and environment teardown.
*   **Verification**: Strict validation of Ansible playbooks and runtime results.
*   **Theming**: Post-deployment UI/UX refinements for the KDE Plasma desktop.

## STRUCTURE
| Script | Purpose |
| :--- | :--- |
| `setup_flux.sh` | Bootstraps Flux CD on the target Kubernetes cluster. |
| `strict-validate.sh` | Execution wrapper that fails if warnings or skipped tasks exceed thresholds. |
| `reset_vps.sh` | Destructive cleanup; reverts OS to a "fresh" state. Use with caution. |
| `validate-playbook.py` | Python-based linter for playbook structure and best practices. |
| `apply-whitesur-kde.sh` | Configures macOS-style visuals on KDE Plasma. |
| `generate-cmdb.sh` | Extracts host metadata into a flat JSON/CSV inventory. |

## CONVENTIONS
*   **Shebangs**: Use `#!/bin/bash` for shell and `#!/usr/bin/env python3` for Python.
*   **Safety**: All shell scripts must start with `set -euo pipefail`.
*   **Permissions**: Files must have the executable bit (`+x`) set.
*   **Arguments**: Use `getopts` or standard long-flag patterns for CLI parameters.
*   **Logs**: Direct output to `/tmp/vps-script-<name>.log` if backgrounding.

## ANTI-PATTERNS
*   **Hardcoded Paths**: Never use `/home/user`. Use `$HOME` or dynamic resolution.
*   **Sudo in Scripts**: Avoid embedding `sudo`. The wrapper `setup.sh` handles escalation.
*   **Interactive Prompts**: Scripts should be non-interactive (use flags or environment variables).
*   **Global Installs**: Python scripts should not `pip install` globally; use Ansible's pip module or venvs.

## VALIDATION PROTOCOL
Run `strict-validate.sh` before any PR merge. It enforces:
1. Zero Ansible errors.
2. Zero "unreachable" hosts.
3. Warning count < 5.
4. Changed count matches expected scope.
