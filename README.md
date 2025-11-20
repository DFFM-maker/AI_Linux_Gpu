# Hyprland Configuration Files

Tested and working configuration files for **EndeavourOS + Hyprland (Wayland)**.

## 📋 Contents

- **hypr/** - Hyprland window manager configuration
- **waybar/** - Status bar configuration  
- **mako/** - Notification daemon configuration
- **kitty/** - Terminal emulator configuration
- **wofi/** - Application launcher configuration

---

## 🚀 Installation

### Method 1: Manual Copy (Recommended)

```bash
# Clone repository
git clone https://github.com/DFFM-maker/AI_Linux_Gpu.git
cd AI_Linux_Gpu/configs

# Backup your existing configs
mkdir -p ~/.config-backup
cp -r ~/.config/hypr ~/.config-backup/ 2>/dev/null
cp -r ~/.config/waybar ~/.config-backup/ 2>/dev/null
cp -r ~/.config/mako ~/.config-backup/ 2>/dev/null
cp -r ~/.config/kitty ~/.config-backup/ 2>/dev/null
cp -r ~/.config/wofi ~/.config-backup/ 2>/dev/null

# Copy new configs
cp -r hypr ~/.config/
cp -r waybar ~/.config/
cp -r mako ~/.config/
cp -r kitty ~/.config/
cp -r wofi ~/.config/

# Reload Hyprland
hyprctl reload
```

### Method 2: Symlinks (Advanced)

```bash
# Clone repository
git clone https://github.com/DFFM-maker/AI_Linux_Gpu.git
cd AI_Linux_Gpu/configs

# Remove existing configs (backup first!)
rm -rf ~/.config/hypr
rm -rf ~/.config/waybar
rm -rf ~/.config/mako
rm -rf ~/.config/kitty
rm -rf ~/.config/wofi

# Create symlinks
ln -s $(pwd)/hypr ~/.config/hypr
ln -s $(pwd)/waybar ~/.config/waybar
ln -s $(pwd)/mako ~/.config/mako
ln -s $(pwd)/kitty ~/.config/kitty
ln -s $(pwd)/wofi ~/.config/wofi
```

---

## 🔧 Required Dependencies

Before using these configs, make sure you have all required packages:

```bash
# Core components
sudo pacman -S hyprland waybar mako kitty wofi

# Wayland support
sudo pacman -S xdg-desktop-portal-hyprland qt5-wayland qt6-wayland

# Screenshot tools
sudo pacman -S grim slurp wl-clipboard

# Audio
sudo pacman -S pipewire pipewire-pulse wireplumber

# Fonts (for icons in Waybar)
sudo pacman -S ttf-font-awesome ttf-jetbrains-mono-nerd \
  ttf-nerd-fonts-symbols noto-fonts noto-fonts-emoji

# File manager
sudo pacman -S thunar thunar-volman gvfs

# Bluetooth (optional)
sudo pacman -S bluez bluez-utils
sudo systemctl enable --now bluetooth
```

---

## ⚙️ Configuration Details

### Hyprland (`hypr/hyprland.conf`)

**Key Features:**
- Wayland environment variables pre-configured
- NVIDIA GPU support (if applicable)
- Common keybindings:
  - `Super + Return` - Open terminal (kitty)
  - `Super + Q` - Close window
  - `Super + D` - App launcher (wofi)
  - `Super + E` - File manager (thunar)
  - `Print Screen` - Screenshot (grim + slurp)
  - `Super + 1-9` - Switch workspace
  - `Super + Shift + 1-9` - Move window to workspace

**Customization:**
Edit `~/.config/hypr/hyprland.conf` to change:
- Monitor configuration (`monitor=`)
- Keybindings (`bind=`)
- Autostart programs (`exec-once=`)
- Window rules (`windowrule=`)

### Waybar (`waybar/config` + `waybar/style.css`)

**Modules Included:**
- Clock
- CPU usage
- Memory usage
- Disk usage
- Network status
- Audio volume (PulseAudio/PipeWire)
- Workspaces
- Tray icons

**Customization:**
- Edit `~/.config/waybar/config` for module content
- Edit `~/.config/waybar/style.css` for appearance

**Reload Waybar:**
```bash
pkill waybar
waybar &
```

### Mako (`mako/config`)

**Features:**
- Notification daemon for Wayland
- Timeout: 5 seconds
- Max visible: 3 notifications
- Position: top-right

**Test notifications:**
```bash
notify-send "Test" "Notification working!"
```

### Kitty (`kitty/kitty.conf`)

**Features:**
- Terminal emulator optimized for Wayland
- Font: JetBrainsMono Nerd Font
- Opacity/transparency support
- GPU-accelerated rendering

### Wofi (`wofi/config` + `wofi/style.css`)

**Features:**
- Application launcher for Wayland
- Dmenu replacement
- Customizable appearance

**Launch:**
```bash
wofi --show drun  # Application launcher
wofi --show run   # Command runner
```

---

## 🐛 Troubleshooting

### Waybar not showing

```bash
# Check if waybar is running
pgrep waybar

# Check for errors
waybar 2>&1 | grep -i error

# Restart waybar
pkill waybar
waybar &
```

### Icons showing as squares (□)

```bash
# Install nerd fonts
sudo pacman -S ttf-font-awesome ttf-jetbrains-mono-nerd

# Regenerate font cache
fc-cache -fv

# Restart waybar
pkill waybar
waybar &
```

### Hyprland config errors

```bash
# Check config syntax
hyprctl reload

# View Hyprland logs
journalctl --user -u hyprland -f
```

### Screenshots not working

```bash
# Install screenshot tools
sudo pacman -S grim slurp wl-clipboard

# Test manually
grim -g "$(slurp)" ~/test-screenshot.png
```

---

## 📚 Additional Resources

- **Hyprland Wiki:** https://wiki.hyprland.org/
- **Waybar Wiki:** https://github.com/Alexays/Waybar/wiki
- **ArchWiki Wayland:** https://wiki.archlinux.org/title/Wayland

---

## 🤝 Contributing

Found issues or have improvements? Please open an issue or PR!

---

**Author:** DFFM-maker  
**Tested on:** EndeavourOS Mercury-Neo 2025.03.19 + Hyprland  
**Last Updated:** 2025-11-20
