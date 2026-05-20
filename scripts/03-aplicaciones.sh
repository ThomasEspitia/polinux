#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 03-aplicaciones.sh — Instalación de aplicaciones del laboratorio
#
# Instala:
#   - Herramientas de red (wireshark, nmap, zenmap, tcpdump, etc.)
#   - GNS3 (GUI completa + imágenes IOU + licencia dinámica + tema Classic)
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

home = os.environ.get('LAB_HOME', '/home/redsi')
hostname_str = hostname
license_str  = iouLicense
iourc_content = f"[license]\n{hostname_str} = {license_str};\n"

# Guardar en ~/.iourc
with open(f"{home}/.iourc", "w") as f:
    f.write(iourc_content)

# Guardar también en GNS3/images/iourc
gns3_iourc = f"{home}/GNS3/images/iourc"
with open(gns3_iourc, "w") as f:
    f.write(iourc_content)

# Autostart en skel para regenerar licencia en primer login de usuarios futuros
skel_autostart = "/etc/skel/.config/autostart"
os.makedirs(skel_autostart, exist_ok=True)
with open(f"{skel_autostart}/gns3-iou-license.desktop", "w") as f:
    f.write("""[Desktop Entry]
Type=Application
Name=Generar licencia IOU GNS3
Exec=bash -c 'python3 -c "
import os,socket,hashlib,struct
hostid=os.popen(chr(104)+chr(111)+chr(115)+chr(116)+chr(105)+chr(100)).read().strip()
hostname=socket.gethostname()
ioukey=int(hostid,16)
for x in hostname: ioukey+=ord(x)
p1=bytes([0x4B,0x58,0x21,0x81,0x56,0x7B,0x0D,0xF3,0x21,0x43,0x9B,0x7E,0xAC,0x1D,0xE6,0x8A])
p2=b\"\\x80\"+39*b\"\\x00\"
lic=hashlib.md5(p1+p2+struct.pack(\"!i\",ioukey)+p1).hexdigest()[:16]
content=f\"[license]\\n{hostname} = {lic};\\n\"
home=os.path.expanduser(\"~\")
open(f\"{home}/.iourc\",\"w\").write(content)
open(f\"{home}/GNS3/images/iourc\",\"w\").write(content)
" && rm -f ~/.config/autostart/gns3-iou-license.desktop'
Hidden=false
NoDisplay=true
X-GNOME-Autostart-enabled=true
""")

print(f"  Licencia IOU: {hostname_str} = {license_str}")
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
echo "[OK] Imágenes IOU y licencia generada"

# =============================================================
# 3.5 CONFIGURAR GNS3 VIA API
#     - Registrar templates IOU
#     - Configurar licencia IOU
#     - Aplicar tema Classic
# =============================================================
echo ""
echo "  Configurando GNS3 via API..."

# Arrancar gns3server como el usuario (esto también crea ~/.config/GNS3/)
sudo -u "$USUARIO" gns3server --daemon --log /tmp/gns3server.log --pid /tmp/gns3server.pid

# Esperar activamente hasta que el servidor responda (máx 30s)
GNS3_CONF="$LAB_HOME/.config/GNS3/2.2/gns3_server.conf"
echo "  Esperando que GNS3 server arranque..."
INTENTOS=0
until [ -f "$GNS3_CONF" ] && grep -q "^password" "$GNS3_CONF"; do
    sleep 2
    INTENTOS=$((INTENTOS + 1))
    if [ $INTENTOS -ge 15 ]; then
        echo "  [ERROR] GNS3 server no arrancó después de 30s"
        exit 1
    fi
done

# Leer credenciales generadas automáticamente por GNS3
GNS3_USER=$(grep "^user" "$GNS3_CONF" | awk '{print $3}')
GNS3_PASS=$(grep "^password" "$GNS3_CONF" | awk '{print $3}')
GNS3_API="http://localhost:3080/v2"
GNS3_AUTH="$GNS3_USER:$GNS3_PASS"

