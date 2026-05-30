#!/bin/bash

# ==================== FIREWALL (UFW) ====================
setup_firewall() {
    local TITLE="CONFIGURACION DE FIREWALL (UFW)"

    if command -v ufw >/dev/null 2>&1 && sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        log_ok "UFW ya activo (saltando configuracion)"
        return 0
    fi

    echo "$TITLE"
    echo -e "\nUFW no detectado/activo."
    if ! ask_yes_no "¿Instalar y configurar ahora?" "n"; then
        log_msg "Saltando configuración de Firewall."
        return 0
    fi

    echo "Instalando paquetes UFW..."
    sudo pacman -S --needed --noconfirm ufw gufw

    sudo ufw --force reset >/dev/null

    echo "Aplicando políticas por defecto (Deny Incoming / Allow Outgoing)..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    echo "y" | sudo ufw enable
    sudo systemctl enable --now ufw

    if sudo ufw status | grep -q "Status: active"; then
        log_ok "Firewall configurado y ACTIVO."
        echo -e "\nEstado actual:"
        sudo ufw status verbose
    else
        log_err "Hubo un problema activando UFW."
    fi
}
