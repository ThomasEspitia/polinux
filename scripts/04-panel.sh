#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 04-panel.sh — Panel, applets, desklets y escritorio Cinnamon
#
# Configura:
#   - Panel (altura 36px, zonas izq/centro/der)
#   - Applets: menu, network, workspace-switcher, grouped-window-list,
#              ipindicator, notifications, removable-drives, keyboard,
#              sound, power, calendar, cornerbar
#   - Desklets: system-monitor-graph x3 (CPU/Network/RAM) + clockTow +
#               commandResult (IP)
#   - Iconos del escritorio: Home, Network, Wireshark, Chrome, kitty, Trash
#   - Ícono del menú: poli-light.png (logo Politécnico)
#   - Herencia completa a /etc/skel para usuarios futuros
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

echo "============================================="
echo " PASO 04: Configurando panel y escritorio..."
echo "============================================="

# =============================================================
# FUNCIÓN AUXILIAR: dconf como usuario
# =============================================================
dconf_write() {
    sudo -u "$USUARIO" dconf write "$1" "$2"
}

# =============================================================
# 1. APPLETS MANUALES — copiar al sistema si no están
#    (ipindicator y sshlauncher vienen en extras/ del repo)
# =============================================================
echo ""
echo "[1/6] Instalando applets manuales..."

APPLETS_SRC="$REPO_DIR/extras/applets"
APPLETS_DST="/usr/share/cinnamon/applets"

for applet in "$APPLETS_SRC"/*/; do
    nombre=$(basename "$applet")
    if [ -d "$applet" ]; then
        cp -r "$applet" "$APPLETS_DST/$nombre"
        echo "  [OK] Applet instalado: $nombre"
    fi
done

# =============================================================
# 2. DESKLETS MANUALES — copiar al sistema si no están
#    (commandResult, system-monitor-graph, clockTow, etc.)
# =============================================================
echo ""
echo "[2/6] Instalando desklets manuales..."

DESKLETS_SRC="$REPO_DIR/extras/desklets"
DESKLETS_DST="/usr/share/cinnamon/desklets"

for desklet in "$DESKLETS_SRC"/*/; do
    nombre=$(basename "$desklet")
    if [ -d "$desklet" ]; then
        cp -r "$desklet" "$DESKLETS_DST/$nombre"
        echo "  [OK] Desklet instalado: $nombre"
    fi
done

# clockTow viene del home del usuario de origen — debe estar en extras/desklets/
# Si no está en el repo, intentar desde el sistema actual
if [ ! -d "$DESKLETS_DST/clockTow@armandobs14" ]; then
    if [ -d "$LAB_HOME/.local/share/cinnamon/desklets/clockTow@armandobs14" ]; then
        cp -r "$LAB_HOME/.local/share/cinnamon/desklets/clockTow@armandobs14" \
              "$DESKLETS_DST/clockTow@armandobs14"
        echo "  [OK] clockTow copiado desde home del usuario"
    else
        echo "  [WARN] clockTow@armandobs14 no encontrado — descargarlo manualmente"
        echo "         y colocarlo en extras/desklets/ del repo"
    fi
fi

# =============================================================
# 3. ÍCONO DEL MENÚ — poli-light.png
# =============================================================
echo ""
echo "[3/6] Configurando ícono del menú..."

POLI_ICON_SRC="$REPO_DIR/extras/menu-icon/poli-light.png"
POLI_ICON_DST="/usr/share/pixmaps/poli-light.png"

if [ -f "$POLI_ICON_SRC" ]; then
    cp "$POLI_ICON_SRC" "$POLI_ICON_DST"
    echo "  [OK] Logo copiado a $POLI_ICON_DST"
else
    echo "  [WARN] No se encontró $POLI_ICON_SRC"
fi

# =============================================================
# 4. CONFIGURAR CINNAMON VÍA DCONF (usuario redsi)
# =============================================================
echo ""
echo "[4/6] Aplicando configuración de panel y desklets..."

# ---------------------------------------------------------
# 4.1 Panel principal: altura, zonas de íconos y texto
# ---------------------------------------------------------
dconf_write /org/cinnamon/panels-height "['1:36']"

dconf_write /org/cinnamon/panel-zone-icon-sizes \
    "'[{\"panelId\": 1, \"left\": 48, \"center\": 24, \"right\": 24}]'"

dconf_write /org/cinnamon/panel-zone-symbolic-icon-sizes \
    "'[{\"panelId\": 1, \"left\": 16, \"center\": 16, \"right\": 15}]'"

