#!/bin/bash

# ==================== INSTALADOR VIRTUALBOX ====================
install_virtualbox() {
    local TITLE="VirtualBox"
    if check_cmd virtualbox && lsmod | grep -q vboxdrv && ip link show vboxnet0 &>/dev/null; then
        log_ok "$TITLE + RED ✅ YA FUNCIONANDO"
        return 0
    fi
    local PKGS=("${PKGS_VIRTUALBOX[@]}" "$KERNEL_HEADERS")
    log_msg "Instalando: ${PKGS[*]}"
    if ! check_cmd virtualbox; then
        sudo pacman -S --needed --noconfirm "${PKGS[@]}"
    else
        sudo pacman -S --noconfirm virtualbox-host-dkms "$KERNEL_HEADERS"
    fi
    sudo dkms autoinstall --force
    sudo modprobe -r vboxnetadp vboxnetflt vboxdrv 2>/dev/null || true
    sudo modprobe vboxdrv vboxnetflt vboxnetadp
    sudo VBoxManage hostonlyif create 2>/dev/null || true
    sudo usermod -aG vboxusers "$REALUSER"
    create_vbox_service
    log_ok "$TITLE ✅ LISTO + AUTO-START"
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
    sudo systemctl enable --now vbox-modules
    log_ok "✅ vbox-modules.service CREADO + ACTIVADO"
}
