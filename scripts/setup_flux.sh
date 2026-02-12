#!/bin/bash
# =============================================================================
#  Setup Flux CD on Kubernetes
# =============================================================================
set -euo pipefail

log_info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }

# Check dependencies
if ! command -v flux &>/dev/null; then
	log_info "Flux CLI not found. Installing..."
	curl -s https://fluxcd.io/install.sh | sudo bash
fi

if [[ -z "${GITHUB_TOKEN:-}" ]]; then
	echo "Error: GITHUB_TOKEN environment variable is required."
	echo "Export it with: export GITHUB_TOKEN=<your-token>"
	exit 1
fi

if [[ -z "${GITHUB_USER:-}" ]]; then
	echo "Error: GITHUB_USER environment variable is required."
	exit 1
fi

REPO_NAME="${1:-gitops-repo}"

log_info "Bootstrapping Flux into cluster..."
flux bootstrap github \
	--owner="$GITHUB_USER" \
	--repository="$REPO_NAME" \
	--branch=main \
	--path=clusters/production \
	--personal

log_info "Flux setup complete!"