dconf_write /org/cinnamon/panel-zone-text-sizes \
    "'[{\"panelId\": 1, \"left\": 9.0, \"center\": 6.5, \"right\": 9.0}]'"

echo "  [OK] Panel configurado (36px, zonas de íconos)"

# ---------------------------------------------------------
# 4.2 Applets habilitados
#     Orden exacto extraído de dconf dump:
#     izq: menu(0) | network(10) | workspace-switcher(20)
#     centro: grouped-window-list(17)
#     der: ipindicator(21) | notifications(5) | removable-drives(7) |
#          keyboard(8) | sound(11) | power(12) | calendar(13) | cornerbar(14)
# ---------------------------------------------------------
dconf_write /org/cinnamon/enabled-applets \
    "['panel1:left:0:menu@cinnamon.org:0', \
'panel1:right:9:notifications@cinnamon.org:5', \
'panel1:right:11:removable-drives@cinnamon.org:7', \
'panel1:right:12:keyboard@cinnamon.org:8', \
'panel1:left:3:network@cinnamon.org:10', \
'panel1:right:14:sound@cinnamon.org:11', \
'panel1:right:15:power@cinnamon.org:12', \
'panel1:right:16:calendar@cinnamon.org:13', \
'panel1:right:17:cornerbar@cinnamon.org:14', \
'panel1:center:0:grouped-window-list@cinnamon.org:17', \
'panel1:left:4:workspace-switcher@cinnamon.org:20', \
'panel1:right:1:ipindicator@matus.benko@gmail.com:21']"

dconf_write /org/cinnamon/next-applet-id "23"

echo "  [OK] Applets habilitados"

# ---------------------------------------------------------
# 4.3 Desklets habilitados
#     IDs y posiciones para 1920x1080:
#       system-monitor-graph CPU    id=1  x=1660 y=930
#       system-monitor-graph NET    id=15 x=1660 y=790
#       system-monitor-graph RAM    id=16 x=1660 y=860
#       commandResult IP            id=17 x=115  y=935
#       clockTow                    id=20 x=1715 y=70
# ---------------------------------------------------------
dconf_write /org/cinnamon/enabled-desklets \
    "['system-monitor-graph@rcassani:1:1660:930', \
'system-monitor-graph@rcassani:15:1660:790', \
'system-monitor-graph@rcassani:16:1660:860', \
'commandResult@ZimiZones:17:115:935', \
'clockTow@armandobs14:20:1715:70']"

dconf_write /org/cinnamon/next-desklet-id "21"
dconf_write /org/cinnamon/desklet-snap-interval "5"
dconf_write /org/cinnamon/lock-desklets "false"

echo "  [OK] Desklets habilitados"

# ---------------------------------------------------------
# 4.4 Configuración de sonido del sistema (desactivar)
# ---------------------------------------------------------
dconf_write /org/cinnamon/desktop/sound/event-sounds "false"

# ---------------------------------------------------------
# 4.5 Distribución de teclado: latam
# ---------------------------------------------------------
dconf_write /org/cinnamon/desktop/input-sources/sources "[('xkb', 'latam')]"

echo "  [OK] Teclado y sonido configurados"

# =============================================================
# 5. CONFIGURACIONES JSON DE APPLETS Y DESKLETS
# =============================================================
echo ""
echo "[5/6] Escribiendo configuraciones JSON de applets/desklets..."

SPICES_DIR="$LAB_HOME/.config/cinnamon/spices"
SPICES_SKEL="$LAB_SKEL/.config/cinnamon/spices"

mkdir -p "$SPICES_DIR"
mkdir -p "$SPICES_SKEL"

# ---------------------------------------------------------
# 5.1 menu@cinnamon.org — ícono Politécnico, búsqueda arriba
# ---------------------------------------------------------
mkdir -p "$SPICES_DIR/menu@cinnamon.org"

