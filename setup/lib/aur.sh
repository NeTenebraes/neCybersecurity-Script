#!/bin/bash

# ==================== AUR HELPER ====================
install_aur_helper() {
    if check_cmd paru; then
        log_ok "paru ✅ YA INSTALADO (preferido)" >&2
        echo "paru"
        return 0
    elif check_cmd yay; then
        log_ok "yay ✅ YA INSTALADO (alternativa)" >&2
        echo "yay"
        return 0
    fi

    log_msg "Instalando paru..." >&2
    cd /tmp || exit 1
    git clone "$AUR_REPO"
    cd paru-bin && makepkg -si --noconfirm
    cd - &>/dev/null
    log_ok "paru instalado" >&2
    echo "paru"
}

aur_install() {
    local AUR_HELPER
    AUR_HELPER="$(install_aur_helper)"
    log_msg "Instalando paquetes AUR: $*"

    if ! "$AUR_HELPER" -S --noconfirm "$@"; then
        log_err "Fallo instalando algunos paquetes AUR: $*"
        return 1
    fi

    log_ok "AUR completado: $*"
}
