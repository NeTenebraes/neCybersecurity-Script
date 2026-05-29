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


install_burp() {
    local TITLE="Burp Suite Community"
    local BURP_VERSION
    BURP_VERSION=$(get_latest_burp_version)
    local BURP_URL="https://portswigger.net/burp/releases/download?product=community&version=${BURP_VERSION}&type=Linux"

    if detect_burp_binary >/dev/null; then
        local DETECTED_BURP
        DETECTED_BURP=$(detect_burp_binary)
        log_ok "Burp detectado: $DETECTED_BURP ✓"
        create_burp_wrapper "$DETECTED_BURP"
        return 0
    fi

    if command -v burp &>/dev/null; then
        log_ok "Burp detectado: ~/.local/bin/burp ✓"
        return 0
    fi

    if pacman -Q burpsuite &>/dev/null 2>&1; then
        log_ok "Burp detectado: AUR (burpsuite) ✓"
        return 0
    fi

    if flatpak list | grep -q burp; then
        log_ok "Burp detectado: Flatpak ✓"
        return 0
    fi

    log_ok "Burp NO detectado → Instalando..."

    log_msg "📥 Descargando Burp Suite $BURP_VERSION..."
    mkdir -p "$USERHOME/Downloads" "$USERHOME/.local/bin"
    local BURP_SH="$USERHOME/Downloads/burpsuite_community_linux.sh"

    if command -v wget >/dev/null; then
        wget -O "$BURP_SH" "$BURP_URL" || { log_err "Fallo descarga"; return 1; }
    else
        curl -L -o "$BURP_SH" "$BURP_URL" || { log_err "Fallo descarga"; return 1; }
    fi

    chmod +x "$BURP_SH"

    cd "$USERHOME"
    _JAVA_AWT_WM_NONREPARENTING=1 \
    _JAVA_OPTIONS='-Dawt.toolkit.name=MToolkit' \
    QT_QPA_PLATFORM=xcb \
    if ! timeout 600 "$BURP_SH" --auto-install; then
        log_err "Auto-install falló → Método manual..."
        if ask_yes_no "¿Abrir instalador GUI ahora?" "y"; then
            "$BURP_SH" || true
        fi
    fi

    if detect_burp_binary >/dev/null; then
        local DETECTED_BURP
        DETECTED_BURP=$(detect_burp_binary)
        create_burp_wrapper "$DETECTED_BURP"
        log_ok "✅ Burp $BURP_VERSION → ~/.local/bin/burp"
    else
        log_err "❌ Instalación falló"
        return 1
    fi
}

