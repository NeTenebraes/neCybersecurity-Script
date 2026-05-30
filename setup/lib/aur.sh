#!/bin/bash

# ==================== AUR HELPER ====================
install_aur_helper() {
    # --- LÓGICA AUR HELPER: DETECTAR O INSTALAR ---
    local helpers=("yay-bin" "paru" "yay")
    local aur_helper=""

    # 1. Intentar detectar un helper ya instalado
    for h in "paru" "yay"; do
        if command -v "$h" >/dev/null; then
            aur_helper="$h"
            break
        fi
    done

    if [[ -n "$aur_helper" ]]; then
        log_ok "Se detectó '$aur_helper' instalado."
        if ! ask_yes_no "¿Deseas seguir usando $aur_helper?" "y"; then
            aur_helper=""
        fi
    fi

    # 2. Si no hay ninguno o el usuario decidió cambiarlo
    if [[ -z "$aur_helper" ]]; then
        echo -e "\n--- Instalación de AUR Helper ---"
        PS3="Selecciona cuál deseas instalar: "
        select opt in "${helpers[@]}" "Cancelar"; do
            case $opt in
                "yay-bin"|"paru"|"yay")
                    # Si había uno anterior, lo quitamos para no tener conflictos
                    # Buscamos si existe algun binario para borrarlo antes
                    for old in "paru" "yay"; do
                        if command -v "$old" >/dev/null; then
                            log_msg "Eliminando $old antiguo..."
                            sudo pacman -Rs --noconfirm "$old"
                        fi
                    done

                    log_msg "Instalando $opt..."
                    sudo pacman -S --needed --noconfirm base-devel git

                    build_dir=$(mktemp -d)
                    git clone "https://aur.archlinux.org/$opt.git" "$build_dir"
                    (cd "$build_dir" && makepkg -si --noconfirm)
                    rm -rf "$build_dir"

                    aur_helper="${opt%-bin}"
                    break
                    ;;
                "Cancelar")
                    log_err "No se seleccionó ningún AUR Helper. Saliendo..."
                    exit 1
                    ;;
                *) echo "Opción no válida";;
            esac
        done
    fi

    log_ok "Usando $aur_helper para el resto de la instalación."
    echo "$aur_helper"
}

aur_install() {
    local aur_helper
    aur_helper=$(install_aur_helper)
    log_msg "Instalando paquetes AUR: $*"

    if ! "$aur_helper" -S --noconfirm "$@"; then
        log_err "Fallo instalando algunos paquetes AUR: $*"
        return 1
    fi

    log_ok "AUR completado: $*"
}
