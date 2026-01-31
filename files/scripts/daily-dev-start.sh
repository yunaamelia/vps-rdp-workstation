#!/bin/bash
# Daily development startup script

echo "=== Good $(date +%A), $USER! ==="
echo ""

# System status
echo "System Status:"
echo "  Uptime: $(uptime -p)"
echo "  Memory: $(free -h | awk '/^Mem:/{print $3 " / " $2}')"
echo "  Disk: $(df -h / | awk 'NR==2{print $5 " used"}')"
echo ""

# Check for system updates
UPDATES=$(apt list --upgradable 2>/dev/null | grep -c upgradable || echo 0)
if [ "$UPDATES" -gt 1 ]; then
    echo "⚠️  $((UPDATES-1)) system update(s) available"
    echo "   Run: sudo apt update && sudo apt upgrade"
    echo ""
fi

# Docker status
if systemctl is-active --quiet docker 2>/dev/null; then
    CONTAINERS=$(docker ps -q 2>/dev/null | wc -l)
    echo "Docker: $CONTAINERS container(s) running"
    if [ "$CONTAINERS" -gt 0 ]; then
        docker ps --format "  - {{.Names}} ({{.Status}})" 2>/dev/null
    fi
    echo ""
fi

# Git repositories status
echo "Recent Projects:"
if [ -d ~/projects ]; then
    find ~/projects -maxdepth 2 -name .git -type d 2>/dev/null | head -5 | while read -r gitdir; do
        PROJECT_DIR=$(dirname "$gitdir")
        PROJECT_NAME=$(basename "$PROJECT_DIR")
        cd "$PROJECT_DIR" || continue

        BRANCH=$(git branch --show-current 2>/dev/null)
        MODIFIED=$(git status --porcelain 2>/dev/null | wc -l)

        if [ "$MODIFIED" -gt 0 ]; then
            echo "  📝 $PROJECT_NAME (branch: $BRANCH, $MODIFIED change(s))"
        else
            echo "  ✅ $PROJECT_NAME (branch: $BRANCH)"
        fi
    done
else
    echo "  No projects directory found. Create one with: mkproject <name>"
fi
echo ""

# Quick commands reminder
echo "Quick Commands:"
echo "  sysinfo        - System information"
echo "  mkproject      - Create new project"
echo "  rdp-info       - RDP connection details"
echo ""

echo "Happy coding! 🚀"
