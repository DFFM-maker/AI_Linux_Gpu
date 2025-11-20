#!/bin/bash
#  ____                  _           _    
# / ___|  ___ _ __ ___  | |__   ___ | |_ 
# \___ \ / __| '__/ _ \ | '_ \ / _ \| __|
#  ___) | (__| | |  __/ | | | | (_) | |_ 
# |____/ \___|_|  \___| |_| |_|\___/ \__|
#
# Fixed for Wayland/Hyprland by Gemini

DIR="$HOME/Pictures/screenshots/"
NAME="screenshot_$(date +%d%m%Y_%H%M%S).png"

option2="Selected area"
option3="Fullscreen (delay 3 sec)"

options="$option2\n$option3"

# Nota: Ho corretto la fine della riga di rofi che sembrava tagliata nel tuo incollaggio
choice=$(echo -e "$options" | rofi -dmenu -replace -theme ~/.config/rofi/launchers/type-2/style-1.rasi -config ~/.config/rofi/config-screenshot.rasi -p "Screenshot")

case $choice in
    $option2)
        # 1. Cattura e salva il file
        grim -g "$(slurp)" "$DIR$NAME"
        
        # 2. Copia nella clipboard di Wayland (CORRETTO)
        wl-copy < "$DIR$NAME"
        
        # 3. Notifica e apri Swappy
        notify-send "Screenshot created and copied to clipboard" "Mode: Selected area"
        swappy -f "$DIR$NAME"
    ;;
    $option3)
        sleep 3
        # 1. Cattura schermo intero
        grim "$DIR$NAME"
        
        # 2. Copia nella clipboard di Wayland (CORRETTO)
        wl-copy < "$DIR$NAME"
        
        # 3. Notifica e apri Swappy
        notify-send "Screenshot created and copied to clipboard" "Mode: Fullscreen"
        swappy -f "$DIR$NAME"
    ;;
esac
