#!/bin/bash

# ============================================================================
# CURSO: CY401 - Taller Práctico 1 - Sistemas Operativos Avanzados
# GRUPO: 1
# PROYECTO: Sistema de Monitoreo y Automatización del Sistema
# ============================================================================
#
# DESCRIPCIÓN:
# Script de monitoreo del sistema que recolecta métricas (CPU, memoria, disco)
# con marcas de tiempo, genera alertas si se superan umbrales, captura
# interrupciones (SIGINT) y mantiene un registro en archivos de log.
#
# ESTUDIANTES Y SUS CONTRIBUCIONES:
# - Estudiante 1 (Aaron): Arquitectura, entorno, captura de interrupciones
# - Estudiante 2 (Nicole): Monitoreo base y alertas de sistema
# - Estudiante 3 (Celestita): Menú interactivo y automatización en bucle
#
# ============================================================================




# ---------------------- Variables globales (configurables) ----------------------
# Variables para configuración del usuario y ubicación de logs (Estudiante 2 - Nicole)
usuario_guar="$(whoami)"
log_guar="${usuario_guar}_tailer1"

# Configuración base de logs con timestamp en el nombre del archivo
LOG_DIR="./logs"
# El nombre del archivo se configura dinámicamente con la fecha actual
LOG_FILE_PREFIX="monitoreo"
TIMESTAMP_FMT="%Y-%m-%d %H:%M:%S"

# Umbral de memoria para generar alertas (Estudiante 2 - Nicole)
THRESHOLD_MEM=70  # Umbral en porcentaje (por defecto 70%)

# Variables para el bucle de iteraciones (Estudiante 3 - Celestita)
ITERATIONS=5                # Número de iteraciones de monitoreo
SLEEP_INTERVAL=60          # 60 segundos entre iteraciones

# ---------------------- Funciones auxiliares ----------------------

# Manejador de interrupciones (SIGINT) - Estudiante 1 (Aaron)
# Captura interrupciones del usuario (Ctrl+C) y registra el evento en el log
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

# Configurar trap para capturar SIGINT (Estudiante 1 - Aaron)
trap 'manejar_interrupcion' SIGINT

# Crear directorio de logs si no existe
crear_directorio_logs() {
  if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
  fi
}

# Obtener marca de tiempo en formato configurable
timestamp() {
  date "+${TIMESTAMP_FMT}"
}

# Recolectar métricas del sistema (Estudiante 2 - Nicole)
# Captura datos de CPU, memoria y disco con marca de tiempo
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

# Calcular porcentaje de memoria usada (Estudiante 2 - Nicole)
# Utiliza /proc/meminfo para cálculos más precisos en Linux
porcentaje_memoria_usada() {
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
    local used total
    read used total <<< $(free -m | awk '/Mem:/ {print $3" "$2}')
    if [ -z "$used" ] || [ -z "$total" ] || [ "$total" -eq 0 ]; then
      echo "0"
      return
    fi
    echo $(( (used * 100) / total ))
  fi
}

# Verificar y generar alerta si la memoria excede el umbral (Estudiante 2 - Nicole)
# Retorna 0 si está dentro del umbral, 1 si se dispara la alerta
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
# ---------------------- Flujo principal ----------------------
# Crear directorio de logs primero
crear_directorio_logs

# Configurar el nombre del archivo de log con la fecha actual (ANTES del menú)
LOG_FILE="${LOG_DIR}/${LOG_FILE_PREFIX}_$(date +%Y-%m-%d).log"

# ---------------------- Menú interactivo ----------------------
mostrar_menu() {
  while true; do
    echo ""
    echo "========== MENÚ =========="
    echo "1. Ver CPU"
    echo "2. Ver procesos activos"
    echo "3. Salir"
    echo "=========================="
    echo ""

    read -p "Seleccione una opción: " opcion

    case $opcion in
      1)
        echo ""
        echo "[*] Información de CPU:"
        echo "---"
        top -bn1 | grep "Cpu(s)"
        echo ""
        ;;
      2)
        echo ""
        echo "[*] Top 10 procesos por uso de CPU:"
        echo "---"
        ps aux --sort=-%cpu | head -11
        echo ""
        ;;
      3)
        echo ""
        echo "[*] Iniciando monitoreo del sistema..."
        echo ""
        break
        ;;
      *)
        echo "[ERROR] Opción inválida. Por favor, seleccione 1, 2 o 3."
        echo ""
        ;;
    esac
  done
}

# Mostrar menú inicial
mostrar_menu

# Mensaje inicial del monitoreo
{
  echo "============================================================"
  echo "Inicio de Monitoreo - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Usuario: ${usuario_guar}"
  echo "Log Guard: ${log_guar}"
  echo "============================================================"
  echo ""
} >> "$LOG_FILE" 2>&1

# Loop de iteraciones para monitoreo (Estudiante 3 - Celestita)
# Ejecuta el monitoreo durante 5 iteraciones con intervalo de 60 segundos
for ((i=1; i<=ITERATIONS; i++)); do
  {
    echo "--- Iteración $i de $ITERATIONS ---"
    echo ""
  } >> "$LOG_FILE" 2>&1
  
  # Recolectar métricas del sistema
  recolectar_metricas
  
  # Verificar alertas de memoria
  if ! comprobar_alerta_memoria; then
    # Se generó una alerta, pero continuamos con el monitoreo
    :
  fi
  
  # No dormir en la última iteración
  if [ $i -lt $ITERATIONS ]; then
    sleep "$SLEEP_INTERVAL"
  fi
done

# Mensaje final del monitoreo
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