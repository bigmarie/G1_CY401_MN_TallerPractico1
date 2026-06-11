#!/bin/bash

# ============================================================================
# CURSO: CY401 - Taller Práctico 1
# GRUPO: 1
# PROYECTO: Sistema de Monitoreo y Automatización del Sistema
# ============================================================================
# 
# DESCRIPCIÓN:
# Script de monitoreo del sistema que recolecta métricas (CPU, memoria, disco)
# con marcas de tiempo, genera alertas si se superan umbrales, captura
# interrupciones (SIGINT) y mantiene un registro en archivos de log.
#
# ============================================================================




# ---------------------- Variables globales (configurables) ----------------------
# Variables para configuración del usuario y ubicación de logs
usuario_guar="$(whoami)"
log_guar="${usuario_guar}_tailer1"

# Configuración base de logs con timestamp en el nombre del archivo
LOG_DIR="./logs"
# El nombre del archivo se configura dinámicamente con la fecha actual
LOG_FILE_PREFIX="monitoreo"
TIMESTAMP_FMT="%Y-%m-%d %H:%M:%S"
THRESHOLD_MEM=70  # Umbral en porcentaje para generar alerta (por defecto 70)

# Variables para el loop de iteraciones
ITERATIONS=5
SLEEP_INTERVAL=60  # 60 segundos entre iteraciones

# ---------------------- Funciones auxiliares ----------------------

# Manejador de interrupciones (SIGINT)
manejar_interrupcion() {
  local ts
  ts="$(timestamp)"
  {
    echo ""
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] - Script interrumpido por el usuario"
    echo "Usuario: ${usuario_guar}"
    echo "Razón: Señal SIGINT recibida"
    echo ""
  } >> "$LOG_FILE" 2>&1
  exit 130
}

# Configurar trap para capturar SIGINT
trap 'manejar_interrupcion' SIGINT

crear_directorio_logs() {
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
  fi
}

timestamp() {
  date "+${TIMESTAMP_FMT}"
}

recolectar_metricas() {
  local ts
  ts="$(timestamp)"
  {
    echo "===== Registro: ${ts} ====="
    echo "--- top (resumen de CPU/mem) ---"
    top -b -n 1 | head -n 20
    echo "--- free (memoria) ---"
    free -h
    echo "--- df (uso de disco) ---"
    df -h
    echo "\n"
  } >> "$LOG_FILE" 2>&1
}

porcentaje_memoria_usada() {
  # Calcula el porcentaje de memoria usada basado en /proc/meminfo (Linux)
  # Si free no está en el sistema, intenta usar free command como fallback
  if [ -r /proc/meminfo ]; then
    local mem_total mem_available used_percent
    mem_total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    mem_available=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    if [ -z "$mem_total" ] || [ -z "$mem_available" ]; then
      echo "0"
      return
    fi
    used_percent=$(( ( (mem_total - mem_available) * 100 ) / mem_total ))
    echo "$used_percent"
  else
    # Fallback a free -m
    local used total
    read used total <<< $(free -m | awk '/Mem:/ {print $3" "$2}')
    if [ -z "$used" ] || [ -z "$total" ] || [ "$total" -eq 0 ]; then
      echo "0"
      return
    fi
    echo $(( (used * 100) / total ))
  fi
}

comprobar_alerta_memoria() {
  local used
  used=$(porcentaje_memoria_usada)
  if [ "$used" -ge "$THRESHOLD_MEM" ]; then
    local ts
    ts="$(timestamp)"
    echo "[ALERTA] ${ts} - Memoria usada: ${used}% (umbral: ${THRESHOLD_MEM}%)" >> "$LOG_FILE"
    return 1
  fi
  return 0
}
# ---------------------- Menú ----------------------
mostrar_menu() {
  echo ""
  echo "========== MENÚ =========="
  echo "1. Ver CPU"
  echo "2. Ver procesos activos"
  echo "3. Continuar con monitoreo"
  echo "=========================="

  read -p "Seleccione una opción: " opcion

  case $opcion in
    1)
      top -bn1 | grep "Cpu(s)"
      ;;
    2)
      ps aux --sort=-%cpu | head -10
      ;;
    3)
      echo "Iniciando monitoreo..."
      ;;
    *)
      echo "ERROR: Opción inválida."
      ;;
  esac
}
# ---------------------- Flujo principal ----------------------
crear_directorio_logs
mostrar_menu

# Configurar el nombre del archivo de log con la fecha actual
LOG_FILE="${LOG_DIR}/${LOG_FILE_PREFIX}_$(date +%Y-%m-%d).log"

# Mensaje inicial
{
  echo "============================================================"
  echo "Inicio de Monitoreo - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Usuario: ${usuario_guar}"
  echo "Log Guard: ${log_guar}"
  echo "============================================================"
  echo ""
} >> "$LOG_FILE" 2>&1

# Loop de iteraciones para monitoreo
for ((i=1; i<=ITERATIONS; i++)); do
  {
    echo "--- Iteración $i de $ITERATIONS ---"
    echo ""
  } >> "$LOG_FILE" 2>&1
  
  recolectar_metricas
  
  if ! comprobar_alerta_memoria; then
    # Se generó una alerta, pero continuamos
    :
  fi
  
  # No dormir en la última iteración
  if [ $i -lt $ITERATIONS ]; then
    sleep "$SLEEP_INTERVAL"
  fi
done

# Mensaje final
{
  echo ""
  echo "============================================================"
  echo "Fin de Monitoreo - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "============================================================"
} >> "$LOG_FILE" 2>&1

# Salida exitosa
exit 0

# ---------------------- Instrucciones de uso (documentadas) ----------------------
# Comandos útiles:
#  - Crear directorio de logs (si es necesario): mkdir -p "$LOG_DIR"
#  - Hacer ejecutable el script: chmod +x monitoreo.sh
#  - Ejecutar el script: bash monitoreo.sh
#  - Ejecutar con variables personalizadas: LOG_DIR=/ruta/logs THRESHOLD_MEM=80 bash monitoreo.sh
#  - Ver últimos logs: tail -n 100 "$LOG_FILE"
#  - Ejemplo de cron para ejecutar cada hora:
#      0 * * * * /ruta/al/script/monitoreo.sh >> /dev/null 2>&1
#----------------------------------------------------------------------------------