#!/bin/bash
# scripts/check-backup-system.sh
# Basic Timeshift / Btrfs checks

set -e

echo "=== TIMESHiFT SNAPSHOT LIST (may require sudo) ==="
sudo timeshift --list || echo "timeshift not available or failed"

echo ""
echo "=== BTRFS SUBVOLUMES ==="
sudo btrfs subvolume list / || echo "btrfs not in use or permission denied"

echo ""
echo "=== PACMAN HOOKS ==="
ls -la /etc/pacman.d/hooks/ 2>/dev/null || echo "/etc/pacman.d/hooks not present"

echo ""
echo "=== CRONIE STATUS ==="
systemctl status cronie --no-pager || echo "cronie not installed or inactive"

echo ""
echo "=== DISK USAGE ==="
df -h / || true

echo ""
echo "=== TIMESHIFT CONFIG ==="
sudo test -f /etc/timeshift/timeshift.json && sudo sed -n '1,200p' /etc/timeshift/timeshift.json || echo "No timeshift config file found"
