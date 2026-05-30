#!/bin/bash
# ==================== LOGGING ====================
log_ok()  { echo "[OK] $1"; }
log_msg() { echo "[MSG] $1"; }
log_err() { echo "[ERR] $1" >&2; }

check_cmd() { command -v "$1" &>/dev/null; }

# ==================== SYSTEM HELPERS ====================
detect_kernel_headers() {
    local KERNEL
    KERNEL=$(uname -r | sed 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\)-\(.*\)/\2/')
    case "$KERNEL" in
        *-hardened*) echo "linux-hardened-headers" ;;
        *-zen*)      echo "linux-zen-headers" ;;
        *-lts*)      echo "linux-lts-headers" ;;
        *)           echo "linux-headers" ;;
    esac
}

# ==================== HELPERS ====================
ask_yes_no() {
    local prompt="$1"
    local default="${2:-n}"
    local suffix
    local reply

    if [[ "$default" =~ ^([yY]|[sS])$ ]]; then
        suffix="[Y/n]"
    else
        suffix="[y/N]"
    fi

    while true; do
        read -r -p "$prompt $suffix " reply

        if [[ -z "$reply" ]]; then
            reply="$default"
        fi

        case "$reply" in
            [yY]|[yY][eE][sS]|[sS]|[sS][iI]) return 0 ;;
            [nN]|[nN][oO]) return 1 ;;
            *) log_msg "Respuesta no válida. Usa y/n." ;;
        esac
    done
}

require_sudo() {
    sudo -k
    if sudo -v; then
        log_ok "Sesion sudo cacheada"
    else
        log_err "No se pudo obtener sudo"
        exit 1
    fi
}
