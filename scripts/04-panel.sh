#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 04-panel.sh — Panel, applets y desklets de Cinnamon
#
# Qué hace:
#   - Instala applets manuales (ipindicator, sshlauncher)
#     desde extras/applets/ del repo
#   - Instala desklets manuales desde extras/desklets/ del repo
#   - Aplica configuración del panel a redsi vía dconf
#   - Prepara autostart en skel para usuarios futuros
#
# Uso individual: sudo bash scripts/04-panel.sh
# =============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ejecutar como root: sudo bash scripts/04-panel.sh"
    exit 1
fi

# --- Variables ---
USUARIO="${LAB_USER:-redsi}"
LAB_HOME="${LAB_HOME:-/home/${USUARIO}}"
LAB_SKEL="${LAB_SKEL:-/etc/skel}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

APPLETS_SRC="$REPO_DIR/extras/applets"
DESKLETS_SRC="$REPO_DIR/extras/desklets"

APPLETS_SYSTEM="/usr/share/cinnamon/applets"
DESKLETS_SYSTEM="/usr/share/cinnamon/desklets"

echo "============================================="
echo " PASO 04: Configurando panel de Cinnamon..."
echo "============================================="

# =============================================================
# 1. APPLETS MANUALES
# =============================================================
echo ""
echo "[1/4] Instalando applets manuales..."

if [ ! -d "$APPLETS_SRC" ]; then
    echo "  [WARN] No se encontró $APPLETS_SRC"
    echo "         Copia los applets al repo primero (ver instrucciones al final)."
else
    for applet_dir in "$APPLETS_SRC"/*/; do
        applet_name=$(basename "$applet_dir")

        # Instalar en el sistema (disponible para todos los usuarios)
        cp -r "$applet_dir" "$APPLETS_SYSTEM/$applet_name"
        echo "  [OK] Applet instalado: $applet_name"

        # También en skel para usuarios futuros
        mkdir -p "$LAB_SKEL/.local/share/cinnamon/applets"
        cp -r "$applet_dir" "$LAB_SKEL/.local/share/cinnamon/applets/$applet_name"
    done

    echo "[OK] Applets manuales instalados"
fi

# =============================================================
# 2. DESKLETS MANUALES
# =============================================================
echo ""
echo "[2/4] Instalando desklets manuales..."

if [ ! -d "$DESKLETS_SRC" ]; then
    echo "  [WARN] No se encontró $DESKLETS_SRC"
    echo "         Copia los desklets al repo primero (ver instrucciones al final)."
else
    for desklet_dir in "$DESKLETS_SRC"/*/; do
        desklet_name=$(basename "$desklet_dir")

        # Instalar en el sistema
        cp -r "$desklet_dir" "$DESKLETS_SYSTEM/$desklet_name"
        echo "  [OK] Desklet instalado: $desklet_name"

        # También en skel
        mkdir -p "$LAB_SKEL/.local/share/cinnamon/desklets"
        cp -r "$desklet_dir" "$LAB_SKEL/.local/share/cinnamon/desklets/$desklet_name"
    done

    echo "[OK] Desklets manuales instalados"
fi

# =============================================================
# 3. CONFIGURACIÓN DEL PANEL — usuario redsi
# =============================================================
echo ""
echo "[3/4] Aplicando configuración del panel a $USUARIO..."

