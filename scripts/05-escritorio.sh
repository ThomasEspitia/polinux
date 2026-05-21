#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 05-escritorio.sh — Iconos del escritorio y desklets
#
# Qué hace:
#   - Configura iconos visibles en el escritorio (Nemo desktop)
#     Home, Network, Trash — sin Computer ni Volumes
#   - Aplica configuración de desklets con sus JSONs exactos:
#       · system-monitor-graph (id:1)  → RAM
#       · system-monitor-graph (id:15) → CPU
#       · system-monitor-graph (id:16) → Network
#       · timelet            (id:8)    → Reloj Metro 24h
#       · commandResult      (id:17)   → IP de interfaces de red
#   - Copia JSONs de desklets a skel para herencia
#   - Crea autostart en skel para aplicar dconf en nuevos usuarios
#
# Exportado desde: polinux-turing (Cinnamon 6.6.4, 1920x1080)
#
# Uso individual: sudo bash scripts/05-escritorio.sh
# =============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ejecutar como root: sudo bash scripts/05-escritorio.sh"
    exit 1
fi

# --- Variables ---
USUARIO="${LAB_USER:-redsi}"
LAB_HOME="${LAB_HOME:-/home/${USUARIO}}"
LAB_SKEL="${LAB_SKEL:-/etc/skel}"

echo "============================================="
echo " PASO 05: Configurando escritorio..."
echo "============================================="

# =============================================================
# 1. ICONOS DEL ESCRITORIO (Nemo desktop)
# =============================================================
echo ""
echo "[1/3] Configurando iconos del escritorio..."

configurar_nemo_usuario() {
    local DEST_USER="$1"

    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/home-icon-visible    "true"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/network-icon-visible  "true"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/trash-icon-visible    "true"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/computer-icon-visible "false"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/volumes-visible       "false"

    # Mostrar íconos huérfanos (accesos directos copiados al escritorio)
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/show-orphaned-desktop-icons "true"

    # Layout: íconos a la izquierda, orden automático desactivado
    # Valor: 'true::false' = show_desktop=true, auto_arrange=false, align_left=false
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/desktop-layout "'true::false'"

    echo "  [OK] Iconos del escritorio configurados para: $DEST_USER"
}

configurar_nemo_usuario "$USUARIO"

# Skel: autostart aplica la config al primer login del usuario nuevo
mkdir -p "$LAB_SKEL/.config/autostart"
cat > "$LAB_SKEL/.config/autostart/aplicar-escritorio-nemo.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Aplicar iconos escritorio laboratorio
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
Exec=bash -c '\
dconf write /org/nemo/desktop/home-icon-visible true && \
dconf write /org/nemo/desktop/network-icon-visible true && \
dconf write /org/nemo/desktop/trash-icon-visible true && \
dconf write /org/nemo/desktop/computer-icon-visible false && \
dconf write /org/nemo/desktop/volumes-visible false && \
dconf write /org/nemo/desktop/show-orphaned-desktop-icons true && \
dconf write /org/nemo/desktop/desktop-layout "'"'"'true::false'"'"'" && \
rm -f "$HOME/.config/autostart/aplicar-escritorio-nemo.desktop"'
DESKTOP

echo "  [OK] Autostart nemo creado en skel"

# =============================================================
# 2. JSON DE DESKLETS
# =============================================================
echo ""
echo "[2/3] Configurando JSON de desklets..."

