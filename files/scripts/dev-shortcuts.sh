#!/bin/bash
# Development workflow shortcuts - Extended version
# Source this file in .zshrc or .bashrc

# ============================================================================
# PROJECT INITIALIZATION
# ============================================================================

function init-node() {
    npm init -y
    npm install --save-dev eslint prettier
    echo "node_modules/" > .gitignore
    git init
    echo "✅ Node.js project initialized"
}

function init-python() {
    python3 -m venv venv
    # shellcheck disable=SC1091
    source venv/bin/activate
    pip install black pylint pytest
    echo "venv/" > .gitignore
    git init
    echo "✅ Python project initialized (activate: source venv/bin/activate)"
}

function init-php() {
    composer init --no-interaction
    echo "vendor/" > .gitignore
    git init
    echo "✅ PHP project initialized"
}

# ============================================================================
# DOCKER SHORTCUTS
# ============================================================================

function dclean() {
    echo "Cleaning Docker system..."
    docker system prune -af --volumes
    echo "✅ Docker cleanup complete"
}

function dlog() {
    if [ -z "$1" ]; then
        echo "Usage: dlog <container-name>"
        return 1
    fi
    docker logs -f "$1"
}

function dexec() {
    if [ -z "$1" ]; then
        echo "Usage: dexec <container-name> [command]"
        return 1
    fi
    docker exec -it "$1" "${2:-bash}"
}

# ============================================================================
# GIT WORKFLOW
# ============================================================================

function gcommit() {
    if [ -z "$1" ]; then
        echo "Usage: gcommit <message>"
        return 1
    fi
    git add -A
    git commit -m "$1"
}

function gpush() {
    BRANCH=$(git branch --show-current)
    git push origin "$BRANCH"
}

function gpull() {
    BRANCH=$(git branch --show-current)
    git pull origin "$BRANCH"
}

function gnew() {
    if [ -z "$1" ]; then
        echo "Usage: gnew <branch-name>"
        return 1
    fi
    git checkout -b "$1"
}

# ============================================================================
# SYSTEM MONITORING
# ============================================================================

function sysinfo() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(lsb_release -d 2>/dev/null | cut -f2 || grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo ""
    echo "=== Resource Usage ==="
    echo "CPU: $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}')"
    echo "Memory: $(free -h | awk '/^Mem:/{print $3 " / " $2}')"
    echo "Disk: $(df -h / | awk 'NR==2{print $3 " / " $2 " (" $5 " used)"}')"
    echo ""
    echo "=== Network ==="
    echo "Public IP: $(curl -s ifconfig.me 2>/dev/null || echo 'N/A')"
    echo "Local IP: $(hostname -I | awk '{print $1}')"
}

function ports() {
    sudo ss -tulpn | grep LISTEN
}

function myip() {
    echo "Local IP: $(hostname -I | awk '{print $1}')"
    echo "Public IP: $(curl -s ifconfig.me)"
}

# ============================================================================
# QUICK SERVERS
# ============================================================================

function serve-python() {
    PORT=${1:-8000}
    echo "Starting Python HTTP server on port $PORT..."
    python3 -m http.server "$PORT"
}

function serve-node() {
    PORT=${1:-3000}
    if ! command -v http-server &>/dev/null; then
        echo "Installing http-server..."
        npm install -g http-server
    fi
    echo "Starting Node HTTP server on port $PORT..."
    http-server -p "$PORT"
}

function serve() {
    PORT="${1:-8000}"
    echo "Starting server on http://localhost:$PORT"
    python3 -m http.server "$PORT"
}

# ============================================================================
# PROJECT MANAGEMENT
# ============================================================================

function mkproject() {
    if [ -z "$1" ]; then
        echo "Usage: mkproject <project-name>"
        return 1
    fi

    mkdir -p ~/projects/"$1"
    cd ~/projects/"$1" || return
    git init
    echo "# $1" > README.md
    echo "✅ Project $1 created in ~/projects/$1"
}

# ============================================================================
# DATABASE HELPERS
# ============================================================================

function mysql-local() {
    docker run --name mysql-dev -e MYSQL_ROOT_PASSWORD=rootpass -e MYSQL_DATABASE=devdb -p 3306:3306 -d mysql:latest
    echo "MySQL container started (root password: rootpass, database: devdb)"
}

function postgres-local() {
    docker run --name postgres-dev -e POSTGRES_PASSWORD=rootpass -e POSTGRES_DB=devdb -p 5432:5432 -d postgres:latest
    echo "PostgreSQL container started (password: rootpass, database: devdb)"
}

function redis-local() {
    docker run --name redis-dev -p 6379:6379 -d redis:latest
    echo "Redis container started on port 6379"
}

# ============================================================================
# RDP HELPER
# ============================================================================

function rdp-info() {
    echo "=== RDP Connection Information ==="
    echo "Host: $(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')"
    echo "Port: 3389"
    echo "Username: $USER"
    echo ""
    echo "Windows Command:"
    echo "mstsc /v:$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):3389"
}

# ============================================================================
# BACKUP HELPER
# ============================================================================

function backup-project() {
    if [ -z "$1" ]; then
        echo "Usage: backup-project <project-directory>"
        return 1
    fi

    BACKUP_DIR=~/backups
    mkdir -p "$BACKUP_DIR"
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_FILE="$BACKUP_DIR/$(basename "$1")-$TIMESTAMP.tar.gz"

    tar -czf "$BACKUP_FILE" -C "$(dirname "$1")" "$(basename "$1")"
    echo "✅ Backup created: $BACKUP_FILE"
}

# ============================================================================
# SYSTEM UPDATE
# ============================================================================

function system-update() {
    echo "Updating system packages..."
    sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y
    echo "✅ System update complete"
}

echo "✅ Dev shortcuts loaded (sysinfo, mkproject, gcommit, rdp-info, etc.)"
