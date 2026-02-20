# COMPONENT: DOCUMENTATION

**Scope**: Technical specifications, security policies, implementation guides.

## KEY FILES

| File                 | Purpose                                      |
| -------------------- | -------------------------------------------- |
| `ARCHITECTURE.md`    | Master design + role dependency graph        |
| `SECURITY.md`        | Hardening standards, vulnerability reporting |
| `TROUBLESHOOTING.md` | Service recovery, log inspection commands    |
| `CONFIGURATION.md`   | Exhaustive variable reference                |
| `ANTI_PATTERNS.md`   | Common mistakes + deprecated configs         |
| `QUICK_START.md`     | 10-minute setup guide                        |

## CONVENTIONS

- **Format**: GitHub Flavored Markdown (GFM).
- **Structure**: H2/H3 hierarchy; NO H1 in body text.
- **Line Length**: Hard wrap at 80 chars for terminal readability.
- **Diagrams**: Mermaid.js for flowcharts; ASCII for directory trees.
- **Commands**: Copy-paste ready blocks with `bash`/`yaml` syntax highlighting.

## ANTI-PATTERNS

- **Outdated Content**: NEVER leave deprecated installation steps in live docs.
- **Plaintext Secrets**: Don't use placeholders that look like real credentials.
- **Deep Nesting**: Avoid H4+ headings; restructure if logic too deep.
- **Broken Links**: NO unclosed blocks or broken internal links.

[Root Guidelines](../AGENTS.md)
