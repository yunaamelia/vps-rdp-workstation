# COMPONENT: Editors Role — Phase 7 (Dev)

**Context**: IDE installation — VS Code (apt repo), OpenCode (npm global), Antigravity (placeholder).

## OVERVIEW
Adds Microsoft GPG key + apt repo for VS Code, installs extensions in a loop, deploys `settings.json`. OpenCode installed via `community.general.npm`. Antigravity disabled by default — creates manual install note.

## STRUCTURE
```
roles/editors/
├── defaults/       # Toggle flags, extension list
└── tasks/          # VS Code → OpenCode → Antigravity → settings.json
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **MS GPG key** | `tasks/main.yml:23-29` | `/usr/share/keyrings/microsoft.asc`, stat-guarded |
| **Extension loop** | `tasks/main.yml:58-66` | `code --install-extension --force`, `failed_when` handles "already installed" |
| **OpenCode** | `tasks/main.yml:72-78` | `community.general.npm` global install |
| **settings.json** | `tasks/main.yml:98-111` | Deploys to `~/.config/Code/User/`, includes OpenCode serverPath |
| **Antigravity** | `tasks/main.yml:117-148` | Creates markdown install note when binary absent |

## KEY VARIABLES
| Variable | Default | Purpose |
|----------|---------|---------|
| `install_vscode` | `true` | Enable VS Code |
| `install_opencode` | `true` | Enable OpenCode AI agent |
| `install_antigravity` | `false` | Placeholder, disabled |
| `vscode_extensions` | 11 extensions | Loop list for `--install-extension` |

## CONVENTIONS
*   **Variable prefix deviation**: Uses `install_vscode`, NOT `vps_editors_install_vscode`. Legacy naming.
*   **Conflicting repo cleanup**: Removes old `/etc/apt/sources.list.d/vscode.list` and `.sources` before adding new repo.
*   **Extension idempotency**: `failed_when` allows rc!=0 if stdout contains "already installed".

## ANTI-PATTERNS
*   **changed_when: true on extensions**: Always reports changed. No reliable way to detect "already installed" as a skip.
*   **settings.json overwrite**: Full file replacement on every run — user customizations lost. Consider `community.general.json_patch` for surgical updates.
