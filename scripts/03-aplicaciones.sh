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

# Responder automáticamente a diálogos interactivos
echo "wireshark-common wireshark-common/install-setuid boolean true" \
    | debconf-set-selections
echo "iperf3 iperf3/start_daemon boolean false" \
    | debconf-set-selections
echo "ubridge ubridge/install-setuid boolean true" \
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
    python3-pip \
    expect

# Agregar redsi al grupo wireshark para captura sin root
usermod -aG wireshark "$USUARIO"
echo "[OK] Herramientas de red instaladas"

# =============================================================
# 2. GNS3
# =============================================================
echo ""
echo "[2/6] Instalando GNS3..."

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

# Copiar imágenes IOU y darles permisos de ejecución
if [ -d "$IOU_SRC" ]; then
    cp "$IOU_SRC/"*.iol "$GNS3_IMAGES_DIR/" 2>/dev/null || true
    cp "$IOU_SRC/"*.iol "$GNS3_SKEL_DIR/" 2>/dev/null || true
    chmod +x "$GNS3_IMAGES_DIR/"*.iol
    chmod +x "$GNS3_SKEL_DIR/"*.iol
    echo "  [OK] Imágenes IOU copiadas y con permisos de ejecución"
else
    echo "  [WARN] No se encontró $IOU_SRC, omitiendo imágenes IOU"
fi

# Generar licencia IOU dinámicamente según el hostname de la máquina
echo "  Generando licencia IOU para hostname: $(hostname)..."

LAB_HOME="$LAB_HOME" python3 << 'PYEOF'
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

home = os.environ.get('LAB_HOME', '/home/redsi')

# Escribir ~/.iourc
with open(f"{home}/.iourc", "w") as f:
    f.write(iourc_content)

# Escribir en el directorio de imágenes de GNS3 (donde GNS3 la busca)
gns3_iourc = f"{home}/GNS3/images/iourc"
with open(gns3_iourc, "w") as f:
    f.write(iourc_content)

# Escribir en skel para usuarios futuros (se regenera en primer login)
skel_autostart = "/etc/skel/.config/autostart"
os.makedirs(skel_autostart, exist_ok=True)
with open(f"{skel_autostart}/gns3-iou-license.desktop", "w") as f:
    f.write("""[Desktop Entry]
Type=Application
Name=Generar licencia IOU GNS3
Exec=bash -c 'python3 -c "import os,socket,hashlib,struct; hostid=os.popen(chr(104)+chr(111)+chr(115)+chr(116)+chr(105)+chr(100)).read().strip(); hostname=socket.gethostname(); ioukey=int(hostid,16); [ioukey:=ioukey+ord(x) for x in hostname]; pad1=b\\x27\\x4B\\x58\\x21\\x81\\x56\\x7B\\x0D\\xF3\\x21\\x43\\x9B\\x7E\\xAC\\x1D\\xE6\\x8A\\x27; pad2=b\\x27\\x80\\x27+39*b\\x27\\x00\\x27; lic=hashlib.md5(pad1+pad2+struct.pack(chr(33)+chr(105),ioukey)+pad1).hexdigest()[:16]; open(os.path.expanduser(chr(126)+chr(47)+chr(46)+chr(105)+chr(111)+chr(117)+chr(114)+chr(99)),chr(119)).write(chr(91)+chr(108)+chr(105)+chr(99)+chr(101)+chr(110)+chr(115)+chr(101)+chr(93)+chr(10)+hostname+chr(32)+chr(61)+chr(32)+lic+chr(59)+chr(10))" && rm -f ~/.config/autostart/gns3-iou-license.desktop'
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
""")

print(f"  Licencia IOU: {hostname} = {iouLicense}")
print(f"  Guardada en : {home}/.iourc")
print(f"  Guardada en : {gns3_iourc}")
PYEOF

# Deshabilitar phone-home de IOU
if ! grep -q "xml.cisco.com" /etc/hosts; then
    echo "127.0.0.127 xml.cisco.com" >> /etc/hosts
    echo "  [OK] Phone-home de IOU deshabilitado"
fi

# Corregir permisos
chown -R "${USUARIO}:${USUARIO}" "$LAB_HOME/GNS3"
echo "[OK] Imágenes IOU y licencia configuradas"

# =============================================================
# 3.5 REGISTRAR TEMPLATES IOU EN GNS3 VIA API
# =============================================================
echo ""
echo "  Registrando templates IOU en GNS3..."

# Arrancar gns3server como el usuario redsi
sudo -u "$USUARIO" gns3server --daemon --log /tmp/gns3server.log --pid /tmp/gns3server.pid
sleep 5

GNS3_API="http://localhost:3080/v2"

# Registrar imagen L3 (Router)
curl -s -X POST "$GNS3_API/templates" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "IOU-L3",
        "template_type": "iou",
        "path": "x86_64_crb_linux-adventerprisek9-ms.iol",
        "compute_id": "local",
        "category": "router",
        "symbol": ":/symbols/router.svg"
    }' > /dev/null

# Registrar imagen L2 (Switch)
curl -s -X POST "$GNS3_API/templates" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "IOU-L2",
        "template_type": "iou",
        "path": "x86_64_crb_linux_l2-adventerprisek9-ms.iol",
        "compute_id": "local",
        "category": "switch",
        "symbol": ":/symbols/ethernet_switch.svg"
    }' > /dev/null

# Apagar el servidor
kill $(cat /tmp/gns3server.pid 2>/dev/null) 2>/dev/null || pkill -f gns3server || true
echo "  [OK] Templates IOU registrados en GNS3"

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
    apt install -y libpcre2-dev
    expect -c "
    spawn dpkg -i $PT_DEB
    expect \"Press q to quit\"
    send \"q\"
    expect \"enter 1, 2 or 3\"
    send \"2\r\"
    expect eof
    "
    echo "[OK] Packet Tracer instalado"
fi

# =============================================================
# 5. KITTY (emulador de terminal)
# =============================================================
echo ""
echo "[5/6] Instalando Kitty..."

sudo -u "$USUARIO" bash -c 'curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin launch=n'

# Crear enlaces simbólicos globales
ln -sf "$LAB_HOME/.local/kitty.app/bin/kitty" /usr/local/bin/kitty
ln -sf "$LAB_HOME/.local/kitty.app/bin/kitten" /usr/local/bin/kitten

# Entrada en el menú de aplicaciones
cp "$LAB_HOME/.local/kitty.app/share/applications/kitty.desktop" \
    /usr/share/applications/ 2>/dev/null || true

# Copiar a skel para usuarios futuros
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
echo " Wireshark : $(wireshark --version 2>/dev/null | head -1 || echo 'instalado')"
echo " Nmap      : $(nmap --version 2>/dev/null | head -1 || echo 'instalado')"
echo " GNS3      : $(gns3server --version 2>/dev/null || echo 'instalado')"
echo " Kitty     : $(kitty --version 2>/dev/null || echo 'instalado')"
echo " PT        : $(packettracer --version 2>/dev/null | head -1 || echo 'instalado')"
echo " IOU       : $(hostname) = $(grep -o '[a-f0-9]*;' $LAB_HOME/.iourc 2>/dev/null || echo 'generada')"
echo "============================================="
echo ""
echo " [i] IMPORTANTE: Cerrar sesión y volver a entrar"
echo "     para que los permisos de ubridge se apliquen en GNS3"
echo "============================================="
