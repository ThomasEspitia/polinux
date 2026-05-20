#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 02-temas.sh — Instalación y aplicación de temas visuales
#
# Estructura esperada en el repo:
#   temas/
#     blue-dark/
#       cursor/
#         cursors-blue-dark/
#         cursors-dar-blue-dark/      ← se aplica este
#       icons/
#         icons-blue-dark/            ← se aplica este
#         icons-dark-blue-dark/
#         icons-light-blue-dark/
#       theme-blue-dark/              ← Jasper-Blue-Dark
#       wallpaper-blue-dark.png
#
# Uso individual: sudo bash scripts/02-temas.sh
# =============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ejecutar como root: sudo bash scripts/02-temas.sh"
    exit 1
fi

# --- Variables ---
USUARIO="${LAB_USER:-redsi}"
LAB_HOME="${LAB_HOME:-/home/${USUARIO}}"
LAB_SKEL="${LAB_SKEL:-/etc/skel}"

# Directorio raíz del repo (un nivel arriba de scripts/)
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEMAS_DIR="$REPO_DIR/temas"

# Directorios del sistema donde van los temas
THEMES_DIR="/usr/share/themes"
ICONS_DIR="/usr/share/icons"

echo "============================================="
echo " PASO 02: Aplicando temas visuales..."
echo "============================================="

# =============================================================
# FUNCIÓN: aplicar_tema
# Uso: aplicar_tema <nombre_tema>
# Permite escalar fácilmente agregando temas en el futuro
# =============================================================
aplicar_tema() {
    local TEMA="$1"
    local TEMA_DIR="$TEMAS_DIR/$TEMA"

    echo ""
    echo "  Instalando tema: $TEMA"
    echo "  Fuente: $TEMA_DIR"

    if [ ! -d "$TEMA_DIR" ]; then
        echo "  [ERROR] No se encontró la carpeta del tema: $TEMA_DIR"
        exit 1
    fi

    # ---------------------------------------------------------
    # 1. TEMA DE APLICACIONES Y DESKTOP (Jasper-Blue-Dark)
    # ---------------------------------------------------------
    echo ""
    echo "  [1/4] Instalando tema de aplicaciones y desktop..."

    cp -r "$TEMA_DIR/theme-blue-dark" "$THEMES_DIR/Jasper-Blue-Dark"
    echo "  [OK] Tema copiado a $THEMES_DIR/Jasper-Blue-Dark"

    # ---------------------------------------------------------
    # 2. ICONOS (todas las variantes, se aplica Fluent)
    # ---------------------------------------------------------
    echo ""
    echo "  [2/4] Instalando iconos..."

    cp -r "$TEMA_DIR/icons/icons-blue-dark"       "$ICONS_DIR/Fluent"
    cp -r "$TEMA_DIR/icons/icons-dark-blue-dark"  "$ICONS_DIR/Fluent-dark"
    cp -r "$TEMA_DIR/icons/icons-light-blue-dark" "$ICONS_DIR/Fluent-light"
    echo "  [OK] Iconos copiados a $ICONS_DIR"

    # ---------------------------------------------------------
    # 3. CURSOR (ambas variantes, se aplica Fluent-dark-cursors)
    # ---------------------------------------------------------
    echo ""
    echo "  [3/4] Instalando cursores..."

    cp -r "$TEMA_DIR/cursor/cursors-blue-dark"     "$ICONS_DIR/Fluent-cursors"
    cp -r "$TEMA_DIR/cursor/cursors-dar-blue-dark" "$ICONS_DIR/Fluent-dark-cursors"
    echo "  [OK] Cursores copiados a $ICONS_DIR"

    # ---------------------------------------------------------
    # 4. WALLPAPER
    # ---------------------------------------------------------
    echo ""
    echo "  [4/4] Instalando wallpaper..."

    WALLPAPER_SRC="$TEMA_DIR/wallpaper-blue-dark.png"
    WALLPAPER_DST="/usr/share/backgrounds/wallpaper-$TEMA.png"

    cp "$WALLPAPER_SRC" "$WALLPAPER_DST"
    echo "  [OK] Wallpaper copiado a $WALLPAPER_DST"
}

