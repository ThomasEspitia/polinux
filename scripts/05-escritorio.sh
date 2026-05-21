#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 05-escritorio.sh — Iconos del escritorio y desklets
#
# Qué hace:
#   - Instala moonlight-clock desde extras/desklets/
#   - Configura iconos visibles en el escritorio (Home, Network, Trash)
#   - Crea accesos directos de Wireshark, Chrome y kitty en ~/Desktop
#   - Aplica configuración de desklets con sus JSONs exactos:
#       · moonlight-clock         (id:1)  → Reloj arriba derecha
#       · system-monitor-graph    (id:2)  → CPU
#       · system-monitor-graph    (id:3)  → Network
#       · system-monitor-graph    (id:4)  → RAM
#       · commandResult           (id:5)  → IP interfaces de red
#   - Bloquea desklets para que no se puedan mover/modificar
#   - Copia todo a skel para herencia
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
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DESKLETS_SRC="$REPO_DIR/extras/desklets"

echo "============================================="
echo " PASO 05: Configurando escritorio..."
echo "============================================="

# =============================================================
# 1. INSTALAR MOONLIGHT-CLOCK
# =============================================================
echo ""
echo "[1/5] Instalando moonlight-clock..."

MOONLIGHT_SRC="$DESKLETS_SRC/moonlight-clock@torchipeppo"
MOONLIGHT_SYSTEM="/usr/share/cinnamon/desklets/moonlight-clock@torchipeppo"
MOONLIGHT_SKEL="$LAB_SKEL/.local/share/cinnamon/desklets/moonlight-clock@torchipeppo"

if [ ! -d "$MOONLIGHT_SRC" ]; then
    echo "  [WARN] No se encontró $MOONLIGHT_SRC"
    echo "         Agrega el desklet al repo en extras/desklets/"
else
    # Instalar en sistema para que todos los usuarios lo vean
    cp -r "$MOONLIGHT_SRC" "$MOONLIGHT_SYSTEM"
    echo "  [OK] moonlight-clock instalado en sistema"

    # Skel para usuarios futuros
    mkdir -p "$LAB_SKEL/.local/share/cinnamon/desklets"
    cp -r "$MOONLIGHT_SRC" "$MOONLIGHT_SKEL"
    echo "  [OK] moonlight-clock copiado a skel"
fi

# =============================================================
# 2. ICONOS DEL ESCRITORIO (Nemo desktop)
# =============================================================
echo ""
echo "[2/5] Configurando iconos del escritorio..."

configurar_nemo() {
    local DEST_USER="$1"

    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/home-icon-visible    "true"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/network-icon-visible  "true"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/trash-icon-visible    "true"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/computer-icon-visible "false"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/volumes-visible       "false"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/show-orphaned-desktop-icons "true"
    sudo -u "$DEST_USER" dconf write /org/nemo/desktop/desktop-layout        "'true::false'"

    echo "  [OK] Iconos del escritorio configurados para: $DEST_USER"
}

configurar_nemo "$USUARIO"

# =============================================================
# 3. ACCESOS DIRECTOS EN EL ESCRITORIO
# =============================================================
echo ""
echo "[3/5] Creando accesos directos en el escritorio..."

DESKTOP_DIR="$LAB_HOME/Desktop"
SKEL_DESKTOP="$LAB_SKEL/Desktop"
mkdir -p "$DESKTOP_DIR"
mkdir -p "$SKEL_DESKTOP"

# --- Wireshark ---
cat > "$DESKTOP_DIR/wireshark.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Wireshark
Comment=Network traffic analyzer
Exec=wireshark
Icon=wireshark
Terminal=false
Categories=Network;Monitor;
EOF

# --- Google Chrome ---
cat > "$DESKTOP_DIR/google-chrome.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Google Chrome
Comment=Access the Internet
Exec=/usr/bin/google-chrome-stable %U
Icon=google-chrome
Terminal=false
Categories=Network;WebBrowser;
EOF

# --- Kitty ---
cat > "$DESKTOP_DIR/kitty.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=kitty
Comment=Fast, feature-rich, GPU based terminal emulator
Exec=kitty
Icon=kitty
Terminal=false
Categories=System;TerminalEmulator;
EOF

# Permisos: marcar como ejecutables (necesario para que Nemo los muestre)
chmod +x "$DESKTOP_DIR/wireshark.desktop"
chmod +x "$DESKTOP_DIR/google-chrome.desktop"
chmod +x "$DESKTOP_DIR/kitty.desktop"
chown "${USUARIO}:${USUARIO}" "$DESKTOP_DIR/"*.desktop

