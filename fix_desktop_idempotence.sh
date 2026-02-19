#!/bin/bash
# Fix script for Desktop Role Idempotence Issues
# This script applies the recommended fixes to make the desktop role idempotent

set -e

DESKTOP_MAIN="/home/racoondev/vps-rdp-workstation/roles/desktop/tasks/main.yml"
BACKUP_FILE="${DESKTOP_MAIN}.backup.$(date +%Y%m%d_%H%M%S)"

echo "====================================="
echo "Desktop Role Idempotence Fix Script"
echo "====================================="
echo ""
echo "This script will:"
echo "1. Backup current main.yml"
echo "2. Remove 'recurse: true' from Kvantum directory task"
echo "3. Optionally add changed_when conditions"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 1
fi

# Backup
echo "[1/3] Creating backup: $BACKUP_FILE"
cp "$DESKTOP_MAIN" "$BACKUP_FILE"

# Fix 1: Remove recurse from Kvantum directory task
echo "[2/3] Fixing Kvantum config directory task..."
sed -i '/Create Kvantum config directory/,/tags:/ {
    /recurse: true/d
}' "$DESKTOP_MAIN"

# Verification
echo "[3/3] Verifying changes..."
if grep -q "Create Kvantum config directory" "$DESKTOP_MAIN"; then
    echo "✓ Task still exists"
else
    echo "✗ Task was accidentally removed!"
    echo "Restoring backup..."
    cp "$BACKUP_FILE" "$DESKTOP_MAIN"
    exit 1
fi

if grep "Create Kvantum config directory" -A 10 "$DESKTOP_MAIN" | grep -q "recurse: true"; then
    echo "✗ recurse: true still present!"
    echo "Restoring backup..."
    cp "$BACKUP_FILE" "$DESKTOP_MAIN"
    exit 1
else
    echo "✓ recurse: true removed successfully"
fi

echo ""
echo "====================================="
echo "Fix Applied Successfully!"
echo "====================================="
echo ""
echo "Backup saved to: $BACKUP_FILE"
echo ""
echo "Next steps:"
echo "1. Review changes: git diff $DESKTOP_MAIN"
echo "2. Test fix: molecule test -s default"
echo "3. If successful, commit changes"
echo ""
echo "To rollback: cp $BACKUP_FILE $DESKTOP_MAIN"
