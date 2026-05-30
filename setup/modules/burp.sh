#!/bin/bash

# ==================== BURP SUITE ====================
get_latest_burp_version() {
    local releases_url="https://portswigger.net/burp/releases?product=community"
    local html
    local version

    if command -v curl >/dev/null; then
        html=$(curl -s "$releases_url")
    else
        html=$(wget -qO- "$releases_url")
    fi

    version=$(echo "$html" | grep -oE 'Professional / Community [0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?')

    if [[ -z "$version" ]]; then
        log_err "No se pudo detectar versión de Burp. Usando 2026.4.3"
        version="2026.4.3"
    fi

    echo "$version"
}

detect_burp_binary() {
    if [[ -x "$USERHOME/BurpSuiteCommunity/BurpSuiteCommunity" ]]; then
        echo "$USERHOME/BurpSuiteCommunity/BurpSuiteCommunity"
        return 0
    fi

    if [[ -x "/opt/BurpSuiteCommunity/BurpSuiteCommunity" ]]; then
        echo "/opt/BurpSuiteCommunity/BurpSuiteCommunity"
        return 0
    fi

    if find "$USERHOME" -maxdepth 3 -name "*BurpSuite*" -type f -executable 2>/dev/null | grep -q .; then
        find "$USERHOME" -maxdepth 3 -name "*BurpSuite*" -type f -executable | head -1
        return 0
    fi

    return 1
}

# ==================== BURP HELPERS ====================
create_burp_wrapper() {
    local BURPBIN="$1"
    local WRAPPER="$USERHOME/.local/bin/burp"
    mkdir -p "$USERHOME/.local/bin"
    cat > "$WRAPPER" << EOF
#!/bin/bash
export _JAVA_AWT_WM_NONREPARENTING=1
export _JAVA_OPTIONS='-Dawt.toolkit.name=MToolkit -Djava.security.manager=allow'
exec "$BURPBIN" "\$@"
EOF
    chmod +x "$WRAPPER"
    log_ok "Wrapper creado: $WRAPPER"
}


ensure_burp_installer() {
    local version="$1"
    local burp_dir="$USERHOME/$BURP_INSTALL_DIR"
    local burp_sh="$burp_dir/$BURP_INSTALLER_NAME"
    local burp_version_file="$burp_dir/burp_version.txt"
    local min_size="$BURP_MIN_SIZE_BYTES"
    local download_url="https://portswigger.net/burp/releases/download?product=desktop&version=${version}&type=Linux"
    local needs_download="false"

    mkdir -p "$burp_dir"

    if [[ -f "$burp_sh" ]]; then
        local size
        size=$(stat -c%s "$burp_sh" 2>/dev/null || echo 0)
        if (( size < min_size )); then
            needs_download="true"
        elif [[ ! -f "$burp_version_file" ]] || [[ "$(cat "$burp_version_file")" != "$version" ]]; then
            needs_download="true"
        fi
    else
        needs_download="true"
    fi

    if [[ "$needs_download" == "true" ]]; then
        log_msg "Descargando Burp Suite $version en $burp_dir..." >&2
        local tmp_file="$burp_dir/burpsuite_community_linux.sh.tmp"
        if command -v wget >/dev/null; then
            wget -O "$tmp_file" "$download_url" || { log_err "DESCARGA DE BURP FALLO descargar desde: $download_url"; return 1; }
        else
            curl -L -o "$tmp_file" "$download_url" || { log_err "DESCARGA DE BURP FALLO descargar desde: $download_url"; return 1; }
        fi

        local tmp_size
        tmp_size=$(stat -c%s "$tmp_file" 2>/dev/null || echo 0)
        if (( tmp_size < min_size )); then
            rm -f "$tmp_file"
            log_err "DESCARGA DE BURP FALLO descargar desde: $download_url"
            return 1
        fi

        mv "$tmp_file" "$burp_sh"
        chmod +x "$burp_sh"
        echo "$version" > "$burp_version_file"
        log_ok "Instalador Burp actualizado: $burp_sh" >&2
    else
        log_ok "Instalador Burp ya actualizado: $burp_sh" >&2
    fi

    echo "$burp_sh"
}

