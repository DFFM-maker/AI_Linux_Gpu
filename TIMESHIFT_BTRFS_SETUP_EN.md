# Timeshift + Btrfs Configuration on EndeavourOS Hyprland

## 📋 Starting System

**Distribution:** EndeavourOS Mercury-Neo (2025.03.19)  
**Desktop Environment:** Hyprland (Wayland)  
**Bootloader:** systemd-boot  
**Filesystem:** Btrfs with subvolume layout  
**Disk:** `/dev/nvme0n1p2` (1TB available)  
**Installation Script:** [while1618/hyprland-install-script](https://github.com/while1618/hyprland-install-script)

### Initial Installation

```bash
# Clone Hyprland installation script repository
git clone https://github.com/while1618/hyprland-install-script.git
cd hyprland-install-script/
./install.sh
```

**Installation Notes:**
- EndeavourOS installed with **Online** mode + **No Desktop**
- Hyprland installed afterwards via script
- Some errors during script installation (manually resolved)

### Initial Btrfs Layout

```
Subvolume layout:
- @ (root)
- @home
- @cache (/var/cache)
- @log (/var/log)
```

---

## 🎯 Objective

Configure an automatic snapshot system with **Timeshift** to protect the system from:
- Failed system updates
- Configuration errors
- Problematic software installations (e.g., KVM/QEMU, GPU drivers)
- System modifications causing instability
- Quick rollback in case of problems

---

## 🛠️ Installation and Configuration

### 1. Install Timeshift

```bash
# Install Timeshift and dependencies
sudo pacman -S timeshift cronie

# Enable cronie for scheduled automatic snapshots
sudo systemctl enable --now cronie
```

### 2. Initial Timeshift Configuration

```bash
# First configuration via GUI (recommended)
sudo timeshift-gtk

# Or via CLI
sudo timeshift --snapshot-device /dev/nvme0n1p2
```

**Recommended Settings in GUI:**
- **Mode:** BTRFS
- **Snapshot Location:** `/dev/nvme0n1p2` (system disk)
- **Include @home:** ✅ Yes (complete backup including home)
- **Restore @home:** ❌ No (avoid overwriting user data during restore)

**Schedule (automatic scheduled snapshots):**
- **Daily:** 5 snapshots (kept)
- **Weekly:** 3 snapshots (kept)
- **Monthly:** 0 (disabled)
- **Hourly:** 0 (disabled)
- **Boot:** 0 (disabled)

### 3. Enable Btrfs Quotas

Btrfs quotas allow Timeshift to correctly calculate the space occupied by each snapshot.

```bash
# Enable quotas
sudo btrfs quota enable /

# Start rescan (may take 2-5 minutes on large filesystems)
sudo btrfs quota rescan /

# Monitor rescan progress
sudo btrfs quota rescan -s /

# Verify quotas (after rescan completed)
sudo btrfs qgroup show /
```

**Expected output after rescan:**
```
Qgroupid    Referenced    Exclusive   Path
--------    ----------    ---------   ----
0/256        15.2 GB       2.3 GB     @
0/257         8.5 GB       1.1 GB     @home
...
```

### 4. Create Initial Manual Snapshots

```bash
# First snapshot - Stable base system
sudo timeshift --create --comments "Stable system - Hyprland working" --tags O

# Snapshot before important changes
sudo timeshift --create --comments "Pre-KVM installation" --tags O

# List created snapshots
sudo timeshift --list
```

**Available Tags:**
- `O` = Ondemand (manual)
- `D` = Daily
- `W` = Weekly
- `M` = Monthly
- `B` = Boot

### 5. Configure Automatic Pre-Pacman Snapshots

**⚠️ IMPORTANT:** With systemd-boot (not GRUB), snapshots **do not automatically appear in the boot menu**. Rollback still works perfectly via CLI or Live USB.

#### 5.1 Disable Snapper (if present - conflicts with Timeshift)

```bash
# Check if snapper is installed
pacman -Qs snapper

# If present, disable timers
sudo systemctl disable --now snapper-timeline.timer
sudo systemctl disable --now snapper-cleanup.timer

# Remove snapper pacman hooks
sudo rm -f /etc/pacman.d/hooks/snapper-*.hook

# (Optional) Remove snapper completely
sudo pacman -R snapper snap-pac --noconfirm
```

**Note:** Snapper and Timeshift do the same thing but in incompatible ways. Use only Timeshift.

#### 5.2 Create Timeshift Hook for Pacman

This hook automatically creates a snapshot **before** every pacman operation (`-S`, `-U`, `-R`).

```bash
# Create hooks directory if it doesn't exist
sudo mkdir -p /etc/pacman.d/hooks

# Create hook file
sudo tee /etc/pacman.d/hooks/timeshift-autosnap.hook > /dev/null <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Package
Target = *

[Action]
Description = Creating Timeshift snapshot before package operation...
When = PreTransaction
Depends = timeshift
Exec = /usr/bin/timeshift --create --comments "Before pacman operation" --tags O --scripted
EOF

# Verify creation
cat /etc/pacman.d/hooks/timeshift-autosnap.hook

# Verify permissions
ls -la /etc/pacman.d/hooks/
```

#### 5.3 Test Hook

```bash
# Install any package to test
sudo pacman -S htop

# During installation you should see:
# :: Running pre-transaction hooks...
# (1/1) Creating Timeshift snapshot before package operation...
# Using system disk as snapshot device for creating snapshots in BTRFS mode
# ...
# BTRFS Snapshot saved successfully (0s)
```

✅ If you see this output, the hook is working correctly!

```bash
# Verify created snapshot
sudo timeshift --list
```

### 6. Timeshift.json Configuration File

Path: `/etc/timeshift/timeshift.json`

```json
{
  "backup_device_uuid" : "c0236b03-6890-4d91-b33c-d04619bdfa44",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "true",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "true",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "2",
  "count_weekly" : "3",
  "count_daily" : "5",
  "count_hourly" : "6",
  "count_boot" : "5",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [],
  "exclude-apps" : []
}
```

**Note:** Replace `backup_device_uuid` with your disk's UUID (obtainable with `blkid`).

---

## 🔄 Usage and Rollback

### Basic Timeshift Commands

```bash
# List snapshots
sudo timeshift --list

# Create manual snapshot
sudo timeshift --create --comments "Custom description" --tags O

# Restore snapshot (interactive)
sudo timeshift --restore

# Restore specific snapshot
sudo timeshift --restore --snapshot '2025-11-20_08-24-08'

# Delete snapshot
sudo timeshift --delete --snapshot '2025-11-20_08-24-08'

# Delete all snapshots
sudo timeshift --delete-all
```

### Rollback Method 1: From Working System ✅

**Scenario:** System boots but has issues (e.g., GPU driver not working, Hyprland crashed, etc.)

```bash
# 1. Restore interactively
sudo timeshift --restore

# 2. Select desired snapshot (use arrows + number)
# 3. Confirm with ENTER
# 4. Wait for completion
# 5. Reboot
sudo reboot
```

**Note:** Restore overwrites the current `@` subvolume with the snapshot's. Timeshift automatically creates a pre-restore snapshot as backup.

### Rollback Method 2: From Live USB (system doesn't boot) 🛟

**Scenario:** System doesn't boot (black screen, kernel panic, etc.)

```bash
# 1. Boot from EndeavourOS Live USB

# 2. Open terminal

# 3. Mount Btrfs filesystem (toplevel, subvolid=5)
sudo mkdir -p /mnt/btrfs-root
sudo mount -o subvolid=5 /dev/nvme0n1p2 /mnt/btrfs-root

# 4. See available snapshots
ls -la /mnt/btrfs-root/timeshift-btrfs/snapshots/

# 5. Check if @ subvolume exists to replace
sudo btrfs subvolume list /mnt/btrfs-root | grep "path @$"

# 6. If it exists, delete it
sudo btrfs subvolume delete /mnt/btrfs-root/@

# 7. Recreate @ from desired snapshot (e.g., "2025-11-20_08-24-08")
sudo btrfs subvolume snapshot \
  /mnt/btrfs-root/timeshift-btrfs/snapshots/2025-11-20_08-24-08/@ \
  /mnt/btrfs-root/@

# 8. Verify @ was created
sudo btrfs subvolume list /mnt/btrfs-root | grep "path @$"

# 9. Unmount
cd /
sudo umount /mnt/btrfs-root

# 10. Remove USB and reboot
sudo reboot
```

### Rollback Method 3: Chroot from Live USB 🔧

**Scenario:** System doesn't boot, you want to use Timeshift from live USB.

```bash
# 1. Boot from EndeavourOS Live USB

# 2. Mount the system
sudo mount -o subvol=@ /dev/nvme0n1p2 /mnt
sudo mount /dev/nvme0n1p1 /mnt/efi  # EFI partition
sudo mount -o subvol=@home /dev/nvme0n1p2 /mnt/home

# 3. Chroot into the system
sudo arch-chroot /mnt

# 4. Use Timeshift normally
timeshift --list
timeshift --restore

# 5. Exit chroot
exit

# 6. Unmount and reboot
sudo umount -R /mnt
sudo reboot
```

---

## 📊 Verify Backup System Status

### Complete Diagnostic Script

```bash
#!/bin/bash
echo "=== TIMESHIFT STATUS ==="
sudo timeshift --list

echo ""
echo "=== BTRFS SUBVOLUMES ==="
sudo btrfs subvolume list / | grep -E "@|timeshift"

echo ""
echo "=== BTRFS QUOTA ==="
sudo btrfs qgroup show / | head -20

echo ""
echo "=== PACMAN HOOKS ==="
ls -la /etc/pacman.d/hooks/

echo ""
echo "=== CRONIE STATUS ==="
systemctl status cronie --no-pager

echo ""
echo "=== DISK SPACE ==="
df -h / /home

echo ""
echo "=== TIMESHIFT CONFIG ==="
cat /etc/timeshift/timeshift.json | grep -E "schedule|count|btrfs"
```

Save as `check-backup-system.sh`, make executable and run:

```bash
chmod +x check-backup-system.sh
./check-backup-system.sh
```

---

## ⚠️ Important Notes

### systemd-boot vs GRUB

This system uses **systemd-boot** as bootloader, **not GRUB**.

**Implications:**
- ❌ `grub-btrfs` and `grub-btrfsd` are **useless** (they look for GRUB which isn't there)
- ❌ Snapshots **DO NOT automatically appear** in the boot menu
- ✅ Rollback works **perfectly** via CLI or Live USB
- ✅ Snapshots are correctly saved on disk

**Attempted solutions (not applicable):**
```bash
# These commands DO NOT work with systemd-boot
sudo grub-mkconfig -o /boot/grub/grub.cfg  # ❌ File doesn't exist
sudo systemctl enable grub-btrfsd          # ❌ Looks for /.snapshots (Snapper)
```

**Recommended rollback for systemd-boot:**
1. From working system: `sudo timeshift --restore`
2. From Live USB: manual method (see above)

### Disk Space and Snapshots

**Space calculation:**
- Btrfs snapshots are **incremental** (only differences saved)
- A newly created snapshot occupies ~0 bytes
- Space grows only with subsequent filesystem modifications
- Older snapshots occupy more space (more accumulated differences)

**Example:**
```
Snapshot 1 (today):         0 MB
Snapshot 2 (1 day ago):    500 MB  (1 day of changes)
Snapshot 3 (1 week ago):   2 GB    (1 week of changes)
```

**Space management:**
```bash
# See space occupied by each snapshot (after quota rescan)
sudo btrfs qgroup show /

# Delete old snapshots
sudo timeshift --delete --snapshot 'SNAPSHOT_NAME'

# Delete all snapshots except last N
# (Timeshift does this automatically based on count_daily/weekly)
```

### Automatic Snapshots: Frequency

Timeshift creates automatic snapshots via **cron jobs**.

**Verify cron:**
```bash
# See cronie timers
sudo systemctl status cronie

# See cron logs
sudo journalctl -u cronie -f
```

**Snapshots are created:**
- **Daily:** Once a day (at first execution after midnight)
- **Weekly:** Once a week (Sunday)
- **Pre-pacman:** Before every `pacman -S`, `pacman -U`, `pacman -R`

**Automatic cleanup:**
Timeshift automatically deletes oldest snapshots when you exceed configured limits (e.g., 5 daily, 3 weekly).

### Exclusions (optional)

To **exclude** specific directories from snapshots, edit `/etc/timeshift/timeshift.json`:

```json
{
  ...
  "exclude" : [
    "/var/cache/**",
    "/var/tmp/**",
    "/tmp/**",
    "/home/*/.cache/**"
  ],
  "exclude-apps" : []
}
```

**Note:** Exclusions reduce space occupied by snapshots but might make restore incomplete.

---

## 🎯 Final Checklist

After completing configuration, verify:

- [ ] **Timeshift installed** and working
- [ ] **Snapshot device** configured (`/dev/nvme0n1p2`)
- [ ] **Scheduled snapshots** active (daily/weekly)
- [ ] **Btrfs quotas** enabled and rescan completed
- [ ] **Pacman hook** created and tested
- [ ] **Snapper disabled** (if it was present)
- [ ] **Cronie active** (`systemctl status cronie`)
- [ ] **At least 1 manual snapshot** created and tested
- [ ] **Rollback tested** (from working system)

**Final test:**
```bash
# 1. Create test snapshot
sudo timeshift --create --comments "Final test" --tags O

# 2. Modify a system file
echo "test" | sudo tee /etc/test-timeshift.txt

# 3. Restore test snapshot
sudo timeshift --restore --snapshot 'TEST_SNAPSHOT_NAME'

# 4. Reboot
sudo reboot

# 5. Verify file is gone
ls /etc/test-timeshift.txt  # Should show "No such file"
```

---

## 📚 Additional Resources

- **Timeshift GitHub:** https://github.com/linuxmint/timeshift
- **Btrfs Wiki:** https://btrfs.wiki.kernel.org/
- **EndeavourOS Wiki:** https://discovery.endeavouros.com/
- **Hyprland install script:** https://github.com/while1618/hyprland-install-script

---

## 🐛 Troubleshooting

### Error: "Quotas are not enabled"

```bash
sudo btrfs quota enable /
sudo btrfs quota rescan /
```

### Error: "grub-btrfsd.service failed"

Normal with systemd-boot. Disable it:
```bash
sudo systemctl disable --now grub-btrfsd
```

### Error: "Snapper IO Error (.snapshots is not a btrfs subvolume)"

Snapper active but misconfigured. Remove it:
```bash
sudo pacman -R snapper snap-pac
```

### Pacman hook doesn't create snapshots

Verify:
```bash
# Hook exists?
cat /etc/pacman.d/hooks/timeshift-autosnap.hook

# Hook has correct permissions?
ls -la /etc/pacman.d/hooks/

# Manual test
sudo /usr/bin/timeshift --create --comments "Test" --tags O --scripted
```

### Rollback doesn't work (system doesn't boot after restore)

1. Boot from Live USB
2. Mount filesystem: `sudo mount -o subvol=@ /dev/nvme0n1p2 /mnt`
3. Verify `/mnt/etc/fstab` is correct
4. Reinstall bootloader:
   ```bash
   sudo arch-chroot /mnt
   bootctl install
   exit
   ```
5. Reboot

---

**Author:** DFFM-maker  
**Date:** 2025-11-20  
**System:** EndeavourOS Mercury-Neo 2025.03.19 + Hyprland (Wayland)  
**Base Script:** [while1618/hyprland-install-script](https://github.com/while1618/hyprland-install-script)

---

**Contributions and Corrections:** If you find errors or have suggestions, open an issue or PR on this repository or on [while1618/hyprland-install-script](https://github.com/while1618/hyprland-install-script).
