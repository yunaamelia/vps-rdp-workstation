# PROJECT KNOWLEDGE BASE: GitOps Repository

**Generated:** Wed Feb 18 07:45:00 AM UTC 2026
**Scope**: Declarative GitOps management for Kubernetes clusters using ArgoCD and Flux.

## OVERVIEW
This repository serves as the single source of truth for cluster state. It contains multi-environment configurations for applications and core infrastructure components, managed via automated reconciliation loops.

## STRUCTURE
```
gitops-repo/
├── apps/                 # Application manifests and ArgoCD Application resources.
│   ├── base/             # Environment-agnostic Kustomize bases.
│   └── overlays/         # Per-environment (dev, prod) customizations.
├── infrastructure/       # Core cluster components (Ingress, Cert-Manager, DBs).
│   ├── flux-system/      # Flux internal configuration and GitRepositories.
│   └── argocd/           # ArgoCD system configuration and AppProjects.
├── clusters/             # Cluster-specific bootstrap and entry points.
└── scripts/              # Validation and templating helper scripts.
```

## CONVENTIONS
*   **Declarative YAML**: All state MUST be expressed in YAML. No imperative commands.
*   **Kustomize**: Prefer Kustomize for patching across environments.
*   **Secrets**: NEVER commit raw secrets. Use `SealedSecrets` or external vault references.
*   **Atomic Commits**: Each commit should represent a single logical change to a service.
*   **PR-Driven**: All changes require a Pull Request and successful CI linting/validation.

## ANTI-PATTERNS
*   **Manual Changes**: `kubectl edit` or `kubectl apply` directly on the cluster is forbidden.
*   **Hardcoded Environmentals**: Avoid hardcoding environment-specific values in `base/`.
*   **Monolithic Files**: Do not group unrelated resources into a single multi-resource YAML file.
*   **Untracked Dependencies**: All external Helm charts must be pinned to specific versions.

## UNIQUE PATTERNS
*   **App-of-Apps**: Hierarchical ArgoCD patterns for managing groups of related services.
*   **Automated Image Updates**: Flux ImageUpdateAutomation for CD without manual tag changes.
*   **Health Checks**: All Application resources MUST define health check criteria.
