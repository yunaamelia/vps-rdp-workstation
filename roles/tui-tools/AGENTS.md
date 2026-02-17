# COMPONENT: TUI Tools Role — Phase 16 (Tools)

**Context**: Terminal User Interface tools collection (LazyGit, Yazi, Bat, etc.).

## OVERVIEW
Installs a suite of modern CLI/TUI tools. Mixes `apt` packages, manual binary downloads (LazyGit), and GitHub release `.deb` installs (Yazi). Handles symlinks for name collisions (batcat -> bat).

## STRUCTURE
```
roles/tui-tools/
└── tasks/          # Apt installs → Symlinks → LazyGit → Yazi
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| **Apt Installs** | `tasks/main.yml:4-21` | tig, ranger, bat, ripgrep, etc. |
| **Symlinks** | `tasks/main.yml:24-38` | Aliases `batcat`->`bat`, `fdfind`->`fd` |
| **LazyGit DL** | `tasks/main.yml:41-65` | Versioned download with fallback to "latest" API |
| **Yazi Install** | `tasks/main.yml:82-94` | Fetches latest release tag from GitHub API, installs .deb |

## CONVENTIONS
*   **Name Normalization**: Enforces standard names (`bat`, `fd`) for Debian-renamed packages.
*   **Dynamic Versioning**: Queries GitHub API for latest releases when version not pinned.
*   **Fallback Logic**: LazyGit task tries specific version first, falls back to latest API.

## ANTI-PATTERNS
*   **Unverified Downloads**: GitHub API lookups don't verify checksums against a trusted source (relies on transport security).
*   **Manual Binary Placement**: Extracts LazyGit directly to `/usr/local/bin`.
