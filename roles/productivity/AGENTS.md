# COMPONENT: Productivity Role — Phase 16 (Tools)

**Context**: Productivity CLI tools (`thefuck`, `tldr`) with Python environment hacks.

## OVERVIEW
Installs `thefuck` into a dedicated virtual environment to isolate it from system Python. Patches the source code to work with Python 3.12+ (replacing removed `distutils`). Installs `tldr` via `pipx`.

## STRUCTURE
```
roles/productivity/
└── tasks/          # Venv creation → Install → Patch code → Symlink
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Venv Creation** | `tasks/main.yml:18-23` | Creates `/home/user/.local/share/venvs/thefuck` |
| **Git Install** | `tasks/main.yml:32-36` | Installs from git master (needed for Py3.12 compat) |
| **Code Patching** | `tasks/main.yml:54-73` | `replace` module to swap `distutils` with `shutil` in installed libs |
| **Zsh Integration** | `tasks/main.yml:83-93` | Adds `eval $(thefuck --alias)` to `.zshrc` |

## CONVENTIONS
*   **Isolation**: Uses dedicated venv for volatile Python tools.
*   **Hotfixing**: Directly patches installed python files to fix upstream incompatibilities.

## ANTI-PATTERNS
*   **Monkey Patching**: Modifying library code in `site-packages` via Regex is fragile.
*   **Git Master**: Installing from master branch is unstable but necessary here.
