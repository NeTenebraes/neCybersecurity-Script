#!/bin/bash

# ==================== SSH SECURITY ====================
setup_ssh_security() {
    if ! check_cmd sshd; then
        log_msg "sshd no detectado. Instalando openssh..."
        sudo pacman -S --needed --noconfirm openssh
        sudo systemctl enable --now sshd
    fi

    local SSHD_CONFIG="/etc/ssh/sshd_config"
    if [[ ! -f "$SSHD_CONFIG" ]]; then
        log_err "No se encontró $SSHD_CONFIG"
        return 1
    fi

    if ! ask_yes_no "¿Aplicar hardening de SSH?" "n"; then
        log_msg "Saltando hardening de SSH."
        return 0
    fi

    sudo cp "$SSHD_CONFIG" "$SSHD_CONFIG.bak.$(date +%Y%m%d%H%M%S)"

    local new_port
    new_port=$(find_free_port)

    set_sshd_config "Port" "$new_port"
    set_sshd_config "PermitRootLogin" "no"
    if ask_yes_no "¿Desactivar autenticación por contraseña (PasswordAuthentication)?" "y"; then
        set_sshd_config "PasswordAuthentication" "no"
    else
        set_sshd_config "PasswordAuthentication" "yes"
        log_msg "Se mantiene PasswordAuthentication habilitado."
    fi
    set_sshd_config "ChallengeResponseAuthentication" "no"
    set_sshd_config "UsePAM" "yes"
    set_sshd_config "X11Forwarding" "no"
    set_sshd_config "AllowTcpForwarding" "no"
    set_sshd_config "AllowAgentForwarding" "no"
    set_sshd_config "TCPKeepAlive" "no"
    set_sshd_config "ClientAliveInterval" "300"
    set_sshd_config "ClientAliveCountMax" "2"
    set_sshd_config "MaxAuthTries" "3"
    set_sshd_config "LoginGraceTime" "20"
    set_sshd_config "PermitEmptyPasswords" "no"
    set_sshd_config "IgnoreRhosts" "yes"

    log_ok "SSH hardening aplicado. Puerto nuevo: $new_port"

    if check_cmd ufw; then
        sudo ufw allow "$new_port"/tcp
        sudo ufw delete allow 22/tcp 2>/dev/null || true
    fi

    sudo systemctl restart sshd
}

find_free_port() {
    local port
    while true; do
        port=$(shuf -i 20000-65000 -n 1)
        if ! ss -tuln | awk '{print $5}' | grep -q ":$port$"; then
            echo "$port"
            return 0
        fi
    done
}

set_sshd_config() {
    local key="$1"
    local value="$2"
    local file="/etc/ssh/sshd_config"

    if sudo grep -qE "^\s*${key}\s+" "$file"; then
        sudo sed -i "s#^\s*${key}\s\+.*#${key} ${value}#" "$file"
    else
        echo "${key} ${value}" | sudo tee -a "$file" > /dev/null
    fi
}
