#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 05-terminal.sh — Terminal, Shell y Herramientas
#
# Qué hace este script:
#   - Configura Kitty como terminal por defecto del sistema
#   - Copia los dotfiles de kitty (kitty.conf + blue-dark.conf)
#   - Instala la fuente JetBrains Mono Nerd Font
#   - Instala Fish shell y lo establece como shell por defecto
#   - Instala Oh My Posh con tema agnoster
#   - Instala eza, bat, grc, ccze para salidas coloridas
#   - Configura aliases enfocados en laboratorio de redes
#   - Todo se aplica a redsi y usuarios futuros via /etc/skel
#
# Uso individual: sudo bash scripts/05-terminal.sh
# =============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ejecutar como root: sudo bash scripts/05-terminal.sh"
    exit 1
fi

# =============================================================
# VARIABLES
# =============================================================
USUARIO="${LAB_USER:-redsi}"
LAB_HOME="${LAB_HOME:-/home/${USUARIO}}"
LAB_SKEL="${LAB_SKEL:-/etc/skel}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KITTY_DOTFILES="$REPO_DIR/dotfiles/kitty"
FONT_DIR="$REPO_DIR/JetBrainsMono"

echo "============================================="
echo " PASO 05: Terminal, Shell y Herramientas..."
echo "============================================="

# =============================================================
# 1. VERIFICAR ARCHIVOS NECESARIOS
# =============================================================
echo ""
echo "[1/9] Verificando archivos necesarios..."

if [ ! -d "$KITTY_DOTFILES" ]; then
    echo "[ERROR] No se encontró: $KITTY_DOTFILES"
    echo "        Estructura esperada: dotfiles/kitty/kitty.conf y blue-dark.conf"
    exit 1
fi

for ARCHIVO in kitty.conf blue-dark.conf; do
    if [ ! -f "$KITTY_DOTFILES/$ARCHIVO" ]; then
        echo "[ERROR] Falta el archivo: $KITTY_DOTFILES/$ARCHIVO"
        exit 1
    fi
done
echo "[OK] Dotfiles de kitty encontrados"

if [ ! -d "$FONT_DIR" ]; then
    echo "[ERROR] No se encontró la carpeta de fuentes: $FONT_DIR"
    echo "        Descarga JetBrains Mono Nerd Font y colócala en JetBrainsMono/"
    exit 1
fi
echo "[OK] Carpeta de fuentes encontrada"

# =============================================================
# 2. INSTALAR PAQUETES DE SISTEMA
# =============================================================
echo ""
echo "[2/9] Instalando paquetes..."

# bat puede llamarse batcat en Ubuntu/Mint
apt install -y \
    fish \
    grc \
    bat \
    ccze \
    curl \
    unzip \
    fontconfig

echo "[OK] Paquetes base instalados"

# Instalar eza (no está en repos de Ubuntu/Mint estables)
if command -v eza &>/dev/null; then
    echo "[INFO] eza ya instalado: $(eza --version | head -1)"
else
    echo "  Instalando eza..."
    EZA_URL="https://github.com/eza-community/eza/releases/latest/download/eza_x86_64-unknown-linux-gnu.tar.gz"
    curl -Lo /tmp/eza.tar.gz "$EZA_URL"
    tar -xzf /tmp/eza.tar.gz -C /tmp/
    mv /tmp/eza /usr/local/bin/eza
    chmod +x /usr/local/bin/eza
    rm -f /tmp/eza.tar.gz
    echo "[OK] eza instalado: $(eza --version | head -1)"
fi

# En Ubuntu/Mint bat se instala como 'batcat', crear symlink
if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    ln -sf "$(which batcat)" /usr/local/bin/bat
    echo "[OK] Symlink bat → batcat creado"
fi

# =============================================================
# 3. INSTALAR OH MY POSH
# =============================================================
echo ""
echo "[3/9] Instalando Oh My Posh..."

