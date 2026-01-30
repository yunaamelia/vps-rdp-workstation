#!/bin/bash
#===============================================================================
# Update VPS Enhancements
#===============================================================================
# Updates all installed enhancement tools to their latest versions
#===============================================================================

echo "🚀 Updating VPS Enhancements..."

# 1. Update Cargo Packages (if installed via cargo)
if command -v cargo &> /dev/null; then
    echo "📦 Updating Cargo packages..."
    if ! command -v cargo-install-update &> /dev/null; then
        echo "Installing cargo-update..."
        cargo install cargo-update
    fi
    cargo install-update -a
fi

# 2. Update VS Code Extensions
if command -v code &> /dev/null; then
    echo "🤖 Updating VS Code extensions..."
    code --update-extensions
fi

# 3. Update Oh My Zsh
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    echo "🐚 Updating Oh My Zsh..."
    env ZSH="$HOME/.oh-my-zsh" sh "$HOME/.oh-my-zsh/tools/upgrade.sh"
    
    # Update plugins
    echo "   Updating Zsh plugins..."
    find "$HOME/.oh-my-zsh/custom/plugins" -type d -mindepth 1 -maxdepth 1 -exec git -C {} pull \;
fi

# 4. Update Tmux Plugins
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo "🖥️ Updating Tmux plugins..."
    "$HOME/.tmux/plugins/tpm/bin/update_plugins" all
fi

# 5. Update Atuin
if command -v atuin &> /dev/null; then
    echo "📜 Updating Atuin..."
    curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh | bash -s -- --yes
fi

echo "✅ Update complete!"
