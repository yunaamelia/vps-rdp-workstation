#!/bin/bash
set -e

# Setup Molecule Tests
# Automates the creation of scenarios for all roles

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROLES_DIR="$BASE_DIR/roles"
MOLECULE_DIR="$BASE_DIR/molecule"

echo "🧪 Setting up Molecule Infrastructure..."

# 1. Verify Dependencies
if ! command -v molecule &> /dev/null; then
    echo "❌ Molecule not found. Installing..."
    pip install molecule molecule-plugins[docker] ansible-lint
else
    echo "✅ Molecule detected."
fi

# 2. Setup Shared Infrastructure
mkdir -p "$MOLECULE_DIR/helpers"
mkdir -p "$MOLECULE_DIR/fixtures"
echo "✅ Shared directories created."

# 3. Discover Roles and Create Scenarios
echo "🔍 Scanning roles..."
for role_path in "$ROLES_DIR"/*; do
    if [ -d "$role_path" ]; then
        role_name=$(basename "$role_path")
        scenario_path="$MOLECULE_DIR/$role_name"

        if [ ! -d "$scenario_path" ]; then
            echo "   ➕ Creating scenario for role: $role_name"

            # Use molecule init (simulated manual creation for control)
            mkdir -p "$scenario_path"

            # Create molecule.yml
            cat > "$scenario_path/molecule.yml" <<EOF
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: docker.io/geerlingguy/docker-debian12-ansible:latest
    pre_build_image: true
    privileged: true
    volumes:
      - /sys/fs/cgroup:/sys/fs/cgroup:rw
    cgroupns_mode: host
provisioner:
  name: ansible
  inventory:
    host_vars:
      instance:
        ansible_user: ansible
verifier:
  name: ansible
EOF

            # Create converge.yml
            cat > "$scenario_path/converge.yml" <<EOF
---
- name: Converge
  hosts: all
  vars_files:
    - ../fixtures/test_data.yml
  tasks:
    - name: "Include role $role_name"
      include_role:
        name: $role_name
EOF

            # Create verify.yml
            cat > "$scenario_path/verify.yml" <<EOF
---
- name: Verify
  hosts: all
  tasks:
    - name: "Verify service $role_name"
      include_tasks: ../helpers/service_verify.yml
      vars:
        service_name: "$role_name"
        # expected_port: 80 # Uncomment and set if applicable
EOF

        else
            echo "   ⏩ Scenario exists for: $role_name"
        fi
    fi
done

# 4. Final instructions
echo ""
echo "🎉 Setup Complete!"
echo "Run: molecule test --all"
