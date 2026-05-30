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
        cleanup_ufw_ssh_ports "$new_port"
        sudo ufw allow "$new_port"/tcp
        save_ssh_port "$new_port"
    fi

    sudo systemctl restart sshd
}

cleanup_ufw_ssh_ports() {
    local new_port="$1"
    local ports
    local previous_port

    previous_port=$(load_previous_ssh_port)
    ports=$(get_ufw_allow_tcp_ports)

    if [[ -n "$previous_port" ]]; then
        ports=$(printf "%s\n%s\n" "$previous_port" "$ports" | sort -u)
    fi

    local port
    for port in $ports; do
        if [[ "$port" == "$new_port" ]]; then
            continue
        fi

        if ! should_close_port "$port"; then
            continue
        fi

        sudo ufw delete allow "$port"/tcp >/dev/null 2>&1 || true
    done
}

should_close_port() {
    local port="$1"
    local process_info

    process_info=$(get_process_for_port "$port")
    if [[ -n "$process_info" ]]; then
        log_msg "Puerto $port en uso por: $process_info"
    else
        log_msg "Puerto $port sin proceso escuchando"
    fi

    if ask_yes_no "Cerrar regla UFW para $port/tcp?" "n"; then
        return 0
    fi

    return 1
}

get_ufw_allow_tcp_ports() {
    sudo ufw status 2>/dev/null | awk '/ALLOW/ && $1 ~ /^[0-9]+\/tcp$/ { split($1, a, "/"); print a[1]; }'
}

get_process_for_port() {
    local port="$1"
    local pid
    local comm

    pid=$(sudo ss -tulpen 2>/dev/null | awk -v p=":$port" '$5 ~ p { if (match($0, /pid=([0-9]+)/, m)) { print m[1]; exit } }')
    if [[ -z "$pid" ]]; then
        return 0
    fi

    comm=$(ps -p "$pid" -o comm= 2>/dev/null)
    if [[ -n "$comm" ]]; then
        echo "$comm (pid $pid)"
    else
        echo "pid $pid"
    fi
}

load_previous_ssh_port() {
    local file="/etc/ssh/ssh_ports_opencode"

    if [[ -f "$file" ]]; then
        sudo cat "$file" 2>/dev/null | head -n1
    fi
}

save_ssh_port() {
    local port="$1"
    local file="/etc/ssh/ssh_ports_opencode"

    echo "$port" | sudo tee "$file" >/dev/null
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