configurar_json_desklets() {
    local DEST_HOME="$1"
    local SPICES_DIR="$DEST_HOME/.config/cinnamon/spices"

    # ---------------------------------------------------------
    # system-monitor-graph id:1 → RAM
    # ---------------------------------------------------------
    mkdir -p "$SPICES_DIR/system-monitor-graph@rcassani"
    cat > "$SPICES_DIR/system-monitor-graph@rcassani/1.json" << 'JSONEOF'
{
    "type": { "type": "combobox", "default": "cpu", "value": "ram" },
    "duration": { "type": "combobox", "default": 60, "value": 60 },
    "refresh-interval": { "type": "combobox", "default": 1, "value": 1 },
    "background-color": { "type": "colorchooser", "default": "rgba(50,50,50,1)", "value": "rgba(191,64,64,0)" },
    "text-color": { "type": "colorchooser", "default": "rgba(255,255,255,1)", "value": "rgb(153,193,241)" },
    "line-color-cpu": { "type": "colorchooser", "default": "rgba(23,147,208,1.0)", "value": "rgba(23,147,208,1.0)" },
    "line-color-ram": { "type": "colorchooser", "default": "rgba(137,190,67,1.0)", "value": "rgb(153,193,241)" },
    "line-color-network-down": { "type": "colorchooser", "default": "rgba(100,180,120,1.0)", "value": "rgba(100,180,120,1.0)" },
    "line-color-network-up": { "type": "colorchooser", "default": "rgba(180,120,100,1.0)", "value": "rgba(180,120,100,1.0)" },
    "midline-color": { "type": "colorchooser", "default": "rgba(127,127,127,1)", "value": "rgb(26,95,180)" },
    "h-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "v-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "scale-size": { "type": "scale", "default": 1, "value": 0.6 },
    "data-prefix-ram": { "type": "combobox", "default": 0, "value": 0 },
    "network-interface": { "type": "entry", "default": "", "value": "" }
}
JSONEOF

    # ---------------------------------------------------------
    # system-monitor-graph id:15 → CPU
    # ---------------------------------------------------------
    cat > "$SPICES_DIR/system-monitor-graph@rcassani/15.json" << 'JSONEOF'
{
    "type": { "type": "combobox", "default": "cpu", "value": "cpu" },
    "cpu-variable": { "type": "combobox", "default": "usage", "value": "usage" },
    "duration": { "type": "combobox", "default": 60, "value": 60 },
    "refresh-interval": { "type": "combobox", "default": 1, "value": 1 },
    "background-color": { "type": "colorchooser", "default": "rgba(50,50,50,1)", "value": "rgba(191,64,64,0)" },
    "text-color": { "type": "colorchooser", "default": "rgba(255,255,255,1)", "value": "rgb(153,193,241)" },
    "line-color-cpu": { "type": "colorchooser", "default": "rgba(23,147,208,1.0)", "value": "rgb(153,193,241)" },
    "line-color-ram": { "type": "colorchooser", "default": "rgba(137,190,67,1.0)", "value": "rgba(137,190,67,1.0)" },
    "midline-color": { "type": "colorchooser", "default": "rgba(127,127,127,1)", "value": "rgb(26,95,180)" },
    "h-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "v-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "scale-size": { "type": "scale", "default": 1, "value": 0.6 },
    "network-interface": { "type": "entry", "default": "", "value": "" }
}
JSONEOF

    # ---------------------------------------------------------
    # system-monitor-graph id:16 → Network (bits/s)
    # ---------------------------------------------------------
    cat > "$SPICES_DIR/system-monitor-graph@rcassani/16.json" << 'JSONEOF'
{
    "type": { "type": "combobox", "default": "cpu", "value": "network" },
    "data-prefix-network": { "type": "combobox", "default": 0, "value": 2 },
    "network-interface": { "type": "entry", "default": "", "value": "" },
    "duration": { "type": "combobox", "default": 60, "value": 60 },
    "refresh-interval": { "type": "combobox", "default": 1, "value": 1 },
    "background-color": { "type": "colorchooser", "default": "rgba(50,50,50,1)", "value": "rgba(191,64,64,0)" },
    "text-color": { "type": "colorchooser", "default": "rgba(255,255,255,1)", "value": "rgb(153,193,241)" },
    "line-color-cpu": { "type": "colorchooser", "default": "rgba(23,147,208,1.0)", "value": "rgba(23,147,208,1.0)" },
    "line-color-network-down": { "type": "colorchooser", "default": "rgba(100,180,120,1.0)", "value": "rgb(153,193,241)" },
    "line-color-network-up": { "type": "colorchooser", "default": "rgba(180,120,100,1.0)", "value": "rgb(153,193,241)" },
    "midline-color": { "type": "colorchooser", "default": "rgba(127,127,127,1)", "value": "rgb(26,95,180)" },
    "h-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "v-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "scale-size": { "type": "scale", "default": 1, "value": 0.6 }
}
JSONEOF

    # ---------------------------------------------------------
    # timelet id:8 → Reloj Metro, 24h, azul claro, fondo transparente
    # ---------------------------------------------------------
    mkdir -p "$SPICES_DIR/timelet@linuxedo.com"
    cat > "$SPICES_DIR/timelet@linuxedo.com/8.json" << 'JSONEOF'
{
    "themeName": { "type": "combobox", "default": "Gotham", "value": "Metro" },
    "use24H": { "type": "checkbox", "default": false, "value": true },
    "textColor": { "type": "colorchooser", "default": "rgb(255,255,255)", "value": "rgb(153,193,241)" },
    "bgColor": { "type": "colorchooser", "default": "rgb(0,0,0)", "value": "rgba(191,64,64,0)" },
    "scale": { "type": "scale", "default": 1, "min": 0.1, "max": 2, "step": 0.05, "value": 1 },
    "transparency": { "type": "scale", "default": 0.5, "min": 0, "max": 1, "step": 0.05, "value": 0 },
    "cornerRadius": { "type": "scale", "default": 10, "min": 0, "max": 50, "step": 1, "value": 0 }
}
JSONEOF

    # ---------------------------------------------------------
    # commandResult id:17 → Muestra IPs de interfaces de red
    # ---------------------------------------------------------
    mkdir -p "$SPICES_DIR/commandResult@ZimiZones"
    cat > "$SPICES_DIR/commandResult@ZimiZones/commandResult@ZimiZones.json" << 'JSONEOF'
{
    "delay": { "default": 1, "type": "spinbutton", "min": 1, "max": 1440, "step": 10, "value": 1 },
    "timeout": { "default": 30, "type": "spinbutton", "min": 1, "max": 1440, "step": 5, "value": 30 },
    "commands": {
        "type": "list",
        "description": "Commands",
        "columns": [
            { "id": "label", "title": "Label", "type": "string" },
            { "id": "label-align-right", "title": "Align label right", "type": "boolean" },
            { "id": "command", "title": "Command", "type": "string" },
            { "id": "command-align-right", "title": "Align command result right", "type": "boolean" }
        ],
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
    "font": { "type": "fontchooser", "default": "Monospace 15", "value": "Monospace Bold 20" },
    "font-color": { "type": "colorchooser", "default": "rgb(255,255,255)", "value": "rgb(255,255,255)" },
    "background-color": { "type": "colorchooser", "default": "rgb(0,0,0)", "value": "rgba(191,64,64,0)" },
    "background-transparency": { "type": "scale", "default": 0.5, "min": 0, "max": 1, "step": 0.05, "value": 0.5 },
    "border-color": { "type": "colorchooser", "default": "rgb(255,255,255)", "value": "rgb(255,255,255)" },
    "border-width": { "type": "spinbutton", "default": 2, "min": 0, "max": 200, "value": 2.0 }
}
JSONEOF

    echo "  [OK] JSONs de desklets configurados en: $DEST_HOME"
}

configurar_json_desklets "$LAB_HOME"
chown -R "${USUARIO}:${USUARIO}" "$LAB_HOME/.config/cinnamon/spices"

# Copiar JSONs a skel
SKEL_SPICES="$LAB_SKEL/.config/cinnamon/spices"
mkdir -p "$SKEL_SPICES"
cp -r "$LAB_HOME/.config/cinnamon/spices/system-monitor-graph@rcassani" "$SKEL_SPICES/"
cp -r "$LAB_HOME/.config/cinnamon/spices/timelet@linuxedo.com"          "$SKEL_SPICES/"
cp -r "$LAB_HOME/.config/cinnamon/spices/commandResult@ZimiZones"       "$SKEL_SPICES/"
echo "  [OK] JSONs de desklets copiados a skel"

# =============================================================
# 3. DCONF DE DESKLETS — posiciones y dconf del escritorio
# =============================================================
echo ""
echo "[3/3] Aplicando dconf de desklets y escritorio..."

aplicar_dconf_escritorio() {
    local DEST_USER="$1"

    # Desklets habilitados con posiciones (1920x1080)
    # id:1  system-monitor-graph → RAM      (abajo derecha)
    # id:8  timelet              → Reloj    (arriba derecha)
    # id:15 system-monitor-graph → CPU      (abajo derecha, encima de RAM)
    # id:16 system-monitor-graph → Network  (abajo derecha, encima de CPU)
    # id:17 commandResult        → IP       (abajo izquierda)
    sudo -u "$DEST_USER" dconf write /org/cinnamon/enabled-desklets \
        "['system-monitor-graph@rcassani:1:1660:930', \
'timelet@linuxedo.com:8:1620:50', \
'system-monitor-graph@rcassani:15:1660:790', \
'system-monitor-graph@rcassani:16:1660:860', \
'commandResult@ZimiZones:17:115:935']"

    sudo -u "$DEST_USER" dconf write /org/cinnamon/lock-desklets "false"

    echo "  [OK] dconf de desklets aplicado a: $DEST_USER"
}

aplicar_dconf_escritorio "$USUARIO"

# Autostart en skel para dconf de desklets
cat > "$LAB_SKEL/.config/autostart/aplicar-escritorio-desklets.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Aplicar desklets escritorio laboratorio
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
Exec=bash -c '\
dconf write /org/cinnamon/enabled-desklets \
  "['"'"'system-monitor-graph@rcassani:1:1660:930'"'"','"'"'timelet@linuxedo.com:8:1620:50'"'"','"'"'system-monitor-graph@rcassani:15:1660:790'"'"','"'"'system-monitor-graph@rcassani:16:1660:860'"'"','"'"'commandResult@ZimiZones:17:115:935'"'"']" && \
dconf write /org/cinnamon/lock-desklets "false" && \
rm -f "$HOME/.config/autostart/aplicar-escritorio-desklets.desktop"'
DESKTOP

echo "  [OK] Autostart desklets creado en skel"

# =============================================================
# RESUMEN
# =============================================================
echo ""
echo "============================================="
echo " PASO 05 COMPLETADO - Escritorio configurado"
echo ""
echo " Iconos escritorio:"
echo "   Home, Network, Trash (visible)"
echo "   Computer, Volumes    (ocultos)"
echo ""
echo " Desklets (posiciones para 1920x1080):"
echo "   RAM     system-monitor-graph :1  → 1660,930"
echo "   Reloj   timelet              :8  → 1620,50"
echo "   CPU     system-monitor-graph :15 → 1660,790"
echo "   Network system-monitor-graph :16 → 1660,860"
echo "   IP      commandResult        :17 → 115,935"
echo ""
echo " [i] Cierra sesión y vuelve a entrar para"
echo "     ver los cambios aplicados."
echo "============================================="
