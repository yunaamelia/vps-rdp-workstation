#!/bin/bash
#===============================================================================
# Validate VPS Enhancements
#===============================================================================
# Checks if all enhancement tools are correctly installed and functional
#===============================================================================

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Counters
PASS=0
FAIL=0

echo "🔍 Validating VPS Enhancements..."
echo "=================================="

check_command() {
    local cmd=$1
    local name=${2:-$cmd}

    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $name is installed ($(command -v "$cmd"))"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $name is MISSING"
        ((FAIL++))
        return 1
    fi
}

check_file() {
    local file=$1
    local name=$2

    if [[ -f "$file" ]]; then
        echo -e "${GREEN}✓${NC} $name exists ($file)"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $name is MISSING"
        ((FAIL++))
        return 1
    fi
}

check_dir() {
    local dir=$1
    local name=$2

    if [[ -d "$dir" ]]; then
        echo -e "${GREEN}✓${NC} $name exists ($dir)"
        ((PASS++))
        return 0
    else
        echo -e "${RED}✗${NC} $name is MISSING"
        ((FAIL++))
        return 1
    fi
}

# 1. Modern CLI Tools
echo -e "\n📋 Checking Modern CLI Tools"
check_command "eza" "eza (ls)"
check_command "bat" "bat (cat)"
check_command "fd" "fd (find)"
check_command "rg" "ripgrep (grep)"
check_command "dust" "dust (du)"
check_command "procs" "procs (ps)"

# 2. Git Tools
echo -e "\n🌿 Checking Git Tools"
check_command "lazygit" "lazygit"
check_command "delta" "delta (diff)"

# 3. Productivity
echo -e "\n⚡ Checking Productivity Tools"
check_command "fzf" "fzf (fuzzy finder)"
# Check Path or specific location for atuin
if command -v atuin &> /dev/null; then
    check_command "atuin" "atuin (history)"
elif [[ -f "$HOME/.atuin/bin/atuin" ]]; then
    echo -e "${GREEN}✓${NC} atuin (history) is installed ($HOME/.atuin/bin/atuin)"
    ((PASS++))
else
    echo -e "${RED}✗${NC} atuin (history) is MISSING"
    ((FAIL++))
fi
check_command "yazi" "yazi (file manager)"
check_command "pet" "pet (snippets)"

# 4. Zsh Enhancements
echo -e "\n🐚 Checking Zsh Plugins"
check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "zsh-autosuggestions"
check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" "zsh-syntax-highlighting"
check_dir "$HOME/.oh-my-zsh/custom/plugins/zsh-z" "zsh-z (directory jumping)"
check_file "$HOME/.zshrc.enhancements" "Enhancements Config"

# 5. Tmux
echo -e "\n🖥️ Checking Tmux"
check_dir "$HOME/.tmux/plugins/tpm" "Tmux Plugin Manager"
check_file "$HOME/.tmux.conf" "Tmux Config"

# 6. VS Code
echo -e "\n🤖 Checking VS Code Extensions"
if command -v code &> /dev/null; then
    if code --list-extensions 2>/dev/null | grep -qi "Codeium.codeium"; then
        echo -e "${GREEN}✓${NC} Codeium extension installed"
        ((PASS++))
    else
        echo -e "${RED}✗${NC} Codeium extension MISSING"
        ((FAIL++))
    fi
else
    echo -e "${RED}✗${NC} VS Code CLI not found (skipping extension check)"
    ((FAIL++))
fi

echo "=================================="
echo "Results: $PASS Passed, $FAIL Failed"

if [[ $FAIL -eq 0 ]]; then
    echo -e "${GREEN}SUCCESS: All enhancements installed correctly!${NC}"
    exit 0
else
    echo -e "${RED}FAILURE: Some enhancements are missing or broken.${NC}"
    exit 1
fi
