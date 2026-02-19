---
trigger: glob
globs:
  - "plugins/**/*.py"
  - "plugins/mitogen/**"
---

# Ansible Plugins Rules (Python)

> Source: [Red Hat Automation Good Practices §7](https://redhat-cop.github.io/automation-good-practices/#_plugins_good_practices)
> Python coding conventions: also see `@ansible-coding-style.md` for YAML docstrings inside DOCUMENTATION blocks.

## Violation Response Protocol

When reviewing or generating plugin Python code:
1. **MUST** flag top-level imports of optional libraries (`rich`, `prettytable`) without `try/except` guard.
2. **MUST** flag missing `DOCUMENTATION` block or `CALLBACK_VERSION` in callback plugins.
3. **MUST** flag `print()` calls — replace with `self._display.warning()` or `self._display.error()`.
4. **MUST** flag synchronous blocking I/O inside `v2_runner_*` methods.
5. **SHOULD** warn when a function lacks a Sphinx-style docstring.
6. **MUST NOT** generate `unittest`-based tests — use `pytest` exclusively.

## Severity Levels (RFC 2119)

- **MUST / MUST NOT**: Enforced — block or flag every occurrence.
- **SHOULD / SHOULD NOT**: Strongly encouraged — flag and suggest fix.
- **MAY**: Optional — mention only if directly relevant.

## Project Context: Plugins in this Workspace

This project contains:
- `plugins/callback/clean_progress.py` — minimalist stdout callback with unicode spinners.
- `plugins/callback/rich_tui.py` — advanced layout-based TUI using `rich`.
- `plugins/mitogen/` — Mitogen strategy plugin for 2–7× speedup (do not modify directly).

All custom callback plugins **MUST** follow the conventions below.

## Required Conventions

- **MUST** inherit from `ansible.plugins.callback.CallbackBase` for callback plugins.  `[PL-CONV-01]`
- **MUST** include a `DOCUMENTATION` string (YAML format) at module level.  `[PL-CONV-02]`
- **MUST** declare `CALLBACK_VERSION = 2.0` and `CALLBACK_TYPE`.  `[PL-CONV-03]`
- **MUST** follow [PEP 8](https://pep8.org/) style — enforced by `pylint`.  `[PL-CONV-04]`
- **MUST** include a header comment describing the plugin's purpose.  `[PL-CONV-05]`
- **MUST** add Sphinx docstrings to all function and method bodies.  `[PL-CONV-06]`

## Documentation

- **MUST** write `DOCUMENTATION`, `EXAMPLES`, and `RETURN` blocks for ALL plugin types.  `[PL-DOC-01]`
- **MUST** use **Sphinx (reStructuredText)** formatted docstrings:  `[PL-DOC-02]`
  ```python
  def process_result(self, result: TaskResult, failed: bool = False) -> None:
      """Process and display a task result.

      :param result: The Ansible task result object.
      :type result: TaskResult
      :param failed: Whether the task failed.
      :type failed: bool
      :returns: None
      :rtype: None
      """
  ```
- **MUST** use **Python type hints** for all function signatures:  `[PL-DOC-03]`
  ```python
  def v2_runner_on_ok(self, result: TaskResult) -> None:
  ```

## Testing

- **MUST** use **pytest** for all plugin tests.  `[PL-TEST-01]`
- **MUST NOT** use `unittest` — it is discouraged.  `[PL-TEST-02]`
- **SHOULD** develop new plugins using the **ansible plugin builder** (`ansible-creator`).  `[PL-TEST-03]`

## Safety and Performance

- **MUST** use `try/except` for ALL third-party imports with `HAS_*` flag fallbacks:  `[PL-SAFE-01]`
  ```python
  try:
      from rich.console import Console
      HAS_RICH = True
  except ImportError:
      HAS_RICH = False
  ```
- **MUST NOT** perform synchronous network requests or heavy disk I/O in `v2_runner_*` methods.  `[PL-SAFE-02]`
- **MUST NOT** import optional libraries at the top level without a safety wrapper.  `[PL-SAFE-03]`
- **MUST** keep plugin entry files minimal — delegate complex logic to helper modules.  `[PL-SAFE-04]`
- **MUST** respect `ansible_verbosity` levels or the `VPS_LOG_LEVEL` environment variable.  `[PL-SAFE-05]`

## Error Messages

- **MUST** use `self._display.warning()` and `self._display.error()` instead of `print()`.  `[PL-ERR-01]`
- **MUST** include context in messages (host name, task name) for actionable diagnostics.  `[PL-ERR-02]`
  ```python
  # CORRECT
  self._display.warning(f"[{result._host.name}] Package install failed: {msg}")
  # WRONG
  print(f"Failed: {msg}")
  ```

## Thread Safety

- **SHOULD NOT** maintain shared mutable state between `v2_runner_*` callback methods.  `[PL-THREAD-01]`
- **MAY** use `threading.Lock()` when shared state is unavoidable (e.g., progress counters).  `[PL-THREAD-02]`
