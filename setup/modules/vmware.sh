#!/bin/bash

# ==================== INSTALADOR VMWARE ====================
install_vmware() {
    local TITLE="VMware Workstation"

    if check_cmd vmware; then
        log_ok "$TITLE YA INSTALADO"
        sudo systemctl daemon-reload
        systemctl list-unit-files vmware-networks.service &>/dev/null && \
            sudo systemctl enable vmware-networks.service vmware-usbarbitrator.service

        if ! lsmod | grep -q '^vmmon'; then
            if ! sudo modprobe vmmon 2>/dev/null; then
                sudo vmware-modconfig --console --install-all || true
            fi
        fi
        return 0
    fi

    log_msg "PREPARANDO $TITLE ..."

    local PKGS_VMWARE_EXT=("${PKGS_VMWARE[@]}" "$KERNEL_HEADERS")
    sudo pacman -S --noconfirm --needed "${PKGS_VMWARE_EXT[@]}"

    log_msg "Instalando paquetes AUR: ${AUR_VMWARE[*]}"
    if ! aur_install "${AUR_VMWARE[@]}"; then
        log_err "VMware desde AUR falló. Revisa: ${AUR_VMWARE[*]}"
        return 1
    fi

    if ! check_cmd vmware; then
        log_err "$TITLE no instalado correctamente"
        return 1
    fi

    sudo systemctl daemon-reload
    systemctl list-unit-files vmware-networks.service &>/dev/null && \
        sudo systemctl enable vmware-networks.service vmware-usbarbitrator.service

    sudo vmware-modconfig --console --install-all || true
    log_ok "$TITLE OK. Ejecuta 'vmware' para setup inicial"
}
