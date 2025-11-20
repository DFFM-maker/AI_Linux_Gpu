#!/bin/bash
# scripts/export-configs.sh - Export local ~/.config files into repository configs/ (safe copy)
set -e

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST_DIR="$REPO_ROOT/configs"
echo "Exporting current user configs to $DEST_DIR (make sure you scrub secrets after)"

mkdir -p "$DEST_DIR"/{hypr,waybar,mako,kitty,wofi}

cp -r "$HOME/.config/hypr"/* "$DEST_DIR/hypr/" 2>/dev/null || echo "No hypr config to export"
cp -r "$HOME/.config/waybar"/* "$DEST_DIR/waybar/" 2>/dev/null || echo "No waybar config to export"
cp -r "$HOME/.config/mako"/* "$DEST_DIR/mako/" 2>/dev/null || echo "No mako config to export"
cp -r "$HOME/.config/kitty"/* "$DEST_DIR/kitty/" 2>/dev/null || echo "No kitty config to export"
cp -r "$HOME/.config/wofi"/* "$DEST_DIR/wofi/" 2>/dev/null || echo "No wofi config to export"

echo ""
echo "Export complete. IMPORTANT: review $DEST_DIR and remove any personal data, absolute paths, keys or tokens before committing."
