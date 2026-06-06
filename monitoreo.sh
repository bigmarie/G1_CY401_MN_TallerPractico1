#!/bin/bash

# Funcionalidad: recolectar métricas (top, free, df) con marcas de tiempo
# y generar una alerta si el uso de memoria RAM supera el umbral configurado.

# ---------------------- Variables globales (configurables) ----------------------
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/monitoreo.log"
TIMESTAMP_FMT="%Y-%m-%d %H:%M:%S"
THRESHOLD_MEM=70  # Umbral en porcentaje para generar alerta (por defecto 70)

# ---------------------- Funciones auxiliares ----------------------
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

# ---------------------- Flujo principal ----------------------
crear_directorio_logs
recolectar_metricas
if ! comprobar_alerta_memoria; then
  # Código de salida 1 indica que se generó una alerta
  exit 1
fi

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