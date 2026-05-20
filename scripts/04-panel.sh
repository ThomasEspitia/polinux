#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 04-panel.sh — Panel, applets y desklets de Cinnamon
#
# Qué hace:
#   - Copia el logo del Politécnico a /usr/share/pixmaps/
#   - Instala applets manuales desde extras/applets/
#   - Instala desklets manuales desde extras/desklets/
#   - Aplica configuración del panel a redsi vía dconf
#   - Configura JSON de applets (logo menú, workspace, ipindicator)
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
MENU_ICON_SRC="$REPO_DIR/extras/menu-icon/poli-light.png"
MENU_ICON_DST="/usr/share/pixmaps/poli-light.png"

APPLETS_SYSTEM="/usr/share/cinnamon/applets"
DESKLETS_SYSTEM="/usr/share/cinnamon/desklets"

echo "============================================="
echo " PASO 04: Configurando panel de Cinnamon..."
echo "============================================="

# =============================================================
# 1. LOGO DEL MENÚ
# =============================================================
echo ""
echo "[1/5] Instalando logo del menú..."

if [ ! -f "$MENU_ICON_SRC" ]; then
    echo "  [WARN] No se encontró $MENU_ICON_SRC"
    echo "         El menú usará el ícono por defecto de Mint."
    MENU_ICON_DST="linuxmint-logo-ring-symbolic"
else
    cp "$MENU_ICON_SRC" "$MENU_ICON_DST"
    chmod 644 "$MENU_ICON_DST"
    echo "  [OK] Logo copiado a $MENU_ICON_DST"
fi

# =============================================================
# 2. APPLETS MANUALES
# =============================================================
echo ""
echo "[2/5] Instalando applets manuales..."

if [ ! -d "$APPLETS_SRC" ]; then
    echo "  [WARN] No se encontró $APPLETS_SRC, omitiendo."
else
    for applet_dir in "$APPLETS_SRC"/*/; do
        applet_name=$(basename "$applet_dir")
        cp -r "$applet_dir" "$APPLETS_SYSTEM/$applet_name"
        echo "  [OK] Applet instalado: $applet_name"

        mkdir -p "$LAB_SKEL/.local/share/cinnamon/applets"
        cp -r "$applet_dir" "$LAB_SKEL/.local/share/cinnamon/applets/$applet_name"
    done
    echo "[OK] Applets manuales instalados"
fi

# =============================================================
# 3. DESKLETS MANUALES
# =============================================================
echo ""
echo "[3/5] Instalando desklets manuales..."

if [ ! -d "$DESKLETS_SRC" ]; then
    echo "  [WARN] No se encontró $DESKLETS_SRC, omitiendo."
else
    for desklet_dir in "$DESKLETS_SRC"/*/; do
        desklet_name=$(basename "$desklet_dir")
        cp -r "$desklet_dir" "$DESKLETS_SYSTEM/$desklet_name"
        echo "  [OK] Desklet instalado: $desklet_name"

        mkdir -p "$LAB_SKEL/.local/share/cinnamon/desklets"
        cp -r "$desklet_dir" "$LAB_SKEL/.local/share/cinnamon/desklets/$desklet_name"
    done
    echo "[OK] Desklets manuales instalados"
fi

# =============================================================
# 4. CONFIGURACIÓN DEL PANEL Y APPLETS — usuario redsi
# =============================================================
echo ""
echo "[4/5] Aplicando configuración del panel a $USUARIO..."

