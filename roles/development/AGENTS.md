# COMPONENT: Development Role — Phase 5 (Dev)

**Context**: Programming language stacks — Node.js, Python, PHP with package managers.

## OVERVIEW
Three independent sections, each guarded by a toggle: Node.js (NodeSource repo + npm globals), Python (apt + pipx tools), PHP (apt + Composer with signature verification).

## STRUCTURE
```
roles/development/
├── defaults/       # Toggle flags, package lists
└── tasks/          # 3 sections: nodejs → python → php
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Node.js GPG + repo** | `tasks/main.yml:8-47` | NodeSource keyring at `/usr/share/keyrings/nodesource.asc` |
| **npm globals** | `tasks/main.yml:66-74` | `shell` + `creates` for idempotency |
| **Python pipx** | `tasks/main.yml:107-115` | `shell` + `creates` pattern |
| **Composer** | `tasks/main.yml:140-174` | Signature verification via shell, `creates` on `/usr/local/bin/composer` |
| **Defaults** | `defaults/main.yml` | Package lists: `npm_global_packages`, `python_pipx_packages`, `php_extensions` |

## KEY VARIABLES
| Variable | Default | Purpose |
|----------|---------|---------|
| `install_nodejs` | `true` | Enable Node.js section |
| `install_python` | `true` | Enable Python section |
| `install_php` | `true` | Enable PHP section |
| `install_composer` | `true` | Enable Composer install |
| `npm_global_packages` | yarn, pnpm, typescript, ... | Global npm packages |
| `python_pipx_packages` | black, pylint, pytest, ... | pipx-managed tools |
| `php_extensions` | curl, mbstring, xml, ... | PHP extension list |

## CONVENTIONS
*   **Variable prefix deviation**: Uses `install_nodejs`, NOT `vps_development_install_nodejs`. Legacy naming.
*   **npm prefix**: Global packages install to `~/.npm-global/bin/` (user-scoped, not `/usr/lib`).
*   **Shell + creates**: Both npm and pipx use `shell` module with `creates` for idempotency — `creates` path derives from `item.split('@')[0]` or `item.split('[')[0]`.
*   **Composer verification**: Downloads `installer.sig` from GitHub, compares SHA-384 hash before install.

## ANTI-PATTERNS
*   **Shell module for npm/pipx**: Breaks strict idempotency — `changed_when: true` on npm config. Acceptable tradeoff for user-scoped installs.
*   **No rollback**: Failed npm/pipx installs leave partial state. Re-run is safe but won't clean up.
