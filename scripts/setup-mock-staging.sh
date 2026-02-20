#!/bin/bash
set -eo pipefail

echo "🚀 Setting up Mock Staging Environment via LXD"

# Ensure LXD is installed
if ! command -v lxc &> /dev/null; then
    echo "❌ LXD is not installed. Please install it with: sudo snap install lxd && sudo lxd init --auto"
    exit 1
fi

CONTAINER_NAME="mock-staging-vps"

if lxc info "$CONTAINER_NAME" &> /dev/null; then
    echo "⚠️  Container $CONTAINER_NAME already exists. Cleaning up..."
    lxc stop "$CONTAINER_NAME" --force || true
    lxc delete "$CONTAINER_NAME"
fi

echo "📦 Launching container..."
lxc launch images:debian/12 "$CONTAINER_NAME"

echo "⏳ Waiting for network..."
sleep 5

# Get IP Address
STAGING_IP=$(lxc list "$CONTAINER_NAME" -c 4 --format csv | awk '{print $1}')

if [ -z "$STAGING_IP" ]; then
    echo "❌ Failed to get IP address for the mock staging VPS."
    exit 1
fi

echo "✅ Container running at IP: $STAGING_IP"

# Setup SSH key access
echo "🔑 Setting up SSH access..."
ssh-keygen -t rsa -N "" -f /tmp/mock_staging_key <<< y > /dev/null 2>&1
lxc exec "$CONTAINER_NAME" -- mkdir -p /root/.ssh
cat /tmp/mock_staging_key.pub | lxc exec "$CONTAINER_NAME" -- sh -c 'cat >> /root/.ssh/authorized_keys'
lxc exec "$CONTAINER_NAME" -- chmod 700 /root/.ssh
lxc exec "$CONTAINER_NAME" -- chmod 600 /root/.ssh/authorized_keys

# Install python3 and sudo for Ansible
echo "🐍 Installing Python3 and Sudo..."
lxc exec "$CONTAINER_NAME" -- apt-get update
lxc exec "$CONTAINER_NAME" -- apt-get install -y python3 sudo openssh-server

echo "📝 Updating inventory/staging.yml..."
cat <<EOF > inventory/staging.yml
---
all:
  children:
    staging:
      hosts:
        mock_staging:
          ansible_host: $STAGING_IP
          ansible_user: root
          ansible_ssh_private_key_file: /tmp/mock_staging_key
          ansible_ssh_common_args: '-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
EOF

echo "🎉 Mock Staging Setup Complete!"
echo "You can now run: ./scripts/deploy-staging.sh"
