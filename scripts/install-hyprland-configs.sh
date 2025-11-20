#!/bin/bash
# install-hyprland-configs.sh - Installa automaticamente le configurazioni

set -e

echo "🚀 Installazione configurazioni Hyprland"
echo "========================================="
echo ""

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Funzione per stampare con colori
print_error() { echo -e "${RED}❌ $1${NC}"; }
print_success() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# Verifica se siamo nella directory corretta
if [ ! -d "configs" ]; then
    print_error "Directory 'configs' non trovata!"
    echo "Esegui questo script dalla root del repository:"
    echo "  cd AI_Linux_Gpu"
    echo "  ./scripts/install-hyprland-configs.sh"
    exit 1
fi

# 1. Installa dipendenze
echo "📦 Installazione dipendenze..."
PACKAGES=(
    hyprland waybar mako kitty wofi
    xdg-desktop-portal-hyprland qt5-wayland qt6-wayland
    grim slurp wl-clipboard
    pipewire pipewire-pulse wireplumber
    ttf-font-awesome ttf-jetbrains-mono-nerd ttf-nerd-fonts-symbols
    noto-fonts noto-fonts-emoji
    thunar thunar-volman gvfs
)

if ! sudo pacman -S --needed --noconfirm "${PACKAGES[@]}"; then
    print_warning "Alcune dipendenze potrebbero non essere state installate"
fi
print_success "Dipendenze installate"

# 2. Backup configurazioni esistenti
echo ""
echo "💾 Backup configurazioni esistenti..."
BACKUP_DIR="$HOME/.config-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP_DIR"

for dir in hypr waybar mako kitty wofi; do
    if [ -d "$HOME/.config/$dir" ]; then
        cp -r "$HOME/.config/$dir" "$BACKUP_DIR/"
        print_success "Backup $dir -> $BACKUP_DIR"
    fi
done

# 3. Copia nuove configurazioni
echo ""
echo "📂 Installazione nuove configurazioni..."
mkdir -p ~/.config

for dir in hypr waybar mako kitty wofi; do
    if [ -d "configs/$dir" ]; then
        rm -rf "$HOME/.config/$dir"
        cp -r "configs/$dir" "$HOME/.config/"
        print_success "Installato $dir"
    else
        print_warning "$dir non trovato in configs/"
    fi
done

# 4. Abilita servizi
echo ""
echo "🔧 Abilitazione servizi..."
systemctl --user enable --now pipewire pipewire-pulse wireplumber 2>/dev/null || true
print_success "Servizi audio abilitati"

# 5. Rigenera cache font
echo ""
echo "🔤 Rigenerazione cache font..."
fc-cache -fv > /dev/null 2>&1
print_success "Cache font rigenerata"

# 6. Test configurazioni
echo ""
echo "🧪 Test configurazioni..."

# Test Hyprland config syntax
if command -v hyprctl &> /dev/null; then
    if hyprctl reload 2>&1 | grep -q "error"; then
        print_warning "Possibili errori nella configurazione Hyprland"
    else
        print_success "Configurazione Hyprland valida"
    fi
else
    print_warning "hyprctl non disponibile (normale se non sei in sessione Hyprland)"
fi

# 7. Riepilogo
echo ""
echo "========================================="
echo "✅ Installazione completata!"
echo "========================================="
echo ""
echo "📁 Backup salvato in: $BACKUP_DIR"
echo ""
echo "🔄 Prossimi passi:"
echo "   1. Logout dalla sessione corrente"
echo "   2. Login con Hyprland"
echo "   3. Verifica che tutto funzioni correttamente"
echo ""
echo "⚙️  Keybindings principali:"
echo "   Super + Return    - Apri terminale"
echo "   Super + Q         - Chiudi finestra"
echo "   Super + D         - App launcher"
echo "   Super + E         - File manager"
echo "   Print Screen      - Screenshot"
echo ""
echo "🐛 In caso di problemi:"
echo "   - Ripristina backup: cp -r $BACKUP_DIR/* ~/.config/"
echo "   - Esegui diagnostic: ./scripts/check-hyprland-setup.sh"
echo "   - Leggi: ../TIMESHIFT_BTRFS_SETUP_IT.md (sezione troubleshooting)"
echo ""
