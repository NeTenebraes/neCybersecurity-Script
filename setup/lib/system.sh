#!/bin/bash

# ==================== SYSTEM HELPERS ====================
detect_kernel_headers() {
    local KERNEL
    KERNEL=$(uname -r | sed 's/\([0-9]\+\.[0-9]\+\.[0-9]\+\)-\(.*\)/\2/')
    case "$KERNEL" in
        *-hardened*) echo "linux-hardened-headers" ;;
        *-zen*)      echo "linux-zen-headers" ;;
        *-lts*)      echo "linux-lts-headers" ;;
        *)           echo "linux-headers" ;;
    esac
}

check_cmd() { command -v "$1" &>/dev/null; }
