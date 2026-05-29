#!/bin/bash

# ==================== FIREJAIL PERSONAL ====================
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
    log_ok "${PERSONAL_BROWSER^} (Personal) ✓ ROFI + File Picker OK"
}
