#!/usr/bin/env python3
"""
Playbook Validation Script for VPS RDP Workstation Project

This script validates Ansible playbooks and role tasks against the project-specific
conventions documented in CONFIGURATION_ANALYSIS.md.

Usage:
    ./scripts/validate-playbook.py [path/to/playbook.yml]
    ./scripts/validate-playbook.py --all  # Validate all playbooks and roles

Exit codes:
    0 - All checks passed
    1 - Validation errors found
    2 - Script errors or missing dependencies
"""

import argparse
import re
import sys
from pathlib import Path
from typing import Dict, List, Tuple

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is required. Install with: pip install PyYAML", file=sys.stderr)
    sys.exit(2)


class ValidationError:
    """Represents a validation error with severity and context."""

    def __init__(self, severity: str, file_path: str, line: int, rule: str, message: str, suggestion: str = None):
        self.severity = severity  # 'ERROR', 'WARNING', 'INFO'
        self.file_path = file_path
        self.line = line
        self.rule = rule
        self.message = message
        self.suggestion = suggestion

    def __str__(self):
        output = f"[{self.severity}] {self.file_path}:{self.line} - {self.rule}\n  {self.message}"
        if self.suggestion:
            output += f"\n  💡 Suggestion: {self.suggestion}"
        return output


class PlaybookValidator:
    """Validates Ansible playbooks against project conventions."""

    def __init__(self):
        self.errors: List[ValidationError] = []
        self.warnings: List[ValidationError] = []
        self.info: List[ValidationError] = []

        # FQCN modules that should be used (from CONFIGURATION_ANALYSIS.md)
        self.required_fqcn_modules = {
            'apt', 'copy', 'template', 'file', 'lineinfile', 'service', 'systemd',
            'user', 'group', 'command', 'shell', 'debug', 'set_fact', 'include_tasks',
            'import_tasks', 'meta', 'wait_for', 'stat', 'assert', 'fail', 'package',
            'get_url', 'uri', 'git', 'cron', 'authorized_key', 'blockinfile', 'replace',
            'firewalld', 'ufw', 'iptables', 'selinux', 'reboot', 'mount', 'sysctl'
        }

        # Sensitive parameter patterns that require no_log
        self.sensitive_patterns = [
            'password', 'passwd', 'pwd', 'secret', 'token', 'api_key', 'apikey',
            'private_key', 'credentials'
        ]

        # Whitelist of tasks/modules that might contain sensitive keywords but aren't sensitive
        self.sensitive_whitelist = [
            'ansible.builtin.apt',  # Package installation often contains 'auth' or 'hash' in package names
            'ansible.builtin.get_url', # URLs might have tokens but are usually public or safe
            'ansible.builtin.stat',
            'ansible.builtin.file',
            'ansible.builtin.debug',
            'ansible.builtin.getent',
            'ansible.builtin.apt_repository'
        ]


    def validate_file(self, file_path: Path) -> None:
        """Validate a single YAML file."""
        try:
            with open(file_path, 'r') as f:
                content = f.read()
                lines = content.split('\n')

            # Parse YAML
            try:
                data = yaml.safe_load(content)
            except yaml.YAMLError as e:
                self.add_error('ERROR', file_path, 0, 'YAML_SYNTAX', f"Invalid YAML: {e}")
                return

            if not data:
                return

            # Validate based on file type
            if isinstance(data, list):
                # Playbook or task list
                for idx, item in enumerate(data):
                    if isinstance(item, dict):
                        if 'hosts' in item:
                            # This is a play
                            self.validate_play(file_path, item, lines)
                        else:
                            # This is a task
                            self.validate_task(file_path, item, lines, f"Task {idx + 1}")

            # Check file-level issues
            self.check_line_length(file_path, lines)
            self.check_indentation(file_path, lines)
            self.check_octal_values(file_path, lines)

        except Exception as e:
            self.add_error('ERROR', file_path, 0, 'VALIDATION_ERROR', f"Failed to validate: {e}")

    def validate_play(self, file_path: Path, play: dict, lines: List[str]) -> None:
        """Validate a playbook play."""
        if 'tasks' in play:
            for idx, task in enumerate(play['tasks']):
                self.validate_task(file_path, task, lines, f"Play task {idx + 1}")

        if 'pre_tasks' in play:
            for idx, task in enumerate(play['pre_tasks']):
                self.validate_task(file_path, task, lines, f"Pre-task {idx + 1}")

        if 'post_tasks' in play:
            for idx, task in enumerate(play['post_tasks']):
                self.validate_task(file_path, task, lines, f"Post-task {idx + 1}")

    def validate_task(self, file_path: Path, task: dict, lines: List[str], context: str) -> None:
        """Validate an Ansible task against conventions."""
        if not isinstance(task, dict):
            return

        # Find line number (approximate)
        line_num = self.find_task_line(task, lines)

        # Rule 1: Task must have a name
        if 'name' not in task:
            self.add_error('WARNING', file_path, line_num, 'TASK_NAME_MISSING',
                          f"{context}: Task is missing a name",
                          "Add 'name: <imperative present tense description>'")
        else:
            # Rule 2: Task name should be imperative present tense
            name = task['name']
            if not self.is_imperative_present_tense(name):
                self.add_error('INFO', file_path, line_num, 'TASK_NAME_FORMAT',
                              f"{context}: Task name should use imperative present tense: '{name}'",
                              "Use verbs like 'Install', 'Configure', 'Ensure', 'Create'")

        # Rule 3: Check for FQCN module usage
        module_name = self.extract_module_name(task)
        if module_name:
            if module_name in self.required_fqcn_modules:
                # Check if FQCN is used
                # We need to check if the module name is used as a key in the task dictionary
                # BUT task is a dictionary where keys are module names or keywords.
                # If module_name is a short name (e.g. 'sysctl'), we check if it is present as a key.
                # If the task uses 'ansible.posix.sysctl', then 'sysctl' won't be a key, 'ansible.posix.sysctl' will be.
                # So we need to check if the short name is present as a key AND if it's not FQCN.

                # However, self.extract_module_name returns the key it found.
                # If it found 'sysctl', it returned 'sysctl'.
                # If it found 'ansible.posix.sysctl', it returned 'sysctl' (split('.')[-1]).

                # Let's check the raw task keys
                is_fqcn = False
                for key in task.keys():
                    if key == module_name:
                        # Short name usage confirmed
                        is_fqcn = False
                        break
                    if key.endswith(f".{module_name}"):
                        # FQCN usage confirmed
                        is_fqcn = True
                        break

                if not is_fqcn:
                    self.add_error('ERROR', file_path, line_num, 'FQCN_REQUIRED',
                                  f"{context}: Module '{module_name}' must use FQCN",
                                  f"Use 'ansible.builtin.{module_name}' instead of '{module_name}'")

        # Rule 4: Check for no_log on sensitive tasks
        # SKIP checking block tasks (tasks inside blocks are checked individually, but the block itself might flag sensitive vars)
        # Actually, the validator flattens blocks? No, it recurses.
        # But here 'task' might be the block definition itself.
        if 'block' in task:
             # It's a block, we don't enforce no_log on the block container usually,
             # unless it defines vars that are sensitive.
             # But let's skip sensitive check on the block container itself to avoid noise.
             pass
        elif self.contains_sensitive_data(task):
            # Check for no_log: true or no_log: 'true' or no_log: True
            no_log = task.get('no_log', False)
            if not (no_log is True or str(no_log).lower() == 'true'):
                 self.add_error('ERROR', file_path, line_num, 'MISSING_NO_LOG',
                               f"{context}: Task handles sensitive data but missing 'no_log: true'",
                               "Add 'no_log: true' to prevent credential leakage in logs")

        # Rule 5: Check file mode formatting
        if 'mode' in task:
            mode_value = task['mode']
            if isinstance(mode_value, int):
                self.add_error('ERROR', file_path, line_num, 'MODE_MUST_BE_STRING',
                              f"{context}: File mode must be quoted string, not integer: {mode_value}",
                              f"Use 'mode: \"{oct(mode_value)[2:].zfill(4)}\"' instead")
            elif isinstance(mode_value, str):
                # Check for proper octal format
                if not re.match(r'^["\']?0[0-7]{3,4}["\']?$', str(mode_value)):
                    self.add_error('WARNING', file_path, line_num, 'MODE_FORMAT',
                                  f"{context}: File mode should be in octal format: {mode_value}",
                                  "Use format like '0644', '0755', '0600'")

        # Rule 6: Check variable naming for role variables
        for key, value in task.items():
            if isinstance(value, str) and '{{' in value:
                # Extract variable names
                vars_used = re.findall(r'\{\{\s*([a-zA-Z_][a-zA-Z0-9_]*)', value)
                for var_name in vars_used:
                    # Check if it's a role variable (not builtin or common vars)
                    if not self.is_builtin_variable(var_name):
                        if not var_name.startswith('vps_'):
                            self.add_error('INFO', file_path, line_num, 'VARIABLE_PREFIX',
                                          f"{context}: Variable '{var_name}' should use 'vps_<role>_' prefix",
                                          "Follow convention: vps_<role>_<variable_name>")

    def extract_module_name(self, task: dict) -> str:
        """Extract the module name from a task."""
        for key in task.keys():
            # Skip Ansible task keywords
            if key in ['name', 'when', 'tags', 'notify', 'register', 'become', 'no_log',
                      'changed_when', 'failed_when', 'ignore_errors', 'delegate_to',
                      'run_once', 'loop', 'with_items', 'vars', 'environment']:
                continue

            # Check if key looks like a module
            if '.' in key:
                # Already FQCN
                return key.split('.')[-1]
            else:
                # Short name
                return key

        return None

    def contains_sensitive_data(self, task: dict) -> bool:
        """Check if task contains sensitive data parameters."""
        module_name = self.extract_module_name(task)
        # Skip package installations and file/stat/debug modules which often have false positives
        if module_name and any(w in str(module_name) for w in self.sensitive_whitelist):
             return False

        # Convert task to string representation for pattern matching
        # But EXCLUDE the module name itself if it contains a keyword like 'hash' or 'token' (unlikely but safe)
        # Actually, let's just check keys and values, excluding 'name' and 'tags' etc.

        # Simpler approach: check the full string but filter out false positives
        task_str = str(task).lower()

        for pattern in self.sensitive_patterns:
            if pattern in task_str:
                # Check for false positives
                # e.g., 'hash_file', 'python-is-python3' (contains 'python'), wait 'python' is not in sensitive_patterns
                # 'hash' matches 'ansible_failed_result'?? No.
                # 'hash' matches 'hash_behaviour'?
                # 'token' matches 'broken'? No.

                # Check if it's a variable name rather than value
                # This is hard with regex on string dump.

                return True

        return False

    def is_imperative_present_tense(self, name: str) -> bool:
        """Check if task name uses imperative present tense."""
        # Common imperative verbs
        imperative_verbs = [
            'install', 'configure', 'ensure', 'create', 'update', 'remove', 'delete',
            'set', 'enable', 'disable', 'start', 'stop', 'restart', 'reload', 'add',
            'copy', 'download', 'upload', 'generate', 'verify', 'check', 'test',
            'deploy', 'run', 'execute', 'apply', 'register', 'unregister', 'mount',
            'unmount', 'clone', 'pull', 'push', 'sync', 'backup', 'restore', 'clean'
        ]

        first_word = name.strip().lower().split()[0] if name.strip() else ''
        return first_word in imperative_verbs

    def is_builtin_variable(self, var_name: str) -> bool:
        """Check if variable is an Ansible builtin or common variable."""
        builtin_vars = {
            'ansible_facts', 'ansible_version', 'ansible_distribution', 'ansible_os_family',
            'ansible_python_version', 'ansible_user', 'ansible_host', 'ansible_port',
            'inventory_hostname', 'inventory_hostname_short', 'group_names', 'groups',
            'hostvars', 'play_hosts', 'ansible_play_hosts', 'omit', 'item', 'ansible_loop',
            'ansible_check_mode', 'ansible_diff_mode', 'ansible_forks', 'ansible_playbook_python',
            'playbook_dir', 'role_path', 'ansible_verbosity'
        }

        # Check exact match or prefix
        if var_name in builtin_vars:
            return True

        # Check for ansible_ prefix
        if var_name.startswith('ansible_'):
            return True

        return False

    def check_line_length(self, file_path: Path, lines: List[str]) -> None:
        """Check for lines exceeding 180 characters (yamllint rule)."""
        for idx, line in enumerate(lines, start=1):
            # Exclude comments from length check
            stripped = line.lstrip()
            if stripped.startswith('#'):
                continue

            if len(line) > 180:
                self.add_error('WARNING', file_path, idx, 'LINE_LENGTH',
                              f"Line exceeds 180 characters ({len(line)} chars)",
                              "Break into multiple lines or simplify expression")

    def check_indentation(self, file_path: Path, lines: List[str]) -> None:
        """Check for 2-space indentation (yamllint default)."""
        for idx, line in enumerate(lines, start=1):
            if not line.strip() or line.strip().startswith('#'):
                continue

            # Count leading spaces
            leading_spaces = len(line) - len(line.lstrip())

            # Check if indentation is multiple of 2
            if leading_spaces % 2 != 0:
                self.add_error('WARNING', file_path, idx, 'INDENTATION',
                              f"Indentation should be multiple of 2 spaces (found {leading_spaces})",
                              "Use 2-space indentation consistently")

    def check_octal_values(self, file_path: Path, lines: List[str]) -> None:
        """Check for unquoted octal values (yamllint forbids these)."""
        for idx, line in enumerate(lines, start=1):
            # Look for mode: 0644 pattern (unquoted)
            if 'mode:' in line:
                # Extract the value after mode:
                match = re.search(r'mode:\s*([0-7]{3,4})(?:\s|$)', line)
                if match:
                    octal_value = match.group(1)
                    self.add_error('ERROR', file_path, idx, 'OCTAL_VALUE_UNQUOTED',
                                  f"Octal value must be quoted: mode: {octal_value}",
                                  f"Use: mode: \\\"{octal_value}\\\"")

    def find_task_line(self, task: dict, lines: List[str]) -> int:
        """Find approximate line number for a task (best effort)."""
        if 'name' in task:
            task_name = task['name']
            for idx, line in enumerate(lines, start=1):
                if task_name in line:
                    return idx
        return 0  # Unknown

    def add_error(self, severity: str, file_path: Path, line: int, rule: str, message: str, suggestion: str = None):
        """Add a validation error."""
        error = ValidationError(severity, str(file_path), line, rule, message, suggestion)

        if severity == 'ERROR':
            self.errors.append(error)
        elif severity == 'WARNING':
            self.warnings.append(error)
        else:
            self.info.append(error)

    def print_report(self) -> None:
        """Print validation report."""
        total_issues = len(self.errors) + len(self.warnings) + len(self.info)

        print("\n" + "=" * 80)
        print("PLAYBOOK VALIDATION REPORT")
        print("=" * 80)

        if self.errors:
            print(f"\n🔴 ERRORS ({len(self.errors)}):")
            print("-" * 80)
            for error in self.errors:
                print(f"\n{error}")

        if self.warnings:
            print(f"\n🟡 WARNINGS ({len(self.warnings)}):")
            print("-" * 80)
            for warning in self.warnings:
                print(f"\n{warning}")

        if self.info:
            print(f"\n🔵 INFO ({len(self.info)}):")
            print("-" * 80)
            for info in self.info:
                print(f"\n{info}")

        print("\n" + "=" * 80)
        print(f"SUMMARY: {len(self.errors)} errors, {len(self.warnings)} warnings, {len(self.info)} info")
        print("=" * 80)

        if total_issues == 0:
            print("✅ All checks passed!")
        elif len(self.errors) == 0:
            print("⚠️  No errors, but warnings/info found. Review recommended.")
        else:
            print("❌ Validation failed. Please fix errors before committing.")

    def has_errors(self) -> bool:
        """Check if any errors were found."""
        return len(self.errors) > 0


