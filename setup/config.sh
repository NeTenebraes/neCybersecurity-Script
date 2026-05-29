#!/bin/bash

# ==================== CONFIGURACION CENTRALIZADA ====================
set -euo pipefail

# URLs y recursos criticos
BURP_URL="https://portswigger.net/burp/releases/download?product=community&version=2025.11.6&type=Linux"
CAIDO_GITHUB_API="https://api.github.com/repos/caido/caido/releases/latest"
CAIDO_BASE_URL="https://caido.download/releases"
CAIDO_ICON_URL="https://cdn.brandfetch.io/idFdZwH_n_/w/500/h/500/theme/dark/logo.png?c=1bxid64Mup7aczewSAYMX&t=1764981790594"
AUR_REPO="https://aur.archlinux.org/paru-bin.git"

# Paquetes por categoria
PKGS_VIRTUALBOX=("virtualbox" "virtualbox-host-dkms")
PKGS_VMWARE=("fuse2" "dkms" "libcanberra" "gtkmm3" "gst-plugins-base-libs" "pcsclite")
AUR_VMWARE=("vmware-keymaps" "vmware-workstation")

# Rutas del sistema
REALUSER="${SUDO_USER:-${USER}}"
if [[ $EUID -eq 0 ]]; then
    REALUSER="$(logname 2>/dev/null || whoami)"
fi
USERHOME="$(getent passwd "$REALUSER" | cut -d: -f6)"
CFG_FIREJAIL="$USERHOME/.config/firejail"
APP_DIR="$USERHOME/.local/share/applications"
