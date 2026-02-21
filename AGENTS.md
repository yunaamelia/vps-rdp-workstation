# PROJECT KNOWLEDGE BASE

**Generated:** Fri Feb 20 02:12:25 AM UTC 2026
**Commit:** a3c30ec
**Branch:** main

**Scope**: Ansible IaC — Debian 13 VPS → security-hardened RDP developer workstation with KDE Plasma.

## STRUCTURE

```
vps-rdp-workstation/
├── setup.sh              # CANONICAL ENTRY. Validates env, hashes secrets, injects Mitogen.
├── ansible.cfg           # Pipelining, custom callbacks, fact caching.
├── inventory/            # hosts.yml + group_vars/all.yml (config root).
├── playbooks/            # main.yml (orchestration), rollback.yml, templates/.
├── roles/                # 27 flat roles, each with AGENTS.md + uninstall.yml.
├── plugins/              # callback/ (rich_tui.py, clean_progress.py), mitogen/.
├── molecule/             # 31 test scenarios (one per role + default/chaos).
├── tests/                # validate.sh (30 criteria), remote_test.sh, smoke-test.sh.
├── scripts/              # Utility: reset_vps.sh, strict-validate.sh, validate-playbook.py.
├── docs/                 # ARCHITECTURE.md, SECURITY.md, TROUBLESHOOTING.md.
└── gitops-repo/          # ArgoCD/FluxCD manifests for Kubernetes deployments.
```

## WHERE TO LOOK

| Task                | Location                           | Notes                                                               |
| ------------------- | ---------------------------------- | ------------------------------------------------------------------- |
| **Add Feature**     | `roles/<new_role>/`                | Create role, add to `playbooks/main.yml`, create Molecule scenario. |
| **Change Config**   | `inventory/group_vars/all.yml`     | Global variables prefixed `vps_`.                                   |
| **Test Role**       | `molecule/<role>/`                 | `molecule test -s <role>`. Privileged containers for systemd.       |
| **Validate System** | `tests/validate.sh`                | Runs ON target. 30+ criteria (FR, SR, QR, DR).                      |
| **Debug**           | `/var/log/vps-setup.log`           | Full log. `/var/log/vps-setup-summary.log` for summary.             |
| **Progress State**  | `/var/lib/vps-setup/progress.json` | Resume after failure with `--resume`.                               |
| **ARA Reports**     | `ara playbook list`                | SQLite DB at `/var/log/ara-database.sqlite`.                        |

## EXECUTION ORDER (27 Roles)

```
Phase 1:  common (foundation, packages, users)
Phase 2:  security (UFW, fail2ban, SSH hardening) ← MUST run before services
Phase 3:  fonts (Nerd Fonts)
Phase 4:  desktop (KDE Plasma, SDDM)
Phase 5:  xrdp (RDP server, port 3389)
Phase 6:  kde-optimization (Polonium tiling, configs)
Phase 7:  kde-apps (Konsole, Dolphin)
Phase 8:  whitesur-theme (macOS-style theming)
Phase 9:  terminal (Kitty backup, Konsole profiles)
Phase 10: shell-styling (Starship, prompts)
Phase 11: zsh-enhancements (autosuggestions, fzf-tab, forgit)
Phase 12: development (Node.js, Python, PHP)
Phase 13: docker (Engine, Compose V2)
Phase 14: editors (VS Code, OpenCode AI)
Phase 15: tui-tools
Phase 16: network-tools
Phase 17: system-performance
Phase 18: text-processing
Phase 19: file-management
Phase 20: dev-debugging
Phase 21: code-quality
Phase 22: productivity
Phase 23: log-visualization
Phase 24: ai-devtools
Phase 25: cloud-native
Phase 26-27: monitoring (final phase)
```

## CONVENTIONS

- **Wrapper**: ALWAYS use `setup.sh`. Handles secret hashing, Mitogen injection, env validation.
- **Variable Prefix**: `vps_<role>_<feature>` (e.g., `vps_docker_install`, `vps_xrdp_allow_root`).
- **FQCN**: Mandatory `ansible.builtin.*`, `community.general.*`.
- **Tagging**: Schema `[phase, role, feature]` for granular execution.
- **Idempotency**: All roles safe for repeat runs. Test with `--check --diff`.
- **Line Length**: 180 chars max (`.yamllint`).

## PYTHON PLUGINS

### KEY FILES

- `plugins/callback/clean_progress.py`: Minimalist. Unicode ✓/✗ icons. Low-dependency fallback.
- `plugins/callback/rich_tui.py`: Full TUI. Spinners, tables, colors. Requires `rich` library.
- `plugins/mitogen/`: Vendored Mitogen v0.3.21 for 2-7x speedup.

### CONVENTIONS

- **Inheritance**: MUST inherit from `ansible.plugins.callback.CallbackBase`.
- **Documentation**: MUST include `DOCUMENTATION` YAML block for autodiscovery.
- **Redaction**: Handle `vps_user_password_hash` to prevent secret leakage.
- **Degradation**: Graceful fallback if `rich` missing (wrap imports in try/except).
- **pipx Gotcha**: `setup.sh` injects `rich` into pipx-managed Ansible environments.

### ANTI-PATTERNS

- **Blocking I/O**: NEVER synchronous network/disk I/O in callback methods.
- **Direct Import**: Never import `rich` at module level; wrap in try/except.
- **Stdout Noise**: Strictly format or swallow unrestricted stdout.

## ANTI-PATTERNS (PROJECT-WIDE)

- **Plaintext Secrets**: NEVER store passwords/hashes in vars, inventory, or logs.
- **Direct Execution**: NEVER run `ansible-playbook` directly; use `setup.sh` wrapper.
- **Security Reordering**: NEVER move `security` role after service roles (`desktop`, `xrdp`).
- **Root RDP**: NEVER allow root login via RDP in production (`vps_xrdp_allow_root: false`).
- **Hardcoded Users**: ALWAYS use `{{ vps_username }}`, never assume UID 1000.
- **Live Testing**: NEVER run `remote_test.sh` on production systems.
- **Global Handlers**: Forbidden in roles; use role-local handlers only.

## CI/CD

- **12 GitHub Actions workflows** in `.github/workflows/`.
- `ci.yml`: Lint + syntax + Molecule on push/PR. `ci-enhanced.yml`, `ci-parallel.yml`: extended variants.
- `deploy-pipeline.yml`: Staging → production with approval gates. Auto-rollback on failure.
- `security-scan.yml`: Weekly Trivy scan, SARIF to GitHub Security tab.
- `validate-playbooks.yml`: Syntax + lint gate. `weekly-integration.yml`: scheduled full integration.
- `ai-review.yml`: AI-powered PR review. `issue-triage.yml`: automated issue labeling.
- Discord webhook notifications on deploy. Pre-commit hooks configured.

## UNIQUE PATTERNS

- **Mitogen Strategy**: Vendored in `plugins/mitogen/`. Injected by `setup.sh` dynamically.
- **Progress Tracking**: `/var/lib/vps-setup/progress.json` enables `--resume` after failure.
- **ARA Integration**: Auto-records all runs to SQLite for post-run analysis.
- **Non-Circular Validation**: `validate.sh` uses native shell commands, not Ansible modules.
- **Systemd-in-Docker**: Molecule uses `privileged: true` with cgroup mounts for XRDP/UFW testing.
- **Role AGENTS.md**: Each of 27 roles has its own AGENTS.md for granular context.
- **3-Level Tagging**: `[phase, role, feature]` enables precise execution targeting.