# Copiar a skel
cp "$DESKTOP_DIR/wireshark.desktop"    "$SKEL_DESKTOP/"
cp "$DESKTOP_DIR/google-chrome.desktop" "$SKEL_DESKTOP/"
cp "$DESKTOP_DIR/kitty.desktop"        "$SKEL_DESKTOP/"
chmod +x "$SKEL_DESKTOP/"*.desktop

echo "  [OK] Accesos directos creados: Wireshark, Chrome, kitty"

# =============================================================
# 4. JSON DE DESKLETS
# =============================================================
echo ""
echo "[4/5] Configurando JSON de desklets..."

configurar_json_desklets() {
    local DEST_HOME="$1"
    local SPICES_DIR="$DEST_HOME/.config/cinnamon/spices"

    # ---------------------------------------------------------
    # moonlight-clock id:1 → Reloj arriba derecha
    # Configuración: fondo transparente, color azul claro,
    # fase lunar, sin caption, escala 1
    # ---------------------------------------------------------
    mkdir -p "$SPICES_DIR/moonlight-clock@torchipeppo"
    cat > "$SPICES_DIR/moonlight-clock@torchipeppo/1.json" << 'JSONEOF'
{
    "global-h-offset": { "type": "spinbutton", "default": 0, "value": 0 },
    "global-v-offset": { "type": "spinbutton", "default": 0, "value": 0 },
    "global-scale": { "type": "spinbutton", "default": 1, "value": 1 },
    "global-color-scheme": { "type": "combobox", "default": "blue", "value": "the-custom" },
    "global-custom-corner1": { "type": "colorchooser", "default": "#67baff", "value": "rgba(191,64,64,0)" },
    "global-custom-corner2": { "type": "colorchooser", "default": "black", "value": "rgba(191,64,64,0)" },
    "global-custom-time": { "type": "colorchooser", "default": "white", "value": "white" },
    "global-custom-shadow": { "type": "colorchooser", "default": "#447fab", "value": "rgb(15,37,74)" },
    "global-custom-date": { "type": "colorchooser", "default": "#226182", "value": "rgb(255,255,255)" },
    "global-custom-bottom": { "type": "colorchooser", "default": "aliceblue", "value": "rgb(240,248,255)" },
    "global-custom-highlight": { "type": "colorchooser", "default": "#7bffff", "value": "#7bffff" },
    "global-color-invert-bottom": { "type": "switch", "default": false, "value": false },
    "global-color-use-highlight": { "type": "switch", "default": true, "value": true },
    "top-format": { "type": "entry", "default": "", "value": "" },
    "top-font": { "type": "fontchooser", "default": "Bold 52", "value": "Bold 52" },
    "top-v-offset": { "type": "spinbutton", "default": 0, "value": 0 },
    "top-weekday": { "type": "switch", "default": true, "value": true },
    "middle-format": { "type": "entry", "default": "", "value": "" },
    "middle-font": { "type": "fontchooser", "default": "Normal 70", "value": "Normal 70" },
    "middle-v-offset": { "type": "spinbutton", "default": 0, "value": 0 },
    "middle-shadow": { "type": "switch", "default": true, "value": true },
    "middle-shadow-offset": { "type": "spinbutton", "default": 8, "value": 8 },
    "wapi-enable": { "type": "switch", "default": true, "value": false },
    "wapi-key": { "type": "entry", "default": "", "value": "" },
    "wapi-query": { "type": "entry", "default": "auto:ip", "value": "auto:ip" },
    "wapi-update-period-minutes": { "type": "combobox", "default": 60, "value": 60 },
    "bottom-emoji-type": { "type": "combobox", "default": "moon", "value": "moon" },
    "bottom-emoji-size": { "type": "spinbutton", "default": 70, "value": 60 },
    "bottom-caption-type": { "type": "combobox", "default": "cntdn-cstm", "value": "" },
    "bottom-caption-font": { "type": "fontchooser", "default": "Bold 50", "value": "Bold 50" },
    "bottom-caption-v-offset": { "type": "spinbutton", "default": 0, "value": 0 },
    "bottom-caption-shadow": { "type": "switch", "default": false, "value": false },
    "bottom-caption-shadow-offset": { "type": "spinbutton", "default": 4, "value": 4 },
    "bottom-show-secondary-countdowns": { "type": "switch", "default": true, "value": true },
    "custom-countdown-list": { "type": "generic", "default": [], "value": [] },
    "first-time": { "type": "generic", "default": true, "value": false }
}
JSONEOF

    # ---------------------------------------------------------
    # system-monitor-graph id:2 → CPU
    # ---------------------------------------------------------
    mkdir -p "$SPICES_DIR/system-monitor-graph@rcassani"
    cat > "$SPICES_DIR/system-monitor-graph@rcassani/2.json" << 'JSONEOF'
{
    "type": { "type": "combobox", "default": "cpu", "value": "cpu" },
    "cpu-variable": { "type": "combobox", "default": "usage", "value": "usage" },
    "duration": { "type": "combobox", "default": 60, "value": 60 },
    "refresh-interval": { "type": "combobox", "default": 1, "value": 1 },
    "background-color": { "type": "colorchooser", "default": "rgba(50,50,50,1)", "value": "rgba(191,64,64,0)" },
    "text-color": { "type": "colorchooser", "default": "rgba(255,255,255,1)", "value": "rgb(153,193,241)" },
    "line-color-cpu": { "type": "colorchooser", "default": "rgba(23,147,208,1.0)", "value": "rgb(153,193,241)" },
    "midline-color": { "type": "colorchooser", "default": "rgba(127,127,127,1)", "value": "rgb(26,95,180)" },
    "h-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "v-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "scale-size": { "type": "scale", "default": 1, "value": 0.6 }
}
JSONEOF

    # ---------------------------------------------------------
    # system-monitor-graph id:3 → Network (bits/s)
    # ---------------------------------------------------------
    cat > "$SPICES_DIR/system-monitor-graph@rcassani/3.json" << 'JSONEOF'
{
    "type": { "type": "combobox", "default": "cpu", "value": "network" },
    "data-prefix-network": { "type": "combobox", "default": 0, "value": 2 },
    "network-interface": { "type": "entry", "default": "", "value": "" },
    "duration": { "type": "combobox", "default": 60, "value": 60 },
    "refresh-interval": { "type": "combobox", "default": 1, "value": 1 },
    "background-color": { "type": "colorchooser", "default": "rgba(50,50,50,1)", "value": "rgba(191,64,64,0)" },
    "text-color": { "type": "colorchooser", "default": "rgba(255,255,255,1)", "value": "rgb(153,193,241)" },
    "line-color-network-down": { "type": "colorchooser", "default": "rgba(100,180,120,1.0)", "value": "rgb(153,193,241)" },
    "line-color-network-up": { "type": "colorchooser", "default": "rgba(180,120,100,1.0)", "value": "rgb(153,193,241)" },
    "midline-color": { "type": "colorchooser", "default": "rgba(127,127,127,1)", "value": "rgb(26,95,180)" },
    "h-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "v-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "scale-size": { "type": "scale", "default": 1, "value": 0.6 }
}
JSONEOF

    # ---------------------------------------------------------
    # system-monitor-graph id:4 → RAM
    # ---------------------------------------------------------
    cat > "$SPICES_DIR/system-monitor-graph@rcassani/4.json" << 'JSONEOF'
{
    "type": { "type": "combobox", "default": "cpu", "value": "ram" },
    "data-prefix-ram": { "type": "combobox", "default": 0, "value": 0 },
    "duration": { "type": "combobox", "default": 60, "value": 60 },
    "refresh-interval": { "type": "combobox", "default": 1, "value": 1 },
    "background-color": { "type": "colorchooser", "default": "rgba(50,50,50,1)", "value": "rgba(191,64,64,0)" },
    "text-color": { "type": "colorchooser", "default": "rgba(255,255,255,1)", "value": "rgb(153,193,241)" },
    "line-color-ram": { "type": "colorchooser", "default": "rgba(137,190,67,1.0)", "value": "rgb(153,193,241)" },
    "midline-color": { "type": "colorchooser", "default": "rgba(127,127,127,1)", "value": "rgb(26,95,180)" },
    "h-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "v-midlines": { "type": "spinbutton", "default": 4, "value": 4 },
    "scale-size": { "type": "scale", "default": 1, "value": 0.6 }
}
JSONEOF

    # ---------------------------------------------------------
    # commandResult id:5 → IP de interfaces de red
    # ---------------------------------------------------------
    mkdir -p "$SPICES_DIR/commandResult@ZimiZones"
    cat > "$SPICES_DIR/commandResult@ZimiZones/commandResult@ZimiZones.json" << 'JSONEOF'
{
    "delay": { "default": 1, "type": "spinbutton", "min": 1, "max": 1440, "step": 10, "value": 1 },
    "timeout": { "default": 30, "type": "spinbutton", "min": 1, "max": 1440, "step": 5, "value": 30 },
    "commands": {
        "type": "list",
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
    "background-transparency": { "type": "scale", "default": 0.5, "value": 0.5 },
    "border-color": { "type": "colorchooser", "default": "rgb(255,255,255)", "value": "rgb(255,255,255)" },
    "border-width": { "type": "spinbutton", "default": 2, "value": 2.0 }
}
JSONEOF

    echo "  [OK] JSONs de desklets configurados en: $DEST_HOME"
}

configurar_json_desklets "$LAB_HOME"
chown -R "${USUARIO}:${USUARIO}" "$LAB_HOME/.config/cinnamon/spices"

# Copiar JSONs a skel
SKEL_SPICES="$LAB_SKEL/.config/cinnamon/spices"
mkdir -p "$SKEL_SPICES"
cp -r "$LAB_HOME/.config/cinnamon/spices/moonlight-clock@torchipeppo" "$SKEL_SPICES/"
cp -r "$LAB_HOME/.config/cinnamon/spices/system-monitor-graph@rcassani" "$SKEL_SPICES/"
cp -r "$LAB_HOME/.config/cinnamon/spices/commandResult@ZimiZones"       "$SKEL_SPICES/"
echo "  [OK] JSONs de desklets copiados a skel"

# =============================================================
# 5. DCONF — desklets, posiciones y bloqueo
# =============================================================
echo ""
echo "[5/5] Aplicando dconf de desklets..."

aplicar_dconf_escritorio() {
    local DEST_USER="$1"

    # Desklets con IDs frescos (1-5) y posiciones para 1920x1080
    # id:1  moonlight-clock        → arriba derecha  1275:50
    # id:2  system-monitor-graph   → CPU             1660:790
    # id:3  system-monitor-graph   → Network         1660:860
    # id:4  system-monitor-graph   → RAM             1660:930
    # id:5  commandResult          → IP abajo izq    115:935
    sudo -u "$DEST_USER" dconf write /org/cinnamon/enabled-desklets \
        "['moonlight-clock@torchipeppo:1:1275:50', \
'system-monitor-graph@rcassani:2:1660:790', \
'system-monitor-graph@rcassani:3:1660:860', \
'system-monitor-graph@rcassani:4:1660:930', \
'commandResult@ZimiZones:5:115:935']"

    # Bloquear desklets — no se pueden mover ni modificar desde el escritorio
    sudo -u "$DEST_USER" dconf write /org/cinnamon/lock-desklets "true"

    # Asegurarse de que next-desklet-id quede en 6 para no colisionar
    sudo -u "$DEST_USER" dconf write /org/cinnamon/next-desklet-id "6"

    echo "  [OK] dconf de desklets aplicado a: $DEST_USER"
}

aplicar_dconf_escritorio "$USUARIO"

# Autostart en skel para usuarios futuros
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

cat > "$LAB_SKEL/.config/autostart/aplicar-escritorio-desklets.desktop" << 'DESKTOP'
[Desktop Entry]
Type=Application
Name=Aplicar desklets escritorio laboratorio
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
Exec=bash -c '\
dconf write /org/cinnamon/enabled-desklets \
  "['"'"'moonlight-clock@torchipeppo:1:1275:50'"'"','"'"'system-monitor-graph@rcassani:2:1660:790'"'"','"'"'system-monitor-graph@rcassani:3:1660:860'"'"','"'"'system-monitor-graph@rcassani:4:1660:930'"'"','"'"'commandResult@ZimiZones:5:115:935'"'"']" && \
dconf write /org/cinnamon/lock-desklets "true" && \
dconf write /org/cinnamon/next-desklet-id 6 && \
rm -f "$HOME/.config/autostart/aplicar-escritorio-desklets.desktop"'
DESKTOP

echo "  [OK] Autostarts creados en skel"

# =============================================================
# RESUMEN
# =============================================================
echo ""
echo "============================================="
echo " PASO 05 COMPLETADO - Escritorio configurado"
echo ""
echo " Iconos escritorio:"
echo "   Home, Network, Trash   (visibles)"
echo "   Computer, Volumes      (ocultos)"
echo "   Wireshark, Chrome, kitty (accesos directos)"
echo ""
echo " Desklets (1920x1080, bloqueados):"
echo "   moonlight-clock  :1 → 1275,50   (reloj)"
echo "   CPU  graph       :2 → 1660,790"
echo "   Net  graph       :3 → 1660,860"
echo "   RAM  graph       :4 → 1660,930"
echo "   IP commandResult :5 → 115,935"
echo ""
echo " [i] IMPORTANTE:"
echo "     1. Agrega extras/desklets/moonlight-clock@torchipeppo"
echo "        al repo antes de correr en los otros equipos."
echo "     2. Cierra sesión y vuelve a entrar para ver cambios."
echo "============================================="
