#!/bin/bash
# =============================================================================
#  Install ArgoCD on Kubernetes
# =============================================================================
set -euo pipefail

log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }

# Check dependencies
if ! command -v kubectl &>/dev/null; then
	echo "Error: kubectl is not installed."
	exit 1
fi

log_info "Creating argocd namespace..."
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

log_info "Applying ArgoCD manifest..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

log_info "Waiting for ArgoCD server..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd || echo "Warning: Timed out waiting for argocd-server"

# Get initial password
PASSWORD=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

log_success "ArgoCD Installed successfully!"
echo "============================================================================="
echo "Access ArgoCD:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo ""
echo "UI URL:   https://localhost:8080"
echo "Username: admin"
echo "Password: $PASSWORD"
echo "============================================================================="
