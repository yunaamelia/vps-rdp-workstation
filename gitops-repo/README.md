# GitOps Repository

This directory contains the GitOps configuration for the VPS RDP Workstation environment.

## 📂 Structure

```
gitops-repo/
├── apps/               # Application manifests (ArgoCD target)
│   └── production/
│       └── my-app/     # Example application
├── infrastructure/     # Infrastructure components
│   └── ingress-nginx/
└── argocd/             # ArgoCD specific configs
    └── applications/   # App of Apps definitions
```

## 🚀 Setup Guides

Since direct Kubernetes access was not available during initialization, use the helper scripts in `scripts/`:

### 1. Install ArgoCD
```bash
# Requires kubectl configured for your cluster
./scripts/install_argocd.sh
```

### 2. Setup Flux CD (Alternative)
```bash
# Requires Flux CLI and GITHUB_TOKEN
./scripts/setup_flux.sh
```

## 🔄 CI/CD Pipeline

A GitHub Action workflow has been configured at `.github/workflows/deploy.yml`.
This pipeline performs "CIOps" for the Ansible portion of this project:
1.  Lints Ansible playbooks
2.  Checks syntax
3.  Deploys to the VPS using `setup.sh --ci`

**Note:** True GitOps (pull-based) is configured via ArgoCD/Flux monitoring this repository, while the Ansible setup uses push-based CI.