# --- Función: aplica dconf del panel ---
aplicar_dconf_panel() {
    local DEST_USER="$1"

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

    sudo -u "$DEST_USER" dconf write /org/cinnamon/panels-height "['1:36']"

    sudo -u "$DEST_USER" dconf write /org/cinnamon/panel-zone-icon-sizes \
        "'[{\"panelId\": 1, \"left\": 48, \"center\": 24, \"right\": 24}]'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/panel-zone-symbolic-icon-sizes \
        "'[{\"panelId\": 1, \"left\": 16, \"center\": 16, \"right\": 15}]'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/panel-zone-text-sizes \
        "'[{\"panelId\": 1, \"left\": 9.0, \"center\": 6.5, \"right\": 9.0}]'"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/panel-edit-mode "false"

    # Desklets (posiciones para 1920x1080)
    sudo -u "$DEST_USER" dconf write /org/cinnamon/enabled-desklets \
        "['system-monitor-graph@rcassani:1:1660:930', \
'timelet@linuxedo.com:8:1415:40', \
'system-monitor-graph@rcassani:15:1660:790', \
'system-monitor-graph@rcassani:16:1660:860', \
'commandResult@ZimiZones:17:115:950']"
    sudo -u "$DEST_USER" dconf write /org/cinnamon/lock-desklets "false"

    # Gestos trackpad
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

    sudo -u "$DEST_USER" dconf write /org/cinnamon/desktop/sound/event-sounds "false"
    sudo -u "$DEST_USER" dconf write \
        /org/cinnamon/desktop/input-sources/sources "[('xkb', 'latam')]"

    echo "  [OK] dconf del panel aplicado a: $DEST_USER"
}

# --- Función: aplica JSON de configuración de applets ---
aplicar_json_applets() {
    local DEST_HOME="$1"
    local SPICES_DIR="$DEST_HOME/.config/cinnamon/spices"

    # Menú: logo personalizado, tamaño 25px
    mkdir -p "$SPICES_DIR/menu@cinnamon.org"
    cat > "$SPICES_DIR/menu@cinnamon.org/0.json" << JSONEOF
{
    "menu-custom": { "type": "switch", "value": true },
    "menu-icon": { "type": "iconfilechooser", "value": "$MENU_ICON_DST" },
    "menu-icon-size": { "type": "spinbutton", "value": 25.0 },
    "menu-label": { "type": "entry", "value": "" },
    "overlay-key": { "type": "keybinding", "value": "Super_L::Super_R" },
    "activate-on-hover": { "type": "switch", "value": false },
    "enable-animation": { "type": "switch", "value": false },
    "category-hover": { "type": "switch", "value": true },
    "enable-autoscroll": { "type": "switch", "value": true },
    "search-position": { "type": "combobox", "value": "top" },
    "system-position": { "type": "combobox", "value": "sidebar" },
    "show-sidebar": { "type": "switch", "value": true },
    "show-avatar": { "type": "switch", "value": true },
    "show-favorites": { "type": "switch", "value": true },
    "show-recents": { "type": "switch", "value": true },
    "show-desktop": { "type": "switch", "value": true },
    "show-downloads": { "type": "switch", "value": true },
    "show-bookmarks": { "type": "switch", "value": true },
    "show-home": { "type": "switch", "value": false },
    "show-documents": { "type": "switch", "value": false },
    "show-music": { "type": "switch", "value": false },
    "show-pictures": { "type": "switch", "value": false },
    "show-videos": { "type": "switch", "value": false },
    "symbolic-category-icons": { "type": "switch", "value": true },
    "show-description": { "type": "switch", "value": true },
    "force-show-panel": { "type": "switch", "value": true },
    "application-icon-size": { "type": "spinbutton", "value": 32 },
    "category-icon-size": { "type": "spinbutton", "value": 16 },
    "sidebar-icon-size": { "type": "spinbutton", "value": 24 },
    "sidebar-max-width": { "type": "spinbutton", "value": 180 }
}
JSONEOF

    # Workspace switcher: simple buttons
    mkdir -p "$SPICES_DIR/workspace-switcher@cinnamon.org"
    cat > "$SPICES_DIR/workspace-switcher@cinnamon.org/20.json" << JSONEOF
{
    "display-type": { "type": "combobox", "value": "buttons" },
    "scroll-behavior": { "type": "combobox", "value": "reversed" }
}
JSONEOF

    # IP Indicator: mostrar solo IP
    mkdir -p "$SPICES_DIR/ipindicator@matus.benko@gmail.com"
    cat > "$SPICES_DIR/ipindicator@matus.benko@gmail.com/ipindicator@matus.benko@gmail.com.json" << JSONEOF
{
    "appearance": { "type": "radiogroup", "value": "ip" },
    "update_interval_ifconfig": { "type": "spinbutton", "value": 5 },
    "update_interval_service": { "type": "spinbutton", "value": 3.0 },
    "debug_level": { "type": "spinbutton", "value": 0.0 }
}
JSONEOF

    # Grouped window list: pinned apps = Chrome y Kitty (sin Firefox)
    mkdir -p "$SPICES_DIR/grouped-window-list@cinnamon.org"
    cat > "$SPICES_DIR/grouped-window-list@cinnamon.org/17.json" << JSONEOF
{
    "group-apps": { "type": "checkbox", "value": true },
    "scroll-behavior": { "type": "combobox", "value": 1 },
    "left-click-action": { "type": "combobox", "value": 2 },
    "middle-click-action": { "type": "combobox", "value": 3 },
    "show-all-workspaces": { "type": "checkbox", "value": false },
    "window-display-settings": { "type": "combobox", "value": 1 },
    "title-display": { "type": "combobox", "value": 1 },
    "launcher-animation-effect": { "type": "combobox", "value": 3 },
    "enable-window-count-badges": { "type": "checkbox", "value": true },
    "enable-notification-badges": { "type": "checkbox", "value": true },
    "enable-app-button-dragging": { "type": "checkbox", "value": true },
    "show-thumbnails": { "type": "checkbox", "value": true },
    "animate-thumbnails": { "type": "checkbox", "value": false },
    "thumbnail-size": { "type": "combobox", "value": 6 },
    "thumbnail-timeout": { "type": "combobox", "value": 250 },
    "enable-hover-peek": { "type": "checkbox", "value": true },
    "hover-peek-opacity": { "type": "spinbutton", "value": 100 },
    "show-recent": { "type": "checkbox", "value": true },
    "autostart-menu-item": { "type": "checkbox", "value": false },
    "super-num-hotkeys": { "type": "checkbox", "value": true },
    "pinned-apps": {
        "type": "generic",
        "default": ["nemo.desktop", "google-chrome.desktop", "kitty.desktop"],
        "value": ["nemo.desktop", "google-chrome.desktop", "kitty.desktop"]
    }
}
JSONEOF

    echo "  [OK] JSON de applets configurado en: $DEST_HOME"
}

