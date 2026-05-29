#!/bin/bash

# ==================== FIREWALL (UFW) ====================
setup_firewall() {
    local TITLE="🛡️ CONFIGURACIÓN DE FIREWALL (UFW)"

    if command -v ufw >/dev/null 2>&1 && sudo ufw status | grep -q "Status: active"; then
        log_ok "UFW ✅ YA ACTIVO (saltando configuración)"

        if sudo ufw status | grep -q "22.*ALLOW"; then
            log_ok "SSH ✅ YA PERMITIDO (Puerto 22 ALLOW)"
        else
            log_msg "SSH ❌ CERRADO actualmente"
        fi
        return 0
    fi

    echo "$TITLE"
    echo -e "\nUFW no detectado/activo. ¿Instalar y configurar ahora? (y/N)"
    read -r -p " > " ufw_choice

    if [[ ! "$ufw_choice" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        log_msg "Saltando configuración de Firewall."
        return 0
    fi

    echo "Instalando paquetes UFW..."
    sudo pacman -S --needed --noconfirm ufw gufw

    sudo ufw --force reset >/dev/null

    echo "Aplicando políticas por defecto (Deny Incoming / Allow Outgoing)..."
    sudo ufw default deny incoming
    sudo ufw default allow outgoing

    echo -e "\n¿Deseas permitir conexiones SSH entrantes (Puerto 22)? (y/N)"
    echo "   (Útil si administras esta PC desde otro dispositivo)"
    read -r -p " > " ssh_choice

    if [[ "$ssh_choice" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        sudo ufw allow ssh
        log_ok "Regla SSH (Puerto 22) agregada."
    else
        log_ok "SSH mantenido cerrado."
    fi

    echo "y" | sudo ufw enable
    sudo systemctl enable --now ufw

    if sudo ufw status | grep -q "Status: active"; then
        log_ok "✅ Firewall configurado y ACTIVO."
        echo -e "\nEstado actual:"
        sudo ufw status verbose
    else
        log_err "❌ Hubo un problema activando UFW."
    fi
}
