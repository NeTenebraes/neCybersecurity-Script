#!/bin/bash

# ==================== FIREJAIL ORQUESTADOR ====================
setup_firejail_browsers() {
    install_firejail
    setup_firejail_global

    local AVAILABLE_BROWSERS=($(detect_browser))
    if [[ ${#AVAILABLE_BROWSERS[@]} -eq 0 ]]; then
        log_err "❌ No se detectó ningún navegador"
        return 1
    fi

    echo
    log_msg "🦊 Navegadores detectados:"
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
    log_ok "✅ ¡LISTO!"
    if [[ -n "${bug_choice_browser:-}" ]]; then
        echo "rofi drun → '${personal_choice^} (Personal)' | '${bug_choice_browser^} (Bug Bounty)'"
    else
        echo "rofi drun → '${personal_choice^} (Personal)'"
    fi
}