if command -v oh-my-posh &>/dev/null; then
    echo "[INFO] Oh My Posh ya instalado: $(oh-my-posh --version)"
else
    curl -s https://ohmyposh.dev/install.sh | bash -s -- -d /usr/local/bin
    echo "[OK] Oh My Posh instalado en /usr/local/bin/oh-my-posh"
fi

# Descargar temas de Oh My Posh al directorio del sistema
OMP_THEMES_DIR="/usr/local/share/oh-my-posh/themes"
mkdir -p "$OMP_THEMES_DIR"

if [ ! -f "$OMP_THEMES_DIR/agnoster.omp.json" ]; then
    echo "  Descargando temas de Oh My Posh..."
    curl -Lo /tmp/omp-themes.zip \
        "https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip"
    unzip -o /tmp/omp-themes.zip -d "$OMP_THEMES_DIR"
    chmod -R 644 "$OMP_THEMES_DIR/"*.json 2>/dev/null || true
    rm -f /tmp/omp-themes.zip
    echo "[OK] Temas de Oh My Posh descargados en $OMP_THEMES_DIR"
else
    echo "[INFO] Temas de Oh My Posh ya presentes"
fi

# Tema elegido: agnoster — limpio, informativo, ideal para terminales de red
OMP_TEMA="agnoster"

# Copiar tema al cache del usuario principal y de skel
for DESTINO_HOME in "$LAB_HOME" "$LAB_SKEL"; do
    mkdir -p "$DESTINO_HOME/.cache/oh-my-posh/themes"
    cp "$OMP_THEMES_DIR/${OMP_TEMA}.omp.json" \
        "$DESTINO_HOME/.cache/oh-my-posh/themes/${OMP_TEMA}.omp.json"
done

chown -R "${USUARIO}:${USUARIO}" "$LAB_HOME/.cache/oh-my-posh"
echo "[OK] Tema ${OMP_TEMA} copiado a cache de usuario y skel"

# =============================================================
# 4. INSTALAR FUENTE JETBRAINS MONO NERD FONT
# =============================================================
echo ""
echo "[4/9] Instalando fuente JetBrains Mono Nerd Font..."

FONT_DEST="/usr/local/share/fonts/JetBrainsMono"
mkdir -p "$FONT_DEST"

FONT_COUNT=0
find "$FONT_DIR" -name "*.ttf" -o -name "*.otf" | while read -r FONT_FILE; do
    cp "$FONT_FILE" "$FONT_DEST/"
    FONT_COUNT=$((FONT_COUNT + 1))
done

fc-cache -fv > /dev/null 2>&1
echo "[OK] JetBrains Mono Nerd Font instalada en $FONT_DEST"

# =============================================================
# 5. CONFIGURAR KITTY
# =============================================================
echo ""
echo "[5/9] Configurando Kitty..."

KITTY_CONF_SKEL="$LAB_SKEL/.config/kitty"
KITTY_CONF_USER="$LAB_HOME/.config/kitty"

mkdir -p "$KITTY_CONF_SKEL"
mkdir -p "$KITTY_CONF_USER"

# Copiar los dotfiles de kitty
cp "$KITTY_DOTFILES/kitty.conf"    "$KITTY_CONF_SKEL/kitty.conf"
cp "$KITTY_DOTFILES/blue-dark.conf" "$KITTY_CONF_SKEL/blue-dark.conf"

# Asegurarse de que kitty.conf apunte al tema blue-dark
# (por si el archivo fuente trae otro include)
if grep -q "^include " "$KITTY_CONF_SKEL/kitty.conf"; then
    sed -i 's|^include .*|include ./blue-dark.conf|' "$KITTY_CONF_SKEL/kitty.conf"
else
    echo -e "\ninclude ./blue-dark.conf" >> "$KITTY_CONF_SKEL/kitty.conf"
fi

# Agregar opacidad si no está definida
if grep -q "^background_opacity" "$KITTY_CONF_SKEL/kitty.conf"; then
    sed -i 's|^background_opacity.*|background_opacity 0.98|' "$KITTY_CONF_SKEL/kitty.conf"
