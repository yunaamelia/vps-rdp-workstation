# COMPONENT: VALIDATION

**Scope**: Multi-layered testing strategy for deployment verification.

## TOOLS

| Script           | Purpose                      | Execution      |
| ---------------- | ---------------------------- | -------------- |
| `validate.sh`    | Canonical 30+ criteria check | ON target      |
| `remote_test.sh` | Full lifecycle integration   | Remote trigger |
| `smoke-test.sh`  | Quick health check           | ON target      |

## CRITERIA (validate.sh)

- **FR (Functional)**: Services running, packages installed, users created.
- **SR (Security)**: UFW active, fail2ban enabled, no plaintext secrets.
- **QR (Quality)**: Idempotency, lint compliance, no unreachable hosts.
- **DR (Documentation)**: Logs present, progress.json exists.

## CONVENTIONS

- **Fail-Fast**: `set -euo pipefail`. Immediate exit on failure.
- **Non-Circular**: Uses native shell (`systemctl`, `dpkg`, `grep`), NOT Ansible modules.
- **Requirement Mapping**: Tests map to FR-1, SR-2, etc. IDs.
- **Completion**: Deployment invalid without passing `validate.sh`.

## ANTI-PATTERNS

- **Production Use**: NEVER run `remote_test.sh` on live systems.
- **Skipping**: Deployment status invalid without validation run.
- **Ansible Verification**: Don't use Ansible modules to verify Ansible state.

[Root Guidelines](../AGENTS.md)