cat > "$SPICES_DIR/menu@cinnamon.org/0.json" << 'MENUEOF'
{
    "overlay-key": {
        "type": "keybinding",
        "description": "Keyboard shortcut to open and close the menu",
        "default": "Super_L::Super_R",
        "value": "Super_L::Super_R"
    },
    "menu-custom": {
        "type": "switch",
        "default": true,
        "description": "Use a custom icon and label",
        "value": true
    },
    "menu-icon": {
        "type": "iconfilechooser",
        "default": "linuxmint-logo-ring-symbolic",
        "description": "Icon",
        "value": "/usr/share/pixmaps/poli-light.png"
    },
    "menu-icon-size": {
        "type": "spinbutton",
        "default": 32,
        "min": 16,
        "max": 96,
        "step": 1,
        "units": "px",
        "description": "Icon size",
        "dependency": "menu-custom",
        "value": 25
    },
    "menu-label": {
        "type": "entry",
        "default": "",
        "description": "Text",
        "dependency": "menu-custom",
        "value": ""
    },
    "symbolic-category-icons": {
        "type": "switch",
        "default": true,
        "description": "Use symbolic icons for categories",
        "value": false
    },
    "category-icon-size": {
        "type": "spinbutton",
        "default": 16,
        "min": 8,
        "max": 48,
        "step": 1,
        "units": "px",
        "description": "Categories icon size",
        "value": 16
    },
    "application-icon-size": {
        "type": "spinbutton",
        "default": 32,
        "min": 8,
        "max": 48,
        "step": 1,
        "units": "px",
        "description": "Applications icon size",
        "value": 32
    },
    "show-sidebar": {
        "type": "switch",
        "default": true,
        "description": "Sidebar",
        "value": true
    },
    "show-avatar": {
        "type": "switch",
        "default": true,
        "description": "Avatar",
        "value": true
    },
    "show-home":      { "type": "switch", "default": false, "value": false },
    "show-desktop":   { "type": "switch", "default": true,  "value": true  },
    "show-documents": { "type": "switch", "default": false, "value": false },
    "show-downloads": { "type": "switch", "default": true,  "value": true  },
    "show-music":     { "type": "switch", "default": false, "value": false },
    "show-pictures":  { "type": "switch", "default": false, "value": false },
    "show-videos":    { "type": "switch", "default": false, "value": false },
    "show-bookmarks": { "type": "switch", "default": true,  "value": true  },
    "system-position": {
        "type": "combobox",
        "default": "sidebar",
        "description": "Position of the system buttons",
        "options": { "In the sidebar": "sidebar", "Alongside the search bar": "search" },
        "value": "search"
    },
    "search-position": {
        "type": "combobox",
        "default": "bottom",
        "description": "Position of the search bar",
        "options": { "At the top": "top", "At the bottom": "bottom" },
        "value": "top"
    },
    "sidebar-icon-size":  { "type": "spinbutton", "default": 24, "value": 24 },
    "sidebar-max-width":  { "type": "spinbutton", "default": 180, "value": 180 },
    "show-favorites":     { "type": "switch", "default": true, "value": true  },
    "show-recents":       { "type": "switch", "default": true, "value": true  },
    "show-description":   { "type": "switch", "default": true, "value": false },
    "category-hover":     { "type": "switch", "default": true, "value": true  },
    "enable-autoscroll":  { "type": "switch", "default": true, "value": true  },
    "force-show-panel":   { "type": "switch", "default": true, "value": true  },
    "activate-on-hover":  { "type": "switch", "default": false, "value": false },
    "hover-delay":        { "type": "spinbutton", "default": 0, "value": 0    },
    "enable-animation":   { "type": "switch", "default": false, "value": false },
    "popup-width":        { "type": "generic", "default": 665, "value": 665   },
    "popup-height":       { "type": "generic", "default": 425, "value": 425   }
}
MENUEOF

echo "  [OK] menu@cinnamon.org configurado"

# ---------------------------------------------------------
# 5.2 workspace-switcher — modo: simple buttons, scroll: reversed
# ---------------------------------------------------------
mkdir -p "$SPICES_DIR/workspace-switcher@cinnamon.org"

cat > "$SPICES_DIR/workspace-switcher@cinnamon.org/20.json" << 'WSEOF'
{
    "display-type": {
        "type": "combobox",
        "default": "visual",
        "description": "Type of display",
        "options": {
            "A visual representation of the workspaces": "visual",
            "Simple buttons": "buttons"
        },
        "value": "buttons"
    },
    "scroll-behavior": {
        "type": "combobox",
        "default": "normal",
        "description": "Scroll wheel behavior",
        "options": {
            "Normal": "normal",
            "Reversed": "reversed",
            "Disabled": "disabled"
        },
        "value": "reversed"
    }
}
WSEOF

echo "  [OK] workspace-switcher configurado"

# ---------------------------------------------------------
# 5.3 ipindicator — modo: solo IP
# ---------------------------------------------------------
mkdir -p "$SPICES_DIR/ipindicator@matus.benko@gmail.com"

