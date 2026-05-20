#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# 01-usuario.sh — Permisos para el usuario redsi
# =============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ejecutar como root: sudo bash 01-usuario.sh"
    exit 1
fi

USUARIO="redsi"

echo "============================================="
echo " PASO 01: Configurando usuario $USUARIO..."
echo "============================================="

# --- 1. Sudo sin contraseña ---
SUDOERS_FILE="/etc/sudoers.d/$USUARIO"

cat > "$SUDOERS_FILE" << EOF
$USUARIO ALL=(ALL:ALL) NOPASSWD: ALL
EOF

chmod 440 "$SUDOERS_FILE"

if visudo -cf "$SUDOERS_FILE"; then
    echo "[OK] Sudo sin contraseña configurado"
else
    echo "[ERROR] Archivo sudoers inválido, eliminando..."
    rm -f "$SUDOERS_FILE"
    exit 1
fi

# --- 2. Grupos extra ---
GRUPOS_EXTRA="adm cdrom dip plugdev netdev"

for grupo in $GRUPOS_EXTRA; do
    if getent group "$grupo" &>/dev/null; then
        usermod -aG "$grupo" "$USUARIO"
        echo "[OK] Agregado al grupo: $grupo"
    else
        echo "[INFO] Grupo $grupo no existe, se omite"
    fi
done

echo ""
echo "============================================="
echo " PASO 01 COMPLETADO"
id "$USUARIO"
echo "============================================="
