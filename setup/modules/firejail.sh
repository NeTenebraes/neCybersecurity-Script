#!/bin/bash

# ==================== FIREJAIL ====================
detect_browser() {
    local browsers=()
    [[ $(command -v firefox) ]] && browsers+=("firefox")
    [[ $(command -v chromium) ]] && browsers+=("chromium")
    [[ $(command -v brave-browser) ]] && browsers+=("brave")
    [[ $(command -v librewolf) ]] && browsers+=("librewolf")
    [[ $(command -v google-chrome) ]] && browsers+=("google-chrome")
    [[ $(command -v brave) ]] && browsers+=("brave")
    printf '%s\n' "${browsers[@]}"
}

install_firejail() {
    if check_cmd firejail; then
    log_ok "Firejail ya instalado"
    return 0
    fi
    log_msg "Instalando Firejail…"
    sudo pacman -S --needed --noconfirm firejail
    log_ok "Firejail instalado"
}

setup_firejail_global() {
    echo
    log_msg "¿Firejail GLOBAL para apps basicas? (firefox->firejail firefox)"
    if ask_yes_no "Activar Firejail GLOBAL" "n"; then
        if [[ $EUID -eq 0 ]]; then
            sudo -u "$REALUSER" firecfg --fix >/dev/null
        else
            firecfg --fix >/dev/null
        fi
        log_ok "Firejail GLOBAL activado"
    fi
}

setup_personal_browser() {
    local PERSONAL_BROWSER="$1"
    local FULL_FIREJAIL
    local FULL_BROWSER
    local FULL_PROFILE
    FULL_FIREJAIL=$(which firejail)
    FULL_BROWSER=$(which "$PERSONAL_BROWSER")
    FULL_PROFILE="$CFG_FIREJAIL/${PERSONAL_BROWSER}-personal.profile"

    mkdir -p "$CFG_FIREJAIL" "$APP_DIR"

    touch "$FULL_PROFILE"

    cat > "$APP_DIR/${PERSONAL_BROWSER}-personal-firejail.desktop" << EOF
[Desktop Entry]
Name=${PERSONAL_BROWSER^} (Personal)
Comment=${PERSONAL_BROWSER^} Firejail - File Uploads OK
Exec=$FULL_FIREJAIL --profile=$FULL_PROFILE $FULL_BROWSER %u
Icon=${PERSONAL_BROWSER}
Terminal=false
Type=Application
Categories=Network;WebBrowser;
StartupWMClass=${PERSONAL_BROWSER}
EOF

    local LOCAL_DESKTOP="$APP_DIR/${PERSONAL_BROWSER}.desktop"
    cat > "$LOCAL_DESKTOP" << EOF
[Desktop Entry]
Type=Application
Name=${PERSONAL_BROWSER^} (hidden)
Exec=$FULL_BROWSER %u
Icon=${PERSONAL_BROWSER}
NoDisplay=true
EOF

    update-desktop-database "$APP_DIR" 2>/dev/null || true
    log_ok "${PERSONAL_BROWSER^} (Personal) listo"
}

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

    sed -i '/^dns /d' "$PROFILE"

    if ! dns_prompt "DNS para ${BUG_BROWSER^} Bug Bounty" "true"; then
        log_msg "Sin DNS específico"
        return 0
    fi

    if [[ "$DNS_TARGET_IPS" == "auto" ]]; then
        log_msg "Sin DNS específico"
        return 0
    fi

    local ip
    for ip in $DNS_TARGET_IPS; do
        echo "dns $ip" >> "$PROFILE"
    done

    log_ok "$DNS_PROVIDER_NAME"
}

setup_firejail_browsers() {
    install_firejail
    setup_firejail_global

    local AVAILABLE_BROWSERS=($(detect_browser))
    if [[ ${#AVAILABLE_BROWSERS[@]} -eq 0 ]]; then
        log_err "No se detectó ningún navegador"
        return 1
    fi

    echo
    log_msg "Navegadores detectados:"
    printf '   %s\n' "${AVAILABLE_BROWSERS[@]}"
    echo

    read -r -p "¿Cuál usar como PERSONAL? " personal_choice
    if [[ ! " ${AVAILABLE_BROWSERS[*]} " =~ " $personal_choice " ]]; then
        log_err "Navegador no válido. Usando: ${AVAILABLE_BROWSERS[0]}"
        personal_choice="${AVAILABLE_BROWSERS[0]}"
    fi
    setup_personal_browser "$personal_choice"

    echo
    if ask_yes_no "¿Quieres navegador BUG BOUNTY separado?" "n"; then
        echo
        log_msg "Elige navegador para BUG BOUNTY:"
        printf '   %s\n' "${AVAILABLE_BROWSERS[@]}"
        read -r -p " > " bug_choice_browser

        if [[ ! " ${AVAILABLE_BROWSERS[*]} " =~ " $bug_choice_browser " ]]; then
            log_err "Usando: ${AVAILABLE_BROWSERS[0]}"
            bug_choice_browser="${AVAILABLE_BROWSERS[0]}"
        fi

        setup_bugbounty_browser "$bug_choice_browser"
        configure_bugbounty_dns "$bug_choice_browser"
    fi

    echo
    log_ok "Listo"
    if [[ -n "${bug_choice_browser:-}" ]]; then
        echo "rofi drun -> '${personal_choice^} (Personal)' | '${bug_choice_browser^} (Bug Bounty)'"
    else
        echo "rofi drun -> '${personal_choice^} (Personal)'"
    fi
}
