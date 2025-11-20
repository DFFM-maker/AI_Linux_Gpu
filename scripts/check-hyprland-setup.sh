#!/bin/bash
# scripts/check-hyprland-setup.sh
# Simple diagnostics for Hyprland setup

set -e

echo "=== HYPRLAND CHECK ==="
if command -v Hyprland >/dev/null 2>&1; then
  echo "✅ Hyprland binary present"
else
  echo "❌ Hyprland binary NOT found"
fi

echo ""
echo "=== WAYBAR ==="
if command -v waybar >/dev/null 2>&1; then
  echo "✅ waybar installed"
else
  echo "❌ waybar missing"
fi
if pgrep -x waybar >/dev/null 2>&1; then
  echo "✅ waybar running"
else
  echo "⚠️ waybar not running"
fi

echo ""
echo "=== FONTS (nerd / fontawesome) ==="
if fc-list | grep -Ei "nerd|font-awesome|fontawesome" >/dev/null 2>&1; then
  echo "✅ Nerd / icon fonts found"
else
  echo "❌ Nerd / icon fonts NOT found"
fi

echo ""
echo "=== AUDIO (pipewire) ==="
if systemctl --user is-active --quiet pipewire; then
  echo "✅ PipeWire (user) active"
else
  echo "⚠️ PipeWire (user) inactive"
fi

echo ""
echo "=== NOTIFICATIONS ==="
if pgrep -x mako >/dev/null 2>&1; then
  echo "✅ mako running"
else
  echo "⚠️ mako not running"
fi

echo ""
echo "=== SCREENSHOT TOOLS ==="
if command -v grim >/dev/null 2>&1 && command -v slurp >/dev/null 2>&1; then
  echo "✅ grim & slurp installed"
else
  echo "❌ grim and/or slurp missing"
fi

echo ""
echo "=== BLUETOOTH ==="
if systemctl is-active --quiet bluetooth; then
  echo "✅ bluetooth service active"
else
  echo "⚠️ bluetooth inactive"
fi

echo ""
echo "=== GPU DRIVER / KERNEL MODULES ==="
lspci | grep -i vga || true
if lsmod | grep -E "nvidia|amdgpu|i915" >/dev/null 2>&1; then
  echo "✅ Found expected GPU kernel modules"
else
  echo "⚠️ GPU kernel modules not obvious (nvidia/amdgpu/i915)"
fi

echo ""
echo "=== WAYLAND SESSION ==="
echo "XDG_SESSION_TYPE: ${XDG_SESSION_TYPE:-unknown}"
echo "WAYLAND_DISPLAY: ${WAYLAND_DISPLAY:-not set}"

echo ""
echo "=== SUMMARY ==="
echo "Run 'hyprctl reload' (in session) to validate config syntax, and check journalctl --user -xe for Hyprland logs."
