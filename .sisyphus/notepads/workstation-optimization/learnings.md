## Learnings - Docker Role Update

- **Lazydocker Installation**: Replaced shell script installation with `ansible.builtin.get_url` and `ansible.builtin.unarchive` for better idempotency and security.
- **Dynamic Versioning**: Used `ansible.builtin.uri` to fetch the latest release tag from GitHub API, ensuring the latest version is always installed without manual updates.
- **Clean Extraction**: Implemented a pattern of downloading to `/tmp`, extracting to a temporary directory, and then copying the binary to `/usr/local/bin` to keep the filesystem clean.