# =============================================================
# FUNCIÓN: configurar_usuario
# Aplica la configuración de dconf a un usuario específico
# =============================================================
configurar_usuario() {
    local USUARIO_DEST="$1"
    local HOME_DEST="$2"
    local WALLPAPER_PATH="$3"

    echo "  Aplicando configuración a: $USUARIO_DEST"

    # Aplicar configuración de Cinnamon vía dconf como el usuario
    sudo -u "$USUARIO_DEST" dconf write /org/cinnamon/desktop/interface/gtk-theme     "'Jasper-Blue-Dark'"
    sudo -u "$USUARIO_DEST" dconf write /org/cinnamon/desktop/interface/icon-theme    "'Fluent'"
    sudo -u "$USUARIO_DEST" dconf write /org/cinnamon/desktop/interface/cursor-theme  "'Fluent-dark-cursors'"
    sudo -u "$USUARIO_DEST" dconf write /org/cinnamon/theme/name                      "'Jasper-Blue-Dark'"
    sudo -u "$USUARIO_DEST" dconf write /org/cinnamon/desktop/background/picture-uri  "'file://$WALLPAPER_PATH'"
    sudo -u "$USUARIO_DEST" dconf write /org/cinnamon/desktop/background/picture-options "'zoom'"

    echo "  [OK] Configuración aplicada a $USUARIO_DEST"
}

# =============================================================
# FUNCIÓN: configurar_skel
# Exporta la configuración de dconf a /etc/skel para herencia
# =============================================================
configurar_skel() {
    local WALLPAPER_PATH="$1"

    echo ""
    echo "  Exportando configuración a $LAB_SKEL para usuarios futuros..."

    # Guardar configuración dconf como archivo que se ejecuta al primer login
    mkdir -p "$LAB_SKEL/.config/autostart"

    cat > "$LAB_SKEL/.config/autostart/aplicar-tema.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Aplicar tema del laboratorio
Exec=bash -c 'dconf write /org/cinnamon/desktop/interface/gtk-theme "'"'"'Jasper-Blue-Dark'"'"'" && dconf write /org/cinnamon/desktop/interface/icon-theme "'"'"'Fluent'"'"'" && dconf write /org/cinnamon/desktop/interface/cursor-theme "'"'"'Fluent-dark-cursors'"'"'" && dconf write /org/cinnamon/theme/name "'"'"'Jasper-Blue-Dark'"'"'" && dconf write /org/cinnamon/desktop/background/picture-uri "'"'"'file://$WALLPAPER_PATH'"'"'" && dconf write /org/cinnamon/desktop/background/picture-options "'"'"'zoom'"'"'" && rm -f ~/.config/autostart/aplicar-tema.desktop'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

    echo "  [OK] Autostart creado en $LAB_SKEL/.config/autostart/aplicar-tema.desktop"
    echo "  [i] Los usuarios nuevos aplicarán el tema en su primer login"
}

# =============================================================
# EJECUCIÓN
# =============================================================

# 1. Instalar archivos del tema en el sistema
aplicar_tema "blue-dark"

WALLPAPER_PATH="/usr/share/backgrounds/wallpaper-blue-dark.png"

# 2. Aplicar configuración al usuario redsi
echo ""
echo "  Configurando usuario $USUARIO..."
configurar_usuario "$USUARIO" "$LAB_HOME" "$WALLPAPER_PATH"

# 3. Preparar herencia para usuarios futuros via skel
configurar_skel "$WALLPAPER_PATH"

# 4. Reinicia cinnamon
sudo -u "$USUARIO" DISPLAY=:0 cinnamon --replace &


echo ""
echo "============================================="
echo " PASO 02 COMPLETADO - Tema blue-dark aplicado"
echo " Tema aplicaciones : Jasper-Blue-Dark"
echo " Iconos            : Fluent"
echo " Cursor            : Fluent-dark-cursors"
echo " Wallpaper         : $WALLPAPER_PATH"
echo "============================================="