cat > "$SPICES_DIR/ipindicator@matus.benko@gmail.com/ipindicator@matus.benko@gmail.com.json" << 'IPEOF'
{
    "appearance": {
        "type": "radiogroup",
        "options": { "Icon": "icon", "IP": "ip", "Icon and IP": "iconIp" },
        "default": "icon",
        "description": "Appearance",
        "value": "ip"
    },
    "update_interval_ifconfig": {
        "type": "spinbutton",
        "default": 5,
        "min": 1,
        "max": 3600000,
        "step": 1,
        "units": "seconds",
        "description": "Interface check interval:",
        "value": 5
    },
    "update_interval_service": {
        "type": "spinbutton",
        "default": 5,
        "min": 3,
        "max": 100,
        "step": 1,
        "units": "minutes",
        "description": "IP Service interval:",
        "value": 3.0
    },
    "debug_level": { "type": "spinbutton", "default": 0, "value": 0.0 },
    "home_isp":      { "type": "entry", "default": "", "value": "Use your ISP name from here: http://ip-api.com/json" },
    "home_isp_icon-name":   { "type": "iconfilechooser", "default": "gtk-home", "value": "gtk-home" },
    "home_isp_nickname":    { "type": "entry", "default": "", "value": "" },
    "other1_isp":           { "type": "entry", "default": "", "value": "Use your ISP name from here: http://ip-api.com/json" },
    "other1_isp_icon-name": { "type": "iconfilechooser", "default": "gtk-add", "value": "gtk-add" },
    "other1_isp_nickname":  { "type": "entry", "default": "", "value": "" },
    "other2_isp":           { "type": "entry", "default": "", "value": "Use your ISP name from here: http://ip-api.com/json" },
    "other2_isp_icon-name": { "type": "iconfilechooser", "default": "gtk-add", "value": "gtk-add" },
    "other2_isp_nickname":  { "type": "entry", "default": "", "value": "" },
    "other3_isp":           { "type": "entry", "default": "", "value": "Use your ISP name from here: http://ip-api.com/json" },
    "other3_isp_icon-name": { "type": "iconfilechooser", "default": "gtk-add", "value": "gtk-add" },
    "other3_isp_nickname":  { "type": "entry", "default": "", "value": "" },
    "other4_isp":           { "type": "entry", "default": "", "value": "Use your ISP name from here: http://ip-api.com/json" },
    "other4_isp_icon-name": { "type": "iconfilechooser", "default": "gtk-add", "value": "gtk-add" },
    "other4_isp_nickname":  { "type": "entry", "default": "", "value": "" },
    "other5_isp":           { "type": "entry", "default": "", "value": "Use your ISP name from here: http://ip-api.com/json" },
    "other5_isp_icon-name": { "type": "iconfilechooser", "default": "gtk-add", "value": "gtk-add" },
    "other5_isp_nickname":  { "type": "entry", "default": "", "value": "" }
}
IPEOF

echo "  [OK] ipindicator configurado"

# ---------------------------------------------------------
# 5.4 grouped-window-list — pinned: nemo, chrome, kitty
# ---------------------------------------------------------
mkdir -p "$SPICES_DIR/grouped-window-list@cinnamon.org"

