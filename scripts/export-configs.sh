#!/bin/bash
# Export local ~/.config files into repository configs/ (safe copy)
DEST_DIR="$(pwd)/configs"
echo "Exporting current user configs to $DEST_DIR"
mkdir -p "$DEST_DIR"/{hypr,waybar,mako,kitty,wofi}
cp -r "$HOME/.config/hypr"/* "$DEST_DIR/hypr/" 2>/dev/null || true
cp -r "$HOME/.config/waybar"/* "$DEST_DIR/waybar/" 2>/dev/null || true
cp -r "$HOME/.config/mako"/* "$DEST_DIR/mako/" 2>/dev/null || true
cp -r "$HOME/.config/kitty"/* "$DEST_DIR/kitty/" 2>/dev/null || true
cp -r "$HOME/.config/wofi"/* "$DEST_DIR/wofi/" 2>/dev/null || true
echo "Export done. Please review files, remove any sensitive data, then commit."
