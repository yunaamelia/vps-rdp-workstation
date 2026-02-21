# COMPONENT: GITHUB CONFIGURATION

**Scope**: CI/CD workflows, AI agent definitions, prompt templates, coding instructions.

## STRUCTURE

```
.github/
├── workflows/     # 12 GitHub Actions CI/CD pipelines
├── agents/        # 20 AI agent role definitions (.agent.md)
├── instructions/  # 17 coding standard instructions (.instructions.md)
├── prompts/       # 24 reusable prompt templates (.prompt.md)
└── scripts/       # Helper scripts (create_secret_file.py)
```

## WORKFLOWS

| Workflow                   | Trigger              | Purpose                                         |
| -------------------------- | -------------------- | ----------------------------------------------- |
| `ci.yml`                   | push/PR              | Lint + syntax-check + Molecule tests             |
| `ci-enhanced.yml`          | push/PR              | Extended CI with additional checks               |
| `ci-parallel.yml`          | push/PR              | Parallel role testing for speed                  |
| `deploy-pipeline.yml`      | manual/tag           | Staging → production with approval gates         |
| `deploy.yml` / `deploy-staging.yml` | manual      | Direct deployment targets                        |
| `security-scan.yml`        | weekly cron          | Trivy scan, SARIF → GitHub Security tab          |
| `validate-playbooks.yml`   | push/PR              | Playbook syntax validation                       |
| `ai-review.yml`            | PR                   | AI-assisted code review                          |
| `weekly-integration.yml`   | weekly cron          | Full integration test suite                      |

## CONVENTIONS

- **Secrets**: Dual checking pattern — skip (not fail) when secrets missing for forks/PRs.
- **Notifications**: Discord webhook on failure. Configure via repository secrets.
- **Rollback**: `deploy-pipeline.yml` triggers automatic rollback on failure.
- **Molecule**: CI uses `molecule test` with Docker driver; same images as local dev.
- **Agent files**: `.agent.md` suffix for AI agent definitions; `.instructions.md` for standards.

## ANTI-PATTERNS

- **Hardcoded secrets**: Use GitHub repository secrets, never inline values.
- **Missing SARIF upload**: Security scan results must go to GitHub Security tab.

[Root Guidelines](../AGENTS.md)
