#!/bin/bash

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
