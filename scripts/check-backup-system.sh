#!/bin/bash
# Basic Timeshift / Btrfs checks
echo "=== TIMESHiFT ==="
sudo timeshift --list
echo ""
echo "=== BTRFS SUBVOLUMES ==="
sudo btrfs subvolume list / | head -30
echo ""
echo "=== PACMAN HOOKS ==="
ls -la /etc/pacman.d/hooks/ 2>/dev/null
echo ""
echo "=== CRONIE ==="
systemctl status cronie --no-pager
