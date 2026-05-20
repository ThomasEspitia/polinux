#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 03-aplicaciones.sh — Instalación de aplicaciones del laboratorio
#
# Instala:
#   - Herramientas de red (wireshark, nmap, zenmap, tcpdump, etc.)
#   - GNS3 (GUI completa + imágenes IOU + licencia dinámica)
#   - Packet Tracer (desde .deb local)
#   - Kitty (emulador de terminal)
#   - PuTTY (cliente SSH/Telnet)
#   - Utilidades generales
#
# Uso individual: sudo bash scripts/03-aplicaciones.sh
# =============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ejecutar como root: sudo bash scripts/03-aplicaciones.sh"
    exit 1
fi

# --- Variables ---
USUARIO="${LAB_USER:-redsi}"
LAB_HOME="${LAB_HOME:-/home/${USUARIO}}"
LAB_SKEL="${LAB_SKEL:-/etc/skel}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAQUETES_DIR="$REPO_DIR/paquetes"

echo "============================================="
echo " PASO 03: Instalando aplicaciones..."
echo "============================================="

# =============================================================
# 1. HERRAMIENTAS DE RED (repositorios oficiales)
# =============================================================
echo ""
echo "[1/6] Instalando herramientas de red..."

# Responder 'yes' automáticamente al diálogo de Wireshark

echo "iperf3 iperf3/start_daemon boolean false" | debconf-set-selections

echo "wireshark-common wireshark-common/install-setuid boolean true" \
    | debconf-set-selections

apt install -y \
    wireshark \
    tcpdump \
    nmap \
    zenmap \
    net-tools \
    iproute2 \
    traceroute \
    iperf3 \
    netcat-openbsd \
    dnsutils \
    whois \
    curl \
    wget \
    openssh-client \
    openssh-server \
    putty \
    htop \
    tree \
    git \
    unzip \
    zip \
    python3 \
    python3-pip

# Agregar redsi al grupo wireshark para captura sin root
usermod -aG wireshark "$USUARIO"
echo "[OK] Herramientas de red instaladas"

# =============================================================
# 2. GNS3
# =============================================================
echo ""
echo "[2/6] Instalando GNS3..."

# Agregar repositorio oficial de GNS3
add-apt-repository -y ppa:gns3/ppa
apt update
apt install -y gns3-gui gns3-server

# Agregar usuario a grupos necesarios para GNS3
for grupo in ubridge libvirt kvm wireshark; do
    if getent group "$grupo" &>/dev/null; then
        usermod -aG "$grupo" "$USUARIO"
        echo "  [OK] $USUARIO agregado al grupo: $grupo"
    fi
done

echo "[OK] GNS3 instalado"

# =============================================================
# 3. IMÁGENES IOU Y LICENCIA GNS3
# =============================================================
echo ""
echo "[3/6] Configurando imágenes IOU y licencia GNS3..."

GNS3_IMAGES_DIR="$LAB_HOME/GNS3/images/IOU"
GNS3_SKEL_DIR="$LAB_SKEL/GNS3/images/IOU"
IOU_SRC="$PAQUETES_DIR/gns3"

# Crear directorios de imágenes
mkdir -p "$GNS3_IMAGES_DIR"
mkdir -p "$GNS3_SKEL_DIR"

# Copiar imágenes IOU
if [ -d "$IOU_SRC" ]; then
    cp "$IOU_SRC/"*.iol "$GNS3_IMAGES_DIR/" 2>/dev/null || true
    cp "$IOU_SRC/"*.iol "$GNS3_SKEL_DIR/" 2>/dev/null || true
    echo "  [OK] Imágenes IOU copiadas"
else
    echo "  [WARN] No se encontró $IOU_SRC, omitiendo imágenes IOU"
fi

# Generar licencia IOU dinámicamente según el hostname de la máquina
echo "  Generando licencia IOU para hostname: $(hostname)..."

python3 << 'PYEOF'
import os
import socket
import hashlib
import struct

hostid = os.popen("hostid").read().strip()
hostname = socket.gethostname()
ioukey = int(hostid, 16)
for x in hostname:
    ioukey = ioukey + ord(x)

iouPad1 = b'\x4B\x58\x21\x81\x56\x7B\x0D\xF3\x21\x43\x9B\x7E\xAC\x1D\xE6\x8A'
iouPad2 = b'\x80' + 39 * b'\0'
md5input = iouPad1 + iouPad2 + struct.pack('!i', ioukey) + iouPad1
iouLicense = hashlib.md5(md5input).hexdigest()[:16]

iourc_content = f"[license]\n{hostname} = {iouLicense};\n"

# Escribir en home de redsi
home = os.environ.get('LAB_HOME', '/home/redsi')
with open(f"{home}/.iourc", "w") as f:
    f.write(iourc_content)

