## Learnings - Docker Role Update

- **Lazydocker Installation**: Replaced shell script installation with `ansible.builtin.get_url` and `ansible.builtin.unarchive` for better idempotency and security.
- **Dynamic Versioning**: Used `ansible.builtin.uri` to fetch the latest release tag from GitHub API, ensuring the latest version is always installed without manual updates.
- **Clean Extraction**: Implemented a pattern of downloading to `/tmp`, extracting to a temporary directory, and then copying the binary to `/usr/local/bin` to keep the filesystem clean.

## Learnings - Font Configuration

- **Font Rendering**: Configured `fontconfig` (~/.config/fontconfig/conf.d/10-rendering.conf) to enforce RGB subpixel rendering and slight hinting, significantly improving text clarity in RDP sessions.
- **Ansible Check Mode**: Discovered that running `ansible-playbook --check` requires passing dummy values for required variables (like `vps_user_password_hash`) if the playbook performs pre-flight validation on them.

## Terminal Optimization (Wave 1 Patch)
- **Starship Performance**: Increased `command_timeout` to 500ms to prevent timeouts in large git repositories. `scan_timeout` was already set to 10ms.
- **Modern Aliases**: Added conditional alias `alias diff='delta'` to `zshrc.j2`. This ensures `delta` is used for diffs if installed, complementing existing `eza` (ls) and `bat` (cat) aliases.
- **Template Management**: `zshrc.j2` is located in `roles/shell-styling/templates/`, not `roles/terminal/`. This role handles the polished "final" zshrc.

## System Performance Tuning
- **VFS Cache Pressure**: Set to 50 (default 100) to reclaim inode/dentry cache faster, which is beneficial for development workstations handling many small files.
- **Dirty Ratios**: Lowered `vm.dirty_ratio` to 10 and `vm.dirty_background_ratio` to 5. This forces more frequent but smaller writes to disk, preventing large IO stalls during heavy compilations or data transfers.
- **I/O Schedulers**: Implemented udev rules to assign `none` for NVMe (lowest overhead), `mq-deadline` for SSDs, and `bfq` for rotational drives to optimize desktop responsiveness.
- **OOMD**: Enabled `systemd-oomd` for better userspace out-of-memory handling, which can prevent hard system freezes by killing resource-hogging cgroups earlier.
