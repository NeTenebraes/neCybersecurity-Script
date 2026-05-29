#!/bin/bash

# ==================== FIREJAIL BUG BOUNTY ====================
setup_bugbounty_browser() {
    local BUG_BROWSER="$1"
    local BB_PATH="$HOME/.bugbounty_browser_profile"
    local BB_DOWNLOADS="$HOME/Downloads/bugbounty_files"

    mkdir -p "$CFG_FIREJAIL" "$APP_DIR" "$BB_PATH" "$BB_DOWNLOADS"

    if [ ! -f "$BB_PATH/prefs.js" ]; then
        cat > "$BB_PATH/prefs.js" << EOF
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.startup.page", 3);
user_pref("widget.use-xdg-desktop-portal.file-picker", 1);
user_pref("security.cert_pinning.enforcement_level", 1);
EOF
    fi

    cat > "$CFG_FIREJAIL/${BUG_BROWSER}-bugbounty.profile" << EOF
include firefox.profile

# AISLAMIENTO DE DATOS
blacklist \${HOME}/.mozilla/firefox
noblacklist ${BB_PATH}
whitelist ${BB_PATH}
noblacklist ${BB_DOWNLOADS}
whitelist ${BB_DOWNLOADS}

# --- FIX PARA IMPORTAR CERTIFICADOS ---
# Permitir que Firefox gestione su base de datos de seguridad
writable-run-user
ignore memory-deny-write-execute
ignore nodbus

# Comunicación necesaria para el selector de archivos (Certificado .der/.pem)
dbus-user.talk org.freedesktop.portal.Desktop
dbus-user.talk org.freedesktop.portal.Documents
dbus-user.talk org.freedesktop.FileChooser

# Acceso a librerías de seguridad del sistema
noblacklist /etc/ssl
noblacklist /etc/pki
EOF

    cat > "$APP_DIR/${BUG_BROWSER}-bugbounty-firejail.desktop" << EOF
[Desktop Entry]
Name=${BUG_BROWSER^} (Bug Bounty)
Exec=env GTK_USE_PORTAL=1 firejail --profile=$CFG_FIREJAIL/${BUG_BROWSER}-bugbounty.profile $BUG_BROWSER --no-remote --profile ${BB_PATH} %u
Icon=${BUG_BROWSER}
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupWMClass=firefox-bugbounty
EOF

    update-desktop-database "$APP_DIR" 2>/dev/null || true
}

configure_bugbounty_dns() {
    local BUG_BROWSER="$1"
    local PROFILE="$CFG_FIREJAIL/${BUG_BROWSER}-bugbounty.profile"

    echo
    log_msg "🌐 DNS para ${BUG_BROWSER^} Bug Bounty"
    echo "  1) Cloudflare (1.1.1.1) [recomendado]"
    echo "  2) Quad9 (9.9.9.9)"
    echo "  3) Google (8.8.8.8)"
    echo "  4) Sistema"
    read -r -p " > " dns_choice

    sed -i '/^dns /d' "$PROFILE"
    case "$dns_choice" in
        1) echo "dns 1.1.1.1" >> "$PROFILE" && echo "dns 1.0.0.1" >> "$PROFILE" && log_ok "Cloudflare ✓" ;;
        2) echo "dns 9.9.9.9" >> "$PROFILE" && echo "dns 149.112.112.112" >> "$PROFILE" && log_ok "Quad9 ✓" ;;
        3) echo "dns 8.8.8.8" >> "$PROFILE" && echo "dns 8.8.4.4" >> "$PROFILE" && log_ok "Google ✓" ;;
        *) log_msg "Sin DNS específico" ;;
    esac
}
