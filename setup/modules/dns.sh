#!/bin/bash

# ==================== DNS ====================
dns_prompt() {
    local title="$1"
    local allow_skip="${2:-true}"
    local dns_choice

    echo "------------------------------------------------"
    echo "$title"
    echo "------------------------------------------------"
    echo "1) Cloudflare (1.1.1.1, 1.0.0.1)"
    echo "2) Quad9      (9.9.9.9, 149.112.112.112)"
    echo "3) Google     (8.8.8.8, 8.8.4.4)"
    echo "4) Automático (ISP - DHCP)"
    if [[ "$allow_skip" == "true" ]]; then
        echo "5) Saltar"
    fi
    read -r -p " Selecciona una opción: " dns_choice

    if [[ -z "$dns_choice" ]]; then
        dns_choice=1
    fi

    case "$dns_choice" in
        1) DNS_TARGET_IPS="1.1.1.1 1.0.0.1"; DNS_PROVIDER_NAME="Cloudflare" ;;
        2) DNS_TARGET_IPS="9.9.9.9 149.112.112.112"; DNS_PROVIDER_NAME="Quad9" ;;
        3) DNS_TARGET_IPS="8.8.8.8 8.8.4.4"; DNS_PROVIDER_NAME="Google" ;;
        4) DNS_TARGET_IPS="auto"; DNS_PROVIDER_NAME="ISP (Auto)" ;;
        5) return 1 ;;
        *) return 1 ;;
    esac

    return 0
}

setup_dns() {
    if ! dns_prompt "CONFIGURACION DNS PERSISTENTE (NM DISPATCHER)" "true"; then
        return 0
    fi

    if [[ ! -L "/etc/resolv.conf" ]]; then
        sudo rm -f /etc/resolv.conf
        sudo ln -sf /run/NetworkManager/resolv.conf /etc/resolv.conf
        echo "[+] Enlace simbólico resolv.conf creado."
    fi

    echo "$DNS_TARGET_IPS" | sudo tee /etc/NetworkManager/dns-preference > /dev/null

    sudo tee /etc/NetworkManager/dispatcher.d/99-dns-exclusive > /dev/null << 'EOF'
#!/bin/bash
# Script de persistencia DNS para evitar multiplexing
interface=$1
status=$2
DNS_PREF="/etc/NetworkManager/dns-preference"

if [ "$status" = "up" ] && [ -f "$DNS_PREF" ]; then
    # Pequeña espera para asegurar que el DHCP ya entregó sus datos
    sleep 2
    TARGET=$(cat "$DNS_PREF")

    if [ "$TARGET" != "auto" ]; then
        # Obtener el UUID de la conexión activa en la interfaz actual
        UUID=$(nmcli -t -f uuid,device connection show --active | grep "$interface" | cut -d: -f1)

        if [ -n "$UUID" ]; then
            # Configurar prioridad máxima y omitir DNS del ISP
            nmcli connection modify "$UUID" \
                ipv4.ignore-auto-dns yes \
                ipv4.dns "$TARGET" \
                ipv4.dns-priority -1

            # Re-aplicar cambios sin reiniciar la conexión (evita bucles infinitos)
            nmcli device reapply "$interface" > /dev/null 2>&1
        fi
    fi
fi
EOF

    sudo chmod +x /etc/NetworkManager/dispatcher.d/99-dns-exclusive

    local active_conn
    active_conn=$(nmcli -t -f NAME connection show --active | head -n1)

    if [[ -n "$active_conn" ]]; then
        echo "[*] Aplicando $DNS_PROVIDER_NAME a la conexión activa: $active_conn"
        if [[ "$DNS_TARGET_IPS" == "auto" ]]; then
            sudo nmcli connection modify "$active_conn" ipv4.ignore-auto-dns no ipv4.dns "" ipv4.dns-priority 0
        else
            sudo nmcli connection modify "$active_conn" ipv4.ignore-auto-dns yes ipv4.dns "$DNS_TARGET_IPS" ipv4.dns-priority -1
        fi

        sudo nmcli connection up "$active_conn" > /dev/null 2>&1
    fi

    echo "OK: DNS configurado como $DNS_PROVIDER_NAME."
    echo "Nota: Se mantendra en redes nuevas via dispatcher."
}
