#!/bin/bash
# =============================================================
# PRECONFIGURACIÓN MINT - LABORATORIO DE REDES
# Politécnico Grancolombiano
# =============================================================
# 00-sistema.sh — Actualización completa del sistema
#
# Uso individual: sudo bash scripts/00-sistema.sh
# =============================================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "[ERROR] Ejecutar como root: sudo bash scripts/00-sistema.sh"
    exit 1
fi

echo "============================================="
echo " PASO 00: Actualizando el sistema..."
echo "============================================="

# --- 1. Repositorios y actualizaciones ---
echo ""
echo "[00/4] Actualizando lista de repositorios..."
apt update

echo ""
echo "[01/4] Actualizando paquetes del sistema..."
# full-upgrade maneja correctamente cambios de dependencias
apt full-upgrade -y

# --- 2. Limpieza ---
echo ""
echo "[03/4] Limpiando paquetes innecesarios..."
apt autoremove -y
apt autoclean

# --- 3. Configurar zona horaria ---
echo ""
echo "[04/4] Configurando zona horaria (America/Bogota)..."
timedatectl set-timezone America/Bogota

echo ""
echo "============================================="
echo " PASO 00 COMPLETADO - Sistema actualizado"
echo " Zona horaria: $(timedatectl | grep 'Time zone')"
echo "============================================="