else
    printf "\n# Transparencia\nbackground_opacity 0.98\n" >> "$KITTY_CONF_SKEL/kitty.conf"
fi

# Copiar al home del usuario actual
cp "$KITTY_CONF_SKEL/kitty.conf"    "$KITTY_CONF_USER/kitty.conf"
cp "$KITTY_CONF_SKEL/blue-dark.conf" "$KITTY_CONF_USER/blue-dark.conf"
chown -R "${USUARIO}:${USUARIO}" "$KITTY_CONF_USER"

echo "[OK] Kitty configurado con tema blue-dark y opacity 0.98"

# Recargar kitty si está corriendo (para aplicar cambios en caliente)
pkill -USR1 kitty 2>/dev/null || true

# =============================================================
# 6. KITTY COMO TERMINAL POR DEFECTO DEL SISTEMA
# =============================================================
echo ""
echo "[6/9] Configurando Kitty como terminal por defecto..."

# Kitty puede estar en distintos lugares según cómo se instaló
KITTY_BIN=""
for RUTA in /usr/local/bin/kitty /usr/bin/kitty "$LAB_HOME/.local/kitty.app/bin/kitty"; do
    if [ -x "$RUTA" ]; then
        KITTY_BIN="$RUTA"
        break
    fi
done

if [ -z "$KITTY_BIN" ]; then
    echo "[WARN] No se encontró el binario de kitty — ¿ya se ejecutó 03-aplicaciones.sh?"
    echo "       Saltando configuración de terminal por defecto"
else
    update-alternatives --install /usr/bin/x-terminal-emulator \
        x-terminal-emulator "$KITTY_BIN" 50
    update-alternatives --set x-terminal-emulator "$KITTY_BIN"
    echo "[OK] Kitty → x-terminal-emulator ($KITTY_BIN)"
fi

# Configurar en Cinnamon vía dconf como terminal por defecto
sudo -u "$USUARIO" dconf write \
    /org/cinnamon/desktop/default-applications/terminal/exec "'kitty'" 2>/dev/null || true
sudo -u "$USUARIO" dconf write \
    /org/cinnamon/desktop/default-applications/terminal/exec-arg "''" 2>/dev/null || true

# Agregar al autostart de skel para aplicarlo a usuarios nuevos
mkdir -p "$LAB_SKEL/.config/autostart"
cat > "$LAB_SKEL/.config/autostart/aplicar-terminal.desktop" << 'AUTOSTART_EOF'
[Desktop Entry]
Type=Application
Name=Configurar terminal por defecto
Exec=bash -c 'dconf write /org/cinnamon/desktop/default-applications/terminal/exec "'"'"'kitty'"'"'" && dconf write /org/cinnamon/desktop/default-applications/terminal/exec-arg "'"'"''"'"'" && rm -f ~/.config/autostart/aplicar-terminal.desktop'
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
AUTOSTART_EOF

echo "[OK] Kitty configurado como terminal por defecto en Cinnamon"

# =============================================================
# 7. CONFIGURAR FISH SHELL
# =============================================================
echo ""
echo "[7/9] Configurando Fish shell..."

FISH_CONF_SKEL="$LAB_SKEL/.config/fish"
FISH_CONF_USER="$LAB_HOME/.config/fish"

mkdir -p "$FISH_CONF_SKEL/functions"
mkdir -p "$FISH_CONF_USER/functions"

# -----------------------------------------------------------------
# config.fish — configuración principal de Fish
# -----------------------------------------------------------------
cat > "$FISH_CONF_SKEL/config.fish" << 'FISH_EOF'
# =============================================================
# Fish Shell — Laboratorio de Redes
# Politécnico Grancolombiano
# =============================================================

# --- Sin mensaje de bienvenida ---
set fish_greeting ""

# --- PATH ---
fish_add_path ~/.local/bin
fish_add_path /usr/local/bin

