#!/bin/bash

set -euo pipefail

source "$(pwd)/setup/config.sh"

source "$(pwd)/setup/lib/logging.sh"
source "$(pwd)/setup/lib/system.sh"
source "$(pwd)/setup/lib/aur.sh"
source "$(pwd)/setup/lib/burp.sh"

source "$(pwd)/setup/modules/vmware.sh"
source "$(pwd)/setup/modules/virtualbox.sh"
source "$(pwd)/setup/modules/burp.sh"
source "$(pwd)/setup/modules/caido.sh"
source "$(pwd)/setup/modules/firejail_core.sh"
source "$(pwd)/setup/modules/firejail_personal.sh"
source "$(pwd)/setup/modules/firejail_bugbounty.sh"
source "$(pwd)/setup/modules/firejail_orchestrator.sh"
source "$(pwd)/setup/modules/firewall.sh"
source "$(pwd)/setup/modules/dns.sh"

KERNEL_HEADERS=$(detect_kernel_headers)
log_msg "Kernel detectado: $(uname -r) → Usando: $KERNEL_HEADERS"

main() {
    if sudo -v; then
        log_ok "Sesion sudo cacheada ✅"
    else
        log_err "No se pudo obtener sudo"
        exit 1
    fi

    log_msg "Kernel: $(uname -r) | Headers: $KERNEL_HEADERS"

    setup_firewall
    setup_dns

    read -r -p "¿VMs (VirtualBox/VMware)? [y/N] " choice
    case "$choice" in [Yy]*)
        install_virtualbox
        install_vmware
    ;; *)
        log_msg "Saltando VMs"
    esac

    read -r -p "¿Burp/Caido? [y/N] " choice
    case "$choice" in [Yy]*)
        install_burp
        install_caido
    ;; *)
        log_msg "Saltando Burp/Caido"
    esac

    setup_firejail_browsers

    log_ok "¡LISTO! Reinicia sesión → burp, caido, virtualbox, vmware"
}

main "$@"