aplicar_panel_usuario() {
    local DEST_USER="$1"

    # --- Applets y su distribución en el panel ---
    sudo -u "$DEST_USER" dconf write /org/cinnamon/enabled-applets \
        "['panel1:left:0:menu@cinnamon.org:0', \
'panel1:left:3:network@cinnamon.org:10', \
'panel1:left:4:workspace-switcher@cinnamon.org:20', \
'panel1:center:0:grouped-window-list@cinnamon.org:17', \
'panel1:right:1:ipindicator@matus.benko@gmail.com:21', \
'panel1:right:9:notifications@cinnamon.org:5', \
'panel1:right:11:removable-drives@cinnamon.org:7', \
'panel1:right:12:keyboard@cinnamon.org:8', \
'panel1:right:14:sound@cinnamon.org:11', \
'panel1:right:15:power@cinnamon.org:12', \
'panel1:right:16:calendar@cinnamon.org:13', \
'panel1:right:17:cornerbar@cinnamon.org:14']"

    # --- Tamaño del panel ---
    sudo -u "$DEST_USER" dconf write /org/cinnamon/panels-height "['1:36']"

    # --- Tamaños de iconos por zona ---
    sudo -u "$DEST_USER" dconf write /org/cinnamon/panel-zone-icon-sizes \
        "'[{\"panelId\": 1, \"left\": 48, \"center\": 24, \"right\": 24}]'"

    sudo -u "$DEST_USER" dconf write /org/cinnamon/panel-zone-symbolic-icon-sizes \
        "'[{\"panelId\": 1, \"left\": 16, \"center\": 16, \"right\": 15}]'"

    sudo -u "$DEST_USER" dconf write /org/cinnamon/panel-zone-text-sizes \
        "'[{\"panelId\": 1, \"left\": 9.0, \"center\": 6.5, \"right\": 9.0}]'"

    sudo -u "$DEST_USER" dconf write /org/cinnamon/panel-edit-mode "false"

    # --- Desklets activos y sus posiciones ---
    # Nota: posiciones ajustadas para resolución 1920x1080
    sudo -u "$DEST_USER" dconf write /org/cinnamon/enabled-desklets \
        "['system-monitor-graph@rcassani:1:1660:930', \
'timelet@linuxedo.com:8:1415:40', \
'system-monitor-graph@rcassani:15:1660:790', \
'system-monitor-graph@rcassani:16:1660:860', \
'commandResult@ZimiZones:17:115:950']"

    sudo -u "$DEST_USER" dconf write /org/cinnamon/lock-desklets "false"

    # --- Gestos trackpad ---
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-down-2 "'PUSH_TILE_DOWN::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-down-3 "'TOGGLE_OVERVIEW::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-down-4 "'VOLUME_DOWN::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-left-2 "'PUSH_TILE_LEFT::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-left-3 "'WORKSPACE_NEXT::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-left-4 "'WINDOW_WORKSPACE_PREVIOUS::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-right-2 "'PUSH_TILE_RIGHT::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-right-3 "'WORKSPACE_PREVIOUS::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-right-4 "'WINDOW_WORKSPACE_NEXT::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-up-2 "'PUSH_TILE_UP::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-up-3 "'TOGGLE_EXPO::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/swipe-up-4 "'VOLUME_UP::end'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/gestures/tap-3 "'MEDIA_PLAY_PAUSE::end'"

    # --- Sonidos del sistema desactivados ---
    sudo -u "$DEST_USER" dconf write /org/cinnamon/desktop/sound/event-sounds "false"

    # --- Teclado latinoamericano ---
    sudo -u "$DEST_USER" dconf write \
        /org/cinnamon/desktop/input-sources/sources "[('xkb', 'latam')]"

    echo "  [OK] Panel configurado para: $DEST_USER"
}

aplicar_panel_usuario "$USUARIO"

# =============================================================
# 4. AUTOSTART EN SKEL — usuarios futuros
# =============================================================
echo ""
echo "[4/4] Preparando herencia para usuarios futuros (skel)..."

mkdir -p "$LAB_SKEL/.config/autostart"

