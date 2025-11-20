# Hyprland configuration files

This folder contains tested configuration files for Hyprland, Waybar, Mako, Kitty and Wofi.

Quick usage:
1. Backup your current configs:
   mkdir -p ~/.config-backup
   cp -r ~/.config/hypr ~/.config-backup/ 2>/dev/null
2. Copy the provided configs:
   cp -r configs/hypr ~/.config/
   cp -r configs/waybar ~/.config/
   cp -r configs/mako ~/.config/
   cp -r configs/kitty ~/.config/
   cp -r configs/wofi ~/.config/
3. Reload Hyprland:
   hyprctl reload

See scripts/install-hyprland-configs.sh for automatic installation.
