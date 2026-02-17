# COMPONENT: TESTING

**Core Logic**: Multi-layered validation strategy.

## TOOLS
*   `validate.sh`: Canonical POSIX shell tool. Runs ON target. 30+ criteria.
*   `remote_test.sh`: Full lifecycle integration. Remote trigger.
*   `molecule/`: Unit/Role verification in containers.

## CONVENTIONS
*   **Fail-Fast**: Immediate exit on failure.
*   **Non-Circular**: `validate.sh` uses native commands, NOT Ansible modules.
*   **Completion**: Task incomplete without passing `validate.sh`.

## ANTI-PATTERNS
*   **Production Use**: NEVER run `remote_test.sh` on live systems.
*   **Skipping**: Deployment status invalid without validation run.

[Root Guidelines](../AGENTS.md)
