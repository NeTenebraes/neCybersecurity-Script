#!/bin/bash

# ==================== CAIDO ====================
install_caido() {
    local DIR="$USERHOME/.local/share/ciber"
    local BINDIR="$USERHOME/.local/bin"

    mkdir -p "$BINDIR" "$DIR" "$USERHOME/.local/share/applications" "$USERHOME/.local/share/icons"
    log_msg "Configurando icono Caido..."
    wget -q "$CAIDO_ICON_URL" -O "$USERHOME/.local/share/icons/caido.png"

    if [[ "$(uname -r)" == *"-hardened"* ]]; then
        log_msg "Detectado kernel hardened: Asegurando compatibilidad con Sandbox..."
        if [[ $(sysctl -n kernel.unprivileged_userns_clone) -eq 0 ]]; then
            sudo sysctl -w kernel.unprivileged_userns_clone=1
            echo 'kernel.unprivileged_userns_clone=1' | sudo tee /etc/sysctl.d/99-user-namespaces.conf > /dev/null
        fi
    fi

    cat > "$USERHOME/.local/share/applications/caido.desktop" << EOF
[Desktop Entry]
Version=1.0
Name=CaiDO
Comment=Web Security Testing Proxy
Exec=/home/$REALUSER/.local/bin/caido
Icon=caido
Terminal=false
Type=Application
Categories=Network;Security;Hacking;
StartupWMClass=Caido
MimeType=application/x-caido;
EOF
    update-desktop-database "$USERHOME/.local/share/applications"

    local CAIDOVERSION
    CAIDOVERSION=$(curl -s "$CAIDO_GITHUB_API" | grep tag_name | sed -E 's/.*"([^"]+)".*/\1/')
    local CAIDOAPPIMAGE="$BINDIR/caido-desktop-${CAIDOVERSION}-linux-x86_64.AppImage"

    if [[ ! -x "$CAIDOAPPIMAGE" ]] || [[ ! -f "$DIR/caidoversion.txt" ]] || [[ "$(cat "$DIR/caidoversion.txt")" != "$CAIDOVERSION" ]]; then
        log_msg "DESCARGANDO Caido $CAIDOVERSION..."
        rm -f "$BINDIR/caido-desktop-"*.AppImage
        wget --timeout=60 "${CAIDO_BASE_URL}/${CAIDOVERSION}/caido-desktop-${CAIDOVERSION}-linux-x86_64.AppImage" -O "$CAIDOAPPIMAGE"
        chmod +x "$CAIDOAPPIMAGE"
        echo "$CAIDOVERSION" > "$DIR/caidoversion.txt"
    else
        log_ok "Caido ya actualizado ($CAIDOVERSION)."
    fi

    rm -f "$BINDIR/caido"
    ln -sf "$CAIDOAPPIMAGE" "$BINDIR/caido"

    if ! grep -q ".local/bin" "$USERHOME/.bashrc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$USERHOME/.bashrc"
    fi

    log_ok "Caido OK"
}
