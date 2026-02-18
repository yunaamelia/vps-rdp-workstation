# PROJECT DOCUMENTATION HUB

**Generated:** Wed Feb 18 07:45:00 AM UTC 2026
**Scope**: Technical specifications, security policies, and implementation guides.

## OVERVIEW
Central repository for all system-level documentation and project planning.

*   **Architecture**: Logic flow from fresh VPS to hardened workstation (`ARCHITECTURE.md`).
*   **Security**: Comprehensive policy for network, logs, and credentials (`SECURITY.md`).
*   **Troubleshooting**: Runbook for common connection and service failures (`TROUBLESHOOTING.md`).
*   **Implementation Plans**: Multi-phase design for complex features (e.g., `PLAN-whitesur-full-theme.md`).

## STRUCTURE
| File | Role |
|------|------|
| `QUICK_START.md` | 10-minute setup guide for new users. |
| `ARCHITECTURE.md` | Master technical design and role dependency graph. |
| `SECURITY.md` | Hardening standards and vulnerability reporting. |
| `TROUBLESHOOTING.md` | Service recovery and log inspection commands. |
| `CONFIGURATION.md` | Exhaustive reference for global and role-specific variables. |
| `DEPLOYMENT.md` | CI/CD patterns and manual staging procedures. |
| `ANTI_PATTERNS.md` | Common mistakes and deprecated configurations. |

## CONVENTIONS
*   **Standards**: Strict adherence to GitHub Flavored Markdown (GFM).
*   **Structure**: Mandatory H2/H3 hierarchy; NO H1 in body text.
*   **Line Length**: Hard wrap at 80 characters for terminal readability.
*   **Diagrams**: Mermaid.js for flowcharts; ASCII for simple directory trees.
*   **Commands**: Copy-paste ready blocks with `bash` or `yaml` syntax highlighting.

## ANTI-PATTERNS
*   **Outdated Content**: NEVER leave deprecated installation steps in live docs.
*   **Plaintext Secrets**: Do not use placeholders that look like real credentials.
*   **Deep Nesting**: Avoid H4+ headings; restructure content if logic is too deep.
*   **Mangled Formatting**: NO unclosed blocks or broken internal links.