# Escribir en skel para usuarios futuros
# Nota: el hostname cambia por máquina, así que en skel
# dejamos un script que lo regenera en el primer login
skel_script = f"""#!/bin/bash
# Genera la licencia IOU según el hostname de esta máquina
python3 -c "
import os, socket, hashlib, struct
hostid = os.popen('hostid').read().strip()
hostname = socket.gethostname()
ioukey = int(hostid, 16)
for x in hostname: ioukey += ord(x)
pad1 = b'\\x4B\\x58\\x21\\x81\\x56\\x7B\\x0D\\xF3\\x21\\x43\\x9B\\x7E\\xAC\\x1D\\xE6\\x8A'
pad2 = b'\\x80' + 39*b'\\x00'
lic = hashlib.md5(pad1 + pad2 + struct.pack('!i', ioukey) + pad1).hexdigest()[:16]
open(os.path.expanduser('~/.iourc'), 'w').write(f'[license]\\n{{hostname}} = {{lic}};\\n')
print('Licencia IOU generada para:', hostname)
"
# Autoeliminarse después de ejecutarse
rm -f ~/.config/autostart/gns3-iou-license.desktop
"""

skel_autostart = "/etc/skel/.config/autostart"
os.makedirs(skel_autostart, exist_ok=True)
with open(f"{skel_autostart}/gns3-iou-license.desktop", "w") as f:
    f.write(f"""[Desktop Entry]
Type=Application
Name=Generar licencia IOU GNS3
Exec=bash -c '{skel_script.replace(chr(10), "; ").replace("'", "'\\''")}' 
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
""")

print(f"Licencia IOU generada: {hostname} = {iouLicense}")
print(f"Guardada en: {home}/.iourc")
PYEOF

# Añadir entrada en /etc/hosts para deshabilitar phone-home de IOU
if ! grep -q "xml.cisco.com" /etc/hosts; then
    echo "127.0.0.127 xml.cisco.com" >> /etc/hosts
    echo "  [OK] Phone-home de IOU deshabilitado"
fi

# Corregir permisos
chown -R "${USUARIO}:${USUARIO}" "$LAB_HOME/GNS3"
echo "[OK] Licencia IOU generada y configurada"

# =============================================================
# 4. PACKET TRACER
# =============================================================
echo ""
echo "[4/6] Instalando Cisco Packet Tracer..."

PT_DEB=$(find "$PAQUETES_DIR" -maxdepth 1 -name "CiscoPacketTracer*.deb" | head -1)

if [ -z "$PT_DEB" ]; then
    echo "  [WARN] No se encontró el .deb de Packet Tracer en $PAQUETES_DIR"
    echo "         Descárgalo desde https://netacad.com y colócalo en paquetes/"
else
    echo "  Instalando: $(basename $PT_DEB)"
    # Aceptar EULA automáticamente
    echo "packettracer packettracer/accept-eula boolean true" \
        | debconf-set-selections
    dpkg -i "$PT_DEB" || apt install -f -y
    echo "[OK] Packet Tracer instalado"
fi

# =============================================================
# 5. KITTY (emulador de terminal)
# =============================================================
echo ""
echo "[5/6] Instalando Kitty..."

# Instalar via instalador oficial (más actualizado que apt)
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | \
    sudo -u "$USUARIO" sh /dev/stdin launch=n

# Crear enlaces simbólicos
ln -sf "$LAB_HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty
ln -sf "$LAB_HOME/.local/kitty.app/bin/kitten" /usr/local/bin/kitten

# Crear entrada en el menú de aplicaciones
cp "$LAB_HOME/.local/kitty.app/share/applications/kitty.desktop" \
    /usr/share/applications/ 2>/dev/null || true

# Copiar a skel para que usuarios futuros también lo tengan en el menú
mkdir -p "$LAB_SKEL/.local"
cp -r "$LAB_HOME/.local/kitty.app" "$LAB_SKEL/.local/" 2>/dev/null || true

echo "[OK] Kitty instalado"

# =============================================================
# 6. LIMPIEZA
# =============================================================
echo ""
echo "[6/6] Limpiando paquetes innecesarios..."
apt autoremove -y
apt autoclean

echo ""
echo "============================================="
echo " PASO 03 COMPLETADO - Aplicaciones instaladas"
echo " Wireshark    : $(wireshark --version 2>/dev/null | head -1 || echo 'instalado')"
echo " Nmap         : $(nmap --version 2>/dev/null | head -1 || echo 'instalado')"
echo " GNS3         : $(gns3 --version 2>/dev/null || echo 'instalado')"
echo " Kitty        : $(kitty --version 2>/dev/null || echo 'instalado')"
echo " PuTTY        : $(putty --version 2>/dev/null | head -1 || echo 'instalado')"
echo " Licencia IOU : ~/.iourc generada para $(hostname)"
echo "============================================="