aplicar_dconf_panel "$USUARIO"
aplicar_json_applets "$LAB_HOME"
chown -R "${USUARIO}:${USUARIO}" "$LAB_HOME/.config/cinnamon"

# Copiar JSONs a skel para usuarios futuros
# Nota: el JSON del menú usa la ruta de /usr/share/pixmaps/ (global),
# así que funciona igual para cualquier usuario
SKEL_SPICES="$LAB_SKEL/.config/cinnamon/spices"
mkdir -p "$SKEL_SPICES"
cp -r "$LAB_HOME/.config/cinnamon/spices/menu@cinnamon.org" "$SKEL_SPICES/"
cp -r "$LAB_HOME/.config/cinnamon/spices/workspace-switcher@cinnamon.org" "$SKEL_SPICES/"
cp -r "$LAB_HOME/.config/cinnamon/spices/ipindicator@matus.benko@gmail.com" "$SKEL_SPICES/"
cp -r "$LAB_HOME/.config/cinnamon/spices/grouped-window-list@cinnamon.org" "$SKEL_SPICES/"
echo "  [OK] JSONs de applets copiados a skel"

# =============================================================
# 5. AUTOSTART EN SKEL — dconf para usuarios futuros
# =============================================================
echo ""
echo "[5/5] Preparando herencia dconf para usuarios futuros (skel)..."

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
echo " Logo menú : $MENU_ICON_DST"
echo " Izquierda : menu | network | workspace-switcher (buttons)"
echo " Centro    : grouped-window-list"
echo " Derecha   : ipindicator (IP) | notifications"
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
echo "        resolución 1920x1080."
echo "============================================="