# --- Oh My Posh ---
if type -q oh-my-posh
    oh-my-posh init fish --config ~/.cache/oh-my-posh/themes/agnoster.omp.json | source
end

# =============================================================
# COLORES — Herramientas de salida enriquecida
# =============================================================

# --- grc: colorea automáticamente comandos soportados ---
# Aplica colores a ping, ip, ss, dig, nmap, traceroute, etc.
if type -q grc
    # Carga las definiciones de grc para fish
    if test -f /etc/grc.fish
        source /etc/grc.fish
    else if test -f /usr/share/grc/grc.fish
        source /usr/share/grc/grc.fish
    end
end

# --- eza: reemplazo moderno de ls con colores e iconos ---
if type -q eza
    alias ls='eza --icons --group-directories-first'
    alias ll='eza -lh --icons --git --group-directories-first'
    alias la='eza -lah --icons --git --group-directories-first'
    alias lt='eza --tree --icons --level=2'
    alias ltt='eza --tree --icons --level=3'
else
    alias ls='ls --color=auto'
    alias ll='ls -lh --color=auto'
    alias la='ls -lAh --color=auto'
end

# --- bat: cat con resaltado de sintaxis ---
# No reemplaza cat en pipes para no romper scripts
if type -q bat
    alias ccat='bat --style=auto'
    alias bcat='bat --style=full'
end

# =============================================================
# ALIASES DE RED — Laboratorio de Redes
# =============================================================

# Interfaces y direcciones
alias ipl='ip -c link'                            # interfaces con colores
alias ipa='ip -c addr'                            # direcciones con colores
alias ipr='ip -c route'                           # tabla de rutas con colores
alias ipn='ip -c neigh'                           # tabla ARP/vecinos con colores

# Puertos y conexiones
alias ports='ss -tulanp'                          # todos los puertos abiertos
alias listening='ss -tlnp'                        # solo puertos en escucha
alias established='ss -tnp state established'     # conexiones activas

# Logs del sistema en tiempo real con colores (ccze)
alias tailsys='tail -f /var/log/syslog | ccze -A'
alias tailkern='tail -f /var/log/kern.log | ccze -A'
alias tailauth='tail -f /var/log/auth.log | ccze -A'
alias jlog='journalctl -f | ccze -A'             # journal en tiempo real

# Diagnóstico rápido
alias myip='ip -c a'                              # mis IPs
alias gw='ip -c route | grep default'            # gateway por defecto
alias arp='ip -c neigh'                           # tabla ARP

# Escaneo de red rápido (requiere nmap)
alias scan='nmap -sn'                             # descubrir hosts en red (ej: scan 192.168.1.0/24)
alias scanp='nmap -sV'                            # escanear puertos y versiones

# SSH rápido
alias sshv='ssh -v'                               # ssh con verbose (debug)

# =============================================================
# ALIASES GENERALES ÚTILES
# =============================================================
alias ..='cd ..'
alias ...='cd ../..'
alias df='df -h'
alias du='du -sh *'
alias free='free -h'
alias psg='ps aux | grep -v grep | grep'         # buscar proceso: psg firefox
alias reload='source ~/.config/fish/config.fish' # recargar config
alias path='echo $PATH | tr ":" "\n"'            # ver PATH limpio

# =============================================================
FISH_EOF

# Copiar config.fish al usuario principal
cp "$FISH_CONF_SKEL/config.fish" "$FISH_CONF_USER/config.fish"
chown -R "${USUARIO}:${USUARIO}" "$FISH_CONF_USER"
echo "[OK] Fish configurado con aliases de redes y herramientas de color"

# =============================================================
# 8. FISH COMO SHELL POR DEFECTO
# =============================================================
echo ""
echo "[8/9] Configurando Fish como shell por defecto..."

FISH_PATH=$(which fish)

# Registrar fish en /etc/shells si no está
if ! grep -qx "$FISH_PATH" /etc/shells; then
    echo "$FISH_PATH" >> /etc/shells
    echo "[OK] Fish agregado a /etc/shells ($FISH_PATH)"
