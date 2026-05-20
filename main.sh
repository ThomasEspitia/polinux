#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# main.sh — Orquestador principal
# Ejecuta todos los pasos en orden. Si un paso falla, se detiene.
#
# REQUISITO PREVIO: Habilitar contraseña de root antes de ejecutar:
#   sudo passwd root
#
# Uso: sudo bash main.sh
#
# Para ejecutar un paso individual:
#   sudo bash scripts/00-sistema.sh
#   sudo bash scripts/01-usuario.sh
# =============================================================

set -e

# --- Verificar root ---
if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ejecutar como root: sudo bash main.sh"
    exit 1
fi

# --- Directorio base del proyecto ---
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/scripts"

# --- Exportar variables globales para los sub-scripts ---
# Todos los scripts hijos heredan estas variables
export LAB_USER="redsi"
export LAB_HOME="/home/${LAB_USER}"
export LAB_SKEL="/etc/skel"

# Verificar que el usuario principal existe
if ! id "$LAB_USER" &>/dev/null; then
    echo "[ERROR] El usuario '${LAB_USER}' no existe en el sistema."
    echo "        Créalo antes de ejecutar este script."
    exit 1
fi

echo "============================================="
echo " PRECONFIGURACIÓN LINUX MINT"
echo " Laboratorio de Redes - Politécnico"
echo " Grancolombiano"
echo "============================================="
echo " Usuario principal : $LAB_USER"
echo " Home              : $LAB_HOME"
echo " Skel (herencia)   : $LAB_SKEL"
echo "============================================="
echo ""

# --- Lista de scripts en orden de ejecución ---
PASOS=(
    "00-sistema.sh"
    "01-usuario.sh"
    "02-temas.sh"
    "03-aplicaciones.sh"
)

TOTAL=${#PASOS[@]}
ACTUAL=0

for PASO in "${PASOS[@]}"; do
    ACTUAL=$((ACTUAL + 1))
    SCRIPT="$SCRIPTS_DIR/$PASO"

    if [ ! -f "$SCRIPT" ]; then
        echo "[ERROR] No se encontró el script: $SCRIPT"
        exit 1
    fi

    echo "============================================="
    echo " Paso $ACTUAL/$TOTAL: $PASO"
    echo "============================================="

    bash "$SCRIPT"

    echo ""
    echo "[OK] $PASO completado"
    echo ""
done

echo "============================================="
echo " PRECONFIGURACIÓN COMPLETADA"
echo " El sistema está listo para el laboratorio."
echo ""
echo " PRÓXIMOS PASOS:"
echo "   1. Reiniciar el sistema para aplicar todos"
echo "      los cambios: sudo reboot"
echo "   2. Crear usuarios adicionales con:"
echo "      sudo adduser <nombre>"
echo "      (heredarán automáticamente la config)"
echo "============================================="
