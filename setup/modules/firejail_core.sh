#!/bin/bash

# ==================== FIREJAIL (NUCLEO) ====================
detect_browser() {
    local browsers=()
    [[ $(command -v firefox) ]] && browsers+=("firefox")
    [[ $(command -v chromium) ]] && browsers+=("chromium")
    [[ $(command -v brave-browser) ]] && browsers+=("brave")
    [[ $(command -v librewolf) ]] && browsers+=("librewolf")
    [[ $(command -v google-chrome) ]] && browsers+=("google-chrome")
    [[ $(command -v brave) ]] && browsers+=("brave")
    printf '%s\n' "${browsers[@]}"
}

install_firejail() {
    if check_cmd firejail; then
        log_ok "Firejail ya instalado"
        return 0
    fi
    log_msg "Instalando Firejail…"
    sudo pacman -S --needed --noconfirm firejail
    log_ok "Firejail instalado"
}

setup_firejail_global() {
    echo
    log_msg "🔥 ¿Firejail GLOBAL para apps básicas? (firefox→firejail firefox)"
    read -r -p "[y/N] " global_choice

    if [[ "$global_choice" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if [[ $EUID -eq 0 ]]; then
            sudo -u "$REALUSER" firecfg --fix
        else
            firecfg --fix
        fi
        log_ok "✅ Firejail GLOBAL activado"
    fi
}
