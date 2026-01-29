# GitHub Copilot Resources untuk VPS-Workstation

Folder ini berisi koleksi agents, instructions, prompts, dan skills yang relevan dengan project RDP Workstation automation.

## 📁 Struktur Folder

### `/agents`
Agents yang tersedia untuk mendukung workflow development:
- **arch.agent.md** - Architecture design dan decision making
- **adr-generator.agent.md** - Architecture Decision Records generator
- **api-architect.agent.md** - API design dan architecture
- **azure-principal-architect.agent.md** - Cloud architecture (Azure)
- **devops-expert.agent.md** - DevOps best practices dan automation
- **se-security-reviewer.agent.md** - Security review dan hardening
- **se-system-architecture-reviewer.agent.md** - System architecture review

### `/instructions`
Instructions untuk berbagai teknologi dan best practices:
- **ansible.instructions.md** - Ansible automation best practices
- **shell.instructions.md** - Shell scripting guidelines
- **powershell.instructions.md** - PowerShell scripting
- **code-review-generic.instructions.md** - Code review guidelines
- **containerization-docker-best-practices.instructions.md** - Docker best practices
- **github-actions-ci-cd-best-practices.instructions.md** - GitHub Actions CI/CD
- **kubernetes-deployment-best-practices.instructions.md** - Kubernetes deployment
- **ai-prompt-engineering-safety-best-practices.instructions.md** - AI prompt engineering

### `/prompts`
Prompts untuk berbagai task automation:
- **architecture-blueprint-generator.prompt.md** - Generate architecture blueprints
- **create-architectural-decision-record.prompt.md** - Create ADR documents
- **breakdown-epic-arch.prompt.md** - Break down epic to architecture tasks
- **breakdown-feature-implementation.prompt.md** - Break down features to implementation
- **breakdown-plan.prompt.md** - Create breakdown plans
- **breakdown-test.prompt.md** - Generate test breakdown
- **create-github-action-workflow-specification.prompt.md** - GitHub Actions workflow spec
- **project-workflow-analysis-blueprint-generator.prompt.md** - Workflow analysis
- **create-implementation-plan.prompt.md** - Implementation planning
- **create-readme.prompt.md** - Generate README
- **readme-blueprint-generator.prompt.md** - README blueprint
- **documentation-writer.prompt.md** - Documentation generation
- **review-and-refactor.prompt.md** - Code review and refactoring

### `/skills`
Skills untuk berbagai development tasks:
- **git-commit/** - Git commit message generation
- **github-issues/** - GitHub issues management
- **prd/** - Product Requirements Document generation
- **refactor/** - Code refactoring guidance
- **vscode-ext-commands/** - VS Code extension commands
- **webapp-testing/** - Web application testing

## 🚀 Cara Menggunakan

### Menggunakan Agents
Agents dapat digunakan untuk mode agentic di GitHub Copilot Chat:
```
@workspace /use-agent arch
```

### Menggunakan Instructions
Instructions dapat direferensikan dalam prompt atau disimpan di `.copilot-instructions.md`

### Menggunakan Prompts
Prompts dapat dipanggil langsung atau digunakan sebagai template:
```
/use-prompt architecture-blueprint-generator
```

### Menggunakan Skills
Skills dapat dipanggil sebagai context untuk task-specific guidance

## 📋 Workflow yang Didukung

1. **Phase 0 - Infrastructure Foundation**
   - Architecture design (arch.agent.md, architecture-blueprint-generator.prompt.md)
   - ADR creation (adr-generator.agent.md, create-architectural-decision-record.prompt.md)
   - Security review (se-security-reviewer.agent.md)

2. **Phase 1-2 - System Preparation & User Management**
   - Shell scripting (shell.instructions.md)
   - Ansible automation (ansible.instructions.md)
   - Security hardening (se-security-reviewer.agent.md)

3. **Phase 3-5 - Dependency Installation & Validation**
   - Implementation planning (create-implementation-plan.prompt.md)
   - Testing (breakdown-test.prompt.md, webapp-testing/)
   - Docker containerization (containerization-docker-best-practices.instructions.md)

4. **Phase 6-7 - Configuration Optimization & Validation**
   - Code review (code-review-generic.instructions.md)
   - Refactoring (refactor/, review-and-refactor.prompt.md)
   - DevOps automation (devops-expert.agent.md)

5. **Phase 8 - Enhancement & Documentation**
   - Documentation generation (documentation-writer.prompt.md, create-readme.prompt.md)
   - PRD creation (prd/)
   - GitHub workflow (github-issues/, git-commit/)

## 🔧 Integrasi dengan Project

Semua resources ini telah dipilih untuk mendukung:
- ✅ Automated RDP Workstation deployment
- ✅ Infrastructure as Code (Ansible)
- ✅ Security hardening dan compliance
- ✅ CI/CD automation
- ✅ Architecture documentation
- ✅ Testing dan validation
- ✅ Code quality dan review

## 📚 Referensi

- Sumber: [awesome-copilot](https://github.com/github/awesome-copilot)
- Project: VPS RDP Developer Workstation Automation
- Version: 1.0.0
