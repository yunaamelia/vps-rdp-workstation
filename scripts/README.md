# Validation Scripts

This directory contains validation and utility scripts for the VPS RDP Workstation project.

## validate-playbook.py

Validates Ansible playbooks and role tasks against project-specific conventions documented in `CONFIGURATION_ANALYSIS.md`.

### Features

- **FQCN Module Checking**: Ensures all core modules use Fully Qualified Collection Names (`ansible.builtin.*`)
- **Task Naming Convention**: Verifies imperative present tense naming
- **Secrets Management**: Detects sensitive data without `no_log: true`
- **File Mode Formatting**: Catches unquoted octal values (must be strings)
- **Variable Naming**: Checks for `vps_<role>_` prefix convention
- **YAML Lint Integration**: Validates line length (180 chars), indentation (2 spaces), octal values
- **Severity Levels**: ERROR (blocking), WARNING (should fix), INFO (suggestions)

### Usage

#### Validate a single playbook:
```bash
./scripts/validate-playbook.py site.yml
```

#### Validate role tasks:
```bash
./scripts/validate-playbook.py roles/common/tasks/main.yml
```

#### Validate all playbooks and roles:
```bash
./scripts/validate-playbook.py --all
```

#### Strict mode (warnings become errors):
```bash
./scripts/validate-playbook.py --all --strict
```

#### Quiet mode (errors only):
```bash
./scripts/validate-playbook.py --all --quiet
```

### Exit Codes

- `0` - All checks passed
- `1` - Validation errors found
- `2` - Script errors or missing dependencies

### Requirements

```bash
pip install PyYAML
```

### Integration with CI/CD

This script is automatically run by:
- **Pre-commit hooks**: `.pre-commit-config.yaml` (local validation)
- **GitHub Actions**: `.github/workflows/validate-playbooks.yml` (CI validation)

### Rules Checked

| Rule ID | Severity | Description |
|---------|----------|-------------|
| `YAML_SYNTAX` | ERROR | Invalid YAML syntax |
| `FQCN_REQUIRED` | ERROR | Core modules must use FQCN |
| `MISSING_NO_LOG` | ERROR | Sensitive data without `no_log: true` |
| `MODE_MUST_BE_STRING` | ERROR | File mode must be quoted string |
| `OCTAL_VALUE_UNQUOTED` | ERROR | Unquoted octal values forbidden |
| `TASK_NAME_MISSING` | WARNING | Task missing a name |
| `TASK_NAME_FORMAT` | INFO | Task name should be imperative |
| `VARIABLE_PREFIX` | INFO | Variables should use `vps_<role>_` prefix |
| `LINE_LENGTH` | WARNING | Line exceeds 180 characters |
| `INDENTATION` | WARNING | Non-standard indentation |

### Examples

#### ❌ WRONG - Will fail validation:
```yaml
- name: installing packages
  apt:  # Missing FQCN
    name: vim
    state: present

- copy:  # No task name
    src: config.conf
    dest: /etc/app/config.conf
    mode: 0644  # Unquoted octal

- name: Create user with password
  user:
    name: admin
    password: "{{ admin_password }}"  # Missing no_log!
```

#### ✅ CORRECT - Will pass validation:
```yaml
- name: Install required packages
  ansible.builtin.apt:  # FQCN used
    name: vim
    state: present

- name: Deploy application configuration
  ansible.builtin.copy:
    src: config.conf
    dest: /etc/app/config.conf
    mode: "0644"  # Quoted octal

- name: Create administrative user
  ansible.builtin.user:
    name: admin
    password: "{{ vps_security_admin_password_hash }}"  # Proper variable prefix
  no_log: true  # Prevents credential leakage
```

### Continuous Improvement

This validator is based on conventions documented in:
- `CONFIGURATION_ANALYSIS.md` - Configuration philosophy and rules
- `.github/copilot-instructions.md` - Project-specific guidelines
- `ansible.cfg` - Ansible behavior settings
- `.yamllint` - YAML formatting rules

As conventions evolve, update the validator to match.

### Troubleshooting

**"ModuleNotFoundError: No module named 'yaml'"**
```bash
pip install PyYAML
```

**"Permission denied"**
```bash
chmod +x scripts/validate-playbook.py
```

**"Too many false positives"**
- Use `--strict` mode only in CI/CD
- Adjust severity levels in the script if needed
- INFO messages are suggestions, not requirements

### Contributing

When adding new validation rules:
1. Update the `PlaybookValidator` class with new check methods
2. Add the rule to this README's "Rules Checked" table
3. Update `CONFIGURATION_ANALYSIS.md` with the convention
4. Add test cases to verify the rule works correctly

### Related Tools

- **yamllint**: YAML formatting (`yamllint .`)
- **ansible-lint**: Ansible best practices (`ansible-lint`)
- **ansible-playbook --syntax-check**: Basic syntax validation
- **Pre-commit**: Automated validation on commit (`.pre-commit-config.yaml`)
