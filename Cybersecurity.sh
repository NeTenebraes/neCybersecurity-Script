#!/bin/bash

set -euo pipefail

source "$(pwd)/setup/config.sh"

source "$(pwd)/setup/lib/helpers.sh"
source "$(pwd)/setup/lib/aur.sh"

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
source "$(pwd)/setup/modules/ssh_security.sh"

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
    setup_ssh_security

    if ask_yes_no "¿VMs (VirtualBox/VMware)?" "n"; then
        install_virtualbox
        install_vmware
    else
        log_msg "Saltando VMs"
    fi

    if ask_yes_no "¿Burp/Caido?" "n"; then
        install_burp
        install_caido
    else
        log_msg "Saltando Burp/Caido"
    fi

    setup_firejail_browsers

    log_ok "¡LISTO! Reinicia sesión → burp, caido, virtualbox, vmware"
}

main "$@"