cat > "$SPICES_DIR/grouped-window-list@cinnamon.org/17.json" << 'GWLEOF'
{
    "group-apps":          { "type": "checkbox", "default": true,  "value": true  },
    "scroll-behavior":     { "type": "combobox", "default": 1, "value": 1 },
    "left-click-action":   { "type": "combobox", "default": 2, "value": 2 },
    "middle-click-action": { "type": "combobox", "default": 3, "value": 3 },
    "show-all-workspaces": { "type": "checkbox", "default": false, "value": false },
    "window-display-settings": { "type": "combobox", "default": 1, "value": 1 },
    "cycleMenusHotkey":    { "type": "keybinding", "default": "", "value": "" },
    "show-apps-order-hotkey": { "type": "keybinding", "default": "<Super>grave", "value": "<Super>grave" },
    "show-apps-order-timeout": { "type": "spinbutton", "default": 2500, "value": 2500 },
    "super-num-hotkeys":   { "type": "checkbox", "default": true, "value": true },
    "title-display":       { "type": "combobox", "default": 1, "value": 1 },
    "launcher-animation-effect": { "type": "combobox", "default": 3, "value": 3 },
    "enable-window-count-badges":  { "type": "checkbox", "default": true, "value": true },
    "enable-notification-badges":  { "type": "checkbox", "default": true, "value": true },
    "enable-app-button-dragging":  { "type": "checkbox", "default": true, "value": true },
    "thumbnail-scroll-behavior":   { "type": "checkbox", "default": false, "value": false },
    "show-thumbnails":     { "type": "checkbox", "default": true,  "value": true  },
    "animate-thumbnails":  { "type": "checkbox", "default": false, "value": false },
    "vertical-thumbnails": { "type": "checkbox", "default": false, "value": false },
    "sort-thumbnails":     { "type": "checkbox", "default": false, "value": false },
    "highlight-last-focused-thumbnail": { "type": "checkbox", "default": true, "value": true },
    "onclick-thumbnails":  { "type": "checkbox", "default": false, "value": false },
    "thumbnail-timeout":   { "type": "combobox", "default": 250,  "value": 250  },
    "thumbnail-size":      { "type": "combobox", "default": 6,    "value": 6    },
    "enable-hover-peek":   { "type": "checkbox", "default": true,  "value": true  },
    "hover-peek-time-in":  { "type": "combobox", "default": 300,  "value": 300  },
    "hover-peek-time-out": { "type": "combobox", "default": 0,    "value": 0    },
    "hover-peek-opacity":  { "type": "spinbutton","default": 100, "value": 100  },
    "show-recent":         { "type": "checkbox", "default": true,  "value": true  },
    "autostart-menu-item": { "type": "checkbox", "default": false, "value": false },
    "monitor-move-all-windows": { "type": "checkbox", "default": true, "value": true },
    "pinned-apps": {
        "type": "generic",
        "default": ["nemo.desktop", "firefox.desktop", "org.gnome.Terminal.desktop"],
        "value": ["nemo.desktop", "google-chrome.desktop", "kitty.desktop"]
    }
}
GWLEOF

echo "  [OK] grouped-window-list configurado (pinned: nemo, chrome, kitty)"

# ---------------------------------------------------------
# 5.5 system-monitor-graph — 3 instancias: CPU (id=1), Network (id=15), RAM (id=16)
#     Colores: fondo transparente, texto y líneas azul GNOME (rgb 153,193,241)
#     Tamaño: 0.6 (198x72px aprox.), duración 1min, refresco 1s
# ---------------------------------------------------------
mkdir -p "$SPICES_DIR/system-monitor-graph@rcassani"

# Plantilla base compartida entre las 3 instancias
SMG_BASE='{
    "duration":        { "type": "combobox",   "default": 60,   "value": 60   },
    "refresh-interval":{ "type": "combobox",   "default": 1,    "value": 1    },
    "background-color":{ "type": "colorchooser","default": "rgba(50,50,50,1)", "value": "rgba(191,64,64,0)" },
    "text-color":      { "type": "colorchooser","default": "rgba(255,255,255,1)", "value": "rgb(153,193,241)" },
    "midline-color":   { "type": "colorchooser","default": "rgba(127,127,127,1)", "value": "rgb(26,95,180)"  },
    "h-midlines":      { "type": "spinbutton", "default": 4,    "value": 4    },
    "v-midlines":      { "type": "spinbutton", "default": 4,    "value": 4    },
    "scale-size":      { "type": "scale",      "default": 1,    "value": 0.6  },
    "line-color-cpu":  { "type": "colorchooser","default": "rgba(23,147,208,1.0)",  "value": "rgb(153,193,241)"      },
    "line-color-ram":  { "type": "colorchooser","default": "rgba(137,190,67,1.0)",  "value": "rgb(153,193,241)"      },
    "line-color-swap": { "type": "colorchooser","default": "rgba(229,165,10,1.0)",  "value": "rgba(229,165,10,1.0)"  },
    "line-color-hdd":  { "type": "colorchooser","default": "rgba(197,86,33,1.0)",   "value": "rgba(197,86,33,1.0)"   },
    "line-color-gpu":  { "type": "colorchooser","default": "rgba(197,86,133,1.0)",  "value": "rgba(197,86,133,1.0)"  },
    "line-color-network-down": { "type": "colorchooser","default": "rgba(100,180,120,1.0)", "value": "rgb(153,193,241)" },
    "line-color-network-up":   { "type": "colorchooser","default": "rgba(180,120,100,1.0)", "value": "rgb(153,193,241)" },
    "line-color-battery":      { "type": "colorchooser","default": "rgba(255,204,0,1.0)",   "value": "rgba(255,204,0,1.0)" },
    "data-prefix-ram":     { "type": "combobox", "default": 0, "value": 0 },
    "data-prefix-swap":    { "type": "combobox", "default": 0, "value": 0 },
    "data-prefix-hdd":     { "type": "combobox", "default": 0, "value": 0 },
    "data-prefix-network": { "type": "combobox", "default": 0, "value": 2 },
    "network-interface":   { "type": "entry",    "default": "", "value": "" },
    "battery-name":        { "type": "entry",    "default": "BAT0", "value": "BAT0" },
    "filesystem":          { "type": "filechooser","default": "file:///", "value": "file:///" },
    "filesystem-label":    { "type": "entry",    "default": "", "value": "" },
    "cpu-variable":        { "type": "combobox", "default": "usage", "value": "usage" },
    "temperature-units-cpu": { "type": "combobox", "default": "C", "value": "C" },
    "gpu-manufacturer":    { "type": "combobox", "default": "nvidia", "value": "nvidia" },
    "gpu-id":              { "type": "entry",    "default": "0", "value": "0" },
    "gpu-variable":        { "type": "combobox", "default": "usage", "value": "usage" },
    "temperature-units-gpu": { "type": "combobox", "default": "C", "value": "C" },
    "data-prefix-gpumem":  { "type": "combobox", "default": 0, "value": 0 }
}'