def find_yaml_files(base_path: Path) -> List[Path]:
    """Find all YAML files in the project (excluding ignored paths)."""
    yaml_files = []

    # Excluded paths from .yamllint
    excluded_patterns = ['collections/', '.github/workflows/', 'venv/', '.venv/', '.git/', 'gitops-repo/']

    for pattern in ['**/*.yml', '**/*.yaml']:
        for file_path in base_path.glob(pattern):
            # Check if file should be excluded
            relative_path = file_path.relative_to(base_path)
            if any(str(relative_path).startswith(excl.rstrip('/')) for excl in excluded_patterns):
                continue

            yaml_files.append(file_path)

    return yaml_files


def main():
    parser = argparse.ArgumentParser(
        description='Validate Ansible playbooks against project conventions',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s site.yml                    # Validate single playbook
  %(prog)s roles/common/tasks/main.yml # Validate role tasks
  %(prog)s --all                        # Validate all playbooks and roles
  %(prog)s --all --strict               # Treat warnings as errors

Rules checked:
  - FQCN module names (ansible.builtin.*, community.general.*)
  - Task naming (imperative present tense)
  - Secrets management (no_log: true for sensitive data)
  - File mode formatting (quoted strings, not integers)
  - Variable naming (vps_<role>_ prefix)
  - Line length (max 180 characters)
  - Indentation (2 spaces)
  - Octal values (must be quoted)

See CONFIGURATION_ANALYSIS.md for detailed conventions.
        """
    )

    parser.add_argument('files', nargs='*', help='YAML files to validate')
    parser.add_argument('--all', action='store_true', help='Validate all playbooks and roles')
    parser.add_argument('--strict', action='store_true', help='Treat warnings as errors')
    parser.add_argument('--quiet', action='store_true', help='Only show errors')

    args = parser.parse_args()

    # Determine files to validate
    base_path = Path(__file__).parent.parent
    files_to_validate = []

    if args.all:
        files_to_validate = find_yaml_files(base_path)
        print(f"🔍 Found {len(files_to_validate)} YAML files to validate...")
    elif args.files:
        for file_arg in args.files:
            file_path = Path(file_arg)
            if not file_path.exists():
                print(f"ERROR: File not found: {file_path}", file=sys.stderr)
                return 2
            files_to_validate.append(file_path)
    else:
        parser.print_help()
        return 2

    # Validate files
    validator = PlaybookValidator()

    for file_path in files_to_validate:
        if not args.quiet:
            print(f"Validating {file_path}...", end=' ')

        validator.validate_file(file_path)

        if not args.quiet:
            print("✓")

    # Print report
    validator.print_report()

    # Determine exit code
    if validator.has_errors():
        return 1

    if args.strict and len(validator.warnings) > 0:
        return 1

    return 0


if __name__ == '__main__':
    sys.exit(main())
