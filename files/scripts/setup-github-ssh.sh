#!/bin/bash
# GitHub SSH Key Setup Helper

echo "=== GitHub SSH Key Setup ==="
echo ""

if [ -f ~/.ssh/id_ed25519 ]; then
    echo "SSH key already exists at ~/.ssh/id_ed25519"
    echo ""
    echo "Your public key:"
    cat ~/.ssh/id_ed25519.pub
    echo ""
    echo "Add this key to GitHub: https://github.com/settings/keys"
else
    echo "Enter your GitHub email address:"
    read -r email

    if [ -z "$email" ]; then
        echo "Email is required. Aborting."
        exit 1
    fi

    mkdir -p ~/.ssh
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""

    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519

    echo ""
    echo "✅ SSH key generated successfully!"
    echo ""
    echo "Your public key:"
    cat ~/.ssh/id_ed25519.pub
    echo ""
    echo "Next steps:"
    echo "1. Copy the public key above"
    echo "2. Go to https://github.com/settings/keys"
    echo "3. Click 'New SSH key'"
    echo "4. Paste your key and save"
    echo ""
    echo "Test with: ssh -T git@github.com"
fi