cat > "$LAB_SKEL/.config/autostart/aplicar-panel.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Aplicar panel del laboratorio
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Exec=bash -c '\
dconf write /org/cinnamon/enabled-applets \
  "['"'"'panel1:left:0:menu@cinnamon.org:0'"'"','"'"'panel1:left:3:network@cinnamon.org:10'"'"','"'"'panel1:left:4:workspace-switcher@cinnamon.org:20'"'"','"'"'panel1:center:0:grouped-window-list@cinnamon.org:17'"'"','"'"'panel1:right:1:ipindicator@matus.benko@gmail.com:21'"'"','"'"'panel1:right:9:notifications@cinnamon.org:5'"'"','"'"'panel1:right:11:removable-drives@cinnamon.org:7'"'"','"'"'panel1:right:12:keyboard@cinnamon.org:8'"'"','"'"'panel1:right:14:sound@cinnamon.org:11'"'"','"'"'panel1:right:15:power@cinnamon.org:12'"'"','"'"'panel1:right:16:calendar@cinnamon.org:13'"'"','"'"'panel1:right:17:cornerbar@cinnamon.org:14'"'"']" && \
dconf write /org/cinnamon/panels-height "['"'"'1:36'"'"']" && \
dconf write /org/cinnamon/panel-zone-icon-sizes '"'"'[{"panelId": 1, "left": 48, "center": 24, "right": 24}]'"'"' && \
dconf write /org/cinnamon/panel-zone-symbolic-icon-sizes '"'"'[{"panelId": 1, "left": 16, "center": 16, "right": 15}]'"'"' && \
dconf write /org/cinnamon/panel-zone-text-sizes '"'"'[{"panelId": 1, "left": 9.0, "center": 6.5, "right": 9.0}]'"'"' && \
dconf write /org/cinnamon/enabled-desklets \
  "['"'"'system-monitor-graph@rcassani:1:1660:930'"'"','"'"'timelet@linuxedo.com:8:1415:40'"'"','"'"'system-monitor-graph@rcassani:15:1660:790'"'"','"'"'system-monitor-graph@rcassani:16:1660:860'"'"','"'"'commandResult@ZimiZones:17:115:950'"'"']" && \
dconf write /org/cinnamon/lock-desklets "false" && \
dconf write /org/cinnamon/desktop/sound/event-sounds "false" && \
dconf write /org/cinnamon/desktop/input-sources/sources "['"'"'('"'"''"'"'xkb'"'"''"'"', '"'"''"'"'latam'"'"''"'"')'"'"']" && \
rm -f "$HOME/.config/autostart/aplicar-panel.desktop"'
DESKTOP

echo "  [OK] Autostart creado en $LAB_SKEL/.config/autostart/aplicar-panel.desktop"

# =============================================================
# RESUMEN
# =============================================================
echo ""
echo "============================================="
echo " PASO 04 COMPLETADO - Panel configurado"
echo " Izquierda : menu | network | workspace-switcher"
echo " Centro    : grouped-window-list"
echo " Derecha   : ipindicator | notifications"
echo "             removable-drives | keyboard"
echo "             sound | power | calendar | cornerbar"
echo " Desklets  : system-monitor-graph (x3)"
echo "             timelet | commandResult"
echo " Altura    : 36px"
echo "============================================="
echo ""
echo " [i] NOTAS:"
echo "     1. Cierra sesión y vuelve a entrar para"
echo "        ver los cambios aplicados."
echo "     2. Las posiciones de los desklets asumen"
echo "        resolución 1920x1080. Si la resolución"
echo "        es distinta, reposiciónalos manualmente."
echo "============================================="
echo ""
echo " ESTRUCTURA REQUERIDA EN EL REPO:"
echo "   extras/"
echo "     applets/"
echo "       ipindicator@matus.benko@gmail.com/"
echo "       sshlauncher@sumo/"
echo "     desklets/"
echo "       commandResult@ZimiZones/"
echo "       cpuload@kimse/"
echo "       simple-system-monitor@ariel/"
echo "       sys-monitor@Paul163-ai/"
echo "       system-monitor-graph@rcassani/"
echo "       timelet@linuxedo.com/"
echo "============================================="
echo ""
echo " COMANDOS PARA PREPARAR EL REPO (en polinux-turing):"
echo "   cd /ruta/al/repo"
echo "   mkdir -p extras/applets extras/desklets"
echo "   cp -r ~/.local/share/cinnamon/applets/ipindicator@matus.benko@gmail.com extras/applets/"
echo "   cp -r ~/.local/share/cinnamon/applets/sshlauncher@sumo extras/applets/"
echo "   cp -r ~/.local/share/cinnamon/desklets/* extras/desklets/"
echo "   git add extras/"
echo "   git commit -m 'feat: applets y desklets para 04-panel'"
echo "   git push"
echo "============================================="