run_burp_installer() {
    local burp_sh="$1"
    local display
    local xauth

    display="${DISPLAY:-}"
    if [[ -z "$display" ]]; then
        display=$(detect_display)
    fi

    xauth="$USERHOME/.Xauthority"
    if [[ ! -f "$xauth" ]]; then
        xauth=""
    fi

    if [[ -z "$display" ]]; then
        log_err "DISPLAY no definido. Ejecuta el instalador desde una sesion grafica: $burp_sh"
        return 1
    fi

    if [[ $EUID -eq 0 ]]; then
        if [[ -n "$xauth" ]]; then
            sudo -u "$REALUSER" env \
                DISPLAY="$display" \
                XAUTHORITY="$xauth" \
                _JAVA_AWT_WM_NONREPARENTING=1 \
                _JAVA_OPTIONS='-Dawt.toolkit.name=MToolkit' \
                QT_QPA_PLATFORM=xcb \
                "$burp_sh"
        else
            sudo -u "$REALUSER" env \
                DISPLAY="$display" \
                _JAVA_AWT_WM_NONREPARENTING=1 \
                _JAVA_OPTIONS='-Dawt.toolkit.name=MToolkit' \
                QT_QPA_PLATFORM=xcb \
                "$burp_sh"
        fi
    else
        if [[ -n "$xauth" ]]; then
            env \
                DISPLAY="$display" \
                XAUTHORITY="$xauth" \
                _JAVA_AWT_WM_NONREPARENTING=1 \
                _JAVA_OPTIONS='-Dawt.toolkit.name=MToolkit' \
                QT_QPA_PLATFORM=xcb \
                "$burp_sh"
        else
            env \
                DISPLAY="$display" \
                _JAVA_AWT_WM_NONREPARENTING=1 \
                _JAVA_OPTIONS='-Dawt.toolkit.name=MToolkit' \
                QT_QPA_PLATFORM=xcb \
                "$burp_sh"
        fi
    fi
}

detect_display() {
    local display

    if [[ -n "${DISPLAY:-}" ]]; then
        echo "$DISPLAY"
        return 0
    fi

    display=$(ls /tmp/.X11-unix/X* 2>/dev/null | head -n1)
    if [[ -n "$display" ]]; then
        echo ":${display##*/X}"
        return 0
    fi

    return 1
}

install_burp() {
    local TITLE="Burp Suite Community"
    local BURP_VERSION
    BURP_VERSION=$(get_latest_burp_version)

    if detect_burp_binary >/dev/null; then
        local DETECTED_BURP
        DETECTED_BURP=$(detect_burp_binary)
        log_ok "Burp detectado: $DETECTED_BURP"
        create_burp_wrapper "$DETECTED_BURP"
        return 0
    fi

    if command -v burp &>/dev/null; then
        log_ok "Burp detectado: ~/.local/bin/burp"
        return 0
    fi

    if pacman -Q burpsuite &>/dev/null 2>&1; then
        log_ok "Burp detectado: AUR (burpsuite)"
        return 0
    fi

    log_ok "Burp no detectado. Abriendo instalador..."

    local BURP_SH
    if ! BURP_SH=$(ensure_burp_installer "$BURP_VERSION"); then
        return 0
    fi

    if ! run_burp_installer "$BURP_SH"; then
        return 0
    fi

    if detect_burp_binary >/dev/null; then
        local DETECTED_BURP
        DETECTED_BURP=$(detect_burp_binary)
        create_burp_wrapper "$DETECTED_BURP"
        log_ok "Burp instalado: $DETECTED_BURP"
    else
        log_err "Burp no detectado despues de la instalacion"
    fi
}
