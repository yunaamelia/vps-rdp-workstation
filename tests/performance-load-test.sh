#!/bin/bash
# VPS RDP Workstation - Performance & Load Testing Suite
set -euo pipefail

HOST="${1:-localhost}"
USER="${2:-testuser}"

echo "⏱️ Starting Performance & Load Testing on $HOST..."

ssh_cmd() {
    ssh -o StrictHostKeyChecking=no "$USER@$HOST" "$1"
}

# Ensure sysbench is installed
ssh_cmd "sudo apt-get update && sudo apt-get install -y sysbench stress-ng"

echo "📊 Running CPU Benchmark..."
ssh_cmd "sysbench cpu --cpu-max-prime=20000 run | grep 'events per second'"

echo "📊 Running Memory Benchmark..."
ssh_cmd "sysbench memory --memory-block-size=1K --memory-total-size=10G run | grep 'MiB/sec'"

echo "🏋️ Running Load Test (Stress-ng) for 30s..."
ssh_cmd "stress-ng --cpu 2 --io 1 --vm 1 --vm-bytes 1G --timeout 30s --metrics-brief"

echo "🎉 Performance & Load tests completed."
