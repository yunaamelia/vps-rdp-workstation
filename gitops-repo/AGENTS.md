# COMPONENT: GITOPS

**Scope**: Declarative Kubernetes management via ArgoCD and Flux.

## STRUCTURE

```
gitops-repo/
├── apps/            # Application manifests (ArgoCD Applications)
├── argocd/          # ArgoCD configs, AppProjects, App-of-Apps
├── infrastructure/  # Core components (Ingress, Cert-Manager, DBs)
└── scripts/         # Bootstrap helpers (install_argocd.sh, setup_flux.sh)
```

## CONVENTIONS

- **Declarative YAML**: All state in YAML. No imperative `kubectl` commands.
- **Kustomize**: Prefer for environment patching (overlays/).
- **Secrets**: NEVER commit raw secrets. Use `SealedSecrets` or vault refs.
- **Health Checks**: All Application resources MUST define health criteria.
- **Version Pinning**: All Helm charts pinned to specific versions.

## ANTI-PATTERNS

- **Manual Changes**: `kubectl edit/apply` directly on cluster is forbidden.
- **Hardcoded Env Values**: Don't put environment-specifics in `base/`.
- **Monolithic Files**: Don't group unrelated resources in single YAML.
- **Untracked Dependencies**: External charts must be version-pinned.

## UNIQUE PATTERNS

- **App-of-Apps**: Hierarchical ArgoCD for managing service groups.
- **Image Automation**: Flux ImageUpdateAutomation for CD without manual tags.

[Root Guidelines](../AGENTS.md)