# id=1 → CPU
python3 -c "
import json
d = json.loads('''$SMG_BASE''')
d['type'] = {'type':'combobox','default':'cpu','value':'cpu'}
print(json.dumps(d, indent=4))
" > "$SPICES_DIR/system-monitor-graph@rcassani/1.json"

# id=15 → Network
python3 -c "
import json
d = json.loads('''$SMG_BASE''')
d['type'] = {'type':'combobox','default':'cpu','value':'network'}
print(json.dumps(d, indent=4))
" > "$SPICES_DIR/system-monitor-graph@rcassani/15.json"

# id=16 → RAM
python3 -c "
import json
d = json.loads('''$SMG_BASE''')
d['type'] = {'type':'combobox','default':'cpu','value':'ram'}
print(json.dumps(d, indent=4))
" > "$SPICES_DIR/system-monitor-graph@rcassani/16.json"

echo "  [OK] system-monitor-graph configurado (CPU/Network/RAM)"

# ---------------------------------------------------------
# 5.6 commandResult@ZimiZones — muestra IP de interfaces físicas
# ---------------------------------------------------------
mkdir -p "$SPICES_DIR/commandResult@ZimiZones"

cat > "$SPICES_DIR/commandResult@ZimiZones/17.json" << 'CMDEOF'
{
    "delay":   { "default": 1,  "type": "spinbutton", "min": 1, "max": 1440, "step": 10, "value": 1  },
    "timeout": { "default": 30, "type": "spinbutton", "min": 1, "max": 1440, "step": 5,  "value": 30 },
    "commands": {
        "type": "list",
        "description": "Commands",
        "columns": [
            { "id": "label",               "title": "Label",                  "type": "string"  },
            { "id": "label-align-right",   "title": "Align label right",      "type": "boolean" },
            { "id": "command",             "title": "Command",                "type": "string"  },
            { "id": "command-align-right", "title": "Align command result right", "type": "boolean" }
        ],
        "default": [],
        "value": [
            {
                "label": "",
                "label-align-right": true,
                "command": "ip -o -4 addr show | awk '$2 ~ /^(en|eth|wl)/ {print $2, $4}'",
                "command-align-right": true
            }
        ]
    },
    "render-ansi": { "type": "checkbox", "default": false, "value": false },
    "font":        { "type": "fontchooser", "default": "Monospace 15", "value": "Monospace Bold 20" },
    "font-color":        { "type": "colorchooser", "default": "rgb(255,255,255)", "value": "rgb(255,255,255)"      },
    "background-color":  { "type": "colorchooser", "default": "rgb(0,0,0)",       "value": "rgba(191,64,64,0)"     },
    "background-transparency": { "type": "scale", "default": 0.5, "min": 0, "max": 1, "step": 0.05, "value": 0.5  },
    "border-color":  { "type": "colorchooser", "default": "rgb(255,255,255)", "value": "rgb(255,255,255)" },
    "border-width":  { "type": "spinbutton",   "default": 2,  "min": 0, "max": 200, "units": "px", "step": 1, "value": 2.0 }
}
CMDEOF

echo "  [OK] commandResult configurado"

# ---------------------------------------------------------
# 5.7 Propietario correcto de todos los spices
# ---------------------------------------------------------
chown -R "${USUARIO}:${USUARIO}" "$SPICES_DIR"