fi

# Shell del usuario principal
chsh -s "$FISH_PATH" "$USUARIO"
echo "[OK] Shell de $USUARIO → Fish"

# Shell por defecto para nuevos usuarios creados con useradd
if grep -q "^SHELL=" /etc/default/useradd; then
    sed -i "s|^SHELL=.*|SHELL=$FISH_PATH|" /etc/default/useradd
else
    echo "SHELL=$FISH_PATH" >> /etc/default/useradd
fi
echo "[OK] /etc/default/useradd → Fish"

# Shell por defecto para nuevos usuarios creados con adduser (Debian/Mint)
if [ -f /etc/adduser.conf ]; then
    if grep -q "^DSHELL=" /etc/adduser.conf; then
        sed -i "s|^DSHELL=.*|DSHELL=$FISH_PATH|" /etc/adduser.conf
    elif grep -q "^#DSHELL=" /etc/adduser.conf; then
        sed -i "s|^#DSHELL=.*|DSHELL=$FISH_PATH|" /etc/adduser.conf
    else
        echo "DSHELL=$FISH_PATH" >> /etc/adduser.conf
    fi
    echo "[OK] /etc/adduser.conf → Fish"
fi

# =============================================================
# 9. VERIFICAR HERENCIA COMPLETA EN /etc/skel
# =============================================================
echo ""
echo "[9/9] Verificando herencia para usuarios nuevos..."

declare -A CHECKS=(
    ["$LAB_SKEL/.config/kitty/kitty.conf"]="Kitty config"
    ["$LAB_SKEL/.config/kitty/blue-dark.conf"]="Kitty tema blue-dark"
    ["$LAB_SKEL/.config/fish/config.fish"]="Fish config"
    ["$LAB_SKEL/.cache/oh-my-posh/themes/agnoster.omp.json"]="Oh My Posh tema"
    ["$LAB_SKEL/.config/autostart/aplicar-terminal.desktop"]="Autostart terminal Cinnamon"
)

for RUTA in "${!CHECKS[@]}"; do
    NOMBRE="${CHECKS[$RUTA]}"
    if [ -f "$RUTA" ]; then
        echo "  [OK] $NOMBRE"
    else
        echo "  [WARN] FALTA: $NOMBRE → $RUTA"
    fi
done

DSHELL=$(grep "^DSHELL=" /etc/adduser.conf 2>/dev/null | cut -d= -f2 || echo "no configurado")
echo "  [OK] Shell nuevos usuarios (adduser): $DSHELL"

# =============================================================
# RESUMEN
# =============================================================
echo ""
echo "============================================="
echo " PASO 05 COMPLETADO"
echo ""
echo " Terminal:      Kitty (por defecto del sistema)"
echo " Tema Kitty:    blue-dark"
echo " Transparencia: 0.98"
echo " Fuente:        JetBrains Mono Nerd Font"
echo " Shell:         Fish (sin bienvenida)"
echo " Prompt:        Oh My Posh - Agnoster"
echo ""
echo " Herramientas de color:"
echo "   grc   → colorea ping, ip, ss, dig, nmap, traceroute..."
echo "   eza   → ls con iconos, colores y estado git"
echo "   bat   → cat con resaltado de sintaxis (alias: ccat, bcat)"
echo "   ccze  → logs en tiempo real con colores"
echo ""
echo " Aliases de red disponibles:"
echo "   ipl, ipa, ipr, ipn      → ip con colores"
echo "   ports, listening         → puertos abiertos"
echo "   tailsys, tailkern, jlog  → logs en tiempo real"
echo "   myip, gw, arp            → diagnóstico rápido"
echo "   scan, scanp              → escaneo de red con nmap"
echo ""
echo " IMPORTANTE:"
echo "   Cerrar sesión y volver a entrar para activar"
echo "   Fish como shell y las fuentes en Kitty."
echo "============================================="
