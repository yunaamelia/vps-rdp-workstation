# ROLE: code-quality

**Purpose**: Linters and formatters for code quality assurance (shellcheck, hadolint).
**Phase**: 15-25

## TASKS

- `main.yml`: Installs shellcheck for bash validation, hadolint for Dockerfile linting.
- `uninstall.yml`: Removes shellcheck and hadolint, cleans configuration directories.

## VARIABLES

- `vps_code_quality_install`: Boolean to enable/disable installation (default: true).
- `vps_code_quality_shellcheck_install`: Install shellcheck for shell script linting (default: true).
- `vps_code_quality_hadolint_install`: Install hadolint for Dockerfile validation (default: true).
- `vps_code_quality_yamllint_install`: Install yamllint for YAML validation (default: true).
- `vps_code_quality_shellcheck_severity`: Minimum severity level for warnings (default: style).

## DEPENDENCIES

- Common (for package management)
- None for development workflow

## ANTI-PATTERNS

- Installing linters without integrating them into CI/CD pipelines.
- Disabling all warnings — use appropriate severity levels instead.
- Not updating linter rules when upgrading to newer versions.

[Root Guidelines](../../AGENTS.md)
