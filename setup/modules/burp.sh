#!/bin/bash

# ==================== BURP SUITE ====================
install_burp() {
    local TITLE="Burp Suite Community"

    if [[ -x "$USERHOME/BurpSuiteCommunity/BurpSuiteCommunity" ]]; then
        log_ok "Burp detectado: ~/BurpSuiteCommunity ✓"
        create_burp_wrapper "$USERHOME/BurpSuiteCommunity/BurpSuiteCommunity"
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

    if find "$USERHOME" -maxdepth 3 -name "*BurpSuite*" -type f -executable 2>/dev/null | grep -q .; then
        local BURP_EXIST
        BURP_EXIST=$(find "$USERHOME" -maxdepth 3 -name "*BurpSuite*" -type f -executable | head -1)
        log_ok "Burp detectado: $BURP_EXIST ✓"
        create_burp_wrapper "$BURP_EXIST"
        return 0
    fi

    if flatpak list | grep -q burp; then
        log_ok "Burp detectado: Flatpak ✓"
        return 0
    fi

    log_ok "Burp NO detectado → Instalando..."

    log_msg "📥 Descargando Burp Suite 2025.11.6 (341MB)..."
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
    timeout 600 "$BURP_SH" --auto-install || {
        log_err "Auto-install falló → Método manual..."
    }

    if [[ -x "$USERHOME/BurpSuiteCommunity/BurpSuiteCommunity" ]]; then
        create_burp_wrapper "$USERHOME/BurpSuiteCommunity/BurpSuiteCommunity"
        log_ok "✅ Burp 2025.11.6 → ~/.local/bin/burp"
    else
        log_err "❌ Instalación falló"
        return 1
    fi
}