# ---------------------------------------------------------
# 5.8 Copiar todos los spices a skel para herencia
# ---------------------------------------------------------
cp -r "$SPICES_DIR/." "$SPICES_SKEL/"
echo "  [OK] Spices copiados a $SPICES_SKEL"

# =============================================================
# 6. ESCRITORIO — íconos y desktop-metadata (nemo)
# =============================================================
echo ""
echo "[6/6] Configurando escritorio..."

# ---------------------------------------------------------
# 6.1 Habilitar íconos en el escritorio via dconf
# ---------------------------------------------------------
dconf_write /org/nemo/desktop/show-desktop-icons "true"
dconf_write /org/nemo/desktop/home-icon-visible    "true"
dconf_write /org/nemo/desktop/trash-icon-visible   "true"
dconf_write /org/nemo/desktop/network-icon-visible "true"
dconf_write /org/nemo/desktop/volumes-visible      "true"

# ---------------------------------------------------------
# 6.2 Crear .desktop para Wireshark en el escritorio
# ---------------------------------------------------------
DESKTOP_DIR="$LAB_HOME/Desktop"
mkdir -p "$DESKTOP_DIR"

cat > "$DESKTOP_DIR/wireshark.desktop" << 'WSDEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Wireshark
Comment=Network protocol analyzer
Exec=wireshark
Icon=wireshark
Terminal=false
Categories=Network;Monitor;
WSDEOF

cat > "$DESKTOP_DIR/google-chrome.desktop" << 'CDEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Chrome
Comment=Access the Internet
Exec=/usr/bin/google-chrome-stable %U
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
CDEOF

cat > "$DESKTOP_DIR/kitty.desktop" << 'KDEOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=kitty
Comment=Fast, feature-rich, GPU based terminal
Exec=kitty
Icon=kitty
Terminal=false
Categories=System;TerminalEmulator;
KDEOF

