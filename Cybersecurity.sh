#!/bin/bash

set -euo pipefail

BASE_DIR="$(pwd)"

source "$BASE_DIR/setup/config.sh"

source "$BASE_DIR/setup/lib/helpers.sh"
source "$BASE_DIR/setup/lib/aur.sh"

source "$BASE_DIR/setup/modules/burp.sh"
source "$BASE_DIR/setup/modules/caido.sh"
source "$BASE_DIR/setup/modules/dns.sh"
source "$BASE_DIR/setup/modules/firejail.sh"
source "$BASE_DIR/setup/modules/firewall.sh"
source "$BASE_DIR/setup/modules/ssh_security.sh"
source "$BASE_DIR/setup/modules/virtualbox.sh"
source "$BASE_DIR/setup/modules/vmware.sh"

KERNEL_HEADERS=$(detect_kernel_headers)

main() {
    require_sudo

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

    log_ok "Listo. Reinicia sesion -> burp, caido, virtualbox, vmware"
}

main "$@"
