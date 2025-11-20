# Hyprland configuration files

This folder contains tested configuration files for Hyprland, Waybar, Mako, Kitty and Wofi.

What's new
- Added helper scripts in scripts/: check-hyprland-setup.sh, check-backup-system.sh, export-configs.sh
- Added minimal configs for mako and wofi to avoid runtime errors
- Added a local modules.jsonc for Waybar so the shipped config can run out-of-the-box

Quick usage:
1. Backup your current configs:
   mkdir -p ~/.config-backup
   cp -r ~/.config/hypr ~/.config-backup/ 2>/dev/null

2. Copy the provided configs (manual):
   cp -r configs/hypr ~/.config/
   cp -r configs/waybar ~/.config/
   cp -r configs/mako ~/.config/
   cp -r configs/kitty ~/.config/
   cp -r configs/wofi ~/.config/

3. Reload Hyprland:
   hyprctl reload

Exporting your local configs:
- Use scripts/export-configs.sh to copy your ~/.config into this repo's configs/ directory.
  IMPORTANT: after exporting, remove any sensitive data (absolute paths, tokens, keys) before committing.

Diagnostics:
- Run ./scripts/check-hyprland-setup.sh and ./scripts/check-backup-system.sh for quick validation.

Notes:
- Inspect and adapt monitor/autostart/keyboard files inside configs/hypr/conf/ before using them.
