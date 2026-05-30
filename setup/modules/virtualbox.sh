#!/bin/bash

# ==================== INSTALADOR VIRTUALBOX ====================
install_virtualbox() {
    local TITLE="VirtualBox"
    if check_cmd virtualbox; then
        log_ok "$TITLE YA INSTALADO"
        sudo pacman -S --noconfirm --needed virtualbox-host-dkms "$KERNEL_HEADERS" >/dev/null
        sudo dkms autoinstall --force >/dev/null 2>&1

        if ! lsmod | grep -q '^vboxdrv'; then
            sudo modprobe -r vboxnetadp vboxnetflt vboxdrv >/dev/null 2>&1 || true
            sudo modprobe vboxdrv vboxnetflt vboxnetadp >/dev/null 2>&1
        fi

        sudo VBoxManage hostonlyif create >/dev/null 2>&1 || true
        sudo usermod -aG vboxusers "$REALUSER"
        create_vbox_service
        log_ok "$TITLE actualizado"
        return 0
    fi
    local PKGS=("${PKGS_VIRTUALBOX[@]}" "$KERNEL_HEADERS")
    log_msg "Instalando: ${PKGS[*]}"
    if ! check_cmd virtualbox; then
        sudo pacman -S --needed --noconfirm "${PKGS[@]}" >/dev/null
    else
        sudo pacman -S --noconfirm virtualbox-host-dkms "$KERNEL_HEADERS" >/dev/null
    fi
    sudo dkms autoinstall --force >/dev/null 2>&1
    sudo modprobe -r vboxnetadp vboxnetflt vboxdrv >/dev/null 2>&1 || true
    sudo modprobe vboxdrv vboxnetflt vboxnetadp >/dev/null 2>&1
    sudo VBoxManage hostonlyif create >/dev/null 2>&1 || true
    sudo usermod -aG vboxusers "$REALUSER"
    create_vbox_service
    log_ok "$TITLE listo (auto-start)"
}

create_vbox_service() {
    local SERVICE_FILE="/etc/systemd/system/vbox-modules.service"
    sudo systemctl stop vbox-modules.service 2>/dev/null || true
    sudo rm -f "$SERVICE_FILE"
    sudo tee "$SERVICE_FILE" > /dev/null << 'EOF'
[Unit]
Description=VirtualBox Kernel Modules
Before=graphical-session.target
After=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStartPre=/usr/bin/dkms autoinstall --force
ExecStart=/usr/bin/modprobe vboxdrv vboxnetflt vboxnetadp
ExecStop=/usr/bin/modprobe -r vboxnetadp vboxnetflt vboxdrv
TimeoutSec=30

[Install]
WantedBy=multi-user.target
EOF
    sudo systemctl daemon-reload
    sudo systemctl enable --now vbox-modules >/dev/null
    log_ok "vbox-modules.service creado y activado"
}