# Esperar a que la API responda
until curl -s -u "$GNS3_AUTH" "$GNS3_API/version" | grep -q "version"; do
    sleep 2
done
echo "  [OK] GNS3 server listo"

# Registrar template IOU-L3 (Router)
curl -s -u "$GNS3_AUTH" -X POST "$GNS3_API/templates" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "IOU-L3",
        "template_type": "iou",
        "path": "x86_64_crb_linux-adventerprisek9-ms.iol",
        "compute_id": "local",
        "category": "router",
        "symbol": ":/symbols/router.svg"
    }' > /dev/null
echo "  [OK] Template IOU-L3 registrado"

# Registrar template IOU-L2 (Switch)
curl -s -u "$GNS3_AUTH" -X POST "$GNS3_API/templates" \
    -H "Content-Type: application/json" \
    -d '{
        "name": "IOU-L2",
        "template_type": "iou",
        "path": "x86_64_crb_linux_l2-adventerprisek9-ms.iol",
        "compute_id": "local",
        "category": "switch",
        "symbol": ":/symbols/ethernet_switch.svg"
    }' > /dev/null
echo "  [OK] Template IOU-L2 registrado"

# Configurar licencia IOU via API
IOURC_JSON=$(python3 -c "import json; print(json.dumps(open('$LAB_HOME/.iourc').read()))")
curl -s -u "$GNS3_AUTH" -X PUT "$GNS3_API/iou_license" \
    -H "Content-Type: application/json" \
    -d "{\"iourc_content\": $IOURC_JSON, \"license_check\": true}" > /dev/null
echo "  [OK] Licencia IOU configurada en GNS3"

# Apagar servidor
kill $(cat /tmp/gns3server.pid 2>/dev/null) 2>/dev/null || pkill -f gns3server || true
sleep 2

# =============================================================
# 3.6 TEMA CLASSIC Y CONFIGURACIÓN GUI DE GNS3
# =============================================================
echo ""
echo "  Aplicando tema Classic a GNS3..."

GNS3_GUI_CONF="$LAB_HOME/.config/GNS3/2.2/gns3_gui.conf"

# Modificar el tema en el archivo de configuración de la GUI
if [ -f "$GNS3_GUI_CONF" ]; then
    # Cambiar el style si ya existe la línea
    if grep -q "^style" "$GNS3_GUI_CONF"; then
        sed -i 's/^style.*/style = Classic/' "$GNS3_GUI_CONF"
    else
        # Agregar bajo [GUI] si no existe
        sed -i '/^\[GUI\]/a style = Classic' "$GNS3_GUI_CONF"
    fi
    echo "  [OK] Tema Classic aplicado en $GNS3_GUI_CONF"
else
    # Crear archivo mínimo de configuración GUI
    mkdir -p "$(dirname "$GNS3_GUI_CONF")"
    cat > "$GNS3_GUI_CONF" << 'EOF'
[GUI]
style = Classic
EOF
    echo "  [OK] Archivo gns3_gui.conf creado con tema Classic"
fi

# Copiar configuración a skel para usuarios futuros
GNS3_SKEL_CONF="$LAB_SKEL/.config/GNS3/2.2"
mkdir -p "$GNS3_SKEL_CONF"
cp "$GNS3_GUI_CONF" "$GNS3_SKEL_CONF/gns3_gui.conf"
echo "  [OK] Configuración GUI copiada a skel"

# Corregir permisos de todo lo generado
chown -R "${USUARIO}:${USUARIO}" "$LAB_HOME/.config/GNS3"
chown -R "${USUARIO}:${USUARIO}" "$LAB_HOME/GNS3"

echo "[OK] GNS3 configurado completamente"

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
echo " PT        : $(which packettracer &>/dev/null && echo 'instalado' || echo 'no encontrado')"
echo " IOU       : $(hostname) licencia generada"
echo " Tema GNS3 : Classic"
echo "============================================="
echo ""
echo " [i] IMPORTANTE: Cerrar sesión y volver a entrar"
echo "     para que los permisos de ubridge se apliquen en GNS3"
echo "============================================="
