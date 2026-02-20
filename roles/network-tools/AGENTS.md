# ROLE: network-tools

**Purpose**: Network utilities and diagnostic tools (nmap, mtr, httpie, iftop).
**Phase**: 15-25

## TASKS

- `main.yml`: Installs nmap for port scanning, mtr for network diagnostics, httpie for HTTP CLI.
- `uninstall.yml`: Removes network tools, cleans up any elevated capability configurations.

## VARIABLES

- `vps_network_tools_install`: Boolean to enable/disable installation (default: true).
- `vps_network_tools_nmap_install`: Install nmap for network scanning (default: true).
- `vps_network_tools_mtr_install`: Install mtr for traceroute/ping hybrid (default: true).
- `vps_network_tools_httpie_install`: Install httpie for HTTP requests (default: true).
- `vps_network_tools_iftop_install`: Install iftop for bandwidth monitoring (default: true).

## DEPENDENCIES

- Common (for base packages and network access)
- None for network diagnostics

## ANTI-PATTERNS

- Installing nmap without documenting port scanning policies and compliance.
- Enabling raw socket access (nmap -sS) without security review.
- Not warning that mtr requires elevated privileges for ICMP.

[Root Guidelines](../../AGENTS.md)
