#!/bin/bash
set -e

VPS_IP="139.59.253.112"
VPS_PASS="gg123123@"
REPO_URL="https://github.com/yunaamelia/vps-rdp-workstation.git"
TEST_USER="testdeploy"
TEST_USER_PASS="SecurePass123!@#"

echo "=== 1. Checking Connectivity ==="
sshpass -p "$VPS_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o PreferredAuthentications=password -o PubkeyAuthentication=no root@$VPS_IP "echo '✓ Connected to $(hostname)'"

echo "=== 2a. Fixing Locales ==="
sshpass -p "$VPS_PASS" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@$VPS_IP "apt-get install -y locales && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8"

echo "=== 3. Cloning Repository ==="
sshpass -p "$VPS_PASS" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@$VPS_IP "rm -rf vps-rdp-workstation && git clone $REPO_URL"

echo "=== 4. Running Rollback (Cleanup) ==="
sshpass -p "$VPS_PASS" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@$VPS_IP "cd vps-rdp-workstation && chmod +x setup.sh && export CONFIRM_ROLLBACK=true && ./setup.sh --rollback"

echo "=== 5. Running Setup (CI Mode) ==="
echo "Create secrets file..."
sshpass -p "$VPS_PASS" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@$VPS_IP "echo 'password=$TEST_USER_PASS' > /root/.vps_secrets && chmod 600 /root/.vps_secrets"

echo "Executing setup.sh..."
sshpass -p "$VPS_PASS" ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no root@$VPS_IP "export LC_ALL=en_US.UTF-8 && cd vps-rdp-workstation && VPS_USERNAME=$TEST_USER VPS_SECRETS_FILE=/root/.vps_secrets ./setup.sh --ci" || echo "Setup finished or disconnected (expected if root login disabled)"

echo "=== 6. Verify Installation (User Access) ==="
echo "Waiting for SSH to reload..."
sleep 15
echo "Attempting login as $TEST_USER..."
sshpass -p "$TEST_USER_PASS" ssh -o StrictHostKeyChecking=no -o PreferredAuthentications=password -o PubkeyAuthentication=no $TEST_USER@$VPS_IP "echo '✓ User login successful'; hostname; echo 'Checking Docker group...'; groups | grep docker && echo '✓ Docker group present'"
