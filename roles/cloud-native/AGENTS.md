# ROLE: cloud-native

**Purpose**: Kubernetes and container orchestration tools (kubectl, helm, k9s).
**Phase**: 15-25

## TASKS

- `main.yml`: Installs kubectl, helm, and k9s from official releases or apt repos.
- `uninstall.yml`: Removes kubectl, helm, k9s binaries and kubeconfig references.

## VARIABLES

- `vps_cloud_native_install`: Boolean to enable/disable installation (default: true).
- `vps_cloud_native_kubectl_install`: Install kubectl CLI (default: true).
- `vps_cloud_native_helm_install`: Install Helm package manager (default: true).
- `vps_cloud_native_k9s_install`: Install k9s TUI for cluster management (default: true).
- `vps_cloud_native_kubectl_version`: Kubernetes API server version (default: latest stable).

## DEPENDENCIES

- Common (for base system setup)
- None for Kubernetes integration (cluster connectivity optional)

## ANTI-PATTERNS

- Installing kubectl without verifying cluster access or kubeconfig presence.
- Overwriting user's kubeconfig file — always preserve existing contexts.
- Using apt repo versions that lag behind official releases by months.

[Root Guidelines](../../AGENTS.md)