chmod +x "$DESKTOP_DIR/wireshark.desktop"
chmod +x "$DESKTOP_DIR/google-chrome.desktop"
chmod +x "$DESKTOP_DIR/kitty.desktop"
chown "${USUARIO}:${USUARIO}" "$DESKTOP_DIR"/*.desktop

echo "  [OK] .desktop de Wireshark, Chrome y Kitty creados"

# ---------------------------------------------------------
# 6.3 desktop-metadata de nemo: posiciones columna izquierda
#     Resolución asumida: 1920x1080
#     Orden vertical: Home(30) → Network(130) → Wireshark(230)
#                     → Chrome(330) → kitty(430) → Trash(530)
# ---------------------------------------------------------
NEMO_CONF_DIR="$LAB_HOME/.config/nemo"
mkdir -p "$NEMO_CONF_DIR"

cat > "$NEMO_CONF_DIR/desktop-metadata" << 'METAEOF'
[desktop-monitor-0]
nemo-icon-view-keep-aligned=true
nemo-icon-view-auto-layout=false
nemo-icon-view-zoom-level=3
nemo-icon-view-sort-reversed=false
desktop-horizontal=false
desktop-grid-adjust=81;100;

[home]
nemo-icon-position=43,30
monitor=0
icon-scale=1

[trash]
nemo-icon-position=43,530
monitor=0
icon-scale=1

[network]
nemo-icon-position=43,130
monitor=0
icon-scale=1

[wireshark.desktop]
nemo-icon-position=43,230
monitor=0
icon-scale=1

[google-chrome.desktop]
nemo-icon-position=43,330
monitor=0
icon-scale=1

[kitty.desktop]
nemo-icon-position=43,430
monitor=0
icon-scale=1
METAEOF

chown -R "${USUARIO}:${USUARIO}" "$NEMO_CONF_DIR"
echo "  [OK] desktop-metadata configurado"

# ---------------------------------------------------------
# 6.4 Copiar Desktop y nemo config a skel para herencia
# ---------------------------------------------------------
SKEL_DESKTOP="$LAB_SKEL/Desktop"
SKEL_NEMO="$LAB_SKEL/.config/nemo"

mkdir -p "$SKEL_DESKTOP"
mkdir -p "$SKEL_NEMO"

cp "$DESKTOP_DIR/wireshark.desktop"    "$SKEL_DESKTOP/"
cp "$DESKTOP_DIR/google-chrome.desktop" "$SKEL_DESKTOP/"
cp "$DESKTOP_DIR/kitty.desktop"        "$SKEL_DESKTOP/"
chmod +x "$SKEL_DESKTOP/"*.desktop

cp "$NEMO_CONF_DIR/desktop-metadata" "$SKEL_NEMO/"

echo "  [OK] Desktop y nemo config copiados a skel"

# ---------------------------------------------------------
# 6.5 Autostart para aplicar panel en usuarios nuevos
#     (dconf no puede aplicarse desde root en skel directamente,
#      se usa el mismo mecanismo que en 02-temas.sh)
# ---------------------------------------------------------
AUTOSTART_SKEL="$LAB_SKEL/.config/autostart"
mkdir -p "$AUTOSTART_SKEL"

cat > "$AUTOSTART_SKEL/aplicar-panel.desktop" << 'PANELEOF'
[Desktop Entry]
Type=Application
Name=Aplicar configuración de panel del laboratorio
Exec=bash -c '\
dconf write /org/cinnamon/panels-height "['"'"'1:36'"'"']" && \
dconf write /org/cinnamon/panel-zone-icon-sizes '"'"'"[{\"panelId\": 1, \"left\": 48, \"center\": 24, \"right\": 24}]"'"'"' && \
dconf write /org/cinnamon/panel-zone-symbolic-icon-sizes '"'"'"[{\"panelId\": 1, \"left\": 16, \"center\": 16, \"right\": 15}]"'"'"' && \
dconf write /org/cinnamon/panel-zone-text-sizes '"'"'"[{\"panelId\": 1, \"left\": 9.0, \"center\": 6.5, \"right\": 9.0}]"'"'"' && \
dconf write /org/cinnamon/enabled-applets "['"'"'panel1:left:0:menu@cinnamon.org:0'"'"', '"'"'panel1:right:9:notifications@cinnamon.org:5'"'"', '"'"'panel1:right:11:removable-drives@cinnamon.org:7'"'"', '"'"'panel1:right:12:keyboard@cinnamon.org:8'"'"', '"'"'panel1:left:3:network@cinnamon.org:10'"'"', '"'"'panel1:right:14:sound@cinnamon.org:11'"'"', '"'"'panel1:right:15:power@cinnamon.org:12'"'"', '"'"'panel1:right:16:calendar@cinnamon.org:13'"'"', '"'"'panel1:right:17:cornerbar@cinnamon.org:14'"'"', '"'"'panel1:center:0:grouped-window-list@cinnamon.org:17'"'"', '"'"'panel1:left:4:workspace-switcher@cinnamon.org:20'"'"', '"'"'panel1:right:1:ipindicator@matus.benko@gmail.com:21'"'"']" && \
dconf write /org/cinnamon/enabled-desklets "['"'"'system-monitor-graph@rcassani:1:1660:930'"'"', '"'"'system-monitor-graph@rcassani:15:1660:790'"'"', '"'"'system-monitor-graph@rcassani:16:1660:860'"'"', '"'"'commandResult@ZimiZones:17:115:935'"'"', '"'"'clockTow@armandobs14:20:1715:70'"'"']" && \
dconf write /org/nemo/desktop/show-desktop-icons true && \
dconf write /org/nemo/desktop/home-icon-visible true && \
dconf write /org/nemo/desktop/trash-icon-visible true && \
dconf write /org/nemo/desktop/network-icon-visible true && \
dconf write /org/nemo/desktop/volumes-visible true && \
rm -f ~/.config/autostart/aplicar-panel.desktop'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
PANELEOF

echo "  [OK] Autostart de panel creado para usuarios futuros"

# =============================================================
# TAMBIÉN APLICAR LAS KEYS DE NEMO/ESCRITORIO AL USUARIO ACTUAL
# =============================================================
dconf_write /org/nemo/desktop/show-desktop-icons "true"
dconf_write /org/nemo/desktop/home-icon-visible    "true"
dconf_write /org/nemo/desktop/trash-icon-visible   "true"
dconf_write /org/nemo/desktop/network-icon-visible "true"
dconf_write /org/nemo/desktop/volumes-visible      "true"

echo ""
echo "============================================="
echo " PASO 04 COMPLETADO"
echo " Panel     : 36px, 12 applets configurados"
echo " Desklets  : CPU + Network + RAM + IP + Clock"
echo " Escritorio: Home / Network / Wireshark /"
echo "             Chrome / kitty / Trash"
echo " Herencia  : /etc/skel lista para adduser"
echo "============================================="
echo ""
echo " [i] Reinicia la sesión gráfica para ver"
echo "     los cambios: sudo pkill -u $USUARIO cinnamon"
echo "     o simplemente: sudo reboot"
echo "============================================="
